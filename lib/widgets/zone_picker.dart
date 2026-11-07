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
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
  @override
  void initState() {
    super.initState();
    _request = widget.state.fetchZones();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state, theme = widget.theme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height:
              (MediaQuery.sizeOf(context).height -
                      MediaQuery.viewInsetsOf(context).bottom -
                      80)
                  .clamp(120, MediaQuery.sizeOf(context).height * .7),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Explorar zonas',
                        style: TextStyle(
                          color: theme.ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar zonas',
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: theme.ink),
                    ),
                  ],
                ),
                Text(
                  'Tu zona guardada se usa por defecto. Explorar otra zona no cambia tu perfil.',
                  style: TextStyle(color: theme.muted),
                ),
                const SizedBox(height: 12),
                ListTile(
                  key: const ValueKey('restore-home-zone'),
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.home_outlined, color: theme.primary),
                  title: Text(
                    state.zoneName,
                    style: TextStyle(
                      color: theme.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    'Mi zona guardada',
                    style: TextStyle(color: theme.muted),
                  ),
                  trailing: state.viewedZone == null
                      ? Icon(Icons.check_circle, color: theme.primary)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    state.browseZone(null);
                  },
                ),
                TextField(
                  onChanged: (value) =>
                      setState(() => _query = value.trim().toLowerCase()),
                  style: TextStyle(color: theme.ink),
                  decoration: InputDecoration(
                    labelText: 'Buscar otra zona',
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<BrowseZone>>(
                  future: _request,
                  builder: (context, result) {
                    if (result.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (result.hasError) {
                      return Center(
                        child: TextButton.icon(
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
                      return Center(
                        child: Text(
                          'Inicia sesión para consultar las zonas disponibles.',
                          style: TextStyle(color: theme.muted),
                        ),
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
                      return Center(
                        child: Text(
                          _query.isEmpty
                              ? 'No hay otras zonas registradas todavía.'
                              : 'No se encontraron zonas.',
                          style: TextStyle(color: theme.muted),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final zone = rows[index];
                        return ListTile(
                          title: Text(
                            zone.name,
                            style: TextStyle(color: theme.ink),
                          ),
                          subtitle: Text(
                            zone.district,
                            style: TextStyle(color: theme.muted),
                          ),
                          trailing: state.viewedZone?.id == zone.id
                              ? Icon(Icons.check_circle, color: theme.primary)
                              : const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pop(context);
                            state.browseZone(zone);
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
