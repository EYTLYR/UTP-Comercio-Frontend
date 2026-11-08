import 'package:flutter/material.dart';

import '../widgets/navigation_chrome.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/nearby_theme.dart';

class WallScreen extends StatelessWidget {
  final AppState state;
  final NearbyThemeData theme;

  const WallScreen({super.key, required this.state, required this.theme});

  @override
  Widget build(BuildContext context) {
    final filtered = state.posts.where((p) {
      final matchesSeg = state.muroSeg == 'all' || p.type == state.muroSeg;
      final matchesCat = state.muroCat == null || p.cat == state.muroCat;
      return matchesSeg && matchesCat;
    }).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: NavigationInsets.of(context).top),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Muro solidario',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: theme.ink,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cadena de favores: resolvemos necesidades sin dinero.',
                        style: TextStyle(color: theme.muted, fontSize: 14),
                      ),
                    ],
                  ),
                ),

                // Cadena de favores progress banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.accentSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.handshake,
                          color: NearbyColors.accentInk,
                          size: 36,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(
                                TextSpan(
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: theme.ink,
                                    fontSize: 14,
                                  ),
                                  children: [
                                    TextSpan(
                                      text:
                                          '${state.posts.length} ${state.posts.length == 1 ? 'favor' : 'favores'} ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const TextSpan(text: 'cerca de ti'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                () {
                                  final mine = state.posts
                                      .where(
                                        (p) =>
                                            p.mine || p.dist == 'tú',
                                      )
                                      .length;
                                  if (mine > 0) return 'Tú publicaste $mine';
                                  return state.posts.isEmpty
                                      ? 'Publica el primero y suma a la cadena'
                                      : 'Pide u ofrece ayuda y suma a la cadena';
                                }(),
                                style: TextStyle(
                                  color: theme.muted,
                                  fontSize: 12,
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

                // Segmented controller (Todo / Necesitan / Ofrecen)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.surface2,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        _segButton('all', 'Todo'),
                        _segButton('need', 'Necesitan'),
                        _segButton('offer', 'Ofrecen'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Category chips
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: kPostCats.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final c = kPostCats[i];
                      final isSel = state.muroCat == c.id;
                      return FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              c.icon,
                              size: 16,
                              color: isSel ? theme.btnInk : theme.muted,
                            ),
                            const SizedBox(width: 6),
                            Text(c.short ?? c.label),
                          ],
                        ),
                        selected: isSel,
                        onSelected: (_) {
                          state.muroCat = isSel ? null : c.id;
                          state.refresh();
                        },
                        backgroundColor: theme.surface,
                        selectedColor: theme.btnBg,
                        labelStyle: TextStyle(
                          fontFamily: 'Poppins',
                          color: isSel ? theme.btnInk : theme.ink,
                          fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                          side: BorderSide(
                            color: isSel ? theme.btnBg : theme.line,
                          ),
                        ),
                        showCheckmark: false,
                      );
                    },
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: theme.line),
                  boxShadow: theme.cardShadow,
                ),
                child: Center(
                  child: Text(
                    'No hay publicaciones en esta categoría todavía.',
                    style: TextStyle(color: theme.muted, fontSize: 13.5),
                  ),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              NavigationInsets.of(context).bottom + 24,
            ),
            sliver: SliverList.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) => _buildPostCard(filtered[index]),
            ),
          ),
      ],
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
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? theme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13.5,
                color: isSelected ? theme.ink : theme.muted,
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

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.surface,
          border: Border.all(color: theme.line),
          borderRadius: BorderRadius.circular(18),
          boxShadow: theme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: p.type == 'need'
                        ? theme.accentSoft
                        : theme.primarySoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    p.type == 'need' ? 'NECESITA' : 'OFRECE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: p.type == 'need'
                          ? theme.accentInk
                          : theme.primaryDark,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                if (catObj != null)
                  Row(
                    children: [
                      Icon(catObj.icon, size: 16, color: theme.muted),
                      const SizedBox(width: 4),
                      Text(
                        catObj.short ?? catObj.label,
                        style: TextStyle(
                          color: theme.muted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              headline,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14.5,
                color: theme.ink,
                height: 1.3,
              ),
            ),
            if (showDetail) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.surface2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '«$detail»',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: theme.ink,
                    height: 1.35,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 4,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: theme.violetSoft,
                  child: Text(
                    p.user
                        .split(' ')
                        .where((w) => w.isNotEmpty)
                        .map((w) => w[0].toUpperCase())
                        .take(2)
                        .join(),
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.violet,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  mine ? 'Tú' : p.user,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: theme.ink,
                  ),
                ),
                Container(
                  width: 3,
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: theme.muted,
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  [
                    if (!mine) 'a ${p.dist.replaceFirst('a ', '')}',
                    p.time,
                    if (!mine && p.zone.isNotEmpty) p.zone,
                  ].join(' · '),
                  style: TextStyle(color: theme.muted, fontSize: 11.5),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // En lo que publiqué yo no hay botón para ayudarme: veo quién respondió.
            if (mine)
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
                    Icon(Icons.campaign_outlined, color: theme.info, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p.responses == 0
                            ? 'Tu publicación · aún nadie respondió. Te avisamos por Mensajes.'
                            : 'Tu publicación · ${p.responses} '
                                  '${p.responses == 1 ? 'vecino respondió' : 'vecinos respondieron'}',
                        style: TextStyle(
                          color: theme.info,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    if (p.responses > 0)
                      TextButton(
                        onPressed: () => state.go('mensajes'),
                        child: const Text('Ver'),
                      ),
                  ],
                ),
              )
            else
            ElevatedButton.icon(
              onPressed: () => state.helpPost(p.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDone ? theme.primarySoft : theme.primarySoft,
                foregroundColor: theme.primaryDark,
                elevation: 0,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: Icon(
                isDone
                    ? Icons.check_circle
                    : (p.type == 'need'
                          ? Icons.volunteer_activism
                          : Icons.front_hand),
                size: 18,
              ),
              label: Text(
                isDone
                    ? 'Le avisamos a ${p.user.split(" ").first}'
                    : (p.type == 'need' ? 'Yo te ayudo' : 'Me interesa'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
