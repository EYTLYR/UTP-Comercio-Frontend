import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/nearby_theme.dart';

class TourStepDef {
  final String title;
  final String desc;
  final String? btn;
  final bool isAction;
  final IconData? icon;
  final bool isCenter;

  const TourStepDef({
    required this.title,
    required this.desc,
    this.btn,
    this.isAction = false,
    this.icon,
    this.isCenter = false,
  });
}

final List<TourStepDef> kMainTourSteps = [
  const TourStepDef(
    isCenter: true,
    icon: Icons.touch_app,
    title: 'Aprende tocando la app',
    desc: 'Te guiamos paso a paso sobre las pantallas reales de Nearby. Toca donde brille. Nada de lo que hagas aquí se envía ni se publica.',
    btn: 'Empezar',
  ),
  const TourStepDef(
    isAction: true,
    title: 'Practica el botón SOS',
    desc: 'Mantén el dedo sobre el botón 2 segundos, hasta que el anillo blanco se complete. Si solo lo tocas, no pasa nada: así se evitan alertas por error.',
  ),
  const TourStepDef(
    title: 'Llamadas de emergencia',
    desc: 'Puedes abrir una llamada a la Policía (105), Bomberos (116) o SAMU (106). Confirma el número en el marcador del teléfono.',
    btn: 'Siguiente',
  ),
  const TourStepDef(
    isAction: true,
    title: 'Busca un oficio de confianza',
    desc: 'Toca «Servicios» en la barra inferior para ver gasfiteros, electricistas, clases y más de tu barrio.',
  ),
  const TourStepDef(
    isAction: true,
    title: 'Filtra por lo que necesitas',
    desc: 'Toca el chip de «Gasfitería».',
  ),
  const TourStepDef(
    isAction: true,
    title: 'Abre un perfil',
    desc: 'Toca a Julio Quispe para ver quién lo recomienda.',
  ),
  const TourStepDef(
    title: 'Visto Bueno Vecinal',
    desc: 'Este número son vecinos de tu zona que ya lo contrataron y lo recomiendan. Así sabes en quién confiar.',
    btn: 'Siguiente',
  ),
  const TourStepDef(
    isAction: true,
    title: 'Recomienda tú también',
    desc: 'Cuando un vecino te atienda bien, toca «Dar visto bueno». Pruébalo ahora.',
  ),
  const TourStepDef(
    isAction: true,
    title: 'Vuelve atrás',
    desc: 'La flecha de arriba siempre te regresa a la pantalla anterior.',
  ),
  const TourStepDef(
    isAction: true,
    title: 'Pide o ofrece ayuda',
    desc:
        'El botón + central sirve para publicar en el muro de favores. Tócalo.',
  ),
  const TourStepDef(
    isAction: true,
    title: 'Toque 1 de 3: el tipo',
    desc: 'Toca «Necesito ayuda».',
  ),
  const TourStepDef(
    isAction: true,
    title: 'Toque 2 de 3: la categoría',
    desc: 'Elige qué necesitas, por ejemplo «Préstamo de herramientas». Escribir es opcional.',
  ),
  const TourStepDef(
    isAction: true,
    title: 'Toque 3 de 3: publicar',
    desc: 'La ubicación se pone sola. Toca el botón para terminar.',
  ),
  const TourStepDef(
    isAction: true,
    title: '¡Publicaste en 3 toques!',
    desc: 'En la vida real, tus vecinos cercanos lo verían al instante. Toca «Volver al inicio».',
  ),
  const TourStepDef(
    title: 'Tu perfil',
    desc: 'Aquí eliges tus contactos de confianza, tu ficha médica, letra grande o tema oscuro. También puedes repetir este tutorial.',
    btn: 'Siguiente',
  ),
  const TourStepDef(
    isCenter: true,
    icon: Icons.crisis_alert,
    title: 'Si hay una emergencia',
    desc: 'Nearby cambia sola a modo emergencia: verás el tablero del barrio, recursos y grupos de apoyo. Cuando todo pase, sales tocando el aviso rojo de arriba.',
    btn: 'Siguiente',
  ),
  const TourStepDef(
    isCenter: true,
    icon: Icons.celebration,
    title: '¡Ya sabes usar Nearby!',
    desc: 'Practicaste el SOS, encontraste un servicio y publicaste un favor, todo tú solo. Puedes repetir el tutorial desde tu perfil.',
    btn: 'Terminar',
  ),
];

final List<TourStepDef> kEmTourSteps = [
  const TourStepDef(
    title: 'Estás en modo emergencia',
    desc: 'Nearby se reorganizó para coordinar ayuda en tu barrio. El botón SOS sigue siendo lo primero.',
    btn: 'Siguiente',
  ),
  const TourStepDef(
    title: 'Cuéntanos cómo estás',
    desc: 'Un toque en «Estoy bien» avisa a tus contactos y al tablero del barrio. Si necesitas ayuda, usa el SOS.',
    btn: 'Siguiente',
  ),
  const TourStepDef(
    title: 'Reporta en 3 toques',
    desc: 'El botón rojo central sirve para reportar vecinos vulnerables o pedir y ofrecer recursos como agua o víveres.',
    btn: 'Siguiente',
  ),
  const TourStepDef(
    isAction: true,
    title: '¿Cómo salgo de este modo?',
    desc: 'Toca el aviso rojo superior con la campana de emergencia.',
  ),
  const TourStepDef(
    title: 'Desactivar cuando pase',
    desc: 'Desde aquí vuelves al modo normal. Si tu zona sigue en emergencia, igual recibirás alertas críticas.',
    btn: 'Entendido',
  ),
];

class InteractiveTourOverlay extends StatefulWidget {
  final AppState state;
  final NearbyThemeData theme;
  const InteractiveTourOverlay({
    super.key,
    required this.state,
    required this.theme,
  });
  @override
  State<InteractiveTourOverlay> createState() => _InteractiveTourOverlayState();
}

class _InteractiveTourOverlayState extends State<InteractiveTourOverlay>
    with WidgetsBindingObserver {
  final _overlayKey = GlobalKey();
  Rect? _target;
  String? _signature;
  int _generation = 0;
  Size? _size;

  String? get _targetName {
    final state = widget.state;
    if (state.tourName == 'em') {
      return {
        0: 'em-banner',
        1: 'checkin',
        2: 'nav-publicar',
        3: 'em-banner',
        4: 'em-exit',
      }[state.tourIndex];
    }
    return {
      1: 'sos',
      2: 'calls',
      3: 'nav-servicios',
      4: 'service-category',
      5: 'service-julio',
      6: 'vb-score',
      7: 'vb',
      8: 'back',
      9: 'nav-publicar',
      10: 'publish-type',
      11: 'publish-category',
      12: 'publish-submit',
      13: 'publish-home',
      14: 'profile',
    }[state.tourIndex];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() => _schedule();

  ScrollableState? _pageScroller() {
    ScrollableState? found;
    void visit(Element element) {
      if (found != null) return;
      if (element is StatefulElement && element.state is ScrollableState) {
        final scroll = element.state as ScrollableState;
        if (axisDirectionToAxis(scroll.axisDirection) == Axis.vertical) {
          found = scroll;
          return;
        }
      }
      element.visitChildElements(visit);
    }

    final root = widget.state.tourViewportKey.currentContext;
    if (root is Element) root.visitChildElements(visit);
    return found;
  }

  void _schedule() {
    final generation = ++_generation;
    void reveal(int attempt) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || generation != _generation) return;
        final targetName = _targetName;
        if (targetName == null) {
          if (widget.state.tourIndex == 0) {
            final scroll = _pageScroller();
            if (scroll != null && scroll.position.hasContentDimensions) {
              scroll.position.jumpTo(scroll.position.minScrollExtent);
            }
          }
          return;
        }
        final targetContext =
            widget.state.tourTargets[targetName]?.currentContext;
        if (targetContext == null) {
          // Lazy lists dispose off-screen targets. Reveal a viewport first,
          // then measure the target after Flutter has built its elements.
          final scroll = _pageScroller();
          if (scroll != null &&
              scroll.position.hasContentDimensions &&
              attempt < 16) {
            final position = scroll.position;
            final offset = attempt == 0
                ? position.minScrollExtent
                : (position.pixels + position.viewportDimension * .65).clamp(
                    position.minScrollExtent,
                    position.maxScrollExtent,
                  );
            position.jumpTo(offset);
            reveal(attempt + 1);
            WidgetsBinding.instance.scheduleFrame();
          }
          return;
        }
        await Scrollable.ensureVisible(targetContext, alignment: .45);
        if (!mounted || generation != _generation || !targetContext.mounted) {
          return;
        }
        _measure(targetContext);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && generation == _generation && targetContext.mounted) {
            _measure(targetContext);
          }
        });
      });
    }

    reveal(0);
  }

  void _measure(BuildContext targetContext) {
    final target = targetContext.findRenderObject();
    final overlay = _overlayKey.currentContext?.findRenderObject();
    if (target is! RenderBox ||
        overlay is! RenderBox ||
        !target.attached ||
        !target.hasSize) {
      return;
    }
    final rect =
        (target.localToGlobal(Offset.zero, ancestor: overlay) & target.size)
            .inflate(6)
            .intersect(Offset.zero & overlay.size);
    if (rect.isEmpty || rect == _target) return;
    setState(() => _target = rect);
  }

  @override
  void dispose() {
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final theme = widget.theme;
    final steps = state.tourName == 'main' ? kMainTourSteps : kEmTourSteps;
    if (state.tourName == null || state.tourIndex >= steps.length) {
      return const SizedBox.shrink();
    }
    final step = steps[state.tourIndex];
    final signature =
        '${state.tourName}:${state.tourIndex}:${state.sheet?['type']}';
    if (signature != _signature) {
      _signature = signature;
      _target = null;
      _schedule();
    }
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, box) {
          final size = box.biggest;
          if (_size != size) {
            _size = size;
            _schedule();
          }
          final target = _target;
          final above = target?.top ?? 0;
          final below = target == null ? 0.0 : size.height - target.bottom;
          final placeAbove = above > below;
          final available = target == null
              ? size.height - 32
              : (placeAbove ? above : below) - 24;
          final cardHeight = available.clamp(
            100.0,
            (size.height - 32).clamp(100.0, 320.0),
          );
          final top = target == null
              ? null
              : placeAbove
              ? null
              : target.bottom + 12;
          final bottom = target != null && placeAbove
              ? size.height - target.top + 12
              : null;
          Widget barrier(Rect rect) => Positioned.fromRect(
            rect: rect,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
            ),
          );
          return Stack(
            key: _overlayKey,
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                child: CustomPaint(
                  painter: _TourSpotlightPainter(
                    target: target,
                    color: Colors.black.withValues(alpha: 0.68),
                    outline: theme.primary,
                  ),
                ),
              ),
              if (target != null && step.isAction) ...[
                barrier(Rect.fromLTRB(0, 0, size.width, target.top)),
                barrier(
                  Rect.fromLTRB(0, target.bottom, size.width, size.height),
                ),
                barrier(
                  Rect.fromLTRB(0, target.top, target.left, target.bottom),
                ),
                barrier(
                  Rect.fromLTRB(
                    target.right,
                    target.top,
                    size.width,
                    target.bottom,
                  ),
                ),
              ] else
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                  ),
                ),
              Positioned(
                left: 16,
                right: 16,
                top: top,
                bottom: bottom,
                child: target == null
                    ? Center(
                        child: _card(step, steps.length, theme, cardHeight),
                      )
                    : _card(step, steps.length, theme, cardHeight),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _card(
    TourStepDef step,
    int count,
    NearbyThemeData theme,
    double maxHeight,
  ) {
    final state = widget.state;
    return Material(
      color: theme.surface,
      borderRadius: BorderRadius.circular(24),
      elevation: 12,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    step.isAction ? Icons.touch_app : step.icon ?? Icons.school,
                    color: theme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'PASO ${state.tourIndex + 1} DE $count${step.isAction ? ' · TU TURNO' : ''}',
                      style: TextStyle(
                        color: theme.primaryDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Salir del tutorial',
                    onPressed: () => state.endTour(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          step.title,
                          style: TextStyle(
                            color: theme.ink,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        step.desc,
                        style: TextStyle(
                          color: theme.muted,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (!step.isAction)
                FilledButton(
                  onPressed: state.nextTourStep,
                  child: Text(step.btn ?? 'Siguiente'),
                )
              else
                Text(
                  'Toca el control resaltado para continuar.',
                  style: TextStyle(
                    color: theme.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: (state.tourIndex + 1) / count,
                color: theme.primary,
                backgroundColor: theme.line,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TourSpotlightPainter extends CustomPainter {
  final Rect? target;
  final Color color;
  final Color outline;
  _TourSpotlightPainter({
    required this.target,
    required this.color,
    required this.outline,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final background = Path()..addRect(Offset.zero & size);
    if (target == null) {
      canvas.drawPath(background, Paint()..color = color);
    } else {
      final shape = RRect.fromRectAndRadius(target!, const Radius.circular(14));
      final hole = Path()..addRRect(shape);
      canvas.drawPath(
        Path.combine(PathOperation.difference, background, hole),
        Paint()..color = color,
      );
      canvas.drawRRect(
        shape,
        Paint()
          ..color = outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(_TourSpotlightPainter oldDelegate) =>
      target != oldDelegate.target ||
      color != oldDelegate.color ||
      outline != oldDelegate.outline;
}
