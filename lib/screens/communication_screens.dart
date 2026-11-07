import 'dart:async';

import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/nearby_theme.dart';

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

  @override
  void dispose() {
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

    final initials = name.split(' ').map((w) => w[0]).take(2).join();

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
                            'Vecino de la Zona 3 · responde rápido',
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
                    onTap: () {
                      state.sendChat('Hola, ¿a qué hora puedo pasar?');
                      _scrollToBottom();
                      state.toast(
                        'Listo, escribimos lo que dijiste',
                        icon: 'mic',
                      );
                    },
                    borderRadius: BorderRadius.circular(25),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: theme.surface2,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mic,
                        color: theme.primaryDark,
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
                        color: theme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
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
  Widget build(BuildContext context) => ColoredBox(
    color: NearbyColors.navy,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
          const SizedBox(height: 16),
          const Text(
            'La llamada se realiza con el teléfono del dispositivo. Para emergencias, confirma el número en el marcador.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: state.launchCurrentCall,
            icon: const Icon(Icons.call),
            label: const Text('Abrir teléfono'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: state.back,
            child: const Text(
              'Volver a Nearby',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
}
