import 'package:flutter/material.dart';

import '../widgets/interactions.dart';
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
    final ui = NearbyCommunityStyle(theme);
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

    return LayoutBuilder(
      builder: (context, constraints) {
        // 1 columna en móvil; 2 desde 700 px y 3 desde 1050 px.
        final width = constraints.maxWidth;
        final cols = width >= 1050 ? 3 : (width >= 700 ? 2 : 1);
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
                            'Servicios del barrio',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: ui.ink,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Oficios recomendados por tus vecinos.',
                            style: TextStyle(color: ui.muted, fontSize: 14),
                          ),
                        ],
                      ),
                    ),

                    // Search bar + filtros en el panel lateral
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 52,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color: theme.surface,
                                border: Border.all(color: ui.ink, width: 1.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.search, color: ui.muted, size: 22),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      onChanged: (val) =>
                                          setState(() => _search = val),
                                      decoration: const InputDecoration(
                                        hintText:
                                            '¿Qué necesitas? Ej. gasfitero',
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          NearbyFilterButton(
                            theme: theme,
                            active: state.servCat == 'all' ? 0 : 1,
                            onPressed: () => _openFilters(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category chips
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
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
                            label: Text(c.label),
                            selected: isSel,
                            onSelected: (_) {
                              state.servCat = c.id;
                              state.refresh();
                              if (c.id == 'gasfiteria') {
                                state.checkTourEvent('servcat');
                              }
                            },
                            backgroundColor: theme.surface,
                            selectedColor: ui.ivory,
                            side: BorderSide(
                              color: isSel ? ui.accent : ui.line,
                            ),
                            labelStyle: TextStyle(
                              fontFamily: 'Poppins',
                              color: ui.ink,
                              fontWeight: isSel
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              fontSize: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                              side: BorderSide(
                                color: isSel ? ui.accent : ui.line,
                              ),
                            ),
                            showCheckmark: false,
                          );
                        },
                      ),
                    ),

                    // VB Explanation box
                    Container(
                      margin: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ui.blueSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.verified, color: ui.ink, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: ui.ink,
                                  fontSize: 12.5,
                                  height: 1.4,
                                ),
                                children: const [
                                  TextSpan(
                                    text: 'Visto Bueno Vecinal: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'recomendaciones de vecinos verificados de tu zona, una por persona.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Services List (Virtualizado)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList.builder(
                itemCount: cols == 1
                    ? filtered.length
                    : (filtered.length / cols).ceil(),
                itemBuilder: (context, index) => cols == 1
                    ? NearbyHover(child: _buildServiceRow(filtered[index]))
                    : _buildServiceGroup(filtered, index, cols),
              ),
            ),

            // Add service banner
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  12,
                  24,
                  NavigationInsets.of(context).bottom + 24,
                ),
                child: InkWell(
                  onTap: () {
                    state.pub.reset(step: 2, type: 'service');
                    state.go('publicar');
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: ui.ivory,
                      border: Border.all(color: ui.line),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: ui.ivory,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.add, color: ui.ink, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¿Tienes un oficio?',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: ui.ink,
                                  fontSize: 14.5,
                                ),
                              ),
                              Text(
                                'Ofrécelo a tus vecinos gratis',
                                style: TextStyle(
                                  color: ui.muted,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: ui.muted),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Panel lateral de filtros: oficios por categoría (cada cambio se ve al instante).
  void _openFilters(BuildContext context) {
    final state = widget.state;
    final theme = widget.theme;
    showNearbyFilterPanel(
      context: context,
      theme: theme,
      title: 'Filtrar oficios',
      subtitle: 'Elige el tipo de servicio',
      onClear: () {
        state.servCat = 'all';
        state.refresh();
      },
      builder: (context, setPanel) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NearbyFilterGroup(theme: theme, title: 'Categoría'),
          for (final c in kServCats)
            NearbyFilterOption(
              theme: theme,
              icon: c.icon,
              label: c.label,
              selected: state.servCat == c.id,
              onTap: () {
                state.servCat = c.id;
                state.refresh();
                setPanel(() {});
              },
            ),
        ],
      ),
    );
  }

  Widget _buildServiceRow(ServiceItem service) {
    final state = widget.state;
    final ui = NearbyCommunityStyle(widget.theme);
    final count = service.vb + (state.vbGiven[service.id] == true ? 1 : 0);

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: widget.theme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: ui.line),
          ),
          child: InkWell(
            key: service.id == 'julio'
                ? state.tourTarget('service-julio')
                : null,
            onTap: () {
              state.selService = service.id;
              state.go('svc');
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: service.tone == 'amber'
                              ? ui.ivory
                              : ui.blueSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(service.icon, size: 21, color: ui.ink),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.name,
                              style: TextStyle(
                                color: ui.ink,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              service.job,
                              style: TextStyle(color: ui.muted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Text(
                          service.price,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: ui.ink,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 16, color: ui.line),
                  Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 14,
                        color: ui.ink,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '$count vistos buenos',
                          style: TextStyle(
                            color: ui.ink,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          service.dist,
                          textAlign: TextAlign.end,
                          style: TextStyle(color: ui.muted, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  if (service.emerg)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Disponible en emergencias',
                          style: TextStyle(
                            color: widget.theme.sosDark,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Fila de tarjetas con la misma altura (pantallas anchas).
  Widget _buildServiceGroup(List<ServiceItem> items, int row, int cols) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var j = 0; j < cols; j++) ...[
            if (j > 0) const SizedBox(width: 12),
            Expanded(
              child: row * cols + j < items.length
                  ? NearbyHover(child: _buildServiceRow(items[row * cols + j]))
                  : const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );
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
    final ui = NearbyCommunityStyle(theme);
    final service =
        state.services
            .where((item) => item.id == state.selService)
            .firstOrNull ??
        state.services.first;
    final given = state.vbGiven[service.id] == true;
    final count = service.vb + (given ? 1 : 0);
    final detail = state.serviceDetails[service.id];
    final endorsers =
        (detail?['endorserInitials'] as List?)?.cast<String>() ??
        const <String>[];

    // Perfil, acciones y datos del servicio.
    final profile = <Widget>[
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ui.panel,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ui.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(service.icon, color: ui.onAccent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: TextStyle(
                          color: ui.onPanel,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        service.job,
                        style: TextStyle(color: ui.onPanel, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(color: ui.onPanel.withValues(alpha: .24)),
            Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: ui.light ? ui.accent : ui.onPanel,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    [
                      if (detail?['ownerVerified'] != false)
                        'Vecino verificado',
                      (detail?['zoneName'] as String?) ?? state.zoneName,
                    ].join(' · '),
                    style: TextStyle(
                      color: ui.onPanel,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Container(
        key: state.tourTarget('vb-score'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ui.blueSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                '$count',
                style: TextStyle(
                  color: ui.ink,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vistos buenos vecinales',
                    style: TextStyle(
                      color: ui.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'De vecinos de ${state.zoneName} que ya lo contrataron.',
                    style: TextStyle(color: ui.muted, fontSize: 11),
                  ),
                  if (endorsers.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (final initials in endorsers)
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: theme.surface,
                            foregroundColor: ui.ink,
                            child: Text(
                              initials,
                              style: const TextStyle(fontSize: 9),
                            ),
                          ),
                        if (count > 4)
                          Text(
                            '+${count - 4}',
                            style: TextStyle(color: ui.muted, fontSize: 11),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => state.contactService(service),
              style: ui.action(),
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Mensaje', textAlign: TextAlign.center),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => state.startCall(service.name),
              style: ui.action(filled: false),
              icon: const Icon(Icons.call_outlined, size: 18),
              label: const Text('Llamar', textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        key: state.tourTarget('vb'),
        onPressed: () => state.toggleVb(service.id),
        style: ui.action(filled: false),
        icon: Icon(given ? Icons.verified_outlined : Icons.check, size: 18),
        label: Text(given ? 'Visto bueno dado' : 'Dar visto bueno'),
      ),
      const SizedBox(height: 24),
      Text(
        'Datos del servicio',
        style: TextStyle(
          color: ui.ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: theme.surface,
          border: Border.all(color: ui.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            _infoRow(
              ui,
              Icons.location_on_outlined,
              'Distancia',
              '${service.dist} de tu casa',
            ),
            Divider(height: 1, color: ui.line),
            _infoRow(ui, Icons.schedule, 'Horario', service.hours),
            Divider(height: 1, color: ui.line),
            _infoRow(
              ui,
              Icons.payments_outlined,
              'Precio referencial',
              service.price,
            ),
          ],
        ),
      ),
      if (service.emerg) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.sosSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Tooltip(
            message: 'Integra los grupos de apoyo de la zona',
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: theme.sosDark,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Disponible en emergencias',
                    style: TextStyle(
                      color: theme.sosDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ];

    // Reseñas de los vecinos.
    final reviewsTitle = Text(
      'Lo que dicen tus vecinos',
      style: TextStyle(
        color: ui.ink,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
    final reviews = <Widget>[
      for (final review in state.reviewsFor(service.id))
        _buildReviewCard(review),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // ≥ 900: perfil y acciones a la izquierda, reseñas a la derecha.
        if (width >= 900) {
          return ListView(
            padding:
                NavigationInsets.of(context) +
                const EdgeInsets.fromLTRB(24, 12, 24, 24),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: profile,
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        reviewsTitle,
                        const SizedBox(height: 12),
                        ...reviews,
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        }
        // Una columna de hasta 720 px centrada (en móvil, márgenes de 24).
        final side = width > 768 ? (width - 720) / 2 : 24.0;
        return ListView(
          padding:
              NavigationInsets.of(context) +
              EdgeInsets.fromLTRB(side, 12, side, 24),
          children: [
            ...profile,
            const SizedBox(height: 24),
            reviewsTitle,
            const SizedBox(height: 12),
            ...reviews,
          ],
        );
      },
    );
  }

  Widget _infoRow(
    NearbyCommunityStyle ui,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: ui.ink, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: TextStyle(color: ui.muted, fontSize: 11)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: ui.ink,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
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
        borderRadius: BorderRadius.circular(12),
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
                ' · ${r.when}',
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
}
