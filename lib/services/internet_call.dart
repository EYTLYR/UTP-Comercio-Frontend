import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../api/api_client.dart';

class InternetCall extends ChangeNotifier {
  final ApiClient api;
  InternetCall({required this.api});
  final RTCVideoRenderer remoteAudio = RTCVideoRenderer();
  bool rendererReady = false;
  Future<void>? _rendererInitialization;
  RTCPeerConnection? _peer;
  MediaStream? _microphone;
  Timer? _timer;
  final Stopwatch _duration = Stopwatch();
  Map<String, dynamic>? details;
  String phase = 'idle';
  String? error;
  bool muted = false, speaker = false;
  bool _disposed = false, _polling = false, _remoteAnswered = false;
  final Set<String> _closed = {};
  int _generation = 0, _networkErrors = 0;
  bool get active => const [
    'preparing',
    'ringing',
    'incoming',
    'connecting',
    'connected',
    'ending',
  ].contains(phase);
  String get elapsed =>
      '${(_duration.elapsed.inSeconds ~/ 60).toString().padLeft(2, '0')}:${(_duration.elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
  void _update() {
    if (!_disposed) notifyListeners();
  }

  bool _current(int generation) => !_disposed && generation == _generation;

  void resetSelection() {
    if (active) return;
    phase = 'idle';
    error = null;
    details = null;
    _duration.reset();
  }

  Future<bool> checkIncoming() async {
    if (active || _polling || _disposed) return false;
    _polling = true;
    try {
      final rows = await api.get('calls') as List;
      final available = rows.where(
        (row) => !_closed.contains((row as Map)['id']),
      );
      if (_disposed || active || available.isEmpty) return false;
      details = Map<String, dynamic>.from(available.first as Map);
      phase = 'incoming';
      error = null;
      _duration.reset();
      _watch();
      _update();
      return true;
    } on ApiException {
      return false;
    } finally {
      _polling = false;
    }
  }

  Future<RTCPeerConnection> _prepare(int generation) async {
    final config = Map<String, dynamic>.from(
      await api.get('calls/config') as Map,
    );
    if (!_current(generation)) throw StateError('Llamada cancelada');
    final stream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });
    if (!_current(generation)) {
      for (final track in stream.getTracks()) {
        await track.stop();
      }
      await stream.dispose();
      throw StateError('Llamada cancelada');
    }
    _microphone = stream;
    if (!rendererReady) {
      await (_rendererInitialization ??= remoteAudio.initialize());
      rendererReady = true;
    }
    if (!_current(generation)) throw StateError('Llamada cancelada');
    final peer = await createPeerConnection(config);
    if (!_current(generation)) {
      await peer.close();
      await peer.dispose();
      throw StateError('Llamada cancelada');
    }
    _peer = peer;
    peer.onTrack = (event) {
      if (_current(generation) && event.streams.isNotEmpty) {
        remoteAudio.srcObject = event.streams.first;
      }
    };
    peer.onConnectionState = (state) {
      if (!_current(generation)) return;
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        phase = 'connected';
        _duration.start();
        _update();
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        unawaited(
          end(
            message: 'No se pudo conectar el audio. Revisa la conexión de ambos dispositivos.',
            failed: true,
          ),
        );
      }
    };
    for (final track in stream.getAudioTracks()) {
      await peer.addTrack(track, stream);
    }
    _update();
    return peer;
  }

  Future<String> _description(
    RTCPeerConnection peer,
    RTCSessionDescription description,
  ) async {
    final gathered = Completer<void>();
    peer.onIceGatheringState = (state) {
      if (state == RTCIceGatheringState.RTCIceGatheringStateComplete &&
          !gathered.isCompleted) {
        gathered.complete();
      }
    };
    await peer.setLocalDescription(description);
    await gathered.future.timeout(const Duration(seconds: 8), onTimeout: () {});
    final local = await peer.getLocalDescription();
    if (local?.sdp == null) throw StateError('No se pudo preparar el audio');
    return local!.sdp!;
  }

  Future<void> start(String conversationId) async {
    if (active || _disposed) return;
    final generation = ++_generation;
    phase = 'preparing';
    details = null;
    error = null;
    muted = false;
    speaker = false;
    _remoteAnswered = false;
    _networkErrors = 0;
    _duration.reset();
    _update();
    try {
      final peer = await _prepare(generation);
      final offer = await _description(
        peer,
        await peer.createOffer({'offerToReceiveAudio': true}),
      );
      if (!_current(generation)) return;
      final record = Map<String, dynamic>.from(
        await api.post(
          'calls',
          body: {'conversationId': conversationId, 'offer': offer},
        ) as Map,
      );
      if (!_current(generation)) {
        await api.post('calls/${record['id']}/end');
        return;
      }
      details = record;
      phase = 'ringing';
      _watch();
      _update();
    } catch (e) {
      if (_current(generation)) await end(message: _message(e), failed: true);
    }
  }

  Future<void> accept() async {
    if (phase != 'incoming' || details == null) return;
    final generation = ++_generation;
    phase = 'preparing';
    _remoteAnswered = true;
    _update();
    try {
      final peer = await _prepare(generation);
      await peer.setRemoteDescription(
        RTCSessionDescription(details!['offer'] as String, 'offer'),
      );
      final answer = await _description(peer, await peer.createAnswer());
      if (!_current(generation)) return;
      await api.post(
        'calls/${details!['id']}/answer',
        body: {'answer': answer},
      );
      if (!_current(generation)) return;
      if (phase != 'connected') phase = 'connecting';
      _watch();
      _update();
    } catch (e) {
      if (_current(generation)) await end(message: _message(e), failed: true);
    }
  }

  String _message(Object error) => error is ApiException
      ? error.message
      : 'No se pudo activar el audio. Revisa el permiso del micrófono y la conexión.';
  void _watch() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
  }

  Future<void> _poll() async {
    if (_polling || details == null || !active || _disposed) return;
    _polling = true;
    final generation = _generation;
    try {
      final record = Map<String, dynamic>.from(
        await api.get('calls/${details!['id']}') as Map,
      );
      if (!_current(generation)) return;
      _networkErrors = 0;
      if (const ['ENDED', 'REJECTED', 'MISSED'].contains(record['state'])) {
        await end(
          notifyRemote: false,
          message: record['state'] == 'REJECTED'
              ? 'La llamada fue rechazada'
              : record['state'] == 'MISSED'
              ? 'No hubo respuesta'
              : null,
        );
      } else if (!_remoteAnswered &&
          record['answer'] != null &&
          _peer != null) {
        _remoteAnswered = true;
        phase = 'connecting';
        await _peer!.setRemoteDescription(
          RTCSessionDescription(record['answer'] as String, 'answer'),
        );
      }
      _update();
    } catch (e) {
      if (++_networkErrors >= 3 && _current(generation)) {
        await end(message: 'Se perdió la conexión de la llamada', failed: true);
      }
    } finally {
      _polling = false;
    }
  }

  void toggleMute() {
    muted = !muted;
    for (final track in _microphone?.getAudioTracks() ?? <MediaStreamTrack>[]) {
      track.enabled = !muted;
    }
    _update();
  }

  Future<void> toggleSpeaker() async {
    if (kIsWeb) return;
    try {
      await Helper.setSpeakerphoneOn(!speaker);
      speaker = !speaker;
      _update();
    } catch (_) {
      error = 'No se pudo cambiar la salida de audio';
      _update();
    }
  }

  Future<void> _release() async {
    final peer = _peer;
    _peer = null;
    final stream = _microphone;
    _microphone = null;
    try {
      await peer?.close();
    } catch (_) {}
    try {
      await peer?.dispose();
    } catch (_) {}
    if (stream != null) {
      for (final track in stream.getTracks()) {
        try {
          await track.stop();
        } catch (_) {}
      }
      try {
        await stream.dispose();
      } catch (_) {}
    }
    if (rendererReady) remoteAudio.srcObject = null;
  }

  Future<void> end({
    bool notifyRemote = true,
    String? message,
    bool failed = false,
  }) async {
    ++_generation;
    _timer?.cancel();
    _duration.stop();
    final id = details?['id'];
    final sendEnd = notifyRemote && id != null && !_closed.contains(id);
    if (id != null) {
      _closed.add(id as String);
      if (_closed.length > 100) _closed.remove(_closed.first);
    }
    phase = 'ending';
    error = message;
    _update();
    try {
      await _release();
    } catch (_) {
      /* Release remaining resources on dispose. */
    }
    phase = failed ? 'failed' : 'ended';
    _update();
    if (sendEnd) {
      try {
        await api.post('calls/$id/end');
      } catch (_) {
        /* Server expires abandoned calls. */
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(
      end().whenComplete(() async {
        await _rendererInitialization;
        if (rendererReady) await remoteAudio.dispose();
      }),
    );
    super.dispose();
  }
}
