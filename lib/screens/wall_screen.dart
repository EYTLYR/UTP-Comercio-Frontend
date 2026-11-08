import 'package:flutter/material.dart';

import '../widgets/navigation_chrome.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/nearby_theme.dart';

class WallScreen extends StatelessWidget {
  final AppState state;
  final NearbyThemeData theme;
  NearbyCommunityStyle get ui => NearbyCommunityStyle(theme);

  const WallScreen({super.key, required this.state, required this.theme});

  @override
  Widget build(BuildContext context) {
    final filtered = state.posts.where((p) {
      // Ignorar automáticamente publicaciones que no estén en estado OPEN en las pestañas Necesitan / Ofrecen
      if (p.status != 'OPEN' && !p.mine) return false;
      final matchesSeg = state.muroSeg == 'all' || p.type == state.muroSeg;
      final matchesCat = state.muroCat == null || p.cat == state.muroCat;
      return matchesSeg && matchesCat;
    }).toList();
    final selectedCategory = kPostCats
        .where((category) => category.id == state.muroCat)
        .firstOrNull;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 1 columna en móvil; 2 desde 700 px y 3 desde 1050 px.
        final width = constraints.maxWidth;
        final cols = width >= 1050 ? 3 : (width >= 700 ? 2 : 1);
        // En ancho, las tarjetas se alinean con el encabezado (24).
        final side = cols == 1 ? 16.0 : 24.0;
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: NavigationInsets.of(context).top),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Muro solidario',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: ui.ink,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cadena de favores entre vecinos.',
                            style: TextStyle(color: ui.muted, fontSize: 14),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: ui.ivory,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                '${state.posts.length}',
                                style: TextStyle(
                                  color: ui.ink,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    state.posts.length == 1
                                        ? 'favor cerca de ti'
                                        : 'favores cerca de ti',
                                    style: TextStyle(
                                      color: ui.ink,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    () {
                                      final mine = state.posts
                                          .where(
                                            (post) =>
                                                post.mine || post.dist == 'tú',
                                          )
                                          .length;
                                      if (mine > 0) {
                                        return 'Tú publicaste $mine';
                                      }
                                      return state.posts.isEmpty
                                          ? 'Publica el primero y suma a la cadena'
                                          : 'Pide u ofrece ayuda y suma a la cadena';
                                    }(),
                                    style: TextStyle(
                                      color: ui.muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: ui.line)),
                        ),
                        child: Row(
                          children: [
                            _segButton('all', 'Todo'),
                            _segButton('need', 'Necesitan'),
                            _segButton('offer', 'Ofrecen'),
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              tooltip: selectedCategory == null
                                  ? 'Filtrar por categoría'
                                  : 'Categoría: ${selectedCategory.label}',
                              icon: const Icon(Icons.tune, size: 20),
                              style: IconButton.styleFrom(
                                foregroundColor: ui.ink,
                                backgroundColor: selectedCategory == null
                                    ? ui.ivory
                                    : ui.accent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onSelected: (categoryId) {
                                state.muroCat = categoryId.isEmpty
                                    ? null
                                    : categoryId;
                                state.refresh();
                              },
                              itemBuilder: (_) => [
                                CheckedPopupMenuItem(
                                  value: '',
                                  checked: selectedCategory == null,
                                  child: const Text('Todas las categorías'),
                                ),
                                for (final category in kPostCats)
                                  CheckedPopupMenuItem(
                                    value: category.id,
                                    checked: category.id == state.muroCat,
                                    child: Text(category.label),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),

            // Posts list (Virtualizado)
            if (filtered.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(side, 0, side, 24),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: ui.line),
                      boxShadow: theme.cardShadow,
                    ),
                    child: Center(
                      child: Text(
                        'No hay publicaciones en esta categoría todavía.',
                        style: TextStyle(color: ui.muted, fontSize: 13.5),
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  side,
                  0,
                  side,
                  NavigationInsets.of(context).bottom + 24,
                ),
                sliver: SliverList.builder(
                  itemCount: cols == 1
                      ? filtered.length
                      : (filtered.length / cols).ceil(),
                  itemBuilder: (context, index) => cols == 1
                      ? _buildPostCard(filtered[index])
                      : _buildPostGroup(filtered, index, cols),
                ),
              ),
          ],
        );
      },
    );
  }

  // Fila de tarjetas con la misma altura (pantallas anchas).
  Widget _buildPostGroup(List<PostItem> items, int row, int cols) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var j = 0; j < cols; j++) ...[
            if (j > 0) const SizedBox(width: 12),
            Expanded(
              child: row * cols + j < items.length
                  ? _buildPostCard(items[row * cols + j])
                  : const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _segButton(String id, String label) {
    final isSelected = state.muroSeg == id;
    return Expanded(
      child: InkWell(
        onTap: () {
          state.muroSeg = id;
          state.refresh();
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? ui.accent : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13.5,
                color: isSelected ? ui.ink : ui.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(PostItem p) {
    final isDone = state.helped[p.id] == true;
    final catObj = kPostCats.where((c) => c.id == p.cat).firstOrNull;
    final mine = p.mine || p.dist == 'tú' || p.dist == 'aquí';
    final catName = (p.catLabel.isNotEmpty ? p.catLabel : catObj?.label ?? '')
        .toLowerCase();
    final firstName = p.user.split(' ').first;
    // Qué pide u ofrece, dicho con su nombre: «Tarrillo necesita ayuda con materiales».
    final headline = mine
        ? (p.type == 'need'
              ? 'Pediste ayuda con $catName'
              : 'Ofreciste ayuda con $catName')
        : (p.type == 'need'
              ? '$firstName necesita ayuda con $catName'
              : '$firstName ofrece ayuda con $catName');
    final detail = p.text.isNotEmpty ? p.text : p.title;
    final showDetail =
        detail.isNotEmpty && detail.toLowerCase() != catName.toLowerCase();

    final initials = p.user
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word.characters.first.toUpperCase())
        .join();
    final metadata = [
      if (!mine && p.dist.isNotEmpty) _formatDistance(p.dist),
      p.time,
      if (!mine && p.zone.isNotEmpty) p.zone,
    ].where((value) => value.isNotEmpty).join(' · ');
    final needsHelp = p.type == 'need';

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.surface,
          border: Border.all(color: ui.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: ui.blueSoft,
                  foregroundColor: ui.ink,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mine ? 'Tú' : p.user,
                        style: TextStyle(
                          color: ui.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (metadata.isNotEmpty)
                        Text(
                          metadata,
                          style: TextStyle(color: ui.muted, fontSize: 10),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: needsHelp ? ui.ivory : ui.blueSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    needsHelp ? 'Necesita' : 'Ofrece',
                    style: TextStyle(
                      color: ui.ink,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              showDetail ? detail : headline,
              style: TextStyle(
                color: ui.ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            // En lo que publiqué yo: veo quién respondió y puedo aceptar/rechazar.
            if (mine) ...[
              if (p.incomingResponses.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: theme.infoSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.campaign_outlined,
                        color: theme.info,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tu publicación · aún nadie respondió. Te avisaremos cuando un vecino se ofrezca.',
                          style: TextStyle(
                            color: theme.info,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.people_alt_outlined,
                            size: 16,
                            color: theme.primaryDark,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Solicitudes recibidas (${p.incomingResponses.length})',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                              color: theme.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...p.incomingResponses.map(
                      (r) => _buildIncomingResponseRow(p, r),
                    ),
                  ],
                ),
              const SizedBox(height: 10),
              if (p.status == 'RESOLVED')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: theme.primaryDark,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Favor resuelto con éxito',
                        style: TextStyle(
                          color: theme.primaryDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                )
              else if (p.status != 'CANCELLED')
                OutlinedButton.icon(
                  onPressed: () => state.updatePostStatus(p.id, 'RESOLVED'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.primaryDark,
                    side: BorderSide(
                      color: theme.primaryDark.withValues(alpha: 0.3),
                    ),
                    minimumSize: const Size.fromHeight(40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.task_alt, size: 18),
                  label: const Text(
                    'Marcar favor como resuelto',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
            ] else ...[
              _buildResponderButton(p, isDone),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIncomingResponseRow(PostItem p, PostResponseItem r) {
    final isPending = r.status == 'PENDING';
    final isInProgress = r.status == 'IN_PROGRESS';
    final isRejected = r.status == 'REJECTED';

    final initials = r.responderInitials.isNotEmpty
        ? r.responderInitials
        : (r.responderName.isNotEmpty ? r.responderName[0].toUpperCase() : '?');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isInProgress
              ? theme.primary.withValues(alpha: 0.3)
              : theme.line,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: isInProgress
                ? theme.primarySoft
                : theme.violetSoft,
            child: Text(
              initials,
              style: TextStyle(
                fontSize: 10,
                color: isInProgress ? theme.primaryDark : theme.violet,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  r.responderName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: theme.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isPending
                      ? 'Desea ayudar · Pendiente'
                      : isInProgress
                      ? 'Aceptado · En progreso'
                      : isRejected
                      ? 'Rechazado'
                      : r.status,
                  style: TextStyle(
                    fontSize: 11,
                    color: isInProgress
                        ? theme.primaryDark
                        : isRejected
                        ? theme.accentInk
                        : theme.muted,
                    fontWeight: isInProgress
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (isPending) ...[
            TextButton(
              onPressed: () => state.rejectPostResponse(p.id, r.id),
              style: TextButton.styleFrom(
                foregroundColor: theme.muted,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: const Text('Rechazar', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 4),
            ElevatedButton(
              onPressed: () => state.acceptPostResponse(p.id, r.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primarySoft,
                foregroundColor: theme.primaryDark,
                elevation: 0,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Aceptar',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
          ] else if (isInProgress) ...[
            OutlinedButton.icon(
              onPressed: () {
                state.openChat(
                  r.responderName,
                  conversationId: r.conversationId,
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.primaryDark,
                side: BorderSide(
                  color: theme.primaryDark.withValues(alpha: 0.3),
                ),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.chat_bubble_outline, size: 14),
              label: const Text(
                'Chat',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResponderButton(PostItem p, bool isDone) {
    final status = p.myResponseStatus;
    final isPending = (status == 'PENDING') || isDone;
    final isInProgress = status == 'IN_PROGRESS';
    final isRejected = status == 'REJECTED';

    if (isInProgress) {
      return ElevatedButton.icon(
        onPressed: () => state.go('mensajes'),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primarySoft,
          foregroundColor: theme.primaryDark,
          elevation: 0,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.chat_bubble_outline, size: 18),
        label: const Text(
          '¡Solicitud aceptada! Ir al chat',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      );
    }

    if (isPending) {
      return ElevatedButton.icon(
        onPressed: () {
          state.toast(
            'Tu solicitud ya fue enviada. Esperando aprobación de ${p.user.split(" ").first}.',
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.surface2,
          foregroundColor: theme.muted,
          elevation: 0,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: theme.line),
          ),
        ),
        icon: const Icon(Icons.hourglass_top_rounded, size: 18),
        label: const Text(
          'Solicitud enviada',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      );
    }

    if (isRejected) {
      return Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.line),
        ),
        child: Text(
          'Solicitud no aceptada',
          style: TextStyle(
            color: theme.muted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (p.type == 'need') {
      return ElevatedButton(
        onPressed: () => state.helpPost(p.id),
        style: ui.action(),
        child: const Text('Yo te ayudo'),
      );
    }
    return OutlinedButton(
      onPressed: () => state.helpPost(p.id),
      style: ui.action(filled: false),
      child: const Text('Me interesa'),
    );
  }

  static String _formatDistance(String dist) {
    final clean = dist.trim();
    if (clean.toLowerCase().contains('menos de 500m') || clean == 'aquí') {
      return 'A menos de 500m';
    }
    final match = RegExp(r'(\d+)\s*m$').firstMatch(clean);
    if (match != null) {
      final meters = int.tryParse(match.group(1)!);
      if (meters != null && meters < 500) {
        return 'A menos de 500m';
      }
    }
    return clean.toLowerCase().startsWith('a ') ? clean : 'a $clean';
  }
}
