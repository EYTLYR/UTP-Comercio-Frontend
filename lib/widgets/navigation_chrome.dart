import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Scroll padding keeps the first and last items reachable above fixed controls.
class NavigationInsets extends InheritedWidget {
  final EdgeInsets padding;
  final EdgeInsets? controlPadding;
  const NavigationInsets({
    super.key,
    required this.padding,
    this.controlPadding,
    required super.child,
  });
  static EdgeInsets of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NavigationInsets>()?.padding ??
      EdgeInsets.zero;
  static EdgeInsets controlsOf(BuildContext context) {
    final data = context.dependOnInheritedWidgetOfExactType<NavigationInsets>();
    return data?.controlPadding ?? data?.padding ?? EdgeInsets.zero;
  }

  @override
  bool updateShouldNotify(NavigationInsets oldWidget) =>
      oldWidget.padding != padding ||
      oldWidget.controlPadding != controlPadding;
}

class NavigationContentFade extends InheritedWidget {
  final ShaderCallback shader;
  const NavigationContentFade({
    super.key,
    required this.shader,
    required super.child,
  });
  static Widget wrap(BuildContext context, Widget child) {
    final data = context
        .dependOnInheritedWidgetOfExactType<NavigationContentFade>();
    return data == null
        ? child
        : ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: data.shader,
            child: child,
          );
  }

  @override
  bool updateShouldNotify(NavigationContentFade oldWidget) =>
      oldWidget.shader != shader;
}

/// Content scrolls behind fixed, transparent bars and fades before their controls.
class NavigationChrome extends StatefulWidget {
  final bool childHandlesFade;
  final Widget top;
  final Widget? bottom;
  final Widget child;
  final Color background;
  final Color topBackground;
  const NavigationChrome({
    super.key,
    required this.top,
    this.childHandlesFade = false,
    required this.child,
    required this.background,
    required this.topBackground,
    this.bottom,
  });
  @override
  State<NavigationChrome> createState() => _NavigationChromeState();
}

class _NavigationChromeState extends State<NavigationChrome> {
  double _topHeight = 58;
  double _bottomHeight = 100;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final height = box.maxHeight;
      if (height <= 0) return const SizedBox.shrink();
      final bottomHeight = widget.bottom == null ? 0.0 : _bottomHeight;
      final topStart = (_topHeight - 48).clamp(0.0, height / 2);
      final topEnd = (_topHeight + 24).clamp(topStart, height / 2);
      final bottomStart = (height - bottomHeight - 52).clamp(topEnd, height);
      final bottomEnd = (height - bottomHeight + 20).clamp(bottomStart, height);
      // One smooth opacity ramp instead of stacking a mask and a white veil.
      final colors = <Color>[Colors.transparent];
      final stops = <double>[0];
      for (var i = 0; i <= 12; i++) {
        final t = i / 12;
        final eased = t * t * (3 - 2 * t);
        colors.add(Colors.black.withValues(alpha: eased));
        stops.add((topStart + (topEnd - topStart) * t) / height);
      }
      if (bottomHeight > 0) {
        for (var i = 0; i <= 12; i++) {
          final t = i / 12;
          final eased = t * t * (3 - 2 * t);
          colors.add(Colors.black.withValues(alpha: 1 - eased));
          stops.add((bottomStart + (bottomEnd - bottomStart) * t) / height);
        }
        colors.add(Colors.transparent);
      } else {
        colors.add(Colors.black);
      }
      stops.add(1);
      return Stack(
        fit: StackFit.expand,
        children: [
          NavigationInsets(
            padding: EdgeInsets.only(
              top: _topHeight + 24,
              bottom: bottomHeight == 0 ? 0 : bottomHeight + 56,
            ),
            controlPadding: EdgeInsets.only(
              top: _topHeight,
              bottom: bottomHeight,
            ),
            child: NavigationContentFade(
              shader: (rect) => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: colors,
                stops: stops,
              ).createShader(rect),
              child: widget.childHandlesFade
                  ? widget.child
                  : ShaderMask(
                      key: const ValueKey('navigation-content-fade'),
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (rect) => LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: colors,
                        stops: stops,
                      ).createShader(rect),
                      child: widget.child,
                    ),
            ),
          ),
          if (widget.topBackground != widget.background &&
              !widget.childHandlesFade)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: _topHeight + 24,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        widget.topBackground,
                        widget.topBackground.withValues(alpha: 0.65),
                        widget.topBackground.withValues(alpha: 0),
                      ],
                      stops: const [0, 0.5, 1],
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _MeasureBar(
              onSize: (size) {
                if (mounted && size.height != _topHeight) {
                  setState(() => _topHeight = size.height);
                }
              },
              child: widget.top,
            ),
          ),
          if (widget.bottom != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _MeasureBar(
                onSize: (size) {
                  if (mounted && size.height != _bottomHeight) {
                    setState(() => _bottomHeight = size.height);
                  }
                },
                child: widget.bottom!,
              ),
            ),
        ],
      );
    },
  );
}

class _MeasureBar extends SingleChildRenderObjectWidget {
  final ValueChanged<Size> onSize;
  const _MeasureBar({required this.onSize, required super.child});
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _MeasureBarRender(onSize);
  @override
  void updateRenderObject(
    BuildContext context,
    covariant _MeasureBarRender renderObject,
  ) => renderObject.onSize = onSize;
}

class _MeasureBarRender extends RenderProxyBox {
  ValueChanged<Size> onSize;
  Size? _previous;
  _MeasureBarRender(this.onSize);
  @override
  void performLayout() {
    super.performLayout();
    if (size == _previous) return;
    _previous = size;
    final measured = size;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached) onSize(measured);
    });
  }
}
