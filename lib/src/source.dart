import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'scroll_state.dart';

class DynMouseScroll extends StatelessWidget {
  final ScrollPhysics mobilePhysics;
  final int durationMS;
  final int scrollSpeed;
  final Curve animationCurve;
  final Function(BuildContext, ScrollController, ScrollPhysics) builder;

  const DynMouseScroll({
    super.key,
    this.mobilePhysics = kMobilePhysics,
    this.durationMS = 200,
    this.scrollSpeed = 1,
    this.animationCurve = Curves.linear,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ScrollState>(
        create: (context) => ScrollState(mobilePhysics, durationMS),
        builder: (context, _) {
          final scrollState = context.read<ScrollState>();
          final controller = scrollState.controller;
          final physics = context.select((ScrollState s) => s.physics);
          return Listener(
            onPointerSignal: (signalEvent) => scrollState.handleDesktopScroll(
                signalEvent, scrollSpeed, animationCurve),
            onPointerDown: scrollState.handleTouchScroll,
            child: builder(context, controller, physics),
          );
        });
  }
}
