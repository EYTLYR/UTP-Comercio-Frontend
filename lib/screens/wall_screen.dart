import 'package:flutter/material.dart';

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

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Muro solidario',
                style: TextStyle(
                  fontSize: 24 * theme.scaleFactor,
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
                Icon(Icons.handshake, color: NearbyColors.accentInk, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            color: theme.ink,
                            fontSize: 14,
                          ),
                          children: const [
                            TextSpan(
                              text: '127 favores ',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                            TextSpan(text: 'esta semana en Las Flores'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 0.71,
                          minHeight: 8,
                          backgroundColor: NearbyColors.accentInk.withValues(
                            alpha: 0.15,
                          ),
                          valueColor: const AlwaysStoppedAnimation(
                            NearbyColors.accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Meta del mes: 180 · Tú hiciste 12',
                        style: TextStyle(color: theme.muted, fontSize: 12),
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
                  fontFamily: 'Nunito',
                  color: isSel ? theme.btnInk : theme.ink,
                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                  side: BorderSide(color: isSel ? theme.btnBg : theme.line),
                ),
                showCheckmark: false,
              );
            },
          ),
        ),
        const SizedBox(height: 14),

        // Posts list
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: filtered.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.line),
                  ),
                  child: Center(
                    child: Text(
                      'No hay publicaciones en esta categoría todavía.',
                      style: TextStyle(color: theme.muted, fontSize: 13.5),
                    ),
                  ),
                )
              : Column(
                  children: filtered.map((p) => _buildPostCard(p)).toList(),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border.all(color: theme.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            p.title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14.5 * theme.scaleFactor,
              color: theme.ink,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: theme.violetSoft,
                child: Text(
                  p.user.split(' ').map((w) => w[0]).take(2).join(),
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.violet,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                p.user,
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
                '${p.dist} · ${p.time}',
                style: TextStyle(color: theme.muted, fontSize: 11.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => state.helpPost(p.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDone ? theme.primarySoft : theme.primarySoft,
              foregroundColor: theme.primaryDark,
              elevation: 0,
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
    );
  }
}
