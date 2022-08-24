import 'package:flutter/material.dart';

class DynEquation {
  /// X bounds, required min < max
  final double minSPS, maxSPS;

  /// Y left and right values. min > max for negative slope.
  final double lowerValue, upperValue;

  /// Applied to [Tween] in [val]
  final Curve curve;

  DynEquation({
    required this.minSPS,
    required this.maxSPS,
    required this.lowerValue,
    required this.upperValue,
    required this.curve,
  });

  /// Calculate the value of this [DynEquation] at the given X.
  double val(double x) => Tween<double>(begin: lowerValue, end: upperValue)
      .transform(curve.transform(x / (maxSPS - minSPS)));
}

class ScrollTranslation {
  /// Created in [ScrollProvider].
  final ScrollController controller;
  final Curve animationCurve, flickAnimationCurve;

  final DynEquation distance;
  final DynEquation duration;
  final DynEquation flickDistance;
  final DynEquation flickDuration;

  /// Constructor converts [String]s into [MathNode]s to be used in calculations,
  ScrollTranslation(
      {required this.controller,
      required this.animationCurve,
      required this.flickAnimationCurve,
      required this.distance,
      required this.duration,
      required this.flickDistance,
      required this.flickDuration});

  /// Static member variables track current state of scrolling
  static double sps = 0; // Scrolls per Second
  static Duration lastTimeStamp = const Duration(milliseconds: 0);
  static bool isAnimating = false;
  static AxisDirection direction = AxisDirection.down;

  void animateScroll(double change, Duration timeStamp) async {
    sps = 1000 / (timeStamp.inMilliseconds - lastTimeStamp.inMilliseconds);

    //limit SPS by upper bound
    if (sps > (flickDistance.maxSPS - flickDistance.minSPS)) {
      sps = (flickDistance.maxSPS - flickDistance.minSPS);
    }

    lastTimeStamp = timeStamp;
    final new_direction = (change > 0) ? AxisDirection.down : AxisDirection.up;

    if (isAnimating && new_direction.name != direction.name) {
      controller.jumpTo(controller.offset);
      return;
    }
    direction = new_direction;
    if (isAnimating) return;
    if (sps < distance.minSPS) {
      sps = distance.minSPS.toDouble();
    } else if (sps > distance.maxSPS) {
      await _startFlickScroll(change);
      return;
    }

    double dist = distance.val(sps) * negate;
    int dur = duration.val(sps).round();

    controller.animateTo(controller.position.pixels + dist,
        duration: Duration(milliseconds: dur), curve: animationCurve);
  }

  Future<void> _startFlickScroll(double change) async {
    // block new scroll events, cancel if direction has changed
    isAnimating = true;

    double dist = flickDistance.val(sps) * negate;
    int dur = flickDuration.val(sps).round();

    await controller.animateTo(controller.position.pixels + dist,
        duration: Duration(milliseconds: dur), curve: flickAnimationCurve);
    // allow new scroll events
    isAnimating = false;

    return;
  }

  static get negate => (direction == AxisDirection.up) ? -1 : 1;
}
