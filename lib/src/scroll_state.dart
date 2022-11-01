import 'package:flutter/material.dart';
import 'package:universal_io/io.dart';

import '../dyn_mouse_scroll.dart';
import 'scroll_translation.dart';

/// Provides the current physics of the scrollable widget and state of the
/// [ScrollTranslation]. If desktop platform is detected, default scrolling is
/// locked. Mobile devices will be able to scroll normally.
/// If the wrong platform is detected, the [Listener] wrapping
/// [DynMouseScroll.builder] will call the set physics method.
///
class ScrollProvider extends ChangeNotifier {
  final ScrollTranslation st;

  /// Default scroll physics for mobile devices.
  final ScrollPhysics mobileScrollPhysics;

  ScrollProvider(
    this.st, {
    required this.mobileScrollPhysics,
    ScrollPhysics? phys,
  }) {
    // use ParentListener physics if passed
    physics = phys ??=
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
            ? kDesktopPhysics
            : mobileScrollPhysics;
  }

  late ScrollPhysics physics;

  setPhysics(ScrollPhysics physics) {
    this.physics = physics;
    notifyListeners();
  }
}

/// To share physics between multiple scrollable widgets, wrap a single
/// [ParentListener] around a widget that contains multiple [DynMouseScroll] widgets,
/// and set [DynMouseScroll.hasParentListener] to true.
///
/// view example here ::
class ParentPhysicsProvider with ChangeNotifier {
  /// Default scroll physics for mobile devices.
  final ScrollPhysics mobileScrollPhysics;

  ParentPhysicsProvider({required this.mobileScrollPhysics});

  late ScrollPhysics physics =
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
          ? kDesktopPhysics
          : mobileScrollPhysics;

  setPhysics(ScrollPhysics physics) {
    this.physics = physics;
    notifyListeners();
  }
}
