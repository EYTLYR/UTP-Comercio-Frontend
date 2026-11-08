import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../state/app_state.dart';
import '../theme/nearby_theme.dart';
import '../widgets/navigation_chrome.dart';

// =============================================================== foto de perfil

/// Avatar del vecino: su foto si la subió; si no, sus iniciales.
class ProfilePhotoAvatar extends StatelessWidget {
  final AppState state;
  final double size;

  /// Muestra el botón de cámara para cambiar la foto.
  final bool editable;

  const ProfilePhotoAvatar({
    super.key,
    required this.state,
    this.size = 44,
    this.editable = false,
  });

  @override
  Widget build(BuildContext context) {
    final initials = Center(
      child: Text(
        state.initials,
        style: TextStyle(
          color: NearbyColors.onPrimary,
          fontSize: size * 0.34,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    final circle = Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: NearbyColors.brandTurquoise,
      ),
      child: state.photoUrl == null
          ? initials
          : Image.network(
              state.photoUrl!,
              fit: BoxFit.cover,
              width: size,
              height: size,
              errorBuilder: (_, _, _) => initials,
            ),
    );
    if (!editable) {
      return Semantics(label: 'Foto de ${state.userName}', child: circle);
    }
    return Semantics(
      button: true,
      label: 'Cambiar tu foto de perfil',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => showProfilePhotoSheet(context, state),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            circle,
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: size * 0.42,
                height: size * 0.42,
                decoration: BoxDecoration(
                  color: NearbyColors.brandNavy,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  Icons.photo_camera,
                  size: size * 0.22,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hoja para elegir la foto: cámara, galería o quitarla.
void showProfilePhotoSheet(BuildContext context, AppState state) {
  Future<void> pick(BuildContext sheet, ImageSource source) async {
    Navigator.pop(sheet);
    try {
      // Se reduce y comprime en el teléfono: ~800 px y calidad 80 (pocos KB por la red).
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.front,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      await state.uploadProfilePhoto(bytes, file.name);
    } catch (_) {
      state.toast(
        'No pudimos abrir la cámara o la galería. Revisa los permisos.',
        icon: 'error',
      );
    }
  }

  showModalBottomSheet(
    context: context,
    useSafeArea: true,
    builder: (sheet) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Tu foto de perfil',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Ayuda a que tus vecinos te reconozcan cuando ofreces o pides ayuda.',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(sheet).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Tomar una foto'),
            onTap: () => pick(sheet, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Elegir de la galería'),
            onTap: () => pick(sheet, ImageSource.gallery),
          ),
          if (state.photoUrl != null)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: NearbyColors.sos),
              title: const Text(
                'Quitar foto',
                style: TextStyle(color: NearbyColors.sos),
              ),
              onTap: () {
                Navigator.pop(sheet);
                state.removeProfilePhoto();
              },
            ),
        ],
      ),
    ),
  );
}

// =============================================================== rol en el barrio

/// Tarjeta de Perfil: pedir ser brigadista, ver el estado o entrar al panel de Municipalidad.
class NeighborhoodRoleCard extends StatelessWidget {
  final AppState state;
  const NeighborhoodRoleCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final (IconData icon, String title, String subtitle, VoidCallback? onTap) =
        switch (state.role) {
          'ADMIN' || 'DELEGATE' => (
            Icons.account_balance,
            'Panel de Municipalidad',
            'Modo de la zona y solicitudes de brigadistas',
            () => state.go('municipalidad'),
          ),
          'BRIGADIST' => (
            Icons.verified_user,
            'Eres brigadista',
            'Ves el tablero del barrio y las alertas de rescate',
            () => state.go('tablero'),
          ),
          _ => switch (state.brigadeRequest) {
            'PENDING' => (
              Icons.hourglass_top,
              'Solicitud enviada',
              'La Municipalidad la está revisando',
              null,
            ),
            'REJECTED' => (
              Icons.shield,
              'Quiero ser brigadista',
              'Tu solicitud anterior no fue aprobada. Puedes volver a pedirlo.',
              () => _askBrigade(context, state),
            ),
            _ => (
              Icons.shield,
              'Quiero ser brigadista',
              'Ayuda en emergencias de tu barrio. La Municipalidad te aprueba.',
              () => _askBrigade(context, state),
            ),
          },
        };
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: NearbyColors.infoSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: NearbyColors.navy2),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12.5, color: muted)),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  static void _askBrigade(BuildContext context, AppState state) {
    final skills = TextEditingController();
    showModalBottomSheet(
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
            const Text(
              'Quiero ser brigadista',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Los brigadistas ven el tablero del barrio y acuden a las alertas cercanas. '
              'La Municipalidad revisa tu solicitud.',
              style: TextStyle(
                fontSize: 13.5,
                color: Theme.of(sheet).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: skills,
              maxLength: 300,
              maxLines: 3,
              minLines: 2,
              decoration: const InputDecoration(
                labelText: '¿Qué sabes hacer? (opcional)',
                hintText: 'Ej. Primeros auxilios, tengo camioneta',
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final ok = await state.requestBrigade(skills.text);
                if (ok && sheet.mounted) Navigator.pop(sheet);
              },
              child: const Text('Enviar solicitud'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================== Municipalidad

const _modes = [
  (
    'NORMAL',
    'Normal',
    'Día a día del barrio',
    Icons.wb_sunny,
    NearbyColors.navy2,
    NearbyColors.infoSoft,
  ),
  (
    'PREVENTION',
    'Prevención El Niño',
    'Los vecinos reportan riesgos con foto',
    Icons.flood,
    NearbyColors.accentInk,
    NearbyColors.accentSoft,
  ),
  (
    'EMERGENCY',
    'Emergencia',
    'Sismo, huaico o incendio',
    Icons.crisis_alert,
    NearbyColors.sos,
    NearbyColors.sosSoft,
  ),
];

/// Panel de Municipalidad (ADMIN o DELEGATE): modo de la zona, solicitudes de brigadista y roles.
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
  Map<String, dynamic>? _found;
  bool _searching = false;

  AppState get state => widget.state;

  @override
  void initState() {
    super.initState();
    state.loadAdminRequests();
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _confirmMode(String mode, String label) async {
    if (mode == state.zoneMode) return;
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
              mode == 'NORMAL' ? '¿Volver al modo normal?' : '¿Activar $label?',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Avisaremos a todos los vecinos de ${state.zoneName} y su app cambiará de modo.',
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
              child: Text(mode == 'NORMAL' ? 'Volver a normal' : 'Activar y avisar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(sheet, false),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) await state.setZoneMode(mode, reason.text);
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

  static const _roleLabels = {
    'NEIGHBOR': 'Vecino',
    'BRIGADIST': 'Brigadista',
    'DELEGATE': 'Delegado',
    'ADMIN': 'Municipalidad',
  };

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final pad = NavigationInsets.of(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, pad.bottom + 24),
      children: [
        Text(
          'Modo de ${state.zoneName}',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'El modo cambia la app de todos los vecinos de la zona.',
          style: TextStyle(fontSize: 13, color: muted),
        ),
        const SizedBox(height: 12),
        for (final (id, label, desc, icon, color, soft) in _modes)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(NearbyRadius.card),
                side: BorderSide(
                  color: state.zoneMode == id ? color : NearbyColors.line,
                  width: state.zoneMode == id ? 2 : 1,
                ),
              ),
              color: state.zoneMode == id ? soft : null,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: soft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color),
                ),
                title: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(desc),
                trailing: Icon(
                  state.zoneMode == id
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: state.zoneMode == id ? color : NearbyColors.lineStrong,
                ),
                onTap: () => _confirmMode(id, label),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                'Quieren ser brigadistas · ${state.adminRequests.length}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Actualizar',
              onPressed: state.loadAdminRequests,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (state.adminRequests.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                'No hay solicitudes pendientes.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted),
              ),
            ),
          ),
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
        if (state.role == 'ADMIN') ...[
          const SizedBox(height: 12),
          const Text(
            'Cambiar el rol de un vecino',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
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
                    if (_found!['role'] == 'ADMIN')
                      Text(
                        'El rol de Municipalidad se configura en el servidor.',
                        style: TextStyle(fontSize: 13, color: muted),
                      )
                    else
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'NEIGHBOR', label: Text('Vecino')),
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

// =============================================================== Prevención El Niño

const _riskCategories = [
  ('ACEQUIA_OVERFLOW', 'Acequia que sube', Icons.water),
  ('STREET_FLOODING', 'Calle con agua', Icons.flood),
  ('SEEPAGE', 'Filtración', Icons.roofing),
  ('RAVINE_ACTIVITY', 'Quebrada con lodo', Icons.landslide),
  ('DRAIN_OVERFLOW', 'Desagüe rebalsando', Icons.plumbing),
  ('CRACK', 'Grieta en muro o cerro', Icons.broken_image),
];

/// Banner del modo Prevención: se ve arriba en las pantallas principales.
class NearbyPreventionBanner extends StatelessWidget {
  final AppState state;
  const NearbyPreventionBanner({super.key, required this.state});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    child: Material(
      color: NearbyColors.accentSoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFF6D59A)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => state.go('prevencion'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              const Icon(Icons.flood, color: NearbyColors.accentInk),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Prevención El Niño · reporta riesgos en tu barrio',
                  style: TextStyle(
                    color: NearbyColors.accentInk,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: NearbyColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Ver',
                  style: TextStyle(
                    color: NearbyColors.brandNavy,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Pantalla del modo Prevención El Niño: reportar un riesgo con foto y ver los cercanos.
class PrevencionScreen extends StatefulWidget {
  final AppState state;
  final NearbyThemeData theme;
  const PrevencionScreen({super.key, required this.state, required this.theme});

  @override
  State<PrevencionScreen> createState() => _PrevencionScreenState();
}

class _PrevencionScreenState extends State<PrevencionScreen> {
  String? _category;
  final _text = TextEditingController();
  List<int>? _photo;
  String? _photoName;
  bool _sending = false;

  AppState get state => widget.state;

  @override
  void initState() {
    super.initState();
    state.loadRiskReports();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _photo = bytes;
        _photoName = file.name;
      });
    } catch (_) {
      state.toast('No pudimos abrir la cámara. Revisa los permisos.', icon: 'error');
    }
  }

  Future<void> _send() async {
    if (_category == null) {
      state.toast('Elige qué tipo de riesgo ves', icon: 'warning');
      return;
    }
    setState(() => _sending = true);
    final ok = await state.reportRisk(
      category: _category!,
      text: _text.text,
      photo: _photo,
      photoName: _photoName,
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (ok) {
        _category = null;
        _photo = null;
        _photoName = null;
        _text.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final pad = NavigationInsets.of(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, pad.bottom + 24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF4B04A), Color(0xFFE08F12)],
            ),
            borderRadius: BorderRadius.circular(NearbyRadius.card),
          ),
          child: Row(
            children: [
              const Icon(Icons.flood, size: 40, color: NearbyColors.brandNavy),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Prevención El Niño',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: NearbyColors.brandNavy,
                      ),
                    ),
                    Text(
                      'Activado por la Municipalidad en ${state.zoneName}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: NearbyColors.brandNavy,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '¿Ves algo que pueda empeorar con la lluvia?',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (id, label, icon) in _riskCategories)
              ChoiceChip(
                avatar: Icon(icon, size: 18),
                label: Text(label),
                selected: _category == id,
                onSelected: (_) => setState(() => _category = id),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _text,
          maxLength: 1000,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Cuéntalo en una frase (opcional)',
            hintText: 'Ej. La acequia de Jr. Las Flores está al ras',
          ),
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickPhoto,
                icon: Icon(_photo == null ? Icons.add_a_photo : Icons.check_circle),
                label: Text(_photo == null ? 'Agregar foto' : 'Foto lista'),
              ),
            ),
            if (_photo != null)
              IconButton(
                tooltip: 'Quitar foto',
                onPressed: () => setState(() {
                  _photo = null;
                  _photoName = null;
                }),
                icon: const Icon(Icons.close),
              ),
          ],
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _sending ? null : _send,
          icon: const Icon(Icons.campaign),
          label: Text(_sending ? 'Enviando…' : 'Reportar riesgo'),
        ),
        const SizedBox(height: 22),
        const Text(
          'Riesgos reportados cerca',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (state.riskReports.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                'Aún no hay reportes en las últimas 48 horas.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted),
              ),
            ),
          ),
        for (final r in state.riskReports.take(20))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: ListTile(
                leading: Icon(
                  _riskCategories
                      .firstWhere(
                        (c) => c.$1 == r['category'],
                        orElse: () => _riskCategories.first,
                      )
                      .$3,
                  color: NearbyColors.accentInk,
                ),
                title: Text(
                  (r['label'] as String?) ?? 'Riesgo',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  [
                    if ((r['text'] as String?)?.isNotEmpty == true) r['text'],
                    'hace ${r['minutesAgo'] ?? 0} min',
                  ].join(' · '),
                ),
              ),
            ),
          ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: state.dismissZoneMode,
          child: const Text('Volver al modo normal en mi app'),
        ),
      ],
    );
  }
}
