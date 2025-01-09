import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';

class Button extends StatefulWidget {
  const Button({
    super.key,
    required this.child,
    this.isEnabled = true,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.onDoubleTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.onSecondaryTapUp,
    this.onSecondaryTapDown,
    this.onSecondaryTapCancel,
    this.onHighlightChanged,
    this.onHover,
    this.mouseCursor,
    this.enableFeedback = false,
    this.excludeFromSemantics = false,
    this.focusNode,
    this.canRequestFocus = true,
    this.onFocusChange,
    this.autofocus = false,
    this.statesController,
  });

  final Widget? Function(ButtonContext) child;
  final bool isEnabled;
  final GestureTapCallback? onTap;
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final GestureTapCallback? onTapCancel;
  final GestureTapCallback? onDoubleTap;
  final GestureLongPressCallback? onLongPress;
  final GestureTapCallback? onSecondaryTap;
  final GestureTapUpCallback? onSecondaryTapUp;
  final GestureTapDownCallback? onSecondaryTapDown;
  final GestureTapCallback? onSecondaryTapCancel;
  final ValueChanged<bool>? onHighlightChanged;
  final ValueChanged<bool>? onHover;
  final MouseCursor? mouseCursor;
  final bool enableFeedback;
  final bool excludeFromSemantics;
  final ValueChanged<bool>? onFocusChange;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool canRequestFocus;
  final WidgetStatesController? statesController;

  @override
  ButtonState createState() => ButtonState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final List<String> gestures = <String>[
      if (onTap != null) 'tap',
      if (onDoubleTap != null) 'double tap',
      if (onLongPress != null) 'long press',
      if (onTapDown != null) 'tap down',
      if (onTapUp != null) 'tap up',
      if (onTapCancel != null) 'tap cancel',
      if (onSecondaryTap != null) 'secondary tap',
      if (onSecondaryTapUp != null) 'secondary tap up',
      if (onSecondaryTapDown != null) 'secondary tap down',
      if (onSecondaryTapCancel != null) 'secondary tap cancel'
    ];
    properties
        .add(IterableProperty<String>('gestures', gestures, ifEmpty: '<none>'));
    properties
        .add(DiagnosticsProperty<MouseCursor>('mouseCursor', mouseCursor));
  }
}

class ButtonContext {
  const ButtonContext({
    required this.context,
    required this.state,
    this.localOffset,
    this.globalOffset,
  });

  final BuildContext context;
  final Set<WidgetState> state;
  final Offset? localOffset;
  final Offset? globalOffset;
}

class ButtonState extends State<Button>
    with AutomaticKeepAliveClientMixin<Button> {
  bool _hovering = false;
  Offset? _cursorLocalOffset;
  Offset? _cursorGlobalOffset;

  late final Map<Type, Action<Intent>> _actionMap = <Type, Action<Intent>>{
    ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: activateOnIntent),
    ButtonActivateIntent:
        CallbackAction<ButtonActivateIntent>(onInvoke: activateOnIntent),
  };
  WidgetStatesController? internalStatesController;

  void activateOnIntent(Intent? intent) {
    if (widget.onTap != null) {
      if (widget.enableFeedback) {
        Feedback.forTap(context);
      }
      widget.onTap?.call();
    }
  }

  void handleStatesControllerChange() {
    // Force a rebuild to resolve widget.mouseCursor
    setState(() {});
  }

  WidgetStatesController get statesController =>
      widget.statesController ?? internalStatesController!;

  void initStatesController() {
    if (widget.statesController == null) {
      internalStatesController = WidgetStatesController();
    }
    statesController.update(WidgetState.disabled, !enabled);
    statesController.addListener(handleStatesControllerChange);
  }

  @override
  void initState() {
    super.initState();
    initStatesController();
    FocusManager.instance
        .addHighlightModeListener(handleFocusHighlightModeChange);
  }

  @override
  void didUpdateWidget(Button oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.statesController != oldWidget.statesController) {
      oldWidget.statesController?.removeListener(handleStatesControllerChange);
      if (widget.statesController != null) {
        internalStatesController?.dispose();
        internalStatesController = null;
      }
      initStatesController();
    }
    if (enabled != isWidgetEnabled(oldWidget)) {
      statesController.update(WidgetState.disabled, !enabled);
      if (!enabled) {
        statesController.update(WidgetState.pressed, false);
      }
      // Don't call widget.onHover because many widgets, including the button
      // widgets, apply setState to an ancestor context from onHover.
      updateHighlight(WidgetState.hovered,
          value: _hovering, callOnHover: false);
    }
    updateFocusHighlights();
  }

  @override
  bool get wantKeepAlive => false;

  @override
  void dispose() {
    FocusManager.instance
        .removeHighlightModeListener(handleFocusHighlightModeChange);
    statesController.removeListener(handleStatesControllerChange);
    internalStatesController?.dispose();
    super.dispose();
  }

  void updateHighlight(WidgetState type,
      {required bool value, bool callOnHover = true}) {
    switch (type) {
      case WidgetState.pressed:
        statesController.update(WidgetState.pressed, value);
      case WidgetState.hovered:
        if (callOnHover) {
          statesController.update(WidgetState.hovered, value);
        }
      default:
        break;
    }
    switch (type) {
      case WidgetState.pressed:
        widget.onHighlightChanged?.call(value);
      case WidgetState.hovered:
        if (callOnHover) {
          widget.onHover?.call(value);
        }
      default:
        break;
    }
  }

  void handleFocusHighlightModeChange(FocusHighlightMode mode) {
    if (!mounted) {
      return;
    }
    setState(() {
      updateFocusHighlights();
    });
  }

  bool get _shouldShowFocus {
    return switch (MediaQuery.maybeNavigationModeOf(context)) {
      NavigationMode.traditional || null => enabled && _hasFocus,
      NavigationMode.directional => _hasFocus,
    };
  }

  void updateFocusHighlights() {
    final bool showFocus = switch (FocusManager.instance.highlightMode) {
      FocusHighlightMode.touch => false,
      FocusHighlightMode.traditional => _shouldShowFocus,
    };
    updateHighlight(WidgetState.focused, value: showFocus);
  }

  bool _hasFocus = false;
  void handleFocusUpdate(bool hasFocus) {
    _hasFocus = hasFocus;
    // Set here rather than updateHighlight because this widget's
    // (WidgetState) states include WidgetState.focused if
    // the InkWell _has_ the focus, rather than if it's showing
    // the focus per FocusManager.instance.highlightMode.
    statesController.update(WidgetState.focused, hasFocus);
    updateFocusHighlights();
    widget.onFocusChange?.call(hasFocus);
  }

  void handleAnyTapDown(TapDownDetails details) {
    _cursorGlobalOffset = details.globalPosition;
    _cursorLocalOffset = details.localPosition;
    statesController.update(WidgetState.pressed, true);
    updateKeepAlive();
    updateHighlight(WidgetState.pressed, value: true);
  }

  void handleTapDown(TapDownDetails details) {
    handleAnyTapDown(details);
    widget.onTapDown?.call(details);
  }

  void handleTapUp(TapUpDetails details) {
    clearOffsets();
    widget.onTapUp?.call(details);
  }

  void handleSecondaryTapDown(TapDownDetails details) {
    handleAnyTapDown(details);
    widget.onSecondaryTapDown?.call(details);
  }

  void handleSecondaryTapUp(TapUpDetails details) {
    clearOffsets();
    widget.onSecondaryTapUp?.call(details);
  }

  void handleTap() {
    updateHighlight(WidgetState.pressed, value: false);
    if (widget.onTap != null) {
      if (widget.enableFeedback) {
        Feedback.forTap(context);
      }
      widget.onTap?.call();
    }
  }

  void handleTapCancel() {
    clearOffsets();
    widget.onTapCancel?.call();
    updateHighlight(WidgetState.pressed, value: false);
  }

  void handleDoubleTap() {
    updateHighlight(WidgetState.pressed, value: false);
    widget.onDoubleTap?.call();
  }

  void handleLongPressStart(LongPressStartDetails details) {
    _cursorGlobalOffset = details.globalPosition;
    _cursorLocalOffset = details.localPosition;
  }

  void handleLongPress() {
    if (widget.onLongPress != null) {
      if (widget.enableFeedback) {
        Feedback.forLongPress(context);
      }
      widget.onLongPress!();
    }
  }

  void handleSecondaryTap() {
    updateHighlight(WidgetState.pressed, value: false);
    widget.onSecondaryTap?.call();
  }

  void handleSecondaryTapCancel() {
    clearOffsets();
    widget.onSecondaryTapCancel?.call();
    updateHighlight(WidgetState.pressed, value: false);
  }

  void clearOffsets() {
    _cursorLocalOffset = null;
    _cursorGlobalOffset = null;
  }

  bool isWidgetEnabled(Button widget) {
    return _primaryButtonEnabled(widget) || _secondaryButtonEnabled(widget);
  }

  bool _primaryButtonEnabled(Button widget) {
    return widget.isEnabled &&
        (widget.onTap != null ||
            widget.onDoubleTap != null ||
            widget.onLongPress != null ||
            widget.onTapUp != null ||
            widget.onTapDown != null);
  }

  bool _secondaryButtonEnabled(Button widget) {
    return widget.isEnabled &&
        (widget.onSecondaryTap != null ||
            widget.onSecondaryTapUp != null ||
            widget.onSecondaryTapDown != null);
  }

  bool get enabled => isWidgetEnabled(widget);
  bool get _primaryEnabled => _primaryButtonEnabled(widget);
  bool get _secondaryEnabled => _secondaryButtonEnabled(widget);

  void handleMouseEnter(PointerEnterEvent event) {
    _hovering = true;
    _cursorGlobalOffset = event.position;
    _cursorLocalOffset = event.localPosition;
    if (enabled) {
      handleHoverChange();
    }
  }

  void handleMouseMove(PointerHoverEvent event) {
    _cursorGlobalOffset = event.position;
    _cursorLocalOffset = event.localPosition;
  }

  void handleMouseExit(PointerExitEvent event) {
    _hovering = false;
    clearOffsets();
    // If the exit occurs after we've been disabled, we still
    // want to take down the highlights and run widget.onHover.
    handleHoverChange();
  }

  void handleHoverChange() {
    updateHighlight(WidgetState.hovered, value: _hovering);
  }

  bool get _canRequestFocus {
    return switch (MediaQuery.maybeNavigationModeOf(context)) {
      NavigationMode.traditional || null => enabled && widget.canRequestFocus,
      NavigationMode.directional => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final MouseCursor effectiveMouseCursor =
        WidgetStateProperty.resolveAs<MouseCursor>(
      widget.mouseCursor ?? WidgetStateMouseCursor.clickable,
      statesController.value,
    );

    return Actions(
      actions: _actionMap,
      child: Focus(
        focusNode: widget.focusNode,
        canRequestFocus: _canRequestFocus,
        onFocusChange: handleFocusUpdate,
        autofocus: widget.autofocus,
        child: MouseRegion(
          cursor: effectiveMouseCursor,
          onEnter: handleMouseEnter,
          onExit: handleMouseExit,
          onHover: handleMouseMove,
          child: DefaultSelectionStyle.merge(
            mouseCursor: effectiveMouseCursor,
            child: Semantics(
              onTap: widget.excludeFromSemantics || widget.onTap == null
                  ? null
                  : handleTap,
              onLongPress:
                  widget.excludeFromSemantics || widget.onLongPress == null
                      ? null
                      : handleLongPress,
              child: GestureDetector(
                onTapDown: _primaryEnabled ? handleTapDown : null,
                onTapUp: _primaryEnabled ? handleTapUp : null,
                onTap: _primaryEnabled ? handleTap : null,
                onTapCancel: _primaryEnabled ? handleTapCancel : null,
                onDoubleTap:
                    widget.onDoubleTap != null ? handleDoubleTap : null,
                onDoubleTapCancel:
                    widget.onDoubleTap != null ? clearOffsets : null,
                onLongPressCancel:
                    widget.onLongPress != null ? clearOffsets : null,
                onLongPress:
                    widget.onLongPress != null ? handleLongPress : null,
                onLongPressStart:
                    widget.onLongPress != null ? handleLongPressStart : null,
                onLongPressUp: widget.onLongPress != null ? clearOffsets : null,
                onSecondaryTapDown:
                    _secondaryEnabled ? handleSecondaryTapDown : null,
                onSecondaryTapUp:
                    _secondaryEnabled ? handleSecondaryTapUp : null,
                onSecondaryTap: _secondaryEnabled ? handleSecondaryTap : null,
                onSecondaryTapCancel:
                    _secondaryEnabled ? handleSecondaryTapCancel : null,
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                child: widget.child(
                  ButtonContext(
                    context: context,
                    state: statesController.value,
                    localOffset: _cursorLocalOffset,
                    globalOffset: _cursorGlobalOffset,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
