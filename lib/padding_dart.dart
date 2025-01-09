import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class RenderAnyPadding extends RenderShiftedBox {
  EdgeInsetsGeometry _padding;
  TextDirection? _textDirection;
  EdgeInsets? _resolvedPaddingCache;

  RenderAnyPadding(this._padding, this._textDirection, [RenderBox? child])
      : super(child);

  EdgeInsets get resolvedPadding {
    if (_resolvedPaddingCache != null) return _resolvedPaddingCache!;
    _resolvedPaddingCache = _padding.resolve(_textDirection);
    return _resolvedPaddingCache!;
  }

  void _markNeedResolution() {
    _resolvedPaddingCache = null;
    markNeedsLayout();
  }

  EdgeInsetsGeometry get padding => _padding;
  set padding(EdgeInsetsGeometry value) {
    if (_padding == value) return;
    _padding = value;
    _markNeedResolution();
  }

  TextDirection? get textDirection => _textDirection;
  set textDirection(TextDirection? value) {
    if (_textDirection == value) return;
    _textDirection = value;
    _markNeedResolution();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    final EdgeInsets padding = resolvedPadding;
    final double childWidth =
        child?.getMinIntrinsicWidth(math.max(0.0, height - padding.vertical)) ??
            0.0;
    return math.max(0.0, childWidth + padding.horizontal);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final EdgeInsets padding = resolvedPadding;
    final double childWidth =
        child?.getMaxIntrinsicWidth(math.max(0.0, height - padding.vertical)) ??
            0.0;
    return math.max(0.0, childWidth + padding.horizontal);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    final EdgeInsets padding = resolvedPadding;
    final double childHeight = child?.getMinIntrinsicHeight(
            math.max(0.0, width - padding.horizontal)) ??
        0.0;
    return math.max(0.0, childHeight + padding.vertical);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final EdgeInsets padding = resolvedPadding;
    final double childHeight = child?.getMaxIntrinsicHeight(
            math.max(0.0, width - padding.horizontal)) ??
        0.0;
    return math.max(0.0, childHeight + padding.vertical);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final EdgeInsets padding = resolvedPadding;
    if (child != null) {
      final BoxConstraints innerConstraints = constraints.deflate(padding);
      final Size childSize = child!.getDryLayout(innerConstraints);
      return constraints.constrain(Size(
        math.max(0.0, childSize.width + padding.horizontal),
        math.max(0.0, childSize.height + padding.vertical),
      ));
    }
    return constraints.constrain(Size(
      math.max(0.0, padding.horizontal),
      math.max(0.0, padding.vertical),
    ));
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    final EdgeInsets padding = resolvedPadding;
    if (child == null) {
      return null;
    }
    final distance = child!.getDistanceToActualBaseline(baseline);
    return distance == null ? null : distance + padding.top;
  }

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    final EdgeInsets padding = resolvedPadding;

    if (child != null) {
      final BoxConstraints innerConstraints = constraints.deflate(padding);
      child!.layout(innerConstraints, parentUsesSize: true);
      final BoxParentData childParentData = child!.parentData as BoxParentData;
      childParentData.offset = Offset(padding.left, padding.top);
      size = constraints.constrain(Size(
        math.max(0.0, child!.size.width + padding.horizontal),
        math.max(0.0, child!.size.height + padding.vertical),
      ));
    } else {
      size = constraints.constrain(Size(
        math.max(0.0, padding.horizontal),
        math.max(0.0, padding.vertical),
      ));
    }
  }

  @override
  void debugPaintSize(PaintingContext context, Offset offset) {
    super.debugPaintSize(context, offset);
    if (kDebugMode) {
      final Rect outerRect = offset & size;
      debugPaintPadding(
        context.canvas,
        outerRect,
        child != null ? resolvedPadding.deflateRect(outerRect) : null,
      );
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection));
  }
}

class AnyPadding extends SingleChildRenderObjectWidget {
  final EdgeInsetsGeometry padding;

  const AnyPadding({
    Key? key,
    required this.padding,
    Widget? child,
  }) : super(key: key, child: child);

  @override
  RenderAnyPadding createRenderObject(BuildContext context) {
    return RenderAnyPadding(
      padding,
      Directionality.maybeOf(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderAnyPadding renderObject) {
    renderObject
      ..padding = padding
      ..textDirection = Directionality.maybeOf(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding));
  }
}

class AnimatedAnyPadding extends ImplicitlyAnimatedWidget {
  final Widget? child;
  final EdgeInsetsGeometry padding;

  const AnimatedAnyPadding({
    Key? key,
    required this.padding,
    this.child,
    Curve curve = Curves.linear,
    required Duration duration,
    VoidCallback? onEnd,
  }) : super(key: key, curve: curve, duration: duration, onEnd: onEnd);

  @override
  AnimatedAnyPaddingState createState() => AnimatedAnyPaddingState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding));
  }
}

class AnimatedAnyPaddingState
    extends AnimatedWidgetBaseState<AnimatedAnyPadding> {
  EdgeInsetsGeometryTween? _padding;

  @override
  void initState() {
    _padding = null;
    super.initState();
  }

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _padding = visitor(
      _padding,
      widget.padding,
      (dynamic value) =>
          EdgeInsetsGeometryTween(begin: value as EdgeInsetsGeometry),
    ) as EdgeInsetsGeometryTween?;
  }

  @override
  Widget build(BuildContext context) {
    return AnyPadding(
      padding: _padding!.evaluate(animation),
      child: widget.child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EdgeInsetsGeometryTween>(
        'padding', _padding,
        defaultValue: null));
  }
}
