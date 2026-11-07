import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

abstract class SpeechInput extends ChangeNotifier {
  String transcript = '';
  String? error;
  bool listening = false;
  bool preparing = false;
  Future<void> start();
  Future<void> stop();
  Future<void> cancel();
}

/// One recognizer per application, with callbacks detached by cancel/dispose.
class DeviceSpeechInput extends SpeechInput {
  final SpeechToText _speech = SpeechToText();
  int _session = 0;
  bool _disposed = false;
  bool _acceptResults = false;

  void _update() {
    if (!_disposed) notifyListeners();
  }

  @override
  Future<void> start() async {
    if (preparing || listening || _disposed) return;
    final session = ++_session;
    preparing = true;
    error = null;
    transcript = '';
    _acceptResults = true;
    _update();
    try {
      final available = await _speech.initialize(
        options: [SpeechToText.androidNoBluetooth],
        onStatus: (status) {
          if (!_acceptResults || _disposed) return;
          listening = status == 'listening';
          _update();
        },
        onError: (failure) {
          if (!_acceptResults || _disposed) return;
          listening = false;
          error = switch (failure.errorMsg) {
            'error_permission' || 'error_not_allowed' || 'not-allowed' => 'Permite el acceso al micrófono y al reconocimiento de voz en los ajustes de la app o del navegador.',
            'error_no_match' || 'error_speech_timeout' || 'no-speech' =>
              'No se detectó voz. Acércate al micrófono e inténtalo otra vez.',
            'error_network' || 'network' => 'El reconocimiento necesita conexión en este dispositivo. Puedes escribir tu mensaje.',
            _ =>
              'No se pudo escuchar. Revisa el micrófono y vuelve a intentarlo.',
          };
          _update();
        },
      );
      if (_disposed || session != _session) return;
      if (!available) {
        error = 'El reconocimiento de voz no está disponible o no tiene permiso. Permite el micrófono en los ajustes o escribe tu mensaje.';
        return;
      }
      final locales = await _speech.locales();
      if (_disposed || session != _session) return;
      final spanish = locales
          .where((locale) => locale.localeId.toLowerCase().startsWith('es'))
          .toList();
      final locale =
          spanish
              .where(
                (locale) =>
                    locale.localeId.replaceAll('_', '-').toLowerCase() ==
                    'es-pe',
              )
              .firstOrNull ??
          spanish.firstOrNull;
      await _speech.listen(
        listenOptions: SpeechListenOptions(
          localeId: locale?.localeId ?? (kIsWeb ? 'es-PE' : 'es_PE'),
          listenFor: const Duration(seconds: 60),
          pauseFor: const Duration(seconds: 5),
          partialResults: true,
          cancelOnError: true,
        ),
        onResult: (result) {
          if (_disposed || !_acceptResults || session != _session) return;
          transcript = result.recognizedWords;
          _update();
        },
      );
      if (_disposed || session != _session) await _speech.cancel();
    } catch (_) {
      if (!_disposed && session == _session) {
        error = 'No se pudo activar el micrófono. Revisa los permisos y vuelve a intentarlo.';
      }
    } finally {
      if (!_disposed && session == _session) {
        preparing = false;
        listening = _speech.isListening;
        _update();
      }
    }
  }

  @override
  Future<void> stop() async {
    try {
      if (_speech.isListening) await _speech.stop();
    } catch (_) {
      error = 'No se pudo detener el reconocimiento. Puedes revisar el texto capturado.';
    } finally {
      listening = false;
      _update();
    }
  }

  @override
  Future<void> cancel() async {
    _acceptResults = false;
    _session++;
    preparing = false;
    listening = false;
    try {
      await _speech.cancel();
    } catch (_) {
      /* Not initialized yet. */
    }
  }

  @override
  void dispose() {
    _disposed = true;
    cancel();
    super.dispose();
  }
}
