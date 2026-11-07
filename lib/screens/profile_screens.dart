import 'package:flutter/material.dart';

import '../widgets/navigation_chrome.dart';

import '../models/models.dart';
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
  late String _sangre;
  late TextEditingController _alergiasCtrl;
  late TextEditingController _condicionesCtrl;
  late Set<String> _vive;

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
    _sangre = widget.state.sangre;
    _alergiasCtrl = TextEditingController(text: widget.state.alergias);
    _condicionesCtrl = TextEditingController(text: widget.state.condiciones);
    _vive = Set.from(widget.state.vive);
  }

  @override
  void dispose() {
    _alergiasCtrl.dispose();
    _condicionesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.state.sangre = _sangre;
    widget.state.alergias = _alergiasCtrl.text.trim();
    widget.state.condiciones = _condicionesCtrl.text.trim();
    widget.state.vive = _vive.toList();
    widget.state.saveMedicalCard();
    widget.state.toast('Ficha médica actualizada', icon: 'check_circle');
    widget.state.back();
  }

  @override
  Widget build(BuildContext context) {
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
    final viveMap = {
      'mayor': 'adulto mayor',
      'ninos': 'niños',
      'disc': 'persona con discapacidad',
      'mascotas': 'mascotas',
    };
    final viveText = state.vive.isNotEmpty
        ? 'Vive con: ${state.vive.map((v) => viveMap[v] ?? v).join(', ')}'
        : 'Vive sola o solo';

    final userLearnedItems = state.connected
        ? state.myLearnings
              .where((e) => !(state.aiRemoved['${e.id}${e.tag}'] ?? false))
              .toList()
        : state
              .buildInventory()
              .where((e) => e.who == state.userName)
              .toList();

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
                            'Zona 3 · Urb. Las Flores, SJL · +51 ${state.userPhone}',
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
                                  'Vecina verificada',
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

          // Ficha de emergencia
          _SectionHeader(
            title: 'Ficha de emergencia',
            actionLabel: 'Editar',
            actionIcon: Icons.edit,
            onTap: () => state.go('ficha'),
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
                  ListTile(
                    leading: const Icon(
                      Icons.bloodtype,
                      color: NearbyColors.sos,
                    ),
                    title: Text(
                      'Tipo de sangre ${state.sangre}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'Visible solo para brigadistas',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.medication,
                      color: NearbyColors.primary,
                    ),
                    title: Text(
                      state.alergias.isNotEmpty
                          ? 'Alergia: ${state.alergias}'
                          : 'Sin alergias registradas',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      state.condiciones.isNotEmpty
                          ? state.condiciones
                          : 'Sin condiciones médicas registradas',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.home, color: NearbyColors.accent),
                    title: Text(
                      viveText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'Prioridad en evacuación',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
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
                  const ListTile(
                    leading: Icon(
                      Icons.download_done,
                      color: NearbyColors.accent,
                    ),
                    title: Text(
                      'Zona descargada · 4.2 MB',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'Mapa, directorio y contactos disponibles offline',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
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
