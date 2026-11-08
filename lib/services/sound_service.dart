import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Servicio de efectos de sonido y tonos de llamada / emergencia.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _callPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.loop);
  final AudioPlayer _alarmPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.loop);
  final AudioPlayer _sfxPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.release);

  bool _callRinging = false;
  bool _sosAlarming = false;

  /// Si es true, silencia por completo cualquier sonido para proteger la vida del usuario en Modo Sigiloso.
  bool isSilentMode = false;

  bool get isCallRinging => _callRinging;
  bool get isSosAlarming => _sosAlarming;

  /// Tono de llamada saliente ("tuu... tuu..."): suena mientras espera que contesten.
  Future<void> playCallDialing() async {
    if (isSilentMode) return;
    try {
      await stopCallSounds();
      _callRinging = true;
      await _callPlayer.setReleaseMode(ReleaseMode.loop);
      await _callPlayer.play(AssetSource('sounds/call_dialing.wav'));
    } catch (e) {
      debugPrint('[SoundService] playCallDialing error: $e');
    }
  }

  /// Timbre de llamada entrante ("ringtone"): suena cuando otro vecino nos está llamando.
  Future<void> playCallRingtone() async {
    if (isSilentMode) return;
    try {
      await stopCallSounds();
      _callRinging = true;
      await _callPlayer.setReleaseMode(ReleaseMode.loop);
      await _callPlayer.play(AssetSource('sounds/call_ringtone.wav'));
    } catch (e) {
      debugPrint('[SoundService] playCallRingtone error: $e');
    }
  }

  /// Tono al colgar o cortar la llamada ("beep-beep-beep").
  Future<void> playCallEnded() async {
    if (isSilentMode) return;
    try {
      await stopCallSounds();
      await _sfxPlayer.play(AssetSource('sounds/call_ended.wav'));
    } catch (e) {
      debugPrint('[SoundService] playCallEnded error: $e');
    }
  }

  /// Detiene cualquier tono de llamada (entrante o saliente).
  Future<void> stopCallSounds() async {
    _callRinging = false;
    try {
      await _callPlayer.stop();
    } catch (_) {}
  }

  int _alarmGeneration = 0;

  /// Sirena de alerta de emergencia SOS de alta prioridad.
  Future<void> playSosAlarm() async {
    if (isSilentMode) return;
    final gen = ++_alarmGeneration;
    _sosAlarming = true;
    try {
      await _alarmPlayer.setReleaseMode(ReleaseMode.loop);
      if (_alarmGeneration != gen || !_sosAlarming || isSilentMode) {
        await _alarmPlayer.stop();
        return;
      }
      await _alarmPlayer.play(AssetSource('sounds/sos_alarm.wav'));
      if (_alarmGeneration != gen || !_sosAlarming || isSilentMode) {
        await _alarmPlayer.stop();
        await _alarmPlayer.seek(Duration.zero);
      }
    } catch (e) {
      debugPrint('[SoundService] playSosAlarm error: $e');
    }
  }

  /// Detiene la alarma de emergencia SOS.
  Future<void> stopSosAlarm() async {
    _sosAlarming = false;
    _alarmGeneration++;
    try {
      await _alarmPlayer.stop();
      await _alarmPlayer.seek(Duration.zero);
    } catch (_) {}
  }

  /// Pulso de advertencia en cuenta regresiva SOS (3, 2, 1...).
  Future<void> playSosCountdown() async {
    if (isSilentMode) return;
    try {
      await _sfxPlayer.play(AssetSource('sounds/sos_countdown.wav'));
    } catch (e) {
      debugPrint('[SoundService] playSosCountdown error: $e');
    }
  }

  /// Notificación corta tipo pop al enviar o recibir mensajes.
  Future<void> playMessagePop() async {
    if (isSilentMode) return;
    try {
      await _sfxPlayer.play(AssetSource('sounds/message_pop.wav'));
    } catch (e) {
      debugPrint('[SoundService] playMessagePop error: $e');
    }
  }

  /// Detiene todos los sonidos activos de forma inmediata.
  Future<void> stopAll() async {
    await stopCallSounds();
    await stopSosAlarm();
    try {
      await _sfxPlayer.stop();
    } catch (_) {}
  }

  void dispose() {
    _callPlayer.dispose();
    _alarmPlayer.dispose();
    _sfxPlayer.dispose();
  }
}
