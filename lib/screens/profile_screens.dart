import 'package:flutter/material.dart';

import '../widgets/common_widgets.dart';
import '../widgets/navigation_chrome.dart';
import 'profile/widgets/edit_address_sheet.dart';
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Solo la ven los brigadistas verificados cuando envías un SOS. Les ayuda a atenderte mejor.',
            style: TextStyle(
              fontSize: 13,
              color: NearbyColors.muted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Blood type
          const Text(
            'Tipo de sangre',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _bloodTypes.map((t) {
              final isSelected = _sangre == t;
              return ChoiceChip(
                label: Text(t),
                selected: isSelected,
                selectedColor: NearbyColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : NearbyColors.ink,
                  fontWeight: FontWeight.w700,
                ),
                onSelected: (val) {
                  if (val) setState(() => _sangre = t);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Alergias
          const Text(
            'Alergias',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _alergiasCtrl,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.medication),
              hintText: 'Ej. penicilina',
              filled: true,
              fillColor: NearbyColors.muted.withValues(alpha: 0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: NearbyColors.muted.withValues(alpha: 0.2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Condiciones
          const Text(
            'Condiciones médicas',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _condicionesCtrl,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.favorite),
              hintText: 'Ej. diabetes, uso oxígeno',
              filled: true,
              fillColor: NearbyColors.muted.withValues(alpha: 0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: NearbyColors.muted.withValues(alpha: 0.2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Vivo con
          const Text(
            'Vivo con',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _viveOptions.map((opt) {
              final id = opt['id'] as String;
              final isSelected = _vive.contains(id);
              return FilterChip(
                avatar: Icon(
                  opt['icon'] as IconData,
                  size: 16,
                  color: isSelected ? Colors.white : NearbyColors.muted,
                ),
                label: Text(opt['label'] as String),
                selected: isSelected,
                selectedColor: NearbyColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : NearbyColors.ink,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _vive.add(id);
                    } else {
                      _vive.remove(id);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Save button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.check),
            label: const Text(
              'Guardar ficha',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            onPressed: _save,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _locked() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock, size: 48, color: NearbyColors.sos),
          const SizedBox(height: 12),
          const Text(
            'Tu ficha médica está protegida',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Usa tu huella, tu rostro o el PIN del teléfono para verla o editarla.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: NearbyColors.muted),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: widget.state.openMedicalCard,
            icon: const Icon(Icons.fingerprint),
            label: const Text(
              'Desbloquear',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ),
  );
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
    final cs = state.contactBook
        .where((c) => state.contacts.contains(c.id))
        .toList();
    final userLearnedItems = state.connected
        ? state.myLearnings
              .where((e) => !(state.aiRemoved['${e.id}${e.tag}'] ?? false))
              .toList()
        : state.buildInventory().where((e) => e.who == state.userName).toList();

    return SingleChildScrollView(
      padding: NavigationInsets.of(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // User header card
          StaggeredEntrance(
            index: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: NearbyColors.muted.withValues(alpha: 0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      ProfilePhotoAvatar(
                        state: state,
                        size: 64,
                        editable: true,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.userName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              state.userAddress.isNotEmpty
                                  ? '${state.userAddress} · +51 ${state.userPhone}'
                                  : '${state.effectiveZoneName} · +51 ${state.userPhone}',
                              style: TextStyle(
                                fontSize: 11,
                                color: NearbyColors.muted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: NearbyColors.accent.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.verified_user,
                                    size: 13,
                                    color: NearbyColors.accent,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Vecino verificado',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: NearbyColors.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Profile stats
          StaggeredEntrance(
            index: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Expanded(
                    child: _ProfileStat(val: '12', label: 'Favores hechos'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ProfileStat(
                      val: '${5 + state.vbGiven.values.where((v) => v).length}',
                      label: 'Vistos dados',
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: _ProfileStat(val: '3', label: 'Favores recibidos'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Mi dirección y zona
          StaggeredEntrance(
            index: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionHeader(
                  title: 'Mi dirección y zona',
                  actionLabel: 'Editar',
                  actionIcon: Icons.edit,
                  onTap: () => _openEditAddressSheet(context, state),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: PressableScale(
                    onTap: () => _openEditAddressSheet(context, state),
                    scale: 0.98,
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(color: NearbyColors.muted.withValues(alpha: 0.2)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: NearbyColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.home_outlined,
                                color: NearbyColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    state.userAddress.isNotEmpty
                                        ? state.userAddress
                                        : 'Sin dirección registrada',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${state.effectiveZoneName} · Privada para ti y brigadas de rescate',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: NearbyColors.muted,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: NearbyColors.muted.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: NearbyColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Contactos de confianza
          _SectionHeader(
            title: 'Contactos de confianza',
            actionLabel: cs.isNotEmpty ? 'Editar' : 'Agregar',
            actionIcon: cs.isNotEmpty ? Icons.edit : Icons.add,
            onTap: () {
              state.contactsMode = 'manage';
              state.go('contactos');
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: NearbyColors.muted.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: cs.isNotEmpty
                    ? cs.map((c) {
                        return ListTile(
                          leading: Icon(c.icon, color: NearbyColors.primary),
                          title: Text(
                            c.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            '${c.phone} · recibe tu SOS',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(
                            Icons.sms,
                            color: NearbyColors.muted,
                            size: 20,
                          ),
                        );
                      }).toList()
                    : [
                        ListTile(
                          leading: const Icon(
                            Icons.warning,
                            color: NearbyColors.sos,
                          ),
                          title: const Text(
                            'Aún no tienes contactos',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: const Text(
                            'Agrega hasta 3 para que reciban tu SOS',
                            style: TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            state.contactsMode = 'manage';
                            state.go('contactos');
                          },
                        ),
                      ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Ficha de emergencia: protegida con huella, rostro o PIN; no se muestra aquí.
          _SectionHeader(
            title: 'Ficha de emergencia',
            actionLabel: 'Ver',
            actionIcon: Icons.lock_open,
            onTap: state.openMedicalCard,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: NearbyColors.muted.withValues(alpha: 0.2)),
              ),
              child: ListTile(
                leading: const Icon(Icons.lock, color: NearbyColors.sos),
                title: const Text(
                  'Ficha médica protegida',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                subtitle: const Text(
                  'Sangre, alergias y con quién vives. Toca para verla con tu huella, rostro o PIN.',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: state.openMedicalCard,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Emergencia
          const _SectionHeader(title: 'Emergencia'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: NearbyColors.muted.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    value: state.emergency,
                    activeTrackColor: NearbyColors.sos,
                    activeThumbColor: Colors.white,
                    title: const Text(
                      'Modo emergencia',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      state.emergency
                          ? 'Activo. Tócalo para volver al modo normal'
                          : (state.zoneEm
                                ? 'Tu zona sigue en emergencia'
                                : 'Actívalo para coordinar ayuda en tu barrio'),
                      style: const TextStyle(fontSize: 12),
                    ),
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
            ),
          ),
          const SizedBox(height: 16),

          // Rol en el barrio: pedir ser brigadista o entrar al panel de Municipalidad.
          const _SectionHeader(title: 'Mi rol en el barrio'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: NeighborhoodRoleCard(state: state),
          ),
          if (state.prevention || state.zoneMode == 'PREVENTION') ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.flood,
                    color: NearbyColors.accentInk,
                  ),
                  title: const Text(
                    'Prevención El Niño',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    state.prevention
                        ? 'Activo en tu app'
                        : 'Tu zona sigue en prevención; tú volviste a normal',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => state.go('prevencion'),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Red de rescate con IA
          _SectionHeader(
            title: 'Red de rescate con IA',
            actionLabel: state.isBrigade ? 'Ver red' : null,
            actionIcon: state.isBrigade ? Icons.chevron_right : null,
            onTap: state.isBrigade ? () => state.go('red') : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: NearbyColors.muted.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    value: state.aiConsent,
                    activeTrackColor: NearbyColors.ai,
                    activeThumbColor: Colors.white,
                    title: const Text(
                      'Usar mis publicaciones en emergencias',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'La IA puede sugerirte en un rescate según lo que ofreces en el día a día',
                      style: TextStyle(fontSize: 12),
                    ),
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
                    const Divider(height: 1),
                    if (userLearnedItems.isNotEmpty)
                      ...userLearnedItems.map((item) {
                        final tag = kAiTags[item.tag];
                        return ListTile(
                          leading: Icon(
                            Icons.auto_awesome,
                            color: NearbyColors.ai,
                            size: 20,
                          ),
                          title: Text(
                            'La IA aprendió: ${tag?.l ?? item.tag}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            'De tu publicación: «${item.txt}»',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: NearbyColors.muted,
                              size: 20,
                            ),
                            onPressed: () {
                              state.removeLearning(item);
                              state.toast(
                                'Borrado. La IA ya no usará ese dato.',
                                icon: 'delete',
                              );
                            },
                          ),
                        );
                      })
                    else
                      const ListTile(
                        leading: Icon(Icons.info, color: NearbyColors.muted),
                        title: Text(
                          'La IA aún no aprendió nada de ti',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          'Se basa en lo que publicas en el muro y en tu oficio',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (state.permissions != null)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('Permisos del dispositivo'),
              trailing: const Icon(Icons.chevron_right),
              onTap: state.permissions!.open,
            ),

          // Accesibilidad
          const _SectionHeader(title: 'Accesibilidad'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: NearbyColors.muted.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    value: state.lg,
                    title: const Text(
                      'Texto grande',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'Letras y botones más grandes',
                      style: TextStyle(fontSize: 12),
                    ),
                    onChanged: (_) => state.toggleLg(),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: state.hc,
                    title: const Text(
                      'Alto contraste',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'Mejor lectura con sol o poca vista',
                      style: TextStyle(fontSize: 12),
                    ),
                    onChanged: (_) => state.toggleHc(),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: state.dark,
                    title: const Text(
                      'Tema oscuro',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'Ahorra batería de noche o en un corte de luz',
                      style: TextStyle(fontSize: 12),
                    ),
                    onChanged: (_) => state.toggleDark(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sin conexión
          const _SectionHeader(title: 'Sin conexión'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: NearbyColors.muted.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  _OfflineMapTile(state: state),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.sync,
                      color: NearbyColors.primary,
                    ),
                    title: const Text(
                      'Última sincronización 10:31',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      state.pending > 0
                          ? '${state.pending} envíos pendientes'
                          : 'Todo al día',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Logout button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PressableScale(
              onTap: () => state.openSheet('logout'),
              scale: 0.97,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: NearbyColors.sos, width: 1.5),
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.transparent,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: NearbyColors.sos, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Cerrar sesión',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: NearbyColors.sos,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _openEditAddressSheet(BuildContext context, AppState state) {
    showEditAddressSheet(context, state);
  }
}

class _ProfileStat extends StatelessWidget {
  final String val;
  final String label;
  const _ProfileStat({required this.val, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: NearbyColors.muted.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              val,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: NearbyColors.primary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: NearbyColors.muted,
                fontWeight: FontWeight.w400,
                height: 1.2,
              ),
            ),
          ],
        ),
      );
    }
  }

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onTap;

  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.actionIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          if (actionLabel != null && onTap != null)
            PressableScale(
              onTap: onTap,
              scale: 0.94,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: NearbyColors.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (actionIcon != null) ...[
                      Icon(actionIcon, size: 14, color: NearbyColors.primary),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      actionLabel!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: NearbyColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Estado real del mapa sin conexión: descargar, progreso, tamaño y borrar.
class _OfflineMapTile extends StatelessWidget {
  final AppState state;
  const _OfflineMapTile({required this.state});

  @override
  Widget build(BuildContext context) {
    final tiles = OfflineTiles.instance;
    if (!tiles.ready) {
      return const ListTile(
        leading: Icon(Icons.map_outlined, color: NearbyColors.accent),
        title: Text(
          'Mapa sin conexión',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: Text(
          'Disponible en la app del celular',
          style: TextStyle(fontSize: 12),
        ),
      );
    }
    return ValueListenableBuilder<OfflineMapStatus>(
      valueListenable: tiles.status,
      builder: (context, s, _) {
        final radius = OfflineTiles.defaultRadiusKm.toStringAsFixed(0);
        if (s.downloading) {
          return ListTile(
            leading: const Icon(Icons.downloading, color: NearbyColors.primary),
            title: Text(
              'Descargando mapa · ${(s.progress * 100).round()} %',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: LinearProgressIndicator(value: s.progress),
            ),
            trailing: IconButton(
              tooltip: 'Cancelar descarga',
              onPressed: tiles.cancelDownload,
              icon: const Icon(Icons.close),
            ),
          );
        }
        final c = state.offlineMapCenter;
        final current = c != null && tiles.covers(c.lat, c.lng);
        final when = s.savedAt == null
            ? ''
            : ' · ${s.savedAt!.day}/${s.savedAt!.month} '
                  '${s.savedAt!.hour}:${s.savedAt!.minute.toString().padLeft(2, '0')}';
        return ListTile(
          leading: Icon(
            s.saved ? Icons.download_done : Icons.download_for_offline,
            color: s.saved ? NearbyColors.primary : NearbyColors.accent,
          ),
          title: Text(
            s.saved
                ? 'Mapa de tu zona guardado · ${s.sizeText}'
                : 'Descargar mapa de tu zona ($radius km)',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          subtitle: Text(
            s.error ??
                (s.saved
                    ? (current
                          ? '${s.tiles} teselas$when. Se ve aunque no haya internet.'
                          : 'Guardado para otra dirección: vuelve a descargarlo.')
                    : 'Así el mapa no sale en blanco sin internet (unos 5 MB).'),
            style: const TextStyle(fontSize: 12),
          ),
          trailing: s.saved
              ? PopupMenuButton<String>(
                  tooltip: 'Opciones del mapa guardado',
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
              : const Icon(Icons.chevron_right),
          onTap: s.saved && current
              ? null
              : () => state.ensureOfflineMap(manual: true),
        );
      },
    );
  }
}
