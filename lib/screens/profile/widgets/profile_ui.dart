import 'package:flutter/material.dart';

import '../../../state/app_state.dart';
import '../../../theme/nearby_theme.dart';
import '../../../widgets/navigation_chrome.dart';

// Piezas visuales compartidas por Perfil, Roles y Municipalidad (diseño blanco de Nearby).

/// Tema actual a partir del estado, para widgets que no reciben [NearbyThemeData].
NearbyThemeData uiThemeOf(AppState state) => NearbyThemeData.build(
  dark: state.dark,
  lg: state.lg,
  hc: state.hc,
  emergency: state.emergency,
);

/// Margen lateral de página: 24 (16 en pantallas muy angostas).
double uiGutter(double width) => width < 360 ? 16 : 24;

/// Columnas para listas de tarjetas: 1 (< 700), 2 (≥ 700) o 3 (≥ 1050).
int uiColumns(double width) => width >= 1050 ? 3 : (width >= 700 ? 2 : 1);

/// Página desplazable: márgenes del diseño y contenido centrado con ancho máximo.
/// [builder] recibe el ancho real del contenido para decidir columnas.
class UiScrollPage extends StatelessWidget {
  final double maxWidth;
  final double top;
  final bool centered;
  final List<Widget> Function(BuildContext context, double width) builder;

  const UiScrollPage({
    super.key,
    this.maxWidth = 640,
    this.top = 12,
    this.centered = false,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final nav = NavigationInsets.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final gutter = uiGutter(box.maxWidth);
        final width = (box.maxWidth - gutter * 2).clamp(0.0, maxWidth);
        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            gutter,
            nav.top + top,
            gutter,
            nav.bottom + 32,
          ),
          // Mismo margen izquierdo que Inicio; solo los avisos puntuales van centrados.
          child: Align(
            alignment: centered ? Alignment.topCenter : Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: builder(context, width),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Encabezado de pantalla: antetítulo opcional, título grande y subtítulo.
class UiPageHeader extends StatelessWidget {
  final NearbyCommunityStyle ui;
  final String title;
  final String? subtitle;
  final String? eyebrow;
  final Widget? trailing;

  const UiPageHeader({
    super.key,
    required this.ui,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          Text(
            eyebrow!.toUpperCase(),
            style: TextStyle(
              color: ui.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Text(
          title,
          style: TextStyle(
            color: ui.ink,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            height: 1.15,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: TextStyle(color: ui.muted, fontSize: 14, height: 1.4),
          ),
        ],
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: trailing == null
          ? text
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: text),
                const SizedBox(width: 12),
                trailing!,
              ],
            ),
    );
  }
}

/// Título de sección con acción opcional a la derecha.
class UiSectionTitle extends StatelessWidget {
  final NearbyCommunityStyle ui;
  final String title;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final Widget? trailing;
  final double top;

  const UiSectionTitle({
    super.key,
    required this.ui,
    required this.title,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.trailing,
    this.top = 24,
  });

  @override
  Widget build(BuildContext context) {
    final hasAction = actionLabel != null && onAction != null;
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: 10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: TextStyle(
                    color: ui.ink,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
            if (hasAction)
              TextButton.icon(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: ui.ink,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                icon: Icon(actionIcon ?? Icons.chevron_right, size: 16),
                label: Text(actionLabel!),
              ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// Tarjeta blanca con borde fino y radio 12 (o panel marfil/azul sin borde).
class UiCard extends StatelessWidget {
  final NearbyCommunityStyle ui;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final bool bordered;

  const UiCard({
    super.key,
    required this.ui,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.color,
    this.bordered = true,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: color ?? ui.theme.surface,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: bordered ? BorderSide(color: ui.line) : BorderSide.none,
    ),
    child: Padding(padding: padding, child: child),
  );
}

/// Cuadrito de ícono (azul suave, radio 8).
class UiIconBox extends StatelessWidget {
  final NearbyCommunityStyle ui;
  final IconData icon;
  final double size;
  final Color? color;
  final Color? background;

  const UiIconBox({
    super.key,
    required this.ui,
    required this.icon,
    this.size = 40,
    this.color,
    this.background,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: background ?? ui.blueSoft,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(icon, size: size * 0.5, color: color ?? ui.ink),
  );
}

/// Fila de opción: ícono en cuadrito, título, subtítulo y acción/chevron.
class UiRow extends StatelessWidget {
  final NearbyCommunityStyle ui;
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? iconBackground;

  const UiRow({
    super.key,
    required this.ui,
    required this.icon,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.iconBackground,
  });

  @override
  Widget build(BuildContext context) {
    final end =
        trailing ??
        (onTap == null
            ? null
            : Icon(Icons.chevron_right, color: ui.muted, size: 20));
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              UiIconBox(
                ui: ui,
                icon: icon,
                color: iconColor,
                background: iconBackground,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: ui.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: ui.muted,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                    ?subtitleWidget,
                  ],
                ),
              ),
              if (end != null) ...[const SizedBox(width: 8), end],
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila con interruptor: toda la fila lo cambia.
class UiSwitchRow extends StatelessWidget {
  final NearbyCommunityStyle ui;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;

  const UiSwitchRow({
    super.key,
    required this.ui,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) => SwitchListTile(
    value: value,
    onChanged: onChanged,
    activeTrackColor: activeColor,
    shape: const RoundedRectangleBorder(),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    secondary: UiIconBox(ui: ui, icon: icon),
    title: Text(
      title,
      style: TextStyle(
        color: ui.ink,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
    ),
    subtitle: Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        subtitle,
        style: TextStyle(color: ui.muted, fontSize: 12, height: 1.35),
      ),
    ),
  );
}

/// Separador fino entre filas.
class UiDivider extends StatelessWidget {
  final NearbyCommunityStyle ui;
  const UiDivider({super.key, required this.ui});

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, thickness: 1, color: ui.line);
}

/// Tarjeta con filas separadas por líneas finas.
class UiRowsCard extends StatelessWidget {
  final NearbyCommunityStyle ui;
  final List<Widget> rows;
  const UiRowsCard({super.key, required this.ui, required this.rows});

  @override
  Widget build(BuildContext context) => UiCard(
    ui: ui,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) UiDivider(ui: ui),
          rows[i],
        ],
      ],
    ),
  );
}

/// Opción seleccionable tipo chip (radio 8).
class UiChoice extends StatelessWidget {
  final NearbyCommunityStyle ui;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const UiChoice({
    super.key,
    required this.ui,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? ui.onAccent : ui.ink;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? ui.accent : ui.theme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: selected ? ui.accent : ui.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: selected ? fg : ui.muted),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: fg,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

/// Etiqueta pequeña (radio 8).
class UiTag extends StatelessWidget {
  final NearbyCommunityStyle ui;
  final String label;
  final IconData? icon;
  final Color? background;

  const UiTag({
    super.key,
    required this.ui,
    required this.label,
    this.icon,
    this.background,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: background ?? ui.blueSoft,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: ui.ink),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: ui.ink,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Aviso informativo sobre fondo azul suave.
class UiNotice extends StatelessWidget {
  final NearbyCommunityStyle ui;
  final IconData icon;
  final String text;
  final Color? background;

  const UiNotice({
    super.key,
    required this.ui,
    required this.icon,
    required this.text,
    this.background,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: background ?? ui.blueSoft,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: ui.ink),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: ui.ink, fontSize: 12.5, height: 1.4),
          ),
        ),
      ],
    ),
  );
}

/// Mensaje de lista vacía.
class UiEmpty extends StatelessWidget {
  final NearbyCommunityStyle ui;
  final String text;
  const UiEmpty({super.key, required this.ui, required this.text});

  @override
  Widget build(BuildContext context) => UiCard(
    ui: ui,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(color: ui.muted, fontSize: 13),
    ),
  );
}

/// Etiqueta encima de un campo.
class UiLabeled extends StatelessWidget {
  final NearbyCommunityStyle ui;
  final String label;
  final Widget child;
  const UiLabeled({
    super.key,
    required this.ui,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        label,
        style: TextStyle(
          color: ui.ink,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 6),
      child,
    ],
  );
}

/// Decoración de campo de texto: blanco, borde fino y foco ámbar (radio 8).
InputDecoration uiField(
  NearbyCommunityStyle ui, {
  String? label,
  String? hint,
  IconData? icon,
  Widget? suffix,
  String? prefixText,
  String? counterText,
}) {
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: icon == null ? null : Icon(icon, size: 20, color: ui.muted),
    suffixIcon: suffix,
    prefixText: prefixText,
    counterText: counterText,
    filled: true,
    fillColor: ui.theme.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: border(ui.line),
    enabledBorder: border(ui.line),
    disabledBorder: border(ui.line),
    focusedBorder: border(ui.accent, 2),
    errorBorder: border(ui.theme.sos),
    focusedErrorBorder: border(ui.theme.sos, 2),
  );
}

/// Lista de tarjetas en 1, 2 o 3 columnas según el ancho (altura natural).
class UiGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  const UiGrid({super.key, required this.children, this.spacing = 12});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final cols = uiColumns(box.maxWidth);
      if (cols == 1) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(height: spacing),
              children[i],
            ],
          ],
        );
      }
      // Redondeo hacia abajo para que el redondeo no empuje la última tarjeta a otra fila.
      final w = ((box.maxWidth - spacing * (cols - 1)) / cols).floorToDouble();
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [for (final c in children) SizedBox(width: w, child: c)],
      );
    },
  );
}

/// Pestañas con subrayado (como el muro). [color] tiñe el subrayado de cada opción.
class UiTabs<T> extends StatelessWidget {
  final NearbyCommunityStyle ui;
  final List<(T value, String label, IconData? icon, Color? color)> items;
  final T? selected;
  final ValueChanged<T> onSelect;

  const UiTabs({
    super.key,
    required this.ui,
    required this.items,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => _tabs(box.maxWidth / items.length >= 104),
  );

  // En anchos chicos se ocultan los íconos para que el texto no se corte.
  Widget _tabs(bool showIcons) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: ui.line)),
    ),
    child: Row(
      children: [
        for (final (value, label, icon, color) in items)
          Expanded(
            child: Semantics(
              button: true,
              selected: value == selected,
              child: InkWell(
                onTap: () => onSelect(value),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: value == selected
                            ? (color ?? ui.accent)
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null && showIcons) ...[
                        Icon(
                          icon,
                          size: 16,
                          color: value == selected
                              ? (color ?? ui.ink)
                              : ui.muted,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: value == selected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: value == selected ? ui.ink : ui.muted,
                          ),
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
  );
}

/// Encabezado de hoja inferior: asa, título, subtítulo y cerrar opcional.
class UiSheetHeader extends StatelessWidget {
  final NearbyCommunityStyle ui;
  final String title;
  final String? subtitle;
  final VoidCallback? onClose;

  const UiSheetHeader({
    super.key,
    required this.ui,
    required this.title,
    this.subtitle,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: ui.line,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: ui.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: ui.muted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onClose != null)
            IconButton(
              tooltip: 'Cerrar',
              onPressed: onClose,
              icon: Icon(Icons.close, color: ui.ink),
            ),
        ],
      ),
      const SizedBox(height: 16),
    ],
  );
}

/// Relleno estándar de las hojas inferiores (respeta el teclado).
EdgeInsets uiSheetPadding(BuildContext context) => EdgeInsets.fromLTRB(
  24,
  12,
  24,
  MediaQuery.viewInsetsOf(context).bottom + 24,
);

/// Botón de texto tinta (acción terciaria, p. ej. «Cancelar»).
ButtonStyle uiTextButton(NearbyCommunityStyle ui) => TextButton.styleFrom(
  foregroundColor: ui.ink,
  minimumSize: const Size(0, 44),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  textStyle: const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    fontWeight: FontWeight.w600,
  ),
);
