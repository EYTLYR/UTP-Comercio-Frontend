import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../state/app_state.dart';
import '../theme/nearby_theme.dart';

/// Ancho máximo de mensajes y chat en escritorio.
const double _kMaxWidth = 720;

/// Margen lateral que centra el contenido hasta [maxWidth].
double _sideFor(double width, [double maxWidth = _kMaxWidth]) {
  final base = width < 360 ? 16.0 : 24.0;
  final centered = (width - maxWidth) / 2;
  return centered > base ? centered : base;
}

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
  NearbyCommunityStyle get ui => NearbyCommunityStyle(widget.theme);
  String _filter = 'all';

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

  static ({String kind, String label, IconData icon, Color color, Color bg})
  _categorize(Map<String, dynamic> c) {
    final contextText = (c['contextText'] as String? ?? '').trim();
    final serviceTitle = (c['serviceTitle'] as String? ?? '').trim();
    final postType = (c['postType'] as String? ?? '').trim();

    if (contextText.contains('Emergencia SOS') || contextText.contains('SOS')) {
      final clean = contextText.replaceFirst(
        RegExp(r'^Emergencia\s*SOS:\s*', caseSensitive: false),
        '',
      );
      return (
        kind: 'sos',
        label: clean.isNotEmpty ? 'SOS · $clean' : 'Emergencia SOS',
        icon: Icons.crisis_alert,
        color: NearbyColors.sos,
        bg: NearbyColors.sos.withValues(alpha: 0.12),
      );
    }
    if (serviceTitle.isNotEmpty ||
        contextText.toLowerCase().startsWith('sobre:') ||
        contextText.toLowerCase().startsWith('servicio:')) {
      String clean = serviceTitle.isNotEmpty
          ? serviceTitle
          : contextText.replaceFirst(
            RegExp(r'^(sobre|servicio):\s*', caseSensitive: false),
            '',
          );
      return (
        kind: 'services',
        label: clean.isNotEmpty ? 'Servicio: $clean' : 'Servicio vecinal',
        icon: Icons.handyman_outlined,
        color: const Color(0xFF1E5BB0),
        bg: const Color(0xFFEBF3FF),
      );
    }
    if (contextText.toLowerCase().contains('préstamo') ||
        contextText.toLowerCase().contains('prestamo')) {
      return (
        kind: 'resources',
        label: contextText,
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFF007A5E),
        bg: const Color(0xFFE6F7F2),
      );
    }
    if (postType.isNotEmpty ||
        contextText.toLowerCase().contains('publicación') ||
        contextText.toLowerCase().contains('publicacion') ||
        contextText.toLowerCase().contains('favor') ||
        contextText.toLowerCase().contains('ayuda')) {
      String clean = contextText.replaceFirst(
        RegExp(r'^publicaci[oó]n:\s*', caseSensitive: false),
        '',
      );
      if (clean.isEmpty) clean = 'Favor del muro';
      return (
        kind: 'posts',
        label: clean,
        icon: Icons.volunteer_activism_outlined,
        color: const Color(0xFF945B00),
        bg: const Color(0xFFFFF7E6),
      );
    }
    if (contextText.isNotEmpty) {
      return (
        kind: 'other',
        label: contextText,
        icon: Icons.chat_bubble_outline,
        color: const Color(0xFF4A5568),
        bg: const Color(0xFFF1F5F9),
      );
    }
    return (
      kind: 'direct',
      label: 'Mensaje directo',
      icon: Icons.chat_outlined,
      color: const Color(0xFF64748B),
      bg: const Color(0xFFF1F5F9),
    );
  }

  Widget _filterChip(String id, String label, IconData icon, int count) {
    final selected = _filter == id;
    return InkWell(
      onTap: () => setState(() => _filter = id),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? ui.ink : ui.ivory,
          border: Border.all(color: selected ? ui.ink : ui.line),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? Colors.white : ui.muted),
            const SizedBox(width: 6),
            Text(
              '$label ($count)',
              style: TextStyle(
                color: selected ? Colors.white : ui.ink,
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final theme = widget.theme;
    final list = state.conversations;

    final servicesCount =
        list.where((c) => _categorize(c).kind == 'services').length;
    final postsCount =
        list.where((c) {
          final k = _categorize(c).kind;
          return k == 'posts' || k == 'resources';
        }).length;
    final sosCount = list.where((c) => _categorize(c).kind == 'sos').length;

    final filteredList = switch (_filter) {
      'services' =>
        list.where((c) => _categorize(c).kind == 'services').toList(),
      'posts' =>
        list.where((c) {
          final k = _categorize(c).kind;
          return k == 'posts' || k == 'resources';
        }).toList(),
      'sos' => list.where((c) => _categorize(c).kind == 'sos').toList(),
      _ => list,
    };

    return ColoredBox(
      color: theme.surface,
      child: LayoutBuilder(
        builder: (context, box) {
          final side = _sideFor(box.maxWidth, double.infinity);
          return RefreshIndicator(
            onRefresh: state.loadConversations,
            color: ui.ink,
            child: ListView(
              padding: EdgeInsets.fromLTRB(side, 8, side, 120),
              children: [
                Text(
                  'Tus conversaciones',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: ui.ink,
                    letterSpacing: -0.5,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Aquí aparecen también las que empezó otro vecino.',
                  style: TextStyle(color: ui.muted, fontSize: 14),
                ),
                const SizedBox(height: 16),

                // Filtros de categoría rápida
                if (list.isNotEmpty) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip(
                          'all',
                          'Todos',
                          Icons.all_inbox,
                          list.length,
                        ),
                        const SizedBox(width: 8),
                        _filterChip(
                          'services',
                          'Servicios',
                          Icons.handyman_outlined,
                          servicesCount,
                        ),
                        const SizedBox(width: 8),
                        _filterChip(
                          'posts',
                          'Favores',
                          Icons.volunteer_activism_outlined,
                          postsCount,
                        ),
                        const SizedBox(width: 8),
                        _filterChip(
                          'sos',
                          'SOS',
                          Icons.crisis_alert,
                          sosCount,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (list.isEmpty)
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                    decoration: BoxDecoration(
                      color: ui.ivory,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: ui.blueSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.forum_outlined,
                            size: 28,
                            color: ui.ink,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Aún no tienes mensajes',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: ui.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Cuando respondas un favor o escribas a un oficio, la conversación aparece aquí.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: ui.muted, fontSize: 13.5),
                        ),
                      ],
                    ),
                  )
                else if (filteredList.isEmpty)
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    decoration: BoxDecoration(
                      color: ui.ivory,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.filter_list, size: 28, color: ui.muted),
                        const SizedBox(height: 10),
                        Text(
                          'No hay chats en esta categoría',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: ui.ink,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: theme.surface,
                      border: Border.all(color: ui.line),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (var i = 0; i < filteredList.length; i++) ...[
                          if (i > 0) Divider(height: 1, color: ui.line),
                          _conversationRow(filteredList[i]),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _conversationRow(Map<String, dynamic> c) {
    final unread = ((c['unread'] as num?) ?? 0) > 0;
    final cat = _categorize(c);
    final lastMsg = (c['lastMessage'] as String?)?.trim();
    final isSystemLast =
        lastMsg != null &&
        (lastMsg.startsWith('Aceptaste') ||
            lastMsg.startsWith('Le ofreciste') ||
            lastMsg.startsWith('Te interesa') ||
            lastMsg.startsWith('Emergencia'));

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => widget.state.openConversation(c),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar con indicador de categoría en la esquina
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          unread
                              ? ui.accent.withValues(alpha: 0.16)
                              : ui.blueSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      (c['otherInitials'] as String?) ?? '?',
                      style: TextStyle(
                        color: ui.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: cat.color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.theme.surface,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(cat.icon, size: 9, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fila 1: Nombre + Hora
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            (c['otherUserName'] as String?) ?? 'Vecino',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: ui.ink,
                              fontSize: 14.5,
                              fontWeight:
                                  unread ? FontWeight.w700 : FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _when(c['lastAt'] as String?),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: unread ? ui.ink : ui.muted,
                            fontWeight:
                                unread ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Fila 2: CHIP DESTACADO DEL SERVICIO / TEMA
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: cat.bg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.icon, size: 11, color: cat.color),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              cat.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: cat.color,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Fila 3: Último mensaje + badge de no leídos
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            (lastMsg != null && lastMsg.isNotEmpty)
                                ? lastMsg
                                : 'Toca para abrir la conversación',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: unread ? ui.ink : ui.muted,
                              fontSize: 12.5,
                              fontStyle:
                                  isSystemLast
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                              fontWeight:
                                  unread ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (unread) ...[
                          const SizedBox(width: 6),
                          Container(
                            constraints: const BoxConstraints(minWidth: 20),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: ui.accent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${c['unread']}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: ui.onAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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

  NearbyCommunityStyle get ui => NearbyCommunityStyle(widget.theme);

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
    final convId = state.activeConversationId ?? state.convIds[name];
    final activeConv =
        state.conversations.where((c) => c['id'] == convId).firstOrNull;
    final context0 =
        (activeConv?['contextText'] as String?) ??
        (activeConv?['serviceTitle'] as String?) ??
        state.activeConversationContext;

    // Burbuja propia: tinta con texto blanco (en oscuro, colores del botón).
    final mineBg = ui.light ? ui.ink : theme.btnBg;
    final mineInk = ui.light ? Colors.white : theme.btnInk;

    return ColoredBox(
      color: theme.surface,
      child: LayoutBuilder(
        builder: (context, box) {
          final side = _sideFor(box.maxWidth, double.infinity);
          final bubbleMax = math.min((box.maxWidth - side * 2) * 0.78, 460.0);
          return Column(
            children: [
              // Cabecera del chat
              Padding(
                padding: EdgeInsets.fromLTRB(side, 4, side, 8),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    border: Border.all(color: ui.line),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ui.blueSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          initials,
                          style: TextStyle(
                            color: ui.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: ui.ink,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.verified_outlined,
                                  color: ui.ink,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    context0 != null && context0.isNotEmpty
                                        ? context0
                                        : 'Vecino de ${state.zoneName}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: ui.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => state.startCall(name),
                        style: ui
                            .action(filled: false)
                            .copyWith(
                              minimumSize: const WidgetStatePropertyAll(
                                Size(44, 44),
                              ),
                              padding: const WidgetStatePropertyAll(
                                EdgeInsets.zero,
                              ),
                              side: WidgetStatePropertyAll(
                                BorderSide(color: ui.line),
                              ),
                            ),
                        child: Tooltip(
                          message: 'Llamar',
                          child: Icon(Icons.call_outlined, color: ui.ink),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Banner del servicio o motivo de la conversación
              if (context0 != null && context0.isNotEmpty) ...[
                Padding(
                  padding: EdgeInsets.fromLTRB(side, 0, side, 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: ui.ivory,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ui.line),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          context0.contains('SOS')
                              ? Icons.crisis_alert
                              : (context0.toLowerCase().contains('servicio') ||
                                      context0.toLowerCase().contains('sobre')
                                  ? Icons.handyman_outlined
                                  : Icons.chat_bubble_outline),
                          size: 16,
                          color: context0.contains('SOS')
                              ? NearbyColors.sos
                              : ui.ink,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context0.startsWith('Sobre:') ||
                                    context0.startsWith('Servicio:')
                                ? 'Tema: ${context0.replaceFirst(RegExp(r'^(Sobre|Servicio):\s*', caseSensitive: false), '')}'
                                : context0,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: ui.ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Aviso de seguridad
              Padding(
                padding: EdgeInsets.symmetric(horizontal: side),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: ui.blueSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shield_outlined, color: ui.ink, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Por tu seguridad, reúnanse en un lugar visible y no compartas datos bancarios.',
                          style: TextStyle(color: ui.ink, fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Mensajes
              Expanded(
                child: msgs.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: side),
                          child: Text(
                            'Escribe un mensaje para coordinar con ${name.split(" ").first}.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: ui.muted, fontSize: 13),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.fromLTRB(side, 12, side, 12),
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
                                  color: ui.blueSoft,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  m.text,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: ui.ink,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }

                          final isMine = m.from == 'me';
                          final fg = isMine ? mineInk : ui.ink;
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
                              constraints: BoxConstraints(maxWidth: bubbleMax),
                              decoration: BoxDecoration(
                                color: isMine ? mineBg : ui.ivory,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(14),
                                  topRight: const Radius.circular(14),
                                  bottomLeft: Radius.circular(isMine ? 14 : 4),
                                  bottomRight: Radius.circular(isMine ? 4 : 14),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    m.text,
                                    style: TextStyle(
                                      color: fg,
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
                                          color: isMine
                                              ? fg.withValues(alpha: 0.75)
                                              : ui.muted,
                                          fontSize: 11,
                                        ),
                                      ),
                                      if (isMine) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          m.pending
                                              ? Icons.schedule
                                              : Icons.done_all,
                                          size: 14,
                                          color: fg.withValues(alpha: 0.75),
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

              // Respuestas rápidas y caja de texto
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(side, 10, side, 16),
                decoration: BoxDecoration(
                  color: theme.surface,
                  border: Border(top: BorderSide(color: ui.line)),
                ),
                child: Column(
                  children: [
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
                                padding: const EdgeInsets.only(right: 8),
                                child: OutlinedButton(
                                  onPressed: () {
                                    state.sendChat(q);
                                    _scrollToBottom();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: ui.ink,
                                    backgroundColor: theme.surface,
                                    side: BorderSide(color: ui.line),
                                    minimumSize: const Size(0, 36),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    textStyle: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  child: Text(q),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: theme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: ui.line),
                            ),
                            child: TextField(
                              controller: _msgController,
                              onSubmitted: (_) => _send(),
                              style: TextStyle(color: ui.ink, fontSize: 14),
                              decoration: const InputDecoration(
                                hintText: 'Escribe un mensaje',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _squareButton(
                          icon: _voice.listening ? Icons.stop : Icons.mic,
                          tooltip: _voice.listening
                              ? 'Detener dictado'
                              : 'Dictar mensaje',
                          bg: _voice.listening ? theme.sosSoft : ui.blueSoft,
                          fg: _voice.listening ? NearbyColors.sos : ui.ink,
                          onTap: _toggleVoice,
                        ),
                        const SizedBox(width: 8),
                        _squareButton(
                          icon: Icons.send,
                          tooltip: 'Enviar',
                          bg: ui.accent,
                          fg: ui.onAccent,
                          onTap: _send,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _squareButton({
    required IconData icon,
    required String tooltip,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
  }) => Tooltip(
    message: tooltip,
    child: Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: fg, size: 20),
        ),
      ),
    ),
  );
}

// --- Call Screen ---
class CallScreen extends StatelessWidget {
  final AppState state;
  final NearbyThemeData theme;
  const CallScreen({super.key, required this.state, required this.theme});

  NearbyCommunityStyle get ui => NearbyCommunityStyle(theme);

  ButtonStyle _full(ButtonStyle s) => s.copyWith(
    minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
  );

  /// Rojo solo para colgar o llamar a emergencias.
  ButtonStyle get _redStyle => _full(
    ui.action().copyWith(
      backgroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled) ? ui.line : NearbyColors.sos,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled) ? ui.muted : Colors.white,
      ),
    ),
  );

  Widget _note(String text) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: ui.blueSoft,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, color: ui.ink, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: TextStyle(color: ui.ink, fontSize: 12.5)),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final call = state.internetCall;
    final isPublicEmergency = state.callWith?['publicEmergency'] == true;
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
      color: theme.surface,
      child: LayoutBuilder(
        builder: (context, box) {
          final side = _sideFor(box.maxWidth, 560);
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(side, 24, side, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  emergency ? 'LLAMADA DE EMERGENCIA' : 'LLAMADA',
                  style: TextStyle(
                    color: ui.ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),

                // Panel tinta con el contacto y el estado
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                  decoration: BoxDecoration(
                    color: ui.panel,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: emergency ? NearbyColors.sos : ui.accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.phone_in_talk,
                          color: emergency ? Colors.white : ui.onAccent,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.callWith?['name'] as String? ?? 'Teléfono',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ui.onPanel,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ui.onPanel.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                      if (call.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            call.error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: ui.onPanel,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (call.phase == 'incoming') ...[
                  ElevatedButton.icon(
                    onPressed: call.accept,
                    style: _full(ui.action()),
                    icon: const Icon(Icons.call),
                    label: const Text('Contestar en Nearby'),
                  ),
                  const SizedBox(height: 12),
                ],
                if (call.phase == 'connected') ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: call.toggleMute,
                          style: ui.action(filled: false),
                          icon: Icon(call.muted ? Icons.mic_off : Icons.mic),
                          label: Text(
                            call.muted ? 'Activar micrófono' : 'Silenciar',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (!kIsWeb) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: call.toggleSpeaker,
                            style: ui.action(filled: false),
                            icon: Icon(
                              call.speaker ? Icons.volume_up : Icons.hearing,
                            ),
                            label: Text(
                              call.speaker ? 'Auricular' : 'Altavoz',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                if (inApp) ...[
                  ElevatedButton.icon(
                    style: _redStyle,
                    onPressed: () => call.end(),
                    icon: const Icon(Icons.call_end),
                    label: Text(
                      call.phase == 'incoming' ? 'Rechazar' : 'Colgar',
                    ),
                  ),
                ] else ...[
                  if (!isPublicEmergency) ...[
                    ElevatedButton.icon(
                      key: const ValueKey('nearby-internet-call'),
                      onPressed: state.startInternetCall,
                      style: _full(ui.action()),
                      icon: const Icon(Icons.wifi_calling_3),
                      label: const Text('Llamar dentro de Nearby'),
                    ),
                    const SizedBox(height: 10),
                    _note(
                      'Por internet · Ambos usuarios deben tener Nearby abierto.',
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: Divider(color: ui.line)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'o',
                            style: TextStyle(color: ui.muted, fontSize: 12),
                          ),
                        ),
                        Expanded(child: Divider(color: ui.line)),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (isPublicEmergency)
                    ElevatedButton.icon(
                      key: const ValueKey('nearby-cellular-call'),
                      onPressed: state.callLaunching
                          ? null
                          : () => state.launchCurrentCall(),
                      style: _redStyle,
                      icon: const Icon(Icons.call),
                      label: const Text('Llamar al servicio de emergencia'),
                    )
                  else
                    OutlinedButton.icon(
                      key: const ValueKey('nearby-cellular-call'),
                      onPressed: state.callLaunching
                          ? null
                          : () => state.launchCurrentCall(),
                      style: _full(ui.action(filled: false)),
                      icon: const Icon(Icons.phone_android),
                      label: Text('Llamar al celular de ${state.callWith?['name']}'),
                    ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    key: const ValueKey('nearby-open-dialer'),
                    style: _full(
                      ui
                          .action(filled: false)
                          .copyWith(
                            side: WidgetStatePropertyAll(
                              BorderSide(color: ui.line),
                            ),
                          ),
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
                    style: TextStyle(color: ui.muted, fontSize: 12.5),
                  ),
                ],
                const SizedBox(height: 16),
                Center(
                  child: TextButton.icon(
                    onPressed: state.back,
                    style: TextButton.styleFrom(foregroundColor: ui.ink),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Volver a Nearby'),
                  ),
                ),
                if (call.rendererReady)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 1,
                      height: 1,
                      child: RTCVideoView(call.remoteAudio),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
