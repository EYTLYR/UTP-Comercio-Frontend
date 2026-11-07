import 'package:flutter/material.dart';

import '../widgets/navigation_chrome.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/nearby_theme.dart';

// --- Services List Screen ---
class ServicesScreen extends StatefulWidget {
  final AppState state;
  final NearbyThemeData theme;

  const ServicesScreen({super.key, required this.state, required this.theme});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final state = widget.state;

    final filtered = state.services.where((s) {
      final matchesCat = state.servCat == 'all' || s.cat == state.servCat;
      final matchesSearch =
          _search.isEmpty ||
          '${s.name.toLowerCase()} ${s.job.toLowerCase()}'.contains(
            _search.toLowerCase(),
          );
      return matchesCat && matchesSearch;
    }).toList();

    return ListView(
      padding: NavigationInsets.of(context) + const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Servicios del barrio',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: theme.ink,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Oficios y profesiones de tu zona, recomendados por tus vecinos.',
                style: TextStyle(color: theme.muted, fontSize: 14),
              ),
            ],
          ),
        ),

        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: theme.surface,
              border: Border.all(color: theme.line),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: theme.muted, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _search = val),
                    decoration: const InputDecoration(
                      hintText: '¿Qué necesitas? Ej. gasfitero',
                      border: InputBorder.none,
                    ),
                  ),
                ),
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
            itemCount: kServCats.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final c = kServCats[i];
              final isSel = state.servCat == c.id;
              return FilterChip(
                key: c.id == 'gasfiteria'
                    ? state.tourTarget('service-category')
                    : null,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      c.icon,
                      size: 16,
                      color: isSel ? theme.btnInk : theme.muted,
                    ),
                    const SizedBox(width: 6),
                    Text(c.label),
                  ],
                ),
                selected: isSel,
                onSelected: (_) {
                  state.servCat = c.id;
                  state.refresh();
                  if (c.id == 'gasfiteria') state.checkTourEvent('servcat');
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

        // VB Explanation box
        Container(
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.primarySoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.verified, color: theme.primaryDark, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: theme.primaryDark,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                    children: const [
                      TextSpan(
                        text: 'Visto Bueno Vecinal: ',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      TextSpan(
                        text: 'solo cuentan las recomendaciones de vecinos verificados de tu misma zona, una por persona.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Services List
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: filtered.map((s) => _buildServiceRow(s)).toList(),
          ),
        ),

        // Add service banner
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: InkWell(
            onTap: () {
              state.pub.reset(step: 2, type: 'service');
              state.go('publicar');
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.surface,
                border: Border.all(color: theme.line),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.infoSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.add_business,
                      color: theme.info,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¿Tienes un oficio?',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: theme.ink,
                            fontSize: 14.5,
                          ),
                        ),
                        Text(
                          'Ofrécelo a tus vecinos gratis',
                          style: TextStyle(color: theme.muted, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: theme.muted),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceRow(ServiceItem s) {
    final theme = widget.theme;
    final state = widget.state;
    final hasVb = state.vbGiven[s.id] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        key: s.id == 'julio' ? state.tourTarget('service-julio') : null,
        onTap: () {
          state.selService = s.id;
          state.go('svc');
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.surface,
            border: Border.all(color: theme.line),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _toneSoft(s.tone),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(s.icon, color: _toneColor(s.tone), size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: theme.ink,
                        fontSize: 14.5,
                      ),
                    ),
                    Text(
                      '${s.job} · ${s.dist}',
                      style: TextStyle(color: theme.muted, fontSize: 12.5),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.primarySoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified,
                                color: theme.primaryDark,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${s.vb + (hasVb ? 1 : 0)} vistos buenos',
                                style: TextStyle(
                                  color: theme.primaryDark,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (s.emerg)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: theme.sosSoft,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.emergency,
                                  color: NearbyColors.sosDark,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Emergencias',
                                  style: TextStyle(
                                    color: NearbyColors.sosDark,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.muted),
            ],
          ),
        ),
      ),
    );
  }

  Color _toneColor(String tone) {
    switch (tone) {
      case 'green':
        return NearbyColors.primary;
      case 'blue':
        return NearbyColors.info;
      case 'amber':
        return NearbyColors.accent;
      case 'red':
        return NearbyColors.sos;
      case 'violet':
        return NearbyColors.violet;
      default:
        return NearbyColors.primary;
    }
  }

  Color _toneSoft(String tone) {
    switch (tone) {
      case 'green':
        return widget.theme.primarySoft;
      case 'blue':
        return widget.theme.infoSoft;
      case 'amber':
        return widget.theme.accentSoft;
      case 'red':
        return widget.theme.sosSoft;
      case 'violet':
        return widget.theme.violetSoft;
      default:
        return widget.theme.primarySoft;
    }
  }
}

// --- Service Detail Screen ---
class ServiceDetailScreen extends StatelessWidget {
  final AppState state;
  final NearbyThemeData theme;

  const ServiceDetailScreen({
    super.key,
    required this.state,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final s =
        state.services.where((x) => x.id == state.selService).firstOrNull ??
        state.services.first;
    final given = state.vbGiven[s.id] == true;
    final count = s.vb + (given ? 1 : 0);

    return ListView(
      padding: NavigationInsets.of(context) + const EdgeInsets.only(bottom: 24),
      children: [
        // Hero
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: _toneSoft(s.tone),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(s.icon, color: _toneColor(s.tone), size: 44),
              ),
              const SizedBox(height: 10),
              Text(
                s.name,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: theme.ink,
                ),
              ),
              Text(s.job, style: TextStyle(color: theme.muted, fontSize: 14)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: theme.infoSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user, color: theme.info, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Vecino verificado · Zona 3',
                      style: TextStyle(
                        color: theme.info,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Big Visto Bueno Card
        Padding(
          key: state.tourTarget('vb-score'),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.surface,
              border: Border.all(color: theme.line),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: theme.btnBg,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified, color: theme.primary, size: 24),
                      Text(
                        '$count',
                        style: TextStyle(
                          color: theme.btnInk,
                          fontWeight: FontWeight.w900,
                          fontSize: 26,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vistos buenos vecinales',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: theme.ink,
                          fontSize: 14.5,
                        ),
                      ),
                      Text(
                        'de vecinos de Las Flores que ya lo contrataron',
                        style: TextStyle(color: theme.muted, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ...['EV', 'JP', 'TR', 'LM'].map(
                            (x) => Container(
                              width: 26,
                              height: 26,
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: theme.violetSoft,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.surface,
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  x,
                                  style: TextStyle(
                                    color: theme.violet,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Text(
                            ' +${count - 4}',
                            style: TextStyle(
                              color: theme.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 3 Actions: Call, Message, Give Visto Bueno
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _actionButton(
                  icon: Icons.call,
                  label: 'Llamar',
                  onTap: () => state.startCall(s.name),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionButton(
                  icon: Icons.chat,
                  label: 'Mensaje',
                  onTap: () => state.openChat(s.name),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionButton(
                  icon: Icons.thumb_up,
                  key: state.tourTarget('vb'),
                  label: given ? 'Visto bueno dado' : 'Dar visto bueno',
                  isOn: given,
                  onTap: () => state.toggleVb(s.id),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Info List
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: theme.surface,
              border: Border.all(color: theme.line),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _infoRow(
                  Icons.location_on,
                  'Distancia',
                  '${s.dist} de tu casa',
                ),
                const Divider(height: 1),
                _infoRow(Icons.schedule, 'Horario', s.hours),
                const Divider(height: 1),
                _infoRow(Icons.payments, 'Precio referencial', s.price),
                if (s.emerg) ...[
                  const Divider(height: 1),
                  _infoRow(
                    Icons.emergency,
                    'Disponible en emergencias',
                    'Integra los grupos de apoyo de la zona',
                  ),
                ],
              ],
            ),
          ),
        ),

        // Reviews section
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
          child: Text(
            'Lo que dicen tus vecinos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: theme.ink,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: kReviews.map((r) => _buildReviewCard(r)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    Key? key,
    required IconData icon,
    required String label,
    bool isOn = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: isOn ? theme.btnBg : theme.surface,
          border: Border.all(color: isOn ? theme.btnBg : theme.line),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isOn
                  ? (theme.dark ? theme.btnInk : theme.primary)
                  : theme.primary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isOn ? theme.btnInk : theme.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: theme.muted, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: theme.muted, fontSize: 12)),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: theme.ink,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewItem r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: theme.violetSoft,
                child: Text(
                  r.who.split(' ').map((w) => w[0]).take(2).join(),
                  style: TextStyle(
                    color: theme.violet,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                r.who,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: theme.ink,
                  fontSize: 13,
                ),
              ),
              Text(
                ' · Zona 3 · ${r.when}',
                style: TextStyle(color: theme.muted, fontSize: 11.5),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            r.txt,
            style: TextStyle(color: theme.ink, fontSize: 13, height: 1.35),
          ),
        ],
      ),
    );
  }

  Color _toneColor(String tone) {
    switch (tone) {
      case 'green':
        return NearbyColors.primary;
      case 'blue':
        return NearbyColors.info;
      case 'amber':
        return NearbyColors.accent;
      case 'red':
        return NearbyColors.sos;
      case 'violet':
        return NearbyColors.violet;
      default:
        return NearbyColors.primary;
    }
  }

  Color _toneSoft(String tone) {
    switch (tone) {
      case 'green':
        return theme.primarySoft;
      case 'blue':
        return theme.infoSoft;
      case 'amber':
        return theme.accentSoft;
      case 'red':
        return theme.sosSoft;
      case 'violet':
        return theme.violetSoft;
      default:
        return theme.primarySoft;
    }
  }
}
