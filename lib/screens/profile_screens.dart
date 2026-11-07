import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../widgets/navigation_chrome.dart';

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
              color: Colors.grey.shade600,
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
                  color: isSelected ? Colors.white : Colors.grey.shade800,
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
              fillColor: Colors.grey.withValues(alpha: 0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.2),
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
              fillColor: Colors.grey.withValues(alpha: 0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.2),
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
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
                label: Text(opt['label'] as String),
                selected: isSelected,
                selectedColor: NearbyColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade800,
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
              backgroundColor: NearbyColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
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
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: NearbyColors.primary,
                      child: Text(
                        state.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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
                              color: Colors.grey.shade600,
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

          // Profile stats
          Padding(
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
          const SizedBox(height: 16),

          // Mi dirección y zona
          _SectionHeader(
            title: 'Mi dirección y zona',
            actionLabel: 'Editar',
            actionIcon: Icons.edit,
            onTap: () => _openEditAddressSheet(context, state),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: NearbyColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.home_outlined,
                    color: NearbyColors.primary,
                    size: 22,
                  ),
                ),
                title: Text(
                  state.userAddress.isNotEmpty
                      ? state.userAddress
                      : 'Sin dirección registrada',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  '${state.effectiveZoneName} · Privada para ti y brigadas de rescate',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
                onTap: () => _openEditAddressSheet(context, state),
              ),
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
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
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
                            color: Colors.grey,
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
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
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
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
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
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
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
                              color: Colors.grey,
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
                        leading: Icon(Icons.info, color: Colors.grey),
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
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
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
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
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
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: NearbyColors.sos,
                side: const BorderSide(color: NearbyColors.sos),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout),
              label: const Text(
                'Cerrar sesión',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              onPressed: () => state.openSheet('logout'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _openEditAddressSheet(BuildContext context, AppState state) {
    double tempLat = state.regLat ?? -11.9790;
    double tempLng = state.regLng ?? -77.0030;
    final addrController = TextEditingController(text: state.userAddress);
    bool isDetecting = false;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
                left: 20,
                right: 20,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: NearbyColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.edit_location_alt,
                          color: NearbyColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Editar dirección de tu hogar',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Actualiza tu dirección o muévete con GPS',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Campo de dirección
                  TextField(
                    controller: addrController,
                    decoration: InputDecoration(
                      labelText: 'Dirección o referencia exacta',
                      hintText: 'Ej. Jr. Las Flores 245, SJL',
                      prefixIcon: const Icon(Icons.home_outlined),
                      suffixIcon: addrController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                setModalState(() => addrController.clear());
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 12),

                  // Atajos y detección
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        avatar: isDetecting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(
                                Icons.my_location,
                                size: 16,
                                color: Color(0xFF1E8E3E),
                              ),
                        label: Text(
                          isDetecting ? 'Detectando GPS…' : 'Usar ubicación GPS',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: isDetecting
                            ? null
                            : () async {
                                setModalState(() => isDetecting = true);
                                try {
                                  final pos = await state.location.current();
                                  tempLat = pos.lat;
                                  tempLng = pos.lng;

                                  try {
                                    final uri = Uri.parse(
                                      'https://nominatim.openstreetmap.org/reverse?format=json&lat=${pos.lat}&lon=${pos.lng}&zoom=18&addressdetails=1',
                                    );
                                    final res = await http.get(
                                      uri,
                                      headers: {'User-Agent': 'UTP-Comercio/1.0'},
                                    ).timeout(const Duration(seconds: 4));
                                    if (res.statusCode == 200) {
                                      final data =
                                          jsonDecode(res.body) as Map<String, dynamic>;
                                      final addr =
                                          data['address'] as Map<String, dynamic>?;
                                      if (addr != null) {
                                        final road = addr['road'] as String?;
                                        final num = addr['house_number'] as String?;
                                        final suburb = addr['suburb'] as String? ??
                                            addr['neighbourhood'] as String?;
                                        final district = addr['city_district'] as String? ??
                                            addr['city'] as String?;
                                        if (road != null) {
                                          addrController.text = num != null
                                              ? '$road $num${district != null ? ', $district' : ''}'
                                              : '$road${suburb != null ? ', $suburb' : ''}';
                                        } else if (district != null) {
                                          addrController.text = district;
                                        }
                                      }
                                    }
                                  } catch (_) {
                                    if (pos.city != null && pos.city!.isNotEmpty) {
                                      addrController.text = pos.region != null
                                          ? '${pos.city}, ${pos.region}'
                                          : pos.city!;
                                    }
                                  }
                                } catch (_) {
                                  state.toast('No se pudo obtener el GPS', icon: 'error');
                                } finally {
                                  setModalState(() => isDetecting = false);
                                }
                              },
                      ),
                      ActionChip(
                        avatar: const Icon(
                          Icons.place,
                          size: 16,
                          color: Color(0xFF1A73E8),
                        ),
                        label: const Text(
                          'Jr. Las Flores (SJL)',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: () {
                          setModalState(() {
                            tempLat = -11.9790;
                            tempLng = -77.0030;
                            addrController.text = 'Jr. Las Flores 245, SJL';
                          });
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(
                          Icons.school,
                          size: 16,
                          color: Color(0xFFE37400),
                        ),
                        label: const Text(
                          'UTP Sede SJL',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: () {
                          setModalState(() {
                            tempLat = -11.9892;
                            tempLng = -77.0062;
                            addrController.text = 'UTP Sede San Juan de Lurigancho';
                          });
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(
                          Icons.place,
                          size: 16,
                          color: Color(0xFF1A73E8),
                        ),
                        label: const Text(
                          'J. L. Ortiz (Chiclayo)',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: () {
                          setModalState(() {
                            tempLat = -6.7562;
                            tempLng = -79.8398;
                            addrController.text = 'Calle Los Zapallos, José Leonardo Ortiz';
                          });
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(
                          Icons.place,
                          size: 16,
                          color: Color(0xFF1A73E8),
                        ),
                        label: const Text(
                          'Chiclayo (Lambayeque)',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: () {
                          setModalState(() {
                            tempLat = -6.7701;
                            tempLng = -79.8550;
                            addrController.text = 'Chiclayo, Lambayeque';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Tarjeta de coordenadas
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.explore,
                          color: Color(0xFF1A73E8),
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Coordenadas de referencia',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Lat: ${tempLat.toStringAsFixed(4)}, Lng: ${tempLng.toStringAsFixed(4)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final query = Uri.encodeComponent(
                              addrController.text.isNotEmpty
                                  ? '${addrController.text}, Lima'
                                  : '$tempLat,$tempLng',
                            );
                            final uri = Uri.parse(
                              'https://www.google.com/maps/search/?api=1&query=$query',
                            );
                            try {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } catch (_) {}
                          },
                          icon: const Icon(Icons.open_in_new, size: 14),
                          label: const Text(
                            'Maps',
                            style: TextStyle(fontSize: 11),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1A73E8),
                            side: const BorderSide(color: Color(0xFF1A73E8)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final text = addrController.text.trim();
                            if (text.isEmpty) {
                              state.toast(
                                'Ingresa una dirección o referencia',
                                icon: 'warning',
                              );
                              return;
                            }
                            setModalState(() => isSaving = true);
                            final ok = await state.updateUserLocation(
                              address: text,
                              lat: tempLat,
                              lng: tempLng,
                            );
                            setModalState(() => isSaving = false);
                            if (ok) {
                              Navigator.pop(ctx);
                              state.toast(
                                'Dirección guardada correctamente',
                                icon: 'check_circle',
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NearbyColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Guardar dirección',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String val;
  final String label;
  const _ProfileStat({required this.val, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            val,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: NearbyColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          if (actionLabel != null && onTap != null)
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  children: [
                    if (actionIcon != null) ...[
                      Icon(actionIcon, size: 14, color: NearbyColors.primary),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      actionLabel!,
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
