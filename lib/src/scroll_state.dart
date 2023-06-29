import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

const kMobilePhysics = BouncingScrollPhysics();
const kDesktopPhysics = NeverScrollableScrollPhysics();

class ScrollState with ChangeNotifier {
  final ScrollController controller = ScrollController();
  ScrollPhysics physics = kMobilePhysics;
  double futurePosition = 0;
  bool updateState = false;

  final ScrollPhysics mobilePhysics;
  final int durationMS;

  bool prevDeltaPositive = false;
  double? lastLock = null;

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
    if (physics == kMobilePhysics || lastLock != null) {
      if (lastLock != null) updateState = !updateState;
      if (event is PointerScrollEvent) {
        double posPixels = controller.position.pixels;
        if ((posPixels == controller.position.minScrollExtent && event.scrollDelta.dy < 0)
            || (posPixels == controller.position.maxScrollExtent &&  event.scrollDelta.dy > 0)) return;
        else physics = kDesktopPhysics;
        bool outOfBounds = posPixels < controller.position.minScrollExtent || posPixels > controller.position.maxScrollExtent;
        double calcDelta = calcMaxDelta(controller, event.scrollDelta.dy);
        if (!outOfBounds) controller.jumpTo(lastLock ?? (posPixels - calcDelta));
        double deltaDelta = calcDelta - event.scrollDelta.dy;
        handlePipelinedScroll = () {
          handlePipelinedScroll = null;
          double currPos = controller.position.pixels;
          double currDelta = event.scrollDelta.dy;
          bool shouldLock = lastLock != null ? (lastLock == currPos) : (posPixels != currPos + deltaDelta && 
            (currPos != controller.position.maxScrollExtent || currDelta < 0) && 
            (currPos != controller.position.minScrollExtent || currDelta > 0));
          //bool shouldLock = lastLock != null ? (lastLock == currPos) : (currPos != posPixels);
          if (!outOfBounds && shouldLock) {
            print("SHOULDLOCK");
            controller.jumpTo(posPixels);
            lastLock = posPixels;
            controller.position.moveTo(posPixels)..whenComplete(() {
              physics = kMobilePhysics;
              notifyListeners();
            });
            return;
          }
          else {
            if (lastLock != null || outOfBounds) 
              controller.jumpTo(lastLock ?? (currPos - calcMaxDelta(controller, currDelta)));
            lastLock = null;
            handleDesktopScroll(event, scrollSpeed, animationCurve, false);
          }
        };
        notifyListeners();
      }
      return;
    }
    else if (event is PointerScrollEvent) {
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
