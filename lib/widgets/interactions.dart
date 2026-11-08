import 'package:flutter/material.dart';

import '../theme/nearby_theme.dart';

/// Panel de filtros que entra desde la derecha (slide-over), como los paneles laterales de la app.
/// En el celular ocupa casi todo el ancho; en escritorio, 400 px. Devuelve true si se aplicó.
Future<bool?> showNearbyFilterPanel({
  required BuildContext context,
  required NearbyThemeData theme,
  required String title,
  String? subtitle,
  required Widget Function(BuildContext context, StateSetter setPanel) builder,
  VoidCallback? onClear,
  String applyLabel = 'Ver resultados',
}) {
  final ui = NearbyCommunityStyle(theme);
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar filtros',
    barrierColor: const Color(0x66172338),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, _, _) {
      final width = MediaQuery.sizeOf(context).width;
      final panelWidth = width < 480 ? width * 0.88 : 400.0;
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: theme.surface,
          elevation: 12,
          child: SizedBox(
            width: panelWidth,
            height: double.infinity,
            child: SafeArea(
              child: StatefulBuilder(
                builder: (context, setPanel) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 12, 8),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: ui.blueSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.tune, color: ui.ink, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: ui.ink,
                                  ),
                                ),
                                if (subtitle != null)
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: ui.muted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Cerrar',
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close, color: ui.ink),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: ui.line),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                        children: [builder(context, setPanel)],
                      ),
                    ),
                    Divider(height: 1, color: ui.line),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                      child: Row(
                        children: [
                          if (onClear != null) ...[
                            Expanded(
                              child: OutlinedButton(
                                style: ui.action(filled: false),
                                onPressed: () {
                                  onClear();
                                  Navigator.pop(context, true);
                                },
                                child: const Text('Limpiar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ui.action(),
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(applyLabel),
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
      );
    },
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}

/// Opción de un filtro dentro del panel: ícono en cuadrito, texto y marca de elegido.
class NearbyFilterOption extends StatelessWidget {
  final NearbyThemeData theme;
  final IconData? icon;
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  const NearbyFilterOption({
    super.key,
    required this.theme,
    this.icon,
    required this.label,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ui = NearbyCommunityStyle(theme);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: selected ? ui.blueSoft : theme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? ui.ink : ui.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: selected ? ui.accent : ui.blueSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, size: 18, color: ui.ink),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: ui.ink,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: TextStyle(fontSize: 12, color: ui.muted),
                          ),
                      ],
                    ),
                  ),
                  AnimatedScale(
                    duration: const Duration(milliseconds: 160),
                    scale: selected ? 1 : 0,
                    child: Icon(Icons.check_circle, color: ui.ink, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Título de un grupo dentro del panel de filtros.
class NearbyFilterGroup extends StatelessWidget {
  final NearbyThemeData theme;
  final String title;
  const NearbyFilterGroup({super.key, required this.theme, required this.title});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 10),
    child: Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: NearbyCommunityStyle(theme).muted,
      ),
    ),
  );
}

/// Botón cuadrado de filtros con contador de filtros activos (abre el panel lateral).
class NearbyFilterButton extends StatelessWidget {
  final NearbyThemeData theme;
  final int active;
  final VoidCallback onPressed;
  const NearbyFilterButton({
    super.key,
    required this.theme,
    required this.active,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final ui = NearbyCommunityStyle(theme);
    return Tooltip(
      message: active == 0 ? 'Filtros' : 'Filtros ($active activos)',
      child: Badge(
        isLabelVisible: active > 0,
        label: Text('$active'),
        backgroundColor: ui.ink,
        child: NearbyHover(
          child: Material(
            color: active > 0 ? ui.accent : ui.ivory,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onPressed,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.tune, size: 20, color: ui.ink),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Microinteracción: al pasar el mouse la tarjeta sube 2 px y su sombra crece; al presionar se
/// achica un poco. En el celular solo queda el efecto de presionar.
class NearbyHover extends StatefulWidget {
  final Widget child;
  final double lift;
  const NearbyHover({super.key, required this.child, this.lift = 2});

  @override
  State<NearbyHover> createState() => _NearbyHoverState();
}

class _NearbyHoverState extends State<NearbyHover> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final dy = reduce || !_hover ? 0.0 : -widget.lift;
    final scale = reduce || !_down ? 1.0 : 0.985;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _down = false;
      }),
      child: Listener(
        onPointerDown: (_) => setState(() => _down = true),
        onPointerUp: (_) => setState(() => _down = false),
        onPointerCancel: (_) => setState(() => _down = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, dy, 0)
            ..scaleByDouble(scale, scale, 1, 1),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _hover && !reduce
                ? const [
                    BoxShadow(
                      color: Color(0x1A263B65),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ]
                : const [],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Número que cuenta hasta su valor al aparecer o cambiar (estadísticas y contadores).
class NearbyCountUp extends StatelessWidget {
  final int value;
  final TextStyle? style;
  const NearbyCountUp({super.key, required this.value, this.style});

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce) return Text('$value', style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('${v.round()}', style: style),
    );
  }
}
