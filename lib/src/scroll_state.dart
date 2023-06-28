import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

const kMobilePhysics = BouncingScrollPhysics();
const kDesktopPhysics = NeverScrollableScrollPhysics();

class ScrollState with ChangeNotifier {
  final ScrollController controller = ScrollController();
  ScrollPhysics physics = kMobilePhysics;
  double futurePosition = 0;

  final ScrollPhysics mobilePhysics;
  final int durationMS;

  bool prevDeltaPositive = false;

  Future<void>? _animationEnd;

  Function()? handlePipelinedScroll;

  ScrollState(this.mobilePhysics, this.durationMS);

  static double calcMaxDelta(ScrollController controller, double delta) {
    return delta > 0 ? 
      math.min(controller.position.pixels + delta, controller.position.maxScrollExtent) - controller.position.pixels :
      math.max(controller.position.pixels + delta, controller.position.minScrollExtent) - controller.position.pixels;
  }

  void handleDesktopScroll(
      PointerSignalEvent event, int scrollSpeed, Curve animationCurve, [bool readLastDirection = true]) {
    // Ensure desktop physics is being used.
    if (physics == kMobilePhysics) {
      physics = kDesktopPhysics;
      if (event is PointerScrollEvent) {
        bool outOfBounds = controller.position.pixels < controller.position.minScrollExtent || controller.position.pixels > controller.position.maxScrollExtent;
        if (!outOfBounds) controller.jumpTo(controller.position.pixels - calcMaxDelta(controller, event.scrollDelta.dy));
        handlePipelinedScroll = () {
          handlePipelinedScroll = null;
          if (outOfBounds) controller.jumpTo(controller.position.pixels - calcMaxDelta(controller, event.scrollDelta.dy));
          handleDesktopScroll(event, scrollSpeed, animationCurve, false);
        };
      }
      notifyListeners();
      return;
    }
    if (event is PointerScrollEvent) {
      bool currentDeltaPositive = event.scrollDelta.dy > 0;
      if (readLastDirection && currentDeltaPositive == prevDeltaPositive)
        futurePosition += event.scrollDelta.dy * scrollSpeed;
      else futurePosition = controller.position.pixels + event.scrollDelta.dy * scrollSpeed;
      prevDeltaPositive = event.scrollDelta.dy > 0;
      
      Future<void> animationEnd = _animationEnd = controller.animateTo(
        futurePosition,
        duration: Duration(milliseconds: durationMS),
        curve: animationCurve,
      );
      animationEnd.whenComplete(() {if (animationEnd == _animationEnd && physics == kDesktopPhysics) {
        physics = mobilePhysics;
        notifyListeners();
      }});
    }
  }

  void handleTouchScroll(PointerDownEvent event) {
    if (physics == kDesktopPhysics) {
      physics = mobilePhysics;
      notifyListeners();
    }
  }
}
