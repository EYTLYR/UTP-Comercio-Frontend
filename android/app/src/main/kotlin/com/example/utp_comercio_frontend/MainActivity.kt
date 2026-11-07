package com.example.utp_comercio_frontend

import android.Manifest
import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.Uri
import androidx.core.content.ContextCompat
import com.google.android.gms.auth.api.phone.SmsRetriever
import com.google.android.gms.common.api.CommonStatusCodes
import com.google.android.gms.common.api.Status
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var channel: MethodChannel
    private var registered = false
    private var pendingNumber: String? = null
    private var pendingCall: MethodChannel.Result? = null
    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action != SmsRetriever.SMS_RETRIEVED_ACTION) return
            val status = intent.extras?.get(SmsRetriever.EXTRA_STATUS) as? Status ?: return
            if (status.statusCode == CommonStatusCodes.SUCCESS) {
                val consent = intent.extras?.get(SmsRetriever.EXTRA_CONSENT_INTENT) as? Intent ?: return
                try { startActivityForResult(consent, 721) } catch (_: Exception) { }
            }
        }
    }
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "nearby/device")
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "listenSms" -> {
                    if (!registered) {
                        ContextCompat.registerReceiver(this, receiver, IntentFilter(SmsRetriever.SMS_RETRIEVED_ACTION), SmsRetriever.SEND_PERMISSION, null, ContextCompat.RECEIVER_EXPORTED)
                        registered = true
                    }
                    SmsRetriever.getClient(this).startSmsUserConsent(null)
                        .addOnSuccessListener { result.success(null) }
                        .addOnFailureListener { result.error("SMS_UNAVAILABLE", "Escribe el código manualmente", null) }
                }
                "call" -> {
                    val number = call.argument<String>("number") ?: ""
                    if (!Regex("^\\+?[0-9]{3,15}$").matches(number)) { result.success(false) }
                    else if (call.argument<Boolean>("emergency") == true) { result.success(openPhone(number, false)) }
                    else if (ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) == PackageManager.PERMISSION_GRANTED) { result.success(openPhone(number, true)) }
                    else if (pendingCall != null) { result.success(false) }
                    else { pendingNumber = number; pendingCall = result; requestPermissions(arrayOf(Manifest.permission.CALL_PHONE), 722) }
                }
                else -> result.notImplemented()
            }
        }
    }
    private fun openPhone(number: String, direct: Boolean): Boolean {
        return try { startActivity(Intent(if (direct) Intent.ACTION_CALL else Intent.ACTION_DIAL, Uri.fromParts("tel", number, null))); true } catch (_: Exception) { false }
    }
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 722) {
            pendingCall?.success(openPhone(pendingNumber ?: "", grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED))
            pendingCall = null; pendingNumber = null
        }
    }
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 721 && resultCode == Activity.RESULT_OK) {
            channel.invokeMethod("sms", data?.getStringExtra(SmsRetriever.EXTRA_SMS_MESSAGE))
        }
    }
    override fun onDestroy() {
        if (registered) unregisterReceiver(receiver)
        pendingCall?.success(false); pendingCall = null
        super.onDestroy()
    }
}
