import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../state/app_state.dart';
import '../theme/nearby_theme.dart';

// --- Bandeja de mensajes ---

/// Todas mis conversaciones: aquí aparecen también las que empezó otro vecino.
class MensajesScreen extends StatefulWidget {
  final AppState state;
  final NearbyThemeData theme;
  const MensajesScreen({super.key, required this.state, required this.theme});

  @override
  State<MensajesScreen> createState() => _MensajesScreenState();
}

class _MensajesScreenState extends State<MensajesScreen> {
  @override
  void initState() {
    super.initState();
    widget.state.loadConversations();
  }

  static String _when(String? iso) {
    final t = iso == null ? null : DateTime.tryParse(iso)?.toLocal();
    if (t == null) return '';
    final now = DateTime.now();
    final hm =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    if (t.year == now.year && t.month == now.month && t.day == now.day) {
      return hm;
    }
    return '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final theme = widget.theme;
    final list = state.conversations;
    return RefreshIndicator(
      onRefresh: state.loadConversations,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
        children: [
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Column(
                children: [
                  Icon(Icons.forum_outlined, size: 56, color: theme.muted),
                  const SizedBox(height: 12),
                  Text(
                    'Aún no tienes mensajes',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: theme.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Cuando respondas un favor o escribas a un oficio, la conversación aparece aquí.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.muted, fontSize: 13.5),
                  ),
                ],
              ),
            ),
          for (final c in list)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                leading: CircleAvatar(
                  backgroundColor: theme.violetSoft,
                  child: Text(
                    (c['otherInitials'] as String?) ?? '?',
                    style: TextStyle(
                      color: theme.violet,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                title: Text(
                  (c['otherUserName'] as String?) ?? 'Vecino',
                  style: TextStyle(
                    fontWeight: ((c['unread'] as num?) ?? 0) > 0
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  (c['lastMessage'] as String?) ??
                      (c['contextText'] as String?) ??
                      '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _when(c['lastAt'] as String?),
                      style: TextStyle(fontSize: 11.5, color: theme.muted),
                    ),
                    if (((c['unread'] as num?) ?? 0) > 0) ...[
                      const SizedBox(height: 4),
                      Badge(
                        label: Text('${c['unread']}'),
                        backgroundColor: NearbyColors.sos,
                      ),
                    ],
                  ],
                ),
                onTap: () => state.openConversation(c),
              ),
            ),
        ],
      ),
    );
  }
}

// --- Chat Screen ---
class ChatScreen extends StatefulWidget {
  final AppState state;
  final NearbyThemeData theme;

  const ChatScreen({super.key, required this.state, required this.theme});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final _voice = widget.state.voice;

  @override
  void initState() {
    super.initState();
    _voice.addListener(_onVoice);
  }

  /// Lo que dice el vecino se escribe en la caja; lo revisa y lo envía él.
  void _onVoice() {
    if (!mounted) return;
    if (_voice.listening && _voice.transcript.isNotEmpty) {
      _msgController.value = TextEditingValue(
        text: _voice.transcript,
        selection: TextSelection.collapsed(offset: _voice.transcript.length),
      );
    }
    if (_voice.error != null && !_voice.listening) {
      widget.state.toast(_voice.error!, icon: 'mic_off');
      _voice.error = null;
    }
    setState(() {});
  }

  Future<void> _toggleVoice() async {
    if (_voice.listening || _voice.preparing) {
      await _voice.stop();
    } else {
      await _voice.start();
    }
  }

  @override
  void dispose() {
    _voice.removeListener(_onVoice);
    _voice.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _msgController.text;
    _msgController.clear();
    widget.state.sendChat(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Timer(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final state = widget.state;
    final name = state.chatWith ?? 'Vecino';
    final msgs = state.chats[name] ?? [];

    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join();
    final convId = state.convIds[name];
    final context0 = state.conversations
        .where((c) => c['id'] == convId)
        .map((c) => c['contextText'] as String?)
        .firstOrNull;

    return Column(
      children: [
        // Chat Header Card
        Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: theme.surface,
            border: Border.all(color: theme.line),
            borderRadius: BorderRadius.circular(18),
            boxShadow: theme.cardShadow,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.violetSoft,
                child: Text(
                  initials,
                  style: TextStyle(
                    color: theme.violet,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: theme.ink,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.verified, color: theme.primary, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            context0 != null && context0.isNotEmpty
                                ? context0
                                : 'Vecino de ${state.zoneName}',
                            style: TextStyle(
                              color: theme.muted,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => state.startCall(name),
                icon: Icon(Icons.call, color: theme.primary),
              ),
            ],
          ),
        ),

        // Safety warning
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.surface,
              border: Border.all(color: theme.line),
              borderRadius: BorderRadius.circular(14),
              boxShadow: theme.cardShadow,
            ),
            child: Row(
              children: [
                Icon(Icons.shield, color: theme.info, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Por tu seguridad, reúnanse en un lugar visible y no compartas datos bancarios.',
                    style: TextStyle(color: theme.muted, fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Messages list
        Expanded(
          child: msgs.isEmpty
              ? Center(
                  child: Text(
                    'Escribe un mensaje para coordinar con ${name.split(" ").first}.',
                    style: TextStyle(color: theme.muted, fontSize: 13),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final m = msgs[i];
                    if (m.from == 'sys') {
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.primarySoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            m.text,
                            style: TextStyle(
                              color: theme.primaryDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      );
                    }

                    final isMine = m.from == 'me';
                    return Align(
                      alignment: isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        constraints: const BoxConstraints(maxWidth: 280),
                        decoration: BoxDecoration(
                          color: isMine ? theme.btnBg : theme.surface,
                          border: isMine ? null : Border.all(color: theme.line),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isMine ? 18 : 6),
                            bottomRight: Radius.circular(isMine ? 6 : 18),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              m.text,
                              style: TextStyle(
                                color: isMine ? theme.btnInk : theme.ink,
                                fontSize: 14,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  m.time,
                                  style: TextStyle(
                                    color: (isMine ? theme.btnInk : theme.muted)
                                        .withValues(alpha: 0.7),
                                    fontSize: 11,
                                  ),
                                ),
                                if (isMine) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    m.pending ? Icons.schedule : Icons.done_all,
                                    size: 14,
                                    color: (isMine ? theme.btnInk : theme.muted)
                                        .withValues(alpha: 0.7),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Quick responses & composer
        Container(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
          decoration: BoxDecoration(
            color: theme.surface,
            border: Border(top: BorderSide(color: theme.line)),
          ),
          child: Column(
            children: [
              // Quick responses scroll
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children:
                      [
                        '¿A qué hora te queda bien?',
                        'Voy en 10 minutos',
                        '¡Muchas gracias, vecino!',
                      ].map((q) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            label: Text(
                              q,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.ink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: theme.surface2,
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              state.sendChat(q);
                              _scrollToBottom();
                            },
                          ),
                        );
                      }).toList(),
                ),
              ),
              const SizedBox(height: 8),

              // Composer
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: theme.surface2,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: theme.line),
                      ),
                      child: TextField(
                        controller: _msgController,
                        onSubmitted: (_) => _send(),
                        style: TextStyle(color: theme.ink, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Escribe un mensaje',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _toggleVoice,
                    borderRadius: BorderRadius.circular(25),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: theme.surface2,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _voice.listening ? Icons.stop : Icons.mic,
                        color: _voice.listening
                            ? NearbyColors.sos
                            : theme.primaryDark,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _send,
                    borderRadius: BorderRadius.circular(25),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: NearbyColors.brandTurquoise,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: NearbyColors.onPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- Call Screen ---
class CallScreen extends StatelessWidget {
  final AppState state;
  final NearbyThemeData theme;
  const CallScreen({super.key, required this.state, required this.theme});
  @override
  Widget build(BuildContext context) {
    final call = state.internetCall;
    final emergency = state.callWith?['emergency'] == true;
    final inApp = call.active;
    final label = switch (call.phase) {
      'preparing' => 'Preparando micrófono y conexión…',
      'ringing' => 'Esperando que el vecino responda…',
      'incoming' => 'Llamada entrante de Nearby',
      'connecting' => 'Conectando audio…',
      'connected' => 'En llamada · ${call.elapsed}',
      'ending' => 'Cerrando llamada…',
      'ended' => 'Llamada finalizada',
      'failed' => 'No se pudo conectar',
      _ => 'Elige cómo quieres llamar',
    };
    return ColoredBox(
      color: NearbyColors.navy,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            const Icon(Icons.phone_in_talk, color: Colors.white, size: 72),
            const SizedBox(height: 24),
            Text(
              state.callWith?['name'] as String? ?? 'Teléfono',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            if (call.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  call.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            const SizedBox(height: 24),
            if (call.phase == 'incoming')
              FilledButton.icon(
                onPressed: call.accept,
                icon: const Icon(Icons.call),
                label: const Text('Contestar en Nearby'),
              ),
            if (call.phase == 'connected')
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: call.toggleMute,
                    icon: Icon(call.muted ? Icons.mic_off : Icons.mic),
                    label: Text(call.muted ? 'Activar micrófono' : 'Silenciar'),
                  ),
                  if (!kIsWeb)
                    FilledButton.tonalIcon(
                      onPressed: call.toggleSpeaker,
                      icon: Icon(
                        call.speaker ? Icons.volume_up : Icons.hearing,
                      ),
                      label: Text(call.speaker ? 'Auricular' : 'Altavoz'),
                    ),
                ],
              ),
            if (inApp) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: NearbyColors.sos,
                ),
                onPressed: () => call.end(),
                icon: const Icon(Icons.call_end),
                label: Text(call.phase == 'incoming' ? 'Rechazar' : 'Colgar'),
              ),
            ] else ...[
              if (!emergency) ...[
                FilledButton.icon(
                  key: const ValueKey('nearby-internet-call'),
                  onPressed: state.startInternetCall,
                  icon: const Icon(Icons.wifi_calling_3),
                  label: const Text('Llamar dentro de Nearby'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Por internet · Ambos usuarios deben tener Nearby abierto.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
              ],
              FilledButton.icon(
                key: const ValueKey('nearby-cellular-call'),
                onPressed: state.callLaunching
                    ? null
                    : () => state.launchCurrentCall(),
                icon: const Icon(Icons.call),
                label: Text(
                  emergency
                      ? 'Llamar al servicio de emergencia'
                      : 'Llamar por línea celular',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const ValueKey('nearby-open-dialer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
                onPressed: state.callLaunching
                    ? null
                    : () => state.launchCurrentCall(dialOnly: true),
                icon: const Icon(Icons.dialpad),
                label: const Text('Abrir marcador del teléfono'),
              ),
              const SizedBox(height: 16),
              Text(
                emergency
                    ? 'Las emergencias se confirman en el marcador del sistema.'
                    : 'La llamada celular utiliza tu operador y el permiso de llamadas del dispositivo.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
            const SizedBox(height: 20),
            TextButton(
              onPressed: state.back,
              child: const Text(
                'Volver a Nearby',
                style: TextStyle(color: Colors.white),
              ),
            ),
            if (call.rendererReady)
              SizedBox(
                width: 1,
                height: 1,
                child: RTCVideoView(call.remoteAudio),
              ),
          ],
        ),
      ),
    );
  }
}
