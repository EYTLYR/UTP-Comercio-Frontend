import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../state/app_state.dart';
import '../theme/nearby_theme.dart';
import 'profile/widgets/profile_ui.dart';

// ===================================================================== registro

/// Página para que una Municipalidad se registre. El responsable ingresa con su celular, completa los datos
/// y Nearby revisa el RUC antes de aprobarla. Aprobada, administra su distrito y su equipo desde la app.
class MunicipalityRegisterScreen extends StatefulWidget {
  final AppState state;
  final NearbyThemeData theme;
  const MunicipalityRegisterScreen({
    super.key,
    required this.state,
    required this.theme,
  });

  @override
  State<MunicipalityRegisterScreen> createState() =>
      _MunicipalityRegisterScreenState();
}

class _MunicipalityRegisterScreenState
    extends State<MunicipalityRegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _ruc = TextEditingController();
  final _contact = TextEditingController();
  final _position = TextEditingController();
  final _email = TextEditingController();
  String _district = '';
  bool _sending = false;
  bool _retry = false;

  AppState get state => widget.state;
  NearbyCommunityStyle get ui => NearbyCommunityStyle(widget.theme);

  @override
  void initState() {
    super.initState();
    if (state.connected) {
      state.loadMyMunicipality();
      state.loadMunicipalityDistricts();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _ruc.dispose();
    _contact.dispose();
    _position.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _sending = true);
    final ok = await state.registerMunicipality(
      name: _name.text,
      district: _district,
      ruc: _ruc.text,
      contactName: _contact.text,
      contactPosition: _position.text,
      email: _email.text,
    );
    if (mounted) {
      setState(() {
        _sending = false;
        if (ok) _retry = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = this.ui;
    final theme = widget.theme;
    final status = state.myMunicipality['status'] as String? ?? 'NONE';
    final children = <Widget>[];

    if (state.isMunicipality || state.isPlatformAdmin) {
      children.add(
        _StatusCard(
          ui: ui,
          icon: Icons.verified_outlined,
          title: state.isPlatformAdmin
              ? 'Administras la plataforma Nearby'
              : 'Ya eres parte de ${state.municipality?['name'] ?? 'tu Municipalidad'}',
          body:
              'Desde el panel manejas las zonas, los brigadistas y tu equipo.',
          action: ElevatedButton.icon(
            onPressed: () => state.go('municipalidad'),
            style: ui.action(),
            icon: const Icon(Icons.account_balance_outlined, size: 18),
            label: const Text('Abrir panel'),
          ),
        ),
      );
    } else if (status == 'PENDING') {
      children.add(
        _StatusCard(
          ui: ui,
          icon: Icons.hourglass_top,
          iconBackground: ui.ivory,
          title: 'Registro en revisión',
          body:
              'Nearby está verificando el RUC ${state.myMunicipality['ruc'] ?? ''} '
              'de ${state.myMunicipality['name'] ?? 'tu Municipalidad'}. '
              'Cuando la aprobemos, esta cuenta abrirá el panel de la Municipalidad.',
          action: OutlinedButton.icon(
            onPressed: state.loadAll,
            style: ui.action(filled: false),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Revisar estado'),
          ),
        ),
      );
    } else if (status == 'APPROVED') {
      children.add(
        _StatusCard(
          ui: ui,
          icon: Icons.verified_outlined,
          title: '¡Municipalidad aprobada!',
          body: 'Actualiza para abrir el panel con tu nuevo rol.',
          action: ElevatedButton.icon(
            onPressed: state.loadAll,
            style: ui.action(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Actualizar'),
          ),
        ),
      );
    } else {
      if (status == 'REJECTED' && !_retry) {
        final reason = state.myMunicipality['rejectReason'] as String?;
        children.add(
          _StatusCard(
            ui: ui,
            icon: Icons.info_outline,
            iconColor: theme.accentInk,
            iconBackground: theme.accentSoft,
            title: 'No pudimos aprobar el registro',
            body: reason == null || reason.isEmpty
                ? 'Revisa los datos y vuelve a enviarlo.'
                : 'Motivo: $reason',
            action: OutlinedButton(
              onPressed: () => setState(() => _retry = true),
              style: ui.action(filled: false),
              child: const Text('Corregir y enviar de nuevo'),
            ),
          ),
        );
      } else {
        children
          ..add(_Steps(ui: ui))
          ..add(const SizedBox(height: 16))
          ..add(_buildForm(context));
      }
    }

    return UiScrollPage(
      builder: (context, width) => [
        UiPageHeader(
          ui: ui,
          title: 'Tu Municipalidad en Nearby',
          subtitle: 'Avisa a tus vecinos en emergencias, aprueba brigadistas y activa Prevención El Niño en tu distrito.',
        ),
        ...children,
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    final ui = this.ui;
    final text = TextStyle(color: ui.ink, fontSize: 14);
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiCard(
            ui: ui,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                UiLabeled(
                  ui: ui,
                  label: 'Nombre de la Municipalidad',
                  child: TextFormField(
                    controller: _name,
                    style: text,
                    textCapitalization: TextCapitalization.words,
                    decoration: uiField(
                      ui,
                      hint: 'Ej. Municipalidad de San Juan de Lurigancho',
                      icon: Icons.account_balance_outlined,
                    ),
                    validator: (v) => (v ?? '').trim().length < 5
                        ? 'Escribe el nombre de la Municipalidad'
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                UiLabeled(
                  ui: ui,
                  label: 'Distrito',
                  child: Autocomplete<String>(
                    optionsBuilder: (value) {
                      final q = value.text.trim().toLowerCase();
                      return q.isEmpty
                          ? state.muniDistricts
                          : state.muniDistricts.where(
                              (d) => d.toLowerCase().contains(q),
                            );
                    },
                    onSelected: (d) => _district = d,
                    fieldViewBuilder: (context, controller, focus, onSubmit) =>
                        TextFormField(
                          controller: controller,
                          focusNode: focus,
                          style: text,
                          textCapitalization: TextCapitalization.words,
                          onChanged: (v) => _district = v,
                          decoration: uiField(
                            ui,
                            hint: 'Ej. San Juan de Lurigancho',
                            icon: Icons.location_city,
                          ),
                          validator: (v) => (v ?? '').trim().length < 3
                              ? 'Indica el distrito'
                              : null,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                UiLabeled(
                  ui: ui,
                  label: 'RUC',
                  child: TextFormField(
                    controller: _ruc,
                    style: text,
                    keyboardType: TextInputType.number,
                    maxLength: 11,
                    decoration: uiField(
                      ui,
                      hint: '20XXXXXXXXX',
                      counterText: '',
                      icon: Icons.badge_outlined,
                    ),
                    validator: (v) =>
                        RegExp(r'^20\d{9}$').hasMatch((v ?? '').trim())
                        ? null
                        : 'El RUC tiene 11 dígitos y empieza con 20',
                  ),
                ),
                const SizedBox(height: 16),
                UiLabeled(
                  ui: ui,
                  label: 'Nombre del responsable',
                  child: TextFormField(
                    controller: _contact,
                    style: text,
                    textCapitalization: TextCapitalization.words,
                    decoration: uiField(ui, icon: Icons.person_outline),
                    validator: (v) => (v ?? '').trim().length < 3
                        ? 'Escribe el nombre del responsable'
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                UiLabeled(
                  ui: ui,
                  label: 'Cargo (opcional)',
                  child: TextFormField(
                    controller: _position,
                    style: text,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: uiField(
                      ui,
                      hint: 'Ej. Gerente de Gestión del Riesgo de Desastres',
                      icon: Icons.work_outline,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                UiLabeled(
                  ui: ui,
                  label: 'Correo institucional',
                  child: TextFormField(
                    controller: _email,
                    style: text,
                    keyboardType: TextInputType.emailAddress,
                    decoration: uiField(
                      ui,
                      hint: 'riesgos@muni.gob.pe',
                      icon: Icons.alternate_email,
                    ),
                    validator: (v) =>
                        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch((v ?? '').trim())
                        ? null
                        : 'Revisa el correo',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          UiNotice(
            ui: ui,
            icon: Icons.smartphone,
            text:
                'Ingresaste con el celular +51 ${state.userPhone}: será el de la cuenta administradora.',
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _sending ? null : _submit,
            style: ui.action(),
            icon: _sending
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ui.muted,
                    ),
                  )
                : const Icon(Icons.send_outlined, size: 18),
            label: const Text('Enviar registro'),
          ),
        ],
      ),
    );
  }
}

class _Steps extends StatelessWidget {
  final NearbyCommunityStyle ui;
  const _Steps({required this.ui});

  @override
  Widget build(BuildContext context) {
    const steps = [
      (Icons.smartphone, 'Ingresas con el celular del responsable'),
      (Icons.edit_note, 'Completas los datos de la Municipalidad'),
      (Icons.fact_check_outlined, 'Nearby verifica el RUC y la aprueba'),
      (Icons.account_balance_outlined, 'Administras tu distrito y tu equipo'),
    ];
    return UiCard(
      ui: ui,
      color: ui.ivory,
      bordered: false,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'CÓMO FUNCIONA',
            style: TextStyle(
              color: ui.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  UiIconBox(
                    ui: ui,
                    icon: steps[i].$1,
                    size: 32,
                    background: ui.theme.surface,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${i + 1}. ${steps[i].$2}',
                      style: TextStyle(
                        color: ui.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final NearbyCommunityStyle ui;
  final IconData icon;
  final Color? iconColor, iconBackground;
  final String title, body;
  final Widget action;
  const _StatusCard({
    required this.ui,
    required this.icon,
    this.iconColor,
    this.iconBackground,
    required this.title,
    required this.body,
    required this.action,
  });

  @override
  Widget build(BuildContext context) => UiCard(
    ui: ui,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            UiIconBox(
              ui: ui,
              icon: icon,
              size: 44,
              color: iconColor,
              background: iconBackground,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: ui.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          body,
          style: TextStyle(color: ui.muted, fontSize: 13.5, height: 1.45),
        ),
        const SizedBox(height: 16),
        action,
      ],
    ),
  );
}

// ===================================================================== panel

const _modes = [
  ('NORMAL', 'Normal', Icons.wb_sunny_outlined),
  ('PREVENTION', 'Prevención', Icons.flood),
  ('EMERGENCY', 'Emergencia', Icons.crisis_alert),
];

/// Color de cada modo: tinta (normal), ámbar (prevención) y rojo (emergencia).
Color _modeColor(String id, NearbyCommunityStyle ui) => switch (id) {
  'PREVENTION' => ui.theme.accent,
  'EMERGENCY' => ui.theme.sos,
  _ => ui.ink,
};

const _roleLabels = {
  'NEIGHBOR': 'Vecino',
  'BRIGADIST': 'Brigadista',
  'DELEGATE': 'Delegado',
  'MUNICIPALITY': 'Municipalidad',
  'ADMIN': 'Administración Nearby',
};

/// Panel según el rol:
/// - Administración Nearby (ADMIN): aprueba Municipalidades y ve todas las zonas.
/// - Municipalidad (MUNICIPALITY): zonas de su distrito, brigadistas, roles y su equipo.
/// - Delegado (DELEGATE): su zona y los brigadistas de su zona.
class MunicipalidadScreen extends StatefulWidget {
  final AppState state;
  final NearbyThemeData theme;
  const MunicipalidadScreen({
    super.key,
    required this.state,
    required this.theme,
  });

  @override
  State<MunicipalidadScreen> createState() => _MunicipalidadScreenState();
}

class _MunicipalidadScreenState extends State<MunicipalidadScreen> {
  final _phone = TextEditingController();
  final _staffPhone = TextEditingController();
  Map<String, dynamic>? _found;
  bool _searching = false;

  AppState get state => widget.state;
  NearbyCommunityStyle get ui => NearbyCommunityStyle(widget.theme);

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    state.loadAdminRequests();
    state.loadManagedZones();
    if (state.isPlatformAdmin) state.loadMunicipalities();
    if (state.isMunicipality) state.loadStaff();
  }

  @override
  void dispose() {
    _phone.dispose();
    _staffPhone.dispose();
    super.dispose();
  }

  Future<void> _confirmMode(Map<String, dynamic> zone, String mode) async {
    if (mode == zone['mode']) return;
    final ui = this.ui;
    final name = zone['name'] as String? ?? 'la zona';
    final label = _modes.firstWhere((m) => m.$1 == mode).$2;
    final reason = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheet) => Padding(
        padding: uiSheetPadding(sheet),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UiSheetHeader(
              ui: ui,
              title: mode == 'NORMAL'
                  ? '¿Volver al modo normal en $name?'
                  : '¿Activar $label en $name?',
              subtitle:
                  'Avisaremos a todos los vecinos de $name y su app cambiará de modo.',
            ),
            UiLabeled(
              ui: ui,
              label: 'Mensaje para los vecinos (opcional)',
              child: TextField(
                controller: reason,
                maxLength: 300,
                style: TextStyle(color: ui.ink, fontSize: 14),
                decoration: uiField(
                  ui,
                  hint: 'Ej. Lluvias fuertes previstas esta semana',
                ),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.pop(sheet, true),
              style: ui.action(),
              child: Text(
                mode == 'NORMAL' ? 'Volver a normal' : 'Activar y avisar',
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.pop(sheet, false),
              style: uiTextButton(ui),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      await state.setModeOfZone(zone['id'] as String, name, mode, reason.text);
    }
    reason.dispose();
  }

  Future<void> _reject(Map<String, dynamic> m) async {
    final ui = this.ui;
    final reason = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheet) => Padding(
        padding: uiSheetPadding(sheet),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UiSheetHeader(ui: ui, title: '¿Rechazar a ${m['name']}?'),
            UiLabeled(
              ui: ui,
              label: 'Motivo (lo verá quien la registró)',
              child: TextField(
                controller: reason,
                maxLength: 300,
                style: TextStyle(color: ui.ink, fontSize: 14),
                decoration: uiField(
                  ui,
                  hint: 'Ej. El RUC no corresponde a una Municipalidad',
                ),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.pop(sheet, true),
              style: ui.action(),
              child: const Text('Rechazar'),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.pop(sheet, false),
              style: uiTextButton(ui),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      await state.decideMunicipality(
        m['id'] as String,
        approve: false,
        reason: reason.text,
      );
    }
    reason.dispose();
  }

  Future<void> _search() async {
    final phone = _phone.text.trim();
    if (phone.length < 9) {
      state.toast('Escribe los 9 dígitos del celular', icon: 'warning');
      return;
    }
    setState(() => _searching = true);
    final u = await state.findUserByPhone(phone);
    if (mounted) {
      setState(() {
        _searching = false;
        _found = u;
      });
    }
  }

  Future<void> _addStaff() async {
    final phone = _staffPhone.text.trim();
    if (phone.length < 9) {
      state.toast('Escribe los 9 dígitos del celular', icon: 'warning');
      return;
    }
    if (await state.addStaff(phone)) _staffPhone.clear();
  }

  @override
  Widget build(BuildContext context) {
    final ui = this.ui;
    final pendingMunis = state.municipalities
        .where((m) => m['status'] == 'PENDING')
        .toList();
    final otherMunis = state.municipalities
        .where((m) => m['status'] != 'PENDING')
        .toList();

    Widget refresh(VoidCallback onPressed, [String tooltip = 'Actualizar']) =>
        IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          style: IconButton.styleFrom(
            foregroundColor: ui.ink,
            backgroundColor: ui.ivory,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.refresh, size: 20),
        );

    Widget decisionButtons({
      required VoidCallback onReject,
      required VoidCallback onApprove,
    }) => Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onReject,
            style: ui.action(filled: false),
            child: const Text('Rechazar'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: onApprove,
            style: ui.action(),
            child: const Text('Aprobar'),
          ),
        ),
      ],
    );

    Widget cardHead(IconData icon, String title, String? subtitle) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UiIconBox(ui: ui, icon: icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: ui.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: ui.muted, fontSize: 12, height: 1.35),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    final fieldText = TextStyle(color: ui.ink, fontSize: 14);

    // --- Equipo de la Municipalidad ---
    List<Widget> staffSection() => [
      UiSectionTitle(
        ui: ui,
        title: 'Mi equipo · ${state.staff.length}',
        trailing: refresh(state.loadStaff),
      ),
      UiCard(
        ui: ui,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final s in state.staff) ...[
              UiRow(
                ui: ui,
                icon: Icons.badge_outlined,
                title: '${s['name']}',
                subtitle: '+51 ${s['phone']}',
                trailing: s['me'] == true
                    ? UiTag(ui: ui, label: 'Tú')
                    : IconButton(
                        tooltip: 'Quitar del equipo',
                        onPressed: () => state.removeStaff(s['id'] as String),
                        icon: Icon(
                          Icons.person_remove_outlined,
                          color: ui.muted,
                        ),
                      ),
              ),
              UiDivider(ui: ui),
            ],
            Padding(
              padding: const EdgeInsets.all(14),
              child: UiLabeled(
                ui: ui,
                label: 'Agregar funcionario',
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _staffPhone,
                        style: fieldText,
                        keyboardType: TextInputType.phone,
                        maxLength: 9,
                        decoration: uiField(
                          ui,
                          hint: 'Celular del funcionario',
                          counterText: '',
                          prefixText: '+51 ',
                        ),
                        onSubmitted: (_) => _addStaff(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _addStaff,
                      style: ui.action(),
                      child: const Text('Agregar'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Debe haber ingresado a Nearby al menos una vez con ese celular.',
        style: TextStyle(fontSize: 12, color: ui.muted),
      ),
    ];

    // --- Roles de vecinos ---
    List<Widget> rolesSection() => [
      UiSectionTitle(ui: ui, title: 'Cambiar el rol de un vecino'),
      UiCard(
        ui: ui,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UiLabeled(
              ui: ui,
              label: 'Celular del vecino',
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _phone,
                      style: fieldText,
                      keyboardType: TextInputType.phone,
                      maxLength: 9,
                      decoration: uiField(
                        ui,
                        hint: 'Celular',
                        counterText: '',
                        prefixText: '+51 ',
                      ),
                      onSubmitted: (_) => _search(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _searching ? null : _search,
                    style: ui.action(),
                    child: const Text('Buscar'),
                  ),
                ],
              ),
            ),
            if (_found != null) ...[
              const SizedBox(height: 16),
              UiDivider(ui: ui),
              const SizedBox(height: 16),
              cardHead(
                Icons.person_outline,
                '${_found!['name']} · ${_found!['phone']}',
                'Hoy: ${_roleLabels[_found!['role']] ?? _found!['role']}'
                    '${_found!['zoneName'] != null ? ' · ${_found!['zoneName']}' : ''}',
              ),
              const SizedBox(height: 12),
              if (const {'ADMIN', 'MUNICIPALITY'}.contains(_found!['role']))
                UiNotice(
                  ui: ui,
                  icon: Icons.info_outline,
                  text: 'El equipo de una Municipalidad se maneja en «Mi equipo».',
                )
              else
                UiTabs<String>(
                  ui: ui,
                  items: const [
                    ('NEIGHBOR', 'Vecino', Icons.home_outlined, null),
                    ('BRIGADIST', 'Brigada', Icons.shield_outlined, null),
                    ('DELEGATE', 'Delegado', Icons.how_to_reg_outlined, null),
                  ],
                  selected: _found!['role'] as String,
                  onSelect: (v) async {
                    if (v == _found!['role']) return;
                    final u = await state.changeUserRole(
                      _found!['id'] as String,
                      v,
                    );
                    if (u != null && mounted) setState(() => _found = u);
                  },
                ),
            ],
          ],
        ),
      ),
    ];

    final canManage = state.isPlatformAdmin || state.isMunicipality;

    return UiScrollPage(
      maxWidth: 1100,
      builder: (context, width) => [
        // Quién soy en el panel
        UiPageHeader(
          ui: ui,
          eyebrow: state.isPlatformAdmin
              ? 'Plataforma'
              : state.isMunicipality
              ? 'Municipalidad'
              : 'Delegado',
          title: state.isPlatformAdmin
              ? 'Administración Nearby'
              : state.isMunicipality
              ? (state.municipality?['name'] as String? ?? 'Municipalidad')
              : 'Delegado de ${state.zoneName}',
          subtitle: state.isPlatformAdmin
              ? 'Apruebas Municipalidades y ves todas las zonas'
              : state.isMunicipality
              ? 'Distrito: ${state.municipality?['district'] ?? '—'}'
              : 'Administras tu zona',
          trailing: refresh(_reload, 'Actualizar todo'),
        ),

        // Plataforma: registros de Municipalidades
        if (state.isPlatformAdmin) ...[
          UiSectionTitle(
            ui: ui,
            top: 0,
            title: 'Municipalidades por aprobar · ${pendingMunis.length}',
          ),
          if (pendingMunis.isEmpty)
            UiEmpty(ui: ui, text: 'No hay registros pendientes.')
          else
            UiGrid(
              children: [
                for (final m in pendingMunis)
                  UiCard(
                    ui: ui,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        cardHead(
                          Icons.account_balance_outlined,
                          '${m['name']}',
                          'Distrito: ${m['district']} · RUC ${m['ruc']}',
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: ui.ivory,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${m['contactName']}'
                            '${m['contactPosition'] != null ? ' · ${m['contactPosition']}' : ''}\n'
                            '${m['email']} · +51 ${m['requestedByPhone'] ?? ''}',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: ui.ink,
                              height: 1.45,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        decisionButtons(
                          onReject: () => _reject(m),
                          onApprove: () => state.decideMunicipality(
                            m['id'] as String,
                            approve: true,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          if (otherMunis.isNotEmpty) ...[
            const SizedBox(height: 12),
            UiCard(
              ui: ui,
              child: ExpansionTile(
                shape: const Border(),
                collapsedShape: const Border(),
                iconColor: ui.ink,
                collapsedIconColor: ui.ink,
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text(
                  'Respondidas · ${otherMunis.length}',
                  style: TextStyle(
                    color: ui.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                children: [
                  for (final m in otherMunis) ...[
                    UiDivider(ui: ui),
                    UiRow(
                      ui: ui,
                      icon: m['status'] == 'APPROVED'
                          ? Icons.verified_outlined
                          : Icons.block,
                      iconBackground: m['status'] == 'APPROVED'
                          ? ui.blueSoft
                          : ui.ivory,
                      iconColor: m['status'] == 'APPROVED' ? ui.ink : ui.muted,
                      title: '${m['name']}',
                      subtitle:
                          '${m['district']} · '
                          '${m['status'] == 'APPROVED' ? 'Aprobada' : 'Rechazada'}',
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],

        // Zonas de mi jurisdicción
        UiSectionTitle(
          ui: ui,
          top: state.isPlatformAdmin ? 28 : 0,
          title: state.isPlatformAdmin
              ? 'Todas las zonas'
              : 'Zonas que administras',
          trailing: refresh(state.loadManagedZones),
        ),
        if (canManage)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => CreateZoneSheet(state: state),
                ),
                style: ui.action(filled: false),
                icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                label: const Text('Crear zona'),
              ),
            ),
          ),
        if (state.managedZones.isEmpty)
          UiEmpty(
            ui: ui,
            text: state.isMunicipality
                ? 'Todavía no hay zonas de ${state.municipality?['district'] ?? 'tu distrito'} en Nearby.'
                : 'No hay zonas para mostrar.',
          )
        else
          UiGrid(
            children: [
              for (final z in state.managedZones)
                UiCard(
                  ui: ui,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      cardHead(
                        Icons.location_city,
                        '${z['name']}',
                        '${z['district']}'
                            '${(z['modeReason'] as String?)?.isNotEmpty == true ? ' · ${z['modeReason']}' : ''}',
                      ),
                      const SizedBox(height: 8),
                      UiTabs<String>(
                        ui: ui,
                        items: [
                          for (final (id, label, icon) in _modes)
                            (id, label, icon, _modeColor(id, ui)),
                        ],
                        selected: z['mode'] as String?,
                        onSelect: (id) => _confirmMode(z, id),
                      ),
                    ],
                  ),
                ),
            ],
          ),

        // Brigadistas
        UiSectionTitle(
          ui: ui,
          top: 28,
          title: 'Quieren ser brigadistas · ${state.adminRequests.length}',
          trailing: refresh(state.loadAdminRequests),
        ),
        if (state.adminRequests.isEmpty)
          UiEmpty(ui: ui, text: 'No hay solicitudes pendientes.')
        else
          UiGrid(
            children: [
              for (final r in state.adminRequests)
                UiCard(
                  ui: ui,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      cardHead(
                        Icons.shield_outlined,
                        '${r['name'] ?? 'Vecino'}',
                        '${r['phone'] ?? ''}',
                      ),
                      if ((r['skills'] as String?)?.isNotEmpty == true) ...[
                        const SizedBox(height: 10),
                        Text(
                          r['skills'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            color: ui.ink,
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      decisionButtons(
                        onReject: () => state.decideBrigadeRequest(
                          r['id'] as String,
                          approve: false,
                        ),
                        onApprove: () => state.decideBrigadeRequest(
                          r['id'] as String,
                          approve: true,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

        // Equipo y roles: lado a lado en escritorio.
        if (state.isMunicipality && width >= 900)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: staffSection(),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: rolesSection(),
                  ),
                ),
              ],
            ),
          )
        else ...[
          if (state.isMunicipality) ...staffSection(),
          if (canManage) ...rolesSection(),
        ],
      ],
    );
  }
}

/// Nueva zona: nombre, centro en el mapa y radio. La Municipalidad la crea en su distrito; un vecino registra
/// su barrio, la casa de su familia o su trabajo (el distrito sale del mapa).
class CreateZoneSheet extends StatefulWidget {
  final AppState state;
  const CreateZoneSheet({super.key, required this.state});

  @override
  State<CreateZoneSheet> createState() => CreateZoneSheetState();
}

class CreateZoneSheetState extends State<CreateZoneSheet> {
  final _name = TextEditingController();
  final _district = TextEditingController();
  late LatLng _center = _initialCenter();
  double _radius = 1200;
  bool _saving = false;

  LatLng _initialCenter() {
    final zones = widget.state.managedZones;
    if (zones.isNotEmpty) {
      final z = zones.first;
      return LatLng(
        (z['centerLat'] as num).toDouble(),
        (z['centerLng'] as num).toDouble(),
      );
    }
    if (widget.state.regLat != null && widget.state.regLng != null) {
      return LatLng(widget.state.regLat!, widget.state.regLng!);
    }
    return const LatLng(-12.0464, -77.0428);
  }

  @override
  void dispose() {
    _name.dispose();
    _district.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().length < 3) {
      widget.state.toast('Escribe el nombre de la zona', icon: 'warning');
      return;
    }
    if (widget.state.isPlatformAdmin && _district.text.trim().isEmpty) {
      widget.state.toast('Indica el distrito', icon: 'warning');
      return;
    }
    setState(() => _saving = true);
    final ok = await widget.state.createZone(
      name: _name.text,
      lat: _center.latitude,
      lng: _center.longitude,
      radiusM: _radius.round(),
      district: widget.state.isPlatformAdmin ? _district.text : null,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final ui = NearbyCommunityStyle(uiThemeOf(widget.state));
    final fieldText = TextStyle(color: ui.ink, fontSize: 14);
    return Padding(
      padding: uiSheetPadding(context),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UiSheetHeader(
              ui: ui,
              title: 'Crear zona',
              subtitle: widget.state.isMunicipality
                  ? 'Se crea en ${widget.state.municipality?['district'] ?? 'tu distrito'}. '
                        'Los vecinos que vivan dentro del círculo quedan en esta zona.'
                  : widget.state.isPlatformAdmin
                  ? 'Los vecinos que vivan dentro del círculo quedan en esta zona.'
                  : 'Registra tu barrio, la casa de tu familia o tu trabajo para ver lo que pasa ahí. '
                        'Los vecinos que vivan dentro del círculo quedan en esta zona.',
              onClose: () => Navigator.pop(context),
            ),
            UiLabeled(
              ui: ui,
              label: 'Nombre de la zona',
              child: TextField(
                controller: _name,
                style: fieldText,
                textCapitalization: TextCapitalization.words,
                decoration: uiField(ui, hint: 'Ej. Urb. Mangomarca'),
              ),
            ),
            if (widget.state.isPlatformAdmin) ...[
              const SizedBox(height: 16),
              UiLabeled(
                ui: ui,
                label: 'Distrito',
                child: TextField(
                  controller: _district,
                  style: fieldText,
                  textCapitalization: TextCapitalization.words,
                  decoration: uiField(ui, hint: 'Ej. San Juan de Lurigancho'),
                ),
              ),
            ],
            const SizedBox(height: 16),
            DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                border: Border.all(color: ui.line),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 240,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: _center,
                      initialZoom: 14,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                      onPositionChanged: (camera, _) =>
                          setState(() => _center = camera.center),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName:
                            'com.example.utp_comercio_frontend',
                      ),
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: _center,
                            radius: _radius,
                            useRadiusInMeter: true,
                            color: NearbyColors.brandTurquoise.withValues(
                              alpha: 0.18,
                            ),
                            borderColor: NearbyColors.brandTurquoise,
                            borderStrokeWidth: 2,
                          ),
                        ],
                      ),
                      const Center(
                        child: Icon(
                          Icons.location_on,
                          size: 40,
                          color: NearbyColors.brandNavy,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mueve el mapa para elegir el centro.',
              style: TextStyle(fontSize: 12, color: ui.muted),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Radio de la zona',
                    style: TextStyle(
                      color: ui.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                UiTag(
                  ui: ui,
                  label: '${(_radius / 1000).toStringAsFixed(1)} km',
                  background: ui.ivory,
                ),
              ],
            ),
            Slider(
              value: _radius,
              min: 300,
              max: 5000,
              divisions: 47,
              label: '${(_radius / 1000).toStringAsFixed(1)} km',
              onChanged: (v) => setState(() => _radius = v),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ui.action(),
              child: Text(_saving ? 'Creando…' : 'Crear zona'),
            ),
          ],
        ),
      ),
    );
  }
}
