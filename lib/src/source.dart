import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'scroll_state.dart';
import 'scroll_translation.dart';

const kMobilePhysics = BouncingScrollPhysics();
const kDesktopPhysics = NeverScrollableScrollPhysics();

class DynMouseScroll extends StatelessWidget {
  /// Optional, where [controller] should set its initial scroll position.
  /// Defaults to 0.
  final double initialOffset;

  /// If providing slivers or widgets does not suit your needs or you need
  /// to access [controller], use:
  ///       builder: (context, controller, physics) => ...
  final Function(BuildContext, ScrollController, ScrollPhysics) builder;

  /// Set to true if [ParentListener] is an ancestor of this widget.
  /// [ParentListener] will automatically update all child [] widgets.
  /// Defaults to false.
  final bool hasParentListener;

  /// Curves applied to animation of [ScrollController.animateTo]
  final Curve animationCurve, flickAnimationCurve;

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

  /// Curves applied to [DynEquation.val]. Changes the output of to
  /// match a given [Curve].
  /// The default for each is [Curves.linear] and should only be changed for
  /// fine-tuning.
  /// WARNING Do not use any [Curve] that exceeds the bounds of [0,1]
  /// such as [Curves.easeInOutBack]  <--- do not use
  final Curve distanceCurve,
      durationCurve,
      flickDistanceCurve,
      flickDurationCurve;

  /// Total SPS (normal and flick)
  ///     min default: 1
  ///     max default: 200
  final double minSPS, maxFlickSPS;

  const DynMouseScroll({
    Key? key,
    required this.builder,
    this.hasParentListener = false,
    this.initialOffset = 0,
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
    this.distanceCurve = Curves.linear,
    this.durationCurve = Curves.linear,
    this.flickDistanceCurve = Curves.linear,
    this.flickDurationCurve = Curves.linear,
    this.minSPS = 1,
    this.maxFlickSPS = 200,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ScrollController controller =
        ScrollController(initialScrollOffset: initialOffset);

    ScrollTranslation scrollTranslation = ScrollTranslation(
      animationCurve: animationCurve,
      flickAnimationCurve: flickAnimationCurve,
      controller: controller,
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

    return ChangeNotifierProvider<ScrollProvider>(
        lazy: false,
        create: (_) => (hasParentListener)
            ? ScrollProvider(scrollTranslation,
                phys: context.read<ParentPhysicsProvider>().physics)
            : ScrollProvider(scrollTranslation),
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
                    physics == kMobilePhysics) {
                  physicsProvider.setPhysics(kDesktopPhysics);
                }

                // Animate ScrollProvider's ScrollTranslation
                if (t is PointerScrollEvent) {
                  sp.st.animateScroll(t.scrollDelta.dy, t.timeStamp);
                }
              },
              // Touch screen user input
              onPointerDown: (e) {
                // Ensure correct physics
                if (e.kind == PointerDeviceKind.touch &&
                    physics == kDesktopPhysics) {
                  physicsProvider.setPhysics(kMobilePhysics);
                }
              },
              child: builder(context, controller, physics));
        });
  }
}

class ParentListener extends StatelessWidget {
  final Widget child;
  const ParentListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ParentPhysicsProvider>(
      create: (_) => ParentPhysicsProvider(),
      child: child,
    );
  }
}
