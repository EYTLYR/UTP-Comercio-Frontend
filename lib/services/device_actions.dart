import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class DeviceActions {
  static const channel = MethodChannel('nearby/device');
  Future<void> listenForSms() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await channel.invokeMethod<void>('listenSms');
    } on PlatformException {
      /* Manual entry remains available. */
    } on MissingPluginException {
      /* Unsupported host. */
    }
  }

  Future<bool> call(
    String number, {
    required bool emergency,
    bool dialOnly = false,
  }) async {
    if (!RegExp(r'^\+?[0-9]{3,15}$').hasMatch(number)) return false;
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        return await channel.invokeMethod<bool>('call', {
              'number': number,
              'emergency': emergency,
              if (dialOnly) 'dialOnly': true,
            }) ??
            false;
      }
      return await launchUrl(Uri(scheme: 'tel', path: number));
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
