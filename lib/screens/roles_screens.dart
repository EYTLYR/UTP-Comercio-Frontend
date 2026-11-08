import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../state/app_state.dart';
import '../theme/nearby_theme.dart';
import 'profile/widgets/profile_ui.dart';

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
    final theme = uiThemeOf(state);
    final ui = NearbyCommunityStyle(theme);
    final initials = Center(
      child: Text(
        state.initials,
        style: TextStyle(
          color: ui.ink,
          fontSize: size * 0.34,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    final circle = Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(shape: BoxShape.circle, color: ui.blueSoft),
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
                  color: ui.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.surface, width: 2),
                ),
                child: Icon(
                  Icons.photo_camera,
                  size: size * 0.22,
                  color: ui.onAccent,
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
  final ui = NearbyCommunityStyle(uiThemeOf(state));

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
      padding: uiSheetPadding(sheet),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiSheetHeader(
            ui: ui,
            title: 'Tu foto de perfil',
            subtitle: 'Ayuda a que tus vecinos te reconozcan cuando ofreces o pides ayuda.',
          ),
          UiRowsCard(
            ui: ui,
            rows: [
              UiRow(
                ui: ui,
                icon: Icons.photo_camera_outlined,
                title: 'Tomar una foto',
                onTap: () => pick(sheet, ImageSource.camera),
              ),
              UiRow(
                ui: ui,
                icon: Icons.photo_library_outlined,
                title: 'Elegir de la galería',
                onTap: () => pick(sheet, ImageSource.gallery),
              ),
              if (state.photoUrl != null)
                UiRow(
                  ui: ui,
                  icon: Icons.delete_outline,
                  iconBackground: ui.ivory,
                  title: 'Quitar foto',
                  onTap: () {
                    Navigator.pop(sheet);
                    state.removeProfilePhoto();
                  },
                ),
            ],
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
    final ui = NearbyCommunityStyle(uiThemeOf(state));
    final (
      IconData icon,
      String title,
      String subtitle,
      VoidCallback? onTap,
    ) = switch (state.role) {
      'ADMIN' => (
        Icons.admin_panel_settings_outlined,
        'Administración Nearby',
        'Aprueba Municipalidades y revisa todas las zonas',
        () => state.go('municipalidad'),
      ),
      'MUNICIPALITY' || 'DELEGATE' => (
        Icons.account_balance_outlined,
        'Panel de Municipalidad',
        state.municipality?['name'] as String? ??
            'Modo de tu zona y solicitudes de brigadistas',
        () => state.go('municipalidad'),
      ),
      'BRIGADIST' => (
        Icons.verified_user_outlined,
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
          Icons.shield_outlined,
          'Quiero ser brigadista',
          'Tu solicitud anterior no fue aprobada. Puedes volver a pedirlo.',
          () => _askBrigade(context, state),
        ),
        _ => (
          Icons.shield_outlined,
          'Quiero ser brigadista',
          'Ayuda en emergencias de tu barrio. La Municipalidad te aprueba.',
          () => _askBrigade(context, state),
        ),
      },
    };
    return UiRowsCard(
      ui: ui,
      rows: [
        UiRow(
          ui: ui,
          icon: icon,
          title: title,
          subtitle: subtitle,
          onTap: onTap,
        ),
      ],
    );
  }

  static void _askBrigade(BuildContext context, AppState state) {
    final ui = NearbyCommunityStyle(uiThemeOf(state));
    final skills = TextEditingController();
    showModalBottomSheet(
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
              title: 'Quiero ser brigadista',
              subtitle:
                  'Los brigadistas ven el tablero del barrio y acuden a las alertas cercanas. '
                  'La Municipalidad revisa tu solicitud.',
            ),
            UiLabeled(
              ui: ui,
              label: '¿Qué sabes hacer? (opcional)',
              child: TextField(
                controller: skills,
                maxLength: 300,
                maxLines: 3,
                minLines: 2,
                style: TextStyle(color: ui.ink, fontSize: 14),
                decoration: uiField(
                  ui,
                  hint: 'Ej. Primeros auxilios, tengo camioneta',
                ),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ui.action(),
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
  Widget build(BuildContext context) {
    final theme = uiThemeOf(state);
    final ui = NearbyCommunityStyle(theme);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Material(
        color: ui.ivory,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: ui.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => state.go('prevencion'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Row(
              children: [
                UiIconBox(
                  ui: ui,
                  icon: Icons.flood,
                  size: 34,
                  color: theme.accentInk,
                  background: theme.accentSoft,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Prevención El Niño · reporta riesgos en tu barrio',
                    style: TextStyle(
                      color: ui.ink,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: ui.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Ver',
                    style: TextStyle(
                      color: ui.onAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
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
  NearbyCommunityStyle get ui => NearbyCommunityStyle(widget.theme);

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
      state.toast(
        'No pudimos abrir la cámara. Revisa los permisos.',
        icon: 'error',
      );
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
    final ui = this.ui;
    final theme = widget.theme;

    // Formulario para reportar un riesgo.
    final form = <Widget>[
      UiSectionTitle(
        ui: ui,
        top: 0,
        title: '¿Ves algo que pueda empeorar con la lluvia?',
      ),
      UiCard(
        ui: ui,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UiLabeled(
              ui: ui,
              label: 'Tipo de riesgo',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (id, label, icon) in _riskCategories)
                    UiChoice(
                      ui: ui,
                      icon: icon,
                      label: label,
                      selected: _category == id,
                      onTap: () => setState(() => _category = id),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            UiLabeled(
              ui: ui,
              label: 'Cuéntalo en una frase (opcional)',
              child: TextField(
                controller: _text,
                maxLength: 1000,
                minLines: 2,
                maxLines: 4,
                style: TextStyle(color: ui.ink, fontSize: 14),
                decoration: uiField(
                  ui,
                  hint: 'Ej. La acequia de mi calle está al ras',
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickPhoto,
                    style: ui.action(filled: false),
                    icon: Icon(
                      _photo == null
                          ? Icons.add_a_photo_outlined
                          : Icons.check_circle,
                      size: 18,
                    ),
                    label: Text(_photo == null ? 'Agregar foto' : 'Foto lista'),
                  ),
                ),
                if (_photo != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Quitar foto',
                    onPressed: () => setState(() {
                      _photo = null;
                      _photoName = null;
                    }),
                    icon: Icon(Icons.close, color: ui.ink),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _sending ? null : _send,
              style: ui.action(),
              icon: const Icon(Icons.campaign_outlined, size: 18),
              label: Text(_sending ? 'Enviando…' : 'Reportar riesgo'),
            ),
          ],
        ),
      ),
    ];

    // Reportes cercanos de las últimas horas.
    List<Widget> reports({required bool first}) => [
      UiSectionTitle(
        ui: ui,
        top: first ? 0 : 28,
        title: 'Riesgos reportados cerca',
      ),
      if (state.riskReports.isEmpty)
        UiEmpty(ui: ui, text: 'Aún no hay reportes en las últimas 48 horas.')
      else
        UiRowsCard(
          ui: ui,
          rows: [
            for (final r in state.riskReports.take(20))
              UiRow(
                ui: ui,
                icon: _riskCategories
                    .firstWhere(
                      (c) => c.$1 == r['category'],
                      orElse: () => _riskCategories.first,
                    )
                    .$3,
                iconColor: theme.accentInk,
                iconBackground: theme.accentSoft,
                title: (r['label'] as String?) ?? 'Riesgo',
                subtitle: [
                  if ((r['text'] as String?)?.isNotEmpty == true) r['text'],
                  'hace ${r['minutesAgo'] ?? 0} min',
                ].join(' · '),
              ),
          ],
        ),
      const SizedBox(height: 16),
      OutlinedButton.icon(
        onPressed: state.dismissZoneMode,
        style: ui.action(filled: false),
        icon: const Icon(Icons.wb_sunny_outlined, size: 18),
        label: const Text('Volver al modo normal en mi app'),
      ),
    ];

    return UiScrollPage(
      maxWidth: 1100,
      builder: (context, width) {
        final header = UiPageHeader(
          ui: ui,
          eyebrow: 'Modo prevención',
          title: 'Prevención El Niño',
          subtitle: 'Activado por la Municipalidad en ${state.zoneName}.',
        );
        if (width >= 900) {
          return [
            header,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: form,
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: reports(first: true),
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
                children: [header, ...form, ...reports(first: false)],
              ),
            ),
          ),
        ];
      },
    );
  }
}
