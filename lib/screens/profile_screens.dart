import 'package:flutter/material.dart';

import '../widgets/common_widgets.dart';
import 'profile/widgets/edit_address_sheet.dart';
import 'profile/widgets/profile_ui.dart';
import 'roles_screens.dart';

import '../models/models.dart';
import '../services/offline_tiles.dart';
import '../state/app_state.dart';
import '../theme/nearby_theme.dart';

/* ========================================================================= */
/*                                FICHA SCREEN                               */
/* ========================================================================= */

class FichaScreen extends StatefulWidget {
  final AppState state;
  final NearbyThemeData? theme;
  const FichaScreen({super.key, required this.state, this.theme});

  @override
  State<FichaScreen> createState() => _FichaScreenState();
}

class _FichaScreenState extends State<FichaScreen> {
  /// Ficha que se está mostrando (la carga AppState.openMedicalCard con huella, rostro o PIN).
  MedicalCard? _card;
  String _sangre = 'No sé';
  final TextEditingController _alergiasCtrl = TextEditingController();
  final TextEditingController _condicionesCtrl = TextEditingController();
  Set<String> _vive = {};

  final List<String> _bloodTypes = [
    'O+',
    'O-',
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'No sé',
  ];
  final List<Map<String, dynamic>> _viveOptions = [
    {'id': 'mayor', 'label': 'Adulto mayor', 'icon': Icons.elderly},
    {'id': 'ninos', 'label': 'Niños', 'icon': Icons.child_care},
    {
      'id': 'disc',
      'label': 'Persona con discapacidad',
      'icon': Icons.accessible,
    },
    {'id': 'mascotas', 'label': 'Mascotas', 'icon': Icons.pets},
  ];

  NearbyCommunityStyle get ui =>
      NearbyCommunityStyle(widget.theme ?? uiThemeOf(widget.state));

  @override
  void initState() {
    super.initState();
    _bind();
  }

  /// Toma la ficha cargada (si ya está) una sola vez.
  void _bind() {
    final card = widget.state.medical;
    if (card == null || identical(card, _card)) return;
    _card = card;
    _sangre = card.sangre;
    _alergiasCtrl.text = card.alergias;
    _condicionesCtrl.text = card.condiciones;
    _vive = Set.from(card.vive);
  }

  @override
  void dispose() {
    _alergiasCtrl.dispose();
    _condicionesCtrl.dispose();
    // Fuera de esta pantalla la ficha no queda en memoria.
    widget.state.closeMedicalCard();
    super.dispose();
  }

  void _save() {
    final card = _card;
    if (card == null) return;
    card.sangre = _sangre;
    card.alergias = _alergiasCtrl.text.trim();
    card.condiciones = _condicionesCtrl.text.trim();
    card.vive = _vive.toList();
    widget.state.saveMedicalCard();
    widget.state.toast('Ficha médica actualizada', icon: 'check_circle');
    widget.state.back();
  }

  @override
  Widget build(BuildContext context) {
    _bind();
    if (_card == null) return _locked();
    final ui = this.ui;
    final fieldText = TextStyle(
      color: ui.ink,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );
    return UiScrollPage(
      builder: (context, width) => [
        UiPageHeader(
          ui: ui,
          title: 'Tu ficha médica',
          subtitle: 'Tipo de sangre, alergias y con quién vives.',
        ),
        UiNotice(
          ui: ui,
          icon: Icons.lock_outline,
          text: 'Solo la ven los brigadistas verificados cuando envías un SOS. Les ayuda a atenderte mejor.',
        ),
        const SizedBox(height: 16),
        UiCard(
          ui: ui,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UiLabeled(
                ui: ui,
                label: 'Tipo de sangre',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in _bloodTypes)
                      UiChoice(
                        ui: ui,
                        label: t,
                        selected: _sangre == t,
                        onTap: () => setState(() => _sangre = t),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              UiLabeled(
                ui: ui,
                label: 'Alergias',
                child: TextField(
                  controller: _alergiasCtrl,
                  style: fieldText,
                  decoration: uiField(
                    ui,
                    hint: 'Ej. penicilina',
                    icon: Icons.medication_outlined,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              UiLabeled(
                ui: ui,
                label: 'Condiciones médicas',
                child: TextField(
                  controller: _condicionesCtrl,
                  style: fieldText,
                  decoration: uiField(
                    ui,
                    hint: 'Ej. diabetes, uso oxígeno',
                    icon: Icons.favorite_border,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              UiLabeled(
                ui: ui,
                label: 'Vivo con',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final opt in _viveOptions)
                      UiChoice(
                        ui: ui,
                        icon: opt['icon'] as IconData,
                        label: opt['label'] as String,
                        selected: _vive.contains(opt['id']),
                        onTap: () => setState(() {
                          final id = opt['id'] as String;
                          if (!_vive.remove(id)) _vive.add(id);
                        }),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          style: ui.action(),
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Guardar ficha'),
          onPressed: _save,
        ),
      ],
    );
  }

  Widget _locked() {
    final ui = this.ui;
    return UiScrollPage(
      maxWidth: 420,
      top: 48,
      centered: true,
      builder: (context, width) => [
        Center(
          child: UiIconBox(ui: ui, icon: Icons.lock_outline, size: 64),
        ),
        const SizedBox(height: 20),
        Text(
          'Tu ficha médica está protegida',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ui.ink,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Usa tu huella, tu rostro o el PIN del teléfono para verla o editarla.',
          textAlign: TextAlign.center,
          style: TextStyle(color: ui.muted, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: widget.state.openMedicalCard,
          style: ui.action(),
          icon: const Icon(Icons.fingerprint, size: 20),
          label: const Text('Desbloquear'),
        ),
      ],
    );
  }
}

/* ========================================================================= */
/*                               PERFIL SCREEN                               */
/* ========================================================================= */

class PerfilScreen extends StatelessWidget {
  final AppState state;
  final NearbyThemeData? theme;
  const PerfilScreen({super.key, required this.state, this.theme});

  @override
  Widget build(BuildContext context) {
    final ui = NearbyCommunityStyle(theme ?? uiThemeOf(state));
    final cs = state.contactBook
        .where((c) => state.contacts.contains(c.id))
        .toList();
    final userLearnedItems = state.connected
        ? state.myLearnings
              .where((e) => !(state.aiRemoved['${e.id}${e.tag}'] ?? false))
              .toList()
        : state.buildInventory().where((e) => e.who == state.userName).toList();

    void manageContacts() {
      state.contactsMode = 'manage';
      state.go('contactos');
    }

    // --- Columna de identidad: quién soy, mis números y mi casa ---
    final identity = <Widget>[
      StaggeredEntrance(
        index: 0,
        child: UiCard(
          ui: ui,
          color: ui.ivory,
          bordered: false,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ProfilePhotoAvatar(state: state, size: 64, editable: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.userName,
                      style: TextStyle(
                        color: ui.ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.userAddress.isNotEmpty
                          ? '${state.userAddress} · +51 ${state.userPhone}'
                          : '${state.effectiveZoneName} · +51 ${state.userPhone}',
                      style: TextStyle(color: ui.muted, fontSize: 12),
                    ),
                    if (!state.connected || state.verified) ...[
                      const SizedBox(height: 8),
                      UiTag(
                        ui: ui,
                        icon: Icons.verified_user,
                        label: 'Vecino verificado',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      StaggeredEntrance(
        index: 1,
        child: Row(
          children: [
            Expanded(
              child: _ProfileStat(
                ui: ui,
                val: '${state.myStats['favorsDone'] ?? 0}',
                label: 'Favores hechos',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ProfileStat(
                ui: ui,
                val: '${state.myStats['endorsementsGiven'] ?? 0}',
                label: 'Vistos dados',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ProfileStat(
                ui: ui,
                val: '${state.myStats['favorsReceived'] ?? 0}',
                label: 'Favores recibidos',
              ),
            ),
          ],
        ),
      ),
      StaggeredEntrance(
        index: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UiSectionTitle(
              ui: ui,
              title: 'Mi dirección y zona',
              actionLabel: 'Editar',
              actionIcon: Icons.edit_outlined,
              onAction: () => _openEditAddressSheet(context, state),
            ),
            UiRowsCard(
              ui: ui,
              rows: [
                UiRow(
                  ui: ui,
                  icon: Icons.home_outlined,
                  title: state.userAddress.isNotEmpty
                      ? state.userAddress
                      : 'Sin dirección registrada',
                  subtitle:
                      '${state.effectiveZoneName} · Privada para ti y brigadas de rescate',
                  trailing: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: ui.muted,
                  ),
                  onTap: () => _openEditAddressSheet(context, state),
                ),
              ],
            ),
          ],
        ),
      ),
    ];

    final logout = OutlinedButton.icon(
      onPressed: () => state.openSheet('logout'),
      style: ui.action(filled: false),
      icon: const Icon(Icons.logout, size: 18),
      label: const Text('Cerrar sesión'),
    );

    // --- Secciones de ajustes ---
    List<Widget> sections({required bool first}) => [
      // Contactos de confianza
      UiSectionTitle(
        ui: ui,
        top: first ? 0 : 24,
        title: 'Contactos de confianza',
        actionLabel: cs.isNotEmpty ? 'Editar' : 'Agregar',
        actionIcon: cs.isNotEmpty ? Icons.edit_outlined : Icons.add,
        onAction: manageContacts,
      ),
      UiRowsCard(
        ui: ui,
        rows: cs.isNotEmpty
            ? [
                for (final c in cs)
                  UiRow(
                    ui: ui,
                    icon: c.icon,
                    title: c.name,
                    subtitle: '${c.phone} · recibe tu SOS',
                    trailing: Icon(
                      Icons.sms_outlined,
                      color: ui.muted,
                      size: 20,
                    ),
                  ),
              ]
            : [
                UiRow(
                  ui: ui,
                  icon: Icons.warning_amber_rounded,
                  iconColor: ui.theme.sos,
                  iconBackground: ui.theme.sosSoft,
                  title: 'Aún no tienes contactos',
                  subtitle: 'Agrega hasta 3 para que reciban tu SOS',
                  onTap: manageContacts,
                ),
              ],
      ),

      // Ficha de emergencia: protegida con huella, rostro o PIN; no se muestra aquí.
      UiSectionTitle(
        ui: ui,
        title: 'Ficha de emergencia',
        actionLabel: 'Ver',
        actionIcon: Icons.lock_open,
        onAction: state.openMedicalCard,
      ),
      UiRowsCard(
        ui: ui,
        rows: [
          UiRow(
            ui: ui,
            icon: Icons.lock_outline,
            title: 'Ficha médica protegida',
            subtitle: 'Sangre, alergias y con quién vives. Tócala para verla con tu huella, rostro o PIN.',
            onTap: state.openMedicalCard,
          ),
        ],
      ),

      // Emergencia
      UiSectionTitle(ui: ui, title: 'Emergencia'),
      UiRowsCard(
        ui: ui,
        rows: [
          UiSwitchRow(
            ui: ui,
            icon: Icons.crisis_alert,
            title: 'Modo emergencia',
            subtitle: state.emergency
                ? 'Activo. Tócalo para volver al modo normal'
                : (state.zoneEm
                      ? 'Tu zona sigue en emergencia'
                      : 'Actívalo para coordinar ayuda en tu barrio'),
            value: state.emergency,
            activeColor: ui.theme.sos,
            onChanged: (val) {
              if (val) {
                state.activateEmergencyFromProfile();
              } else {
                state.openSheet('em-off');
              }
            },
          ),
        ],
      ),

      // Rol en el barrio: pedir ser brigadista o entrar al panel de Municipalidad.
      UiSectionTitle(ui: ui, title: 'Mi rol en el barrio'),
      NeighborhoodRoleCard(state: state),
      if (state.prevention || state.zoneMode == 'PREVENTION') ...[
        const SizedBox(height: 10),
        UiRowsCard(
          ui: ui,
          rows: [
            UiRow(
              ui: ui,
              icon: Icons.flood,
              iconColor: ui.theme.accentInk,
              iconBackground: ui.theme.accentSoft,
              title: 'Prevención El Niño',
              subtitle: state.prevention
                  ? 'Activo en tu app'
                  : 'Tu zona sigue en prevención; tú volviste a normal',
              onTap: () => state.go('prevencion'),
            ),
          ],
        ),
      ],
      if (state.connected && !state.isAdmin)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => state.go('muni-registro'),
              style: uiTextButton(ui),
              icon: const Icon(Icons.account_balance_outlined, size: 18),
              label: const Text('¿Trabajas en una Municipalidad? Regístrala'),
            ),
          ),
        ),

      // Red de rescate con IA
      UiSectionTitle(
        ui: ui,
        title: 'Red de rescate con IA',
        actionLabel: state.isBrigade ? 'Ver red' : null,
        actionIcon: Icons.chevron_right,
        onAction: state.isBrigade ? () => state.go('red') : null,
      ),
      UiRowsCard(
        ui: ui,
        rows: [
          UiSwitchRow(
            ui: ui,
            icon: Icons.auto_awesome_outlined,
            title: 'Usar mis publicaciones en emergencias',
            subtitle: 'La IA puede sugerirte en un rescate según lo que ofreces en el día a día',
            value: state.aiConsent,
            onChanged: (val) {
              state.setAiConsent(val);
              state.toast(
                val
                    ? 'La IA puede sugerirte en rescates'
                    : 'La IA ya no usa tus publicaciones',
                icon: 'auto_awesome',
              );
            },
          ),
          if (state.aiConsent) ...[
            if (userLearnedItems.isNotEmpty)
              for (final item in userLearnedItems)
                UiRow(
                  ui: ui,
                  icon: Icons.auto_awesome,
                  title: 'La IA aprendió: ${kAiTags[item.tag]?.l ?? item.tag}',
                  subtitle: 'De tu publicación: «${item.txt}»',
                  trailing: IconButton(
                    tooltip: 'Borrar este dato',
                    icon: Icon(Icons.delete_outline, color: ui.muted, size: 20),
                    onPressed: () {
                      state.removeLearning(item);
                      state.toast(
                        'Borrado. La IA ya no usará ese dato.',
                        icon: 'delete',
                      );
                    },
                  ),
                )
            else
              UiRow(
                ui: ui,
                icon: Icons.info_outline,
                iconBackground: ui.ivory,
                title: 'La IA aún no aprendió nada de ti',
                subtitle:
                    'Se basa en lo que publicas en el muro y en tu oficio',
              ),
          ],
        ],
      ),

      // Permisos del dispositivo
      if (state.permissions != null) ...[
        UiSectionTitle(ui: ui, title: 'Dispositivo'),
        UiRowsCard(
          ui: ui,
          rows: [
            UiRow(
              ui: ui,
              icon: Icons.admin_panel_settings_outlined,
              title: 'Permisos del dispositivo',
              onTap: state.permissions!.open,
            ),
          ],
        ),
      ],

      // Accesibilidad
      UiSectionTitle(ui: ui, title: 'Accesibilidad'),
      UiRowsCard(
        ui: ui,
        rows: [
          UiSwitchRow(
            ui: ui,
            icon: Icons.text_fields,
            title: 'Texto grande',
            subtitle: 'Letras y botones más grandes',
            value: state.lg,
            onChanged: (_) => state.toggleLg(),
          ),
          UiSwitchRow(
            ui: ui,
            icon: Icons.contrast,
            title: 'Alto contraste',
            subtitle: 'Mejor lectura con sol o poca vista',
            value: state.hc,
            onChanged: (_) => state.toggleHc(),
          ),
          UiSwitchRow(
            ui: ui,
            icon: Icons.dark_mode_outlined,
            title: 'Tema oscuro',
            subtitle: 'Ahorra batería de noche o en un corte de luz',
            value: state.dark,
            onChanged: (_) => state.toggleDark(),
          ),
        ],
      ),

      // Sin conexión
      UiSectionTitle(ui: ui, title: 'Sin conexión'),
      UiRowsCard(
        ui: ui,
        rows: [
          _OfflineMapTile(state: state, ui: ui),
          UiRow(
            ui: ui,
            icon: Icons.sync,
            title: state.lastSyncAt == null
                ? 'Aún no se sincroniza'
                : 'Última sincronización '
                      '${state.lastSyncAt!.hour.toString().padLeft(2, '0')}:'
                      '${state.lastSyncAt!.minute.toString().padLeft(2, '0')}',
            subtitle: state.outboxCount > 0
                ? '${state.outboxCount} envíos pendientes'
                : 'Todo al día',
          ),
        ],
      ),
    ];

    return UiScrollPage(
      maxWidth: 1100,
      builder: (context, width) {
        // Escritorio: identidad a la izquierda y ajustes a la derecha.
        if (width >= 900) {
          return [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 340,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [...identity, const SizedBox(height: 24), logout],
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: sections(first: true),
                  ),
                ),
              ],
            ),
          ];
        }
        return [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...identity,
                  ...sections(first: false),
                  const SizedBox(height: 32),
                  logout,
                ],
              ),
            ),
          ),
        ];
      },
    );
  }

  void _openEditAddressSheet(BuildContext context, AppState state) {
    showEditAddressSheet(context, state);
  }
}

class _ProfileStat extends StatelessWidget {
  final NearbyCommunityStyle ui;
  final String val;
  final String label;
  const _ProfileStat({
    required this.ui,
    required this.val,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => UiCard(
    ui: ui,
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          val,
          style: TextStyle(
            color: ui.ink,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: ui.muted, fontSize: 11, height: 1.2),
        ),
      ],
    ),
  );
}

/// Estado real del mapa sin conexión: descargar, progreso, tamaño y borrar.
class _OfflineMapTile extends StatelessWidget {
  final AppState state;
  final NearbyCommunityStyle ui;
  const _OfflineMapTile({required this.state, required this.ui});

  @override
  Widget build(BuildContext context) {
    final tiles = OfflineTiles.instance;
    if (!tiles.ready) {
      return UiRow(
        ui: ui,
        icon: Icons.map_outlined,
        title: 'Mapa sin conexión',
        subtitle: 'Disponible en la app del celular',
      );
    }
    return ValueListenableBuilder<OfflineMapStatus>(
      valueListenable: tiles.status,
      builder: (context, s, _) {
        final radius = OfflineTiles.defaultRadiusKm.toStringAsFixed(0);
        if (s.downloading) {
          return UiRow(
            ui: ui,
            icon: Icons.downloading,
            title: 'Descargando mapa · ${(s.progress * 100).round()} %',
            subtitleWidget: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(
                value: s.progress,
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            trailing: IconButton(
              tooltip: 'Cancelar descarga',
              onPressed: tiles.cancelDownload,
              icon: Icon(Icons.close, color: ui.ink),
            ),
          );
        }
        final c = state.offlineMapCenter;
        final current = c != null && tiles.covers(c.lat, c.lng);
        final when = s.savedAt == null
            ? ''
            : ' · ${s.savedAt!.day}/${s.savedAt!.month} '
                  '${s.savedAt!.hour}:${s.savedAt!.minute.toString().padLeft(2, '0')}';
        return UiRow(
          ui: ui,
          icon: s.saved
              ? Icons.download_done
              : Icons.download_for_offline_outlined,
          title: s.saved
              ? 'Mapa de tu zona guardado · ${s.sizeText}'
              : 'Descargar mapa de tu zona ($radius km)',
          subtitle:
              s.error ??
              (s.saved
                  ? (current
                        ? '${s.tiles} teselas$when. Se ve aunque no haya internet.'
                        : 'Guardado para otra dirección: vuelve a descargarlo.')
                  : 'Así el mapa no sale en blanco sin internet (unos 5 MB).'),
          trailing: s.saved
              ? PopupMenuButton<String>(
                  tooltip: 'Opciones del mapa guardado',
                  icon: Icon(Icons.more_vert, color: ui.ink),
                  onSelected: (v) {
                    if (v == 'update') {
                      state.ensureOfflineMap(manual: true);
                    } else {
                      tiles.clear();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'update', child: Text('Actualizar')),
                    PopupMenuItem(value: 'clear', child: Text('Borrar')),
                  ],
                )
              : null,
          onTap: s.saved && current
              ? null
              : () => state.ensureOfflineMap(manual: true),
        );
      },
    );
  }
}
