import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Scroll padding keeps the first and last items reachable above fixed controls.
class NavigationInsets extends InheritedWidget {
  final EdgeInsets padding;
  const NavigationInsets({
    super.key,
    required this.padding,
    required super.child,
  });
  static EdgeInsets of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NavigationInsets>()?.padding ??
      EdgeInsets.zero;
  @override
  bool updateShouldNotify(NavigationInsets oldWidget) =>
      oldWidget.padding != padding;
}

/// Content scrolls behind fixed, transparent bars and fades before their controls.
class NavigationChrome extends StatefulWidget {
  final Widget top;
  final Widget? bottom;
  final Widget child;
  final Color background;
  final Color topBackground;
  const NavigationChrome({
    super.key,
    required this.top,
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
      final topStart = (_topHeight - 12).clamp(0.0, height / 2);
      final topEnd = (_topHeight + 20).clamp(topStart, height / 2);
      final bottomStart = (height - bottomHeight - 24).clamp(topEnd, height);
      final bottomEnd = (height - bottomHeight + 12).clamp(bottomStart, height);
      return Stack(
        fit: StackFit.expand,
        children: [
          NavigationInsets(
            padding: EdgeInsets.only(
              top: _topHeight + 20,
              bottom: bottomHeight == 0 ? 0 : bottomHeight + 24,
            ),
            child: ShaderMask(
              key: const ValueKey('navigation-content-fade'),
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black,
                  Colors.black,
                  bottomHeight == 0 ? Colors.black : Colors.transparent,
                  bottomHeight == 0 ? Colors.black : Colors.transparent,
                ],
                stops: [
                  0,
                  topStart / height,
                  topEnd / height,
                  bottomStart / height,
                  bottomEnd / height,
                  1,
                ],
              ).createShader(rect),
              child: widget.child,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _topHeight + 20,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      widget.topBackground,
                      widget.topBackground.withValues(alpha: 0.9),
                      widget.topBackground.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.65, 1],
                  ),
                ),
              ),
            ),
          ),
          if (widget.bottom != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: bottomHeight + 24,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        widget.background.withValues(alpha: 0),
                        widget.background.withValues(alpha: 0.92),
                        widget.background,
                      ],
                      stops: const [0, 0.55, 1],
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
