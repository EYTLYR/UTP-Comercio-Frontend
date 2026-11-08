import '../screens/municipality_screens.dart';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/nearby_theme.dart';

Future<void> showZonePicker(
  BuildContext context,
  AppState state,
  NearbyThemeData theme,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: theme.surface,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  ),
  builder: (_) => ZonePicker(state: state, theme: theme),
);

class ZonePicker extends StatefulWidget {
  final AppState state;
  final NearbyThemeData theme;
  const ZonePicker({super.key, required this.state, required this.theme});
  @override
  State<ZonePicker> createState() => _ZonePickerState();
}

class _ZonePickerState extends State<ZonePicker> {
  late Future<List<BrowseZone>> _request;
  String _query = '';

  NearbyCommunityStyle get ui => NearbyCommunityStyle(widget.theme);

  @override
  void initState() {
    super.initState();
    _request = widget.state.fetchZones();
  }

  Widget _iconSquare(IconData icon, {Color? bg}) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: bg ?? ui.blueSoft,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(icon, color: ui.ink, size: 20),
  );

  Widget _message(String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: ui.ivory,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(color: ui.muted, fontSize: 13),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final state = widget.state, theme = widget.theme;
    OutlineInputBorder field(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: c, width: w),
    );
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height:
              (MediaQuery.sizeOf(context).height -
                      MediaQuery.viewInsetsOf(context).bottom -
                      80)
                  .clamp(120, MediaQuery.sizeOf(context).height * .7),
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Agarradera
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: ui.line,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Explorar zonas',
                            style: TextStyle(
                              color: ui.ink,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Cerrar zonas',
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: ui.ink),
                        ),
                      ],
                    ),
                    Text(
                      'Tu zona guardada se usa por defecto. Explorar otra zona no cambia tu perfil.',
                      style: TextStyle(color: ui.muted, fontSize: 13.5),
                    ),
                    const SizedBox(height: 16),

                    // Mi zona guardada
                    Material(
                      color: ui.ivory,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        key: const ValueKey('restore-home-zone'),
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.pop(context);
                          state.browseZone(null);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              _iconSquare(
                                Icons.home_outlined,
                                bg: theme.surface,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      state.zoneName,
                                      style: TextStyle(
                                        color: ui.ink,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                    Text(
                                      'Mi zona guardada',
                                      style: TextStyle(
                                        color: ui.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (state.viewedZone == null)
                                Icon(Icons.check_circle, color: ui.ink),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      onChanged: (value) =>
                          setState(() => _query = value.trim().toLowerCase()),
                      style: TextStyle(color: ui.ink),
                      decoration: InputDecoration(
                        labelText: 'Buscar otra zona',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: theme.surface,
                        border: field(ui.line),
                        enabledBorder: field(ui.line),
                        focusedBorder: field(ui.ink, 1.5),
                      ),
                    ),
                    if (state.connected)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(foregroundColor: ui.ink),
                          onPressed: () async {
                            final created = await showModalBottomSheet<bool>(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              builder: (_) => CreateZoneSheet(state: state),
                            );
                            if (created == true && mounted) {
                              setState(() => _request = state.fetchZones());
                            }
                          },
                          icon: const Icon(Icons.add_location_alt_outlined),
                          label: const Text('Registrar una zona nueva'),
                        ),
                      ),
                    const SizedBox(height: 8),
                    FutureBuilder<List<BrowseZone>>(
                      future: _request,
                      builder: (context, result) {
                        if (result.connectionState != ConnectionState.done) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(color: ui.ink),
                            ),
                          );
                        }
                        if (result.hasError) {
                          return Center(
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: ui.ink,
                              ),
                              onPressed: () =>
                                  setState(() => _request = state.fetchZones()),
                              icon: const Icon(Icons.refresh),
                              label: const Text(
                                'No se pudieron cargar las zonas. Reintentar',
                              ),
                            ),
                          );
                        }
                        if (!state.connected) {
                          return _message(
                            'Inicia sesión para consultar las zonas disponibles.',
                          );
                        }
                        final rows = (result.data ?? [])
                            .where(
                              (zone) =>
                                  zone.id != state.zoneId &&
                                  '${zone.name} ${zone.district}'
                                      .toLowerCase()
                                      .contains(_query),
                            )
                            .toList();
                        if (rows.isEmpty) {
                          return _message(
                            _query.isEmpty
                                ? 'No hay otras zonas registradas todavía.'
                                : 'No se encontraron zonas.',
                          );
                        }
                        return Container(
                          decoration: BoxDecoration(
                            color: theme.surface,
                            border: Border.all(color: ui.line),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: rows.length,
                            separatorBuilder: (_, _) =>
                                Divider(height: 1, color: ui.line),
                            itemBuilder: (context, index) {
                              final zone = rows[index];
                              final viewing = state.viewedZone?.id == zone.id;
                              return Material(
                                type: MaterialType.transparency,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                    state.browseZone(zone);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        _iconSquare(
                                          Icons.location_city_outlined,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                zone.name,
                                                style: TextStyle(
                                                  color: ui.ink,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                zone.district,
                                                style: TextStyle(
                                                  color: ui.muted,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          viewing
                                              ? Icons.check_circle
                                              : Icons.chevron_right,
                                          color: ui.ink,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
