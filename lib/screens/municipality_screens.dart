import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../state/app_state.dart';
import '../theme/nearby_theme.dart';
import '../widgets/navigation_chrome.dart';

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
    final pad = NavigationInsets.of(context);
    final status = state.myMunicipality['status'] as String? ?? 'NONE';
    final children = <Widget>[];

    if (state.isMunicipality || state.isPlatformAdmin) {
      children.add(
        _StatusCard(
          icon: Icons.verified,
          color: NearbyColors.accentInk,
          soft: NearbyColors.accentSoft,
          title: state.isPlatformAdmin
              ? 'Administras la plataforma Nearby'
              : 'Ya eres parte de ${state.municipality?['name'] ?? 'tu Municipalidad'}',
          body:
              'Desde el panel manejas las zonas, los brigadistas y tu equipo.',
          action: ElevatedButton.icon(
            onPressed: () => state.go('municipalidad'),
            icon: const Icon(Icons.account_balance),
            label: const Text('Abrir panel'),
          ),
        ),
      );
    } else if (status == 'PENDING') {
      children.add(
        _StatusCard(
          icon: Icons.hourglass_top,
          color: NearbyColors.navy2,
          soft: NearbyColors.infoSoft,
          title: 'Registro en revisión',
          body:
              'Nearby está verificando el RUC ${state.myMunicipality['ruc'] ?? ''} '
              'de ${state.myMunicipality['name'] ?? 'tu Municipalidad'}. '
              'Cuando la aprobemos, esta cuenta abrirá el panel de la Municipalidad.',
          action: OutlinedButton.icon(
            onPressed: state.loadAll,
            icon: const Icon(Icons.refresh),
            label: const Text('Revisar estado'),
          ),
        ),
      );
    } else if (status == 'APPROVED') {
      children.add(
        _StatusCard(
          icon: Icons.verified,
          color: NearbyColors.accentInk,
          soft: NearbyColors.accentSoft,
          title: '¡Municipalidad aprobada!',
          body: 'Actualiza para abrir el panel con tu nuevo rol.',
          action: ElevatedButton.icon(
            onPressed: state.loadAll,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
          ),
        ),
      );
    } else {
      if (status == 'REJECTED' && !_retry) {
        final reason = state.myMunicipality['rejectReason'] as String?;
        children.add(
          _StatusCard(
            icon: Icons.info_outline,
            color: NearbyColors.sos,
            soft: NearbyColors.sosSoft,
            title: 'No pudimos aprobar el registro',
            body: reason == null || reason.isEmpty
                ? 'Revisa los datos y vuelve a enviarlo.'
                : 'Motivo: $reason',
            action: OutlinedButton(
              onPressed: () => setState(() => _retry = true),
              child: const Text('Corregir y enviar de nuevo'),
            ),
          ),
        );
      } else {
        children
          ..add(const _Steps())
          ..add(const SizedBox(height: 16))
          ..add(_buildForm(context));
      }
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, pad.bottom + 24),
      children: [
        const Text(
          'Tu Municipalidad en Nearby',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Avisa a tus vecinos en emergencias, aprueba brigadistas y activa Prevención El Niño en tu distrito.',
          style: TextStyle(
            fontSize: 13.5,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildForm(BuildContext context) => Form(
    key: _form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nombre de la Municipalidad',
            hintText: 'Ej. Municipalidad de San Juan de Lurigancho',
            prefixIcon: Icon(Icons.account_balance),
          ),
          validator: (v) => (v ?? '').trim().length < 5
              ? 'Escribe el nombre de la Municipalidad'
              : null,
        ),
        const SizedBox(height: 12),
        Autocomplete<String>(
          optionsBuilder: (value) {
            final q = value.text.trim().toLowerCase();
            return q.isEmpty
                ? state.muniDistricts
                : state.muniDistricts.where((d) => d.toLowerCase().contains(q));
          },
          onSelected: (d) => _district = d,
          fieldViewBuilder: (context, controller, focus, onSubmit) =>
              TextFormField(
                controller: controller,
                focusNode: focus,
                textCapitalization: TextCapitalization.words,
                onChanged: (v) => _district = v,
                decoration: const InputDecoration(
                  labelText: 'Distrito',
                  hintText: 'Ej. San Juan de Lurigancho',
                  prefixIcon: Icon(Icons.location_city),
                ),
                validator: (v) =>
                    (v ?? '').trim().length < 3 ? 'Indica el distrito' : null,
              ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _ruc,
          keyboardType: TextInputType.number,
          maxLength: 11,
          decoration: const InputDecoration(
            labelText: 'RUC',
            hintText: '20XXXXXXXXX',
            counterText: '',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
          validator: (v) => RegExp(r'^20\d{9}$').hasMatch((v ?? '').trim())
              ? null
              : 'El RUC tiene 11 dígitos y empieza con 20',
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _contact,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nombre del responsable',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (v) => (v ?? '').trim().length < 3
              ? 'Escribe el nombre del responsable'
              : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _position,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Cargo (opcional)',
            hintText: 'Ej. Gerente de Gestión del Riesgo de Desastres',
            prefixIcon: Icon(Icons.work_outline),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Correo institucional',
            hintText: 'riesgos@muni.gob.pe',
            prefixIcon: Icon(Icons.alternate_email),
          ),
          validator: (v) =>
              RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim())
              ? null
              : 'Revisa el correo',
        ),
        const SizedBox(height: 8),
        Text(
          'Ingresaste con el celular +51 ${state.userPhone}: será el de la cuenta administradora.',
          style: TextStyle(
            fontSize: 12.5,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _sending ? null : _submit,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
          icon: _sending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: const Text('Enviar registro'),
        ),
      ],
    ),
  );
}

class _Steps extends StatelessWidget {
  const _Steps();

  @override
  Widget build(BuildContext context) {
    const steps = [
      (Icons.smartphone, 'Ingresas con el celular del responsable'),
      (Icons.edit_note, 'Completas los datos de la Municipalidad'),
      (Icons.fact_check, 'Nearby verifica el RUC y la aprueba'),
      (Icons.account_balance, 'Administras tu distrito y tu equipo'),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            for (var i = 0; i < steps.length; i++)
              ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: NearbyColors.infoSoft,
                  child: Icon(steps[i].$1, size: 18, color: NearbyColors.navy2),
                ),
                title: Text('${i + 1}. ${steps[i].$2}'),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final Color color, soft;
  final String title, body;
  final Widget action;
  const _StatusCard({
    required this.icon,
    required this.color,
    required this.soft,
    required this.title,
    required this.body,
    required this.action,
  });

  @override
  Widget build(BuildContext context) => Card(
    color: soft,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(fontSize: 14, height: 1.4)),
          const SizedBox(height: 14),
          action,
        ],
      ),
    ),
  );
}

// ===================================================================== panel

const _modes = [
  (
    'NORMAL',
    'Normal',
    Icons.wb_sunny,
    NearbyColors.navy2,
    NearbyColors.infoSoft,
  ),
  (
    'PREVENTION',
    'Prevención',
    Icons.flood,
    NearbyColors.accentInk,
    NearbyColors.accentSoft,
  ),
  (
    'EMERGENCY',
    'Emergencia',
    Icons.crisis_alert,
    NearbyColors.sos,
    NearbyColors.sosSoft,
  ),
];

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
    final name = zone['name'] as String? ?? 'la zona';
    final label = _modes.firstWhere((m) => m.$1 == mode).$2;
    final reason = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheet) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.viewInsetsOf(sheet).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              mode == 'NORMAL'
                  ? '¿Volver al modo normal en $name?'
                  : '¿Activar $label en $name?',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Avisaremos a todos los vecinos de $name y su app cambiará de modo.',
              style: TextStyle(
                fontSize: 13.5,
                color: Theme.of(sheet).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reason,
              maxLength: 300,
              decoration: const InputDecoration(
                labelText: 'Mensaje para los vecinos (opcional)',
                hintText: 'Ej. Lluvias fuertes previstas esta semana',
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.pop(sheet, true),
              child: Text(
                mode == 'NORMAL' ? 'Volver a normal' : 'Activar y avisar',
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(sheet, false),
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
    final reason = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheet) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.viewInsetsOf(sheet).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '¿Rechazar a ${m['name']}?',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reason,
              maxLength: 300,
              decoration: const InputDecoration(
                labelText: 'Motivo (lo verá quien la registró)',
                hintText: 'Ej. El RUC no corresponde a una Municipalidad',
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.pop(sheet, true),
              child: const Text('Rechazar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(sheet, false),
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
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final pad = NavigationInsets.of(context);
    final pendingMunis = state.municipalities
        .where((m) => m['status'] == 'PENDING')
        .toList();
    final otherMunis = state.municipalities
        .where((m) => m['status'] != 'PENDING')
        .toList();

    Widget header(String text, {VoidCallback? onRefresh}) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          if (onRefresh != null)
            IconButton(
              tooltip: 'Actualizar',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
    );

    Widget empty(String text) => Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: muted),
        ),
      ),
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, pad.bottom + 24),
      children: [
        // Quién soy en el panel
        Card(
          color: NearbyColors.infoSoft,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Icon(
              state.isPlatformAdmin
                  ? Icons.admin_panel_settings
                  : Icons.account_balance,
              color: NearbyColors.navy2,
              size: 32,
            ),
            title: Text(
              state.isPlatformAdmin
                  ? 'Administración Nearby'
                  : state.isMunicipality
                  ? (state.municipality?['name'] as String? ?? 'Municipalidad')
                  : 'Delegado de ${state.zoneName}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              state.isPlatformAdmin
                  ? 'Apruebas Municipalidades y ves todas las zonas'
                  : state.isMunicipality
                  ? 'Distrito: ${state.municipality?['district'] ?? '—'}'
                  : 'Administras tu zona',
            ),
            trailing: IconButton(
              tooltip: 'Actualizar todo',
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
            ),
          ),
        ),

        // Plataforma: registros de Municipalidades
        if (state.isPlatformAdmin) ...[
          header('Municipalidades por aprobar · ${pendingMunis.length}'),
          if (pendingMunis.isEmpty) empty('No hay registros pendientes.'),
          for (final m in pendingMunis)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${m['name']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Distrito: ${m['district']} · RUC ${m['ruc']}\n'
                        '${m['contactName']}'
                        '${m['contactPosition'] != null ? ' · ${m['contactPosition']}' : ''}\n'
                        '${m['email']} · +51 ${m['requestedByPhone'] ?? ''}',
                        style: TextStyle(
                          fontSize: 13,
                          color: muted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _reject(m),
                              child: const Text('Rechazar'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => state.decideMunicipality(
                                m['id'] as String,
                                approve: true,
                              ),
                              child: const Text('Aprobar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (otherMunis.isNotEmpty)
            Card(
              child: ExpansionTile(
                title: Text('Respondidas · ${otherMunis.length}'),
                children: [
                  for (final m in otherMunis)
                    ListTile(
                      dense: true,
                      leading: Icon(
                        m['status'] == 'APPROVED'
                            ? Icons.verified
                            : Icons.block,
                        color: m['status'] == 'APPROVED'
                            ? NearbyColors.accentInk
                            : NearbyColors.sos,
                      ),
                      title: Text('${m['name']}'),
                      subtitle: Text(
                        '${m['district']} · '
                        '${m['status'] == 'APPROVED' ? 'Aprobada' : 'Rechazada'}',
                      ),
                    ),
                ],
              ),
            ),
        ],

        // Zonas de mi jurisdicción
        header(
          state.isPlatformAdmin ? 'Todas las zonas' : 'Zonas que administras',
          onRefresh: state.loadManagedZones,
        ),
        if (state.isPlatformAdmin || state.isMunicipality)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton.icon(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => _CreateZoneSheet(state: state),
              ),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Crear zona'),
            ),
          ),
        if (state.managedZones.isEmpty)
          empty(
            state.isMunicipality
                ? 'Todavía no hay zonas de ${state.municipality?['district'] ?? 'tu distrito'} en Nearby.'
                : 'No hay zonas para mostrar.',
          ),
        for (final z in state.managedZones)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${z['name']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '${z['district']}'
                      '${(z['modeReason'] as String?)?.isNotEmpty == true ? ' · ${z['modeReason']}' : ''}',
                      style: TextStyle(fontSize: 12.5, color: muted),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final (id, label, icon, color, soft) in _modes)
                          ChoiceChip(
                            avatar: Icon(
                              icon,
                              size: 18,
                              color: z['mode'] == id ? color : muted,
                            ),
                            label: Text(label),
                            selected: z['mode'] == id,
                            selectedColor: soft,
                            showCheckmark: false,
                            side: BorderSide(
                              color: z['mode'] == id
                                  ? color
                                  : NearbyColors.line,
                            ),
                            onSelected: (_) => _confirmMode(z, id),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Brigadistas
        header(
          'Quieren ser brigadistas · ${state.adminRequests.length}',
          onRefresh: state.loadAdminRequests,
        ),
        if (state.adminRequests.isEmpty)
          empty('No hay solicitudes pendientes.'),
        for (final r in state.adminRequests)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${r['name'] ?? 'Vecino'} · ${r['phone'] ?? ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if ((r['skills'] as String?)?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        r['skills'] as String,
                        style: TextStyle(fontSize: 13, color: muted),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => state.decideBrigadeRequest(
                              r['id'] as String,
                              approve: false,
                            ),
                            child: const Text('Rechazar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => state.decideBrigadeRequest(
                              r['id'] as String,
                              approve: true,
                            ),
                            child: const Text('Aprobar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Equipo de la Municipalidad
        if (state.isMunicipality) ...[
          header(
            'Mi equipo · ${state.staff.length}',
            onRefresh: state.loadStaff,
          ),
          Card(
            child: Column(
              children: [
                for (final s in state.staff)
                  ListTile(
                    leading: const Icon(Icons.badge_outlined),
                    title: Text('${s['name']}'),
                    subtitle: Text('+51 ${s['phone']}'),
                    trailing: s['me'] == true
                        ? const Text('Tú')
                        : IconButton(
                            tooltip: 'Quitar del equipo',
                            onPressed: () =>
                                state.removeStaff(s['id'] as String),
                            icon: const Icon(Icons.person_remove_outlined),
                          ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _staffPhone,
                          keyboardType: TextInputType.phone,
                          maxLength: 9,
                          decoration: const InputDecoration(
                            labelText: 'Celular del funcionario',
                            counterText: '',
                            prefixText: '+51 ',
                          ),
                          onSubmitted: (_) => _addStaff(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _addStaff,
                        child: const Text('Agregar'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Debe haber ingresado a Nearby al menos una vez con ese celular.',
              style: TextStyle(fontSize: 12.5, color: muted),
            ),
          ),
        ],

        // Roles de vecinos
        if (state.isPlatformAdmin || state.isMunicipality) ...[
          header('Cambiar el rol de un vecino'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  maxLength: 9,
                  decoration: const InputDecoration(
                    labelText: 'Celular',
                    counterText: '',
                    prefixText: '+51 ',
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _searching ? null : _search,
                child: const Text('Buscar'),
              ),
            ],
          ),
          if (_found != null) ...[
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${_found!['name']} · ${_found!['phone']}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Hoy: ${_roleLabels[_found!['role']] ?? _found!['role']}'
                      '${_found!['zoneName'] != null ? ' · ${_found!['zoneName']}' : ''}',
                      style: TextStyle(fontSize: 13, color: muted),
                    ),
                    const SizedBox(height: 10),
                    if (const {
                      'ADMIN',
                      'MUNICIPALITY',
                    }.contains(_found!['role']))
                      Text(
                        'El equipo de una Municipalidad se maneja en «Mi equipo».',
                        style: TextStyle(fontSize: 13, color: muted),
                      )
                    else
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'NEIGHBOR',
                            label: Text('Vecino'),
                          ),
                          ButtonSegment(
                            value: 'BRIGADIST',
                            label: Text('Brigada'),
                          ),
                          ButtonSegment(
                            value: 'DELEGATE',
                            label: Text('Delegado'),
                          ),
                        ],
                        selected: {_found!['role'] as String},
                        onSelectionChanged: (v) async {
                          final u = await state.changeUserRole(
                            _found!['id'] as String,
                            v.first,
                          );
                          if (u != null && mounted) setState(() => _found = u);
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

/// Nueva zona: nombre, centro en el mapa y radio. La Municipalidad la crea en su distrito.
class _CreateZoneSheet extends StatefulWidget {
  final AppState state;
  const _CreateZoneSheet({required this.state});

  @override
  State<_CreateZoneSheet> createState() => _CreateZoneSheetState();
}

class _CreateZoneSheetState extends State<_CreateZoneSheet> {
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
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      16,
      16,
      16,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Crear zona',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            widget.state.isMunicipality
                ? 'Se crea en ${widget.state.municipality?['district'] ?? 'tu distrito'}. '
                      'Los vecinos que vivan dentro del círculo quedan en esta zona.'
                : 'Los vecinos que vivan dentro del círculo quedan en esta zona.',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre de la zona',
              hintText: 'Ej. Urb. Mangomarca',
            ),
          ),
          if (widget.state.isPlatformAdmin) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _district,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Distrito'),
            ),
          ],
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
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
                    userAgentPackageName: 'com.example.utp_comercio_frontend',
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
          const SizedBox(height: 6),
          Text(
            'Mueve el mapa para elegir el centro.',
            style: TextStyle(
              fontSize: 12.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text('Radio: ${(_radius / 1000).toStringAsFixed(1)} km'),
          Slider(
            value: _radius,
            min: 300,
            max: 5000,
            divisions: 47,
            onChanged: (v) => setState(() => _radius = v),
          ),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: Text(_saving ? 'Creando…' : 'Crear zona'),
          ),
        ],
      ),
    ),
  );
}
