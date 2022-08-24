import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'scroll_state.dart';
import 'scroll_translation.dart';

const kMobilePhysics = BouncingScrollPhysics();
const kDesktopPhysics = NeverScrollableScrollPhysics();

class DynMouseScroll extends StatelessWidget {
  /// Passed to [ScrollTranslation] and animated dynamically given the speed
  /// the user is scrolling SPS (Scrolls Per Second).
  /// If you need to access the state of this controller, use [builder]
  ScrollController? controller;

  /// Optional, where [controller] should set its initial scroll position.
  /// Defaults to 0.
  final double initialOffset;

  /// If you are not using slivers the provided children will be wrapped
  /// [SliverToBoxAdapter] before being passed to the [CustomScrollView]
  List<Widget>? children, slivers;

  /// If providing slivers or widgets does not suit your needs or you need
  /// to access [controller], use:
  ///       builder: (context, controller, physics) => ...
  Function(BuildContext, ScrollController, ScrollPhysics)? builder;

  /// Set to true if [ParentListener] is an ancestor of this widget.
  /// [ParentListener] will automatically update all child [] widgets.
  /// Defaults to false.
  final bool hasParentListener;

  final Curve animationCurve, flickAnimationCurve;

  late ScrollTranslation scrollTranslation;

  /// Speed (in Scrolls per Second) that will trigger a flick animation.
  /// Defaults to 60.
  final double minFlickSPS;

  /// Lower & Upper bound distance (in pixels).
  ///     Lower default: 120
  ///     Upper default: 250
  final double lowerDistance, upperDistance;

  /// Upper & Lower bound duration (in milliseconds)
  ///     Lower default: 200
  ///     Upper default: 35
  final double lowerDuration, upperDuration;

  /// Lower & Upper bound distance of a FLICK event
  ///     Lower default: 400
  ///     Upper Default: 1000
  final double lowerFlickDistance, upperFlickDistance;

  /// Upper & Lower bound distance of a FLICK scroll event.
  ///     Lower default: 500
  ///     Upper default: 20
  final double lowerFlickDuration, upperFlickDuration;

  DynMouseScroll({
    Key? key,
    this.hasParentListener = false,
    this.initialOffset = 0,
    this.controller,
    this.slivers,
    this.children,
    this.builder,
    this.animationCurve = Curves.linear,
    this.flickAnimationCurve = Curves.linear,
    this.minFlickSPS = 60,
    this.lowerDistance = 120,
    this.upperDistance = 250,
    this.lowerDuration = 200,
    this.upperDuration = 35,
    this.lowerFlickDistance = 400,
    this.upperFlickDistance = 1000,
    this.lowerFlickDuration = 500,
    this.upperFlickDuration = 20,

    /// Curves and outer bounds for fine-turning.
    Curve distanceCurve = Curves.linear,
    Curve durationCurve = Curves.linear,
    Curve flickDistanceCurve = Curves.linear,
    Curve flickDurationCurve = Curves.linear,
    double minSPS = 1,
    double maxFlickSPS = 200,
  }) : super(key: key) {
    assert(slivers != null || children != null || builder != null);
    assert(minSPS < minFlickSPS && minFlickSPS < maxFlickSPS);

    if (builder == null) {
      slivers ??= List.generate(children!.length,
          (index) => SliverToBoxAdapter(child: children![index]));
    }

    controller ??= ScrollController(initialScrollOffset: initialOffset);

    scrollTranslation = ScrollTranslation(
      animationCurve: animationCurve,
      flickAnimationCurve: flickAnimationCurve,
      controller: controller!,
      distance: DynEquation(
          minSPS: minSPS,
          maxSPS: minFlickSPS,
          lowerValue: lowerDistance,
          upperValue: upperDistance,
          curve: distanceCurve),
      duration: DynEquation(
          minSPS: minSPS,
          maxSPS: minFlickSPS,
          lowerValue: lowerDuration,
          upperValue: upperDuration,
          curve: durationCurve),
      flickDistance: DynEquation(
          minSPS: minFlickSPS,
          maxSPS: maxFlickSPS,
          lowerValue: lowerFlickDistance,
          upperValue: upperFlickDistance,
          curve: flickDistanceCurve),
      flickDuration: DynEquation(
          minSPS: minFlickSPS,
          maxSPS: maxFlickSPS,
          lowerValue: lowerFlickDuration,
          upperValue: upperFlickDuration,
          curve: flickDurationCurve),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ScrollProvider>(
        lazy: false,
        create: (_) => (hasParentListener)
            ? ScrollProvider(controller!,
                st: scrollTranslation,
                phys: context.read<ParentPhysicsProvider>().physics)
            : ScrollProvider(controller!, st: scrollTranslation),
        builder: (context, _) {
          ScrollProvider sp = context.read<ScrollProvider>();

          ScrollPhysics physics;
          dynamic physicsProvider;
          if (hasParentListener) {
            physics = context.select((ParentPhysicsProvider p) => p.physics);
            physicsProvider = context.read<ParentPhysicsProvider>();
          } else {
            physics = context.select((ScrollProvider p) => p.physics);
            physicsProvider = sp;
          }

          return Listener(
              // Mouse user input
              onPointerSignal: (t) {
                // Ensure correct physics
                if (t.kind == PointerDeviceKind.mouse &&
                    physics == kMobilePhysics)
                  physicsProvider.setPhysics(kDesktopPhysics);

                // Animate ScrollProvider's ScrollTranslation
                if (t is PointerScrollEvent)
                  sp.st.animateScroll(t.scrollDelta.dy, t.timeStamp);
              },
              // Touch screen user input
              onPointerDown: (e) {
                // Ensure correct physics
                if (e.kind == PointerDeviceKind.touch &&
                    physics == kDesktopPhysics)
                  physicsProvider.setPhysics(kMobilePhysics);
              },
              child: (builder != null)
                  ? builder!(context, sp.controller, physics)
                  : CustomScrollView(
                      slivers: slivers!,
                      controller: sp.controller,
                      physics: physics));
        });
  }
}

class ParentListener extends StatelessWidget {
  final Widget child;
  const ParentListener({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ParentPhysicsProvider>(
      create: (_) => ParentPhysicsProvider(),
      child: child,
    );
  }
}
