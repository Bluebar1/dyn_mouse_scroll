import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

const kMobilePhysics = BouncingScrollPhysics();
const kDesktopPhysics = NeverScrollableScrollPhysics();

class ScrollState with ChangeNotifier {
  final ScrollController controller = ScrollController();
  ScrollPhysics physics = kDesktopPhysics;
  double futurePosition = 0;

  final ScrollPhysics mobilePhysics;
  final int durationMS;

  ScrollState(this.mobilePhysics, this.durationMS);

  void handleDesktopScroll(
      PointerSignalEvent event, int scrollSpeed, Curve animationCurve) {
    // Ensure desktop physics is being used.
    if (physics == kMobilePhysics) {
      physics = kDesktopPhysics;
      notifyListeners();
      return;
    }
    if (event is PointerScrollEvent) {
      // Return if limit is reached in either direction.
      if (controller.position.atEdge) {
        final dy = event.scrollDelta.dy;
        // Return if bounds exceeded.
        if (controller.position.pixels == 0) {
          if (dy < 0) return;
        } else {
          if (dy > 0) return;
        }
      }
      futurePosition += event.scrollDelta.dy * scrollSpeed;

      controller.animateTo(
        futurePosition,
        duration: Duration(milliseconds: durationMS),
        curve: animationCurve,
      );
    }
  }

  void handleTouchScroll(PointerDownEvent event) {
    if (physics == kDesktopPhysics) {
      physics = mobilePhysics;
      notifyListeners();
    }
  }
}
