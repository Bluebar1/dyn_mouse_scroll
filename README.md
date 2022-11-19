# Dynamic Mouse Scroll
A wrapper for scrollable widgets that enables smooth scrolling with a mouse on all platforms.

First gif: Scrolling slowly.  
Second gif: Scrolling quickly (flick scroll).   
Third gif: Mobile drag scroll detected, physics change.  
<p float="left">
  <img src="https://raw.githubusercontent.com/Bluebar1/dyn_mouse_scroll/main/assets/slow_scroll.gif" width="200" height="350"/>
  <img src="https://raw.githubusercontent.com/Bluebar1/dyn_mouse_scroll/main/assets/fast_scroll.gif" width="200" height="350"/>
  <img src="https://raw.githubusercontent.com/Bluebar1/dyn_mouse_scroll/main/assets/drag_scroll.gif" width="200" height="350"/>
</p>

## Features
* Animate smooth scroll based on speed of user's scroll.
* Uses [universal_io](https://pub.dev/packages/universal_io) to detect if platform is mobile or desktop.
* Automatically detect if the wrong ScrollPhysics is being used and update using [provider](https://pub.dev/packages/provider).
* Adjust the duration of your scroll events.
* Choose what mobile physics you would like to use.
## Basic Usage
```dart
DynMouseScroll(
  builder: (context, controller, physics) => ListView(
    controller: controller,
    physics: physics,
    children: ...
    )
)
```

## Problem:
Flutter does not animate smooth scrolls for pointers, causing choppy experiences for the end user.
One package, [web_smooth_scroll](https://pub.dev/packages/web_smooth_scroll), attempts to fix this problem
by disabling default scrolling entirely (mobile can't drag now) and listening for pointer events to animate
the scroll controller that can only move at one speed. 

## Solution:
To allow mobile default scrolling to still be accessible I detect the user's platform
and automatically update if the detection was wrong. When the user scrolls, the 'futurePosition'
variable is updated and the animation is started.

