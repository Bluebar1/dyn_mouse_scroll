# Dynamic Mouse Scroll
A wrapper for scrollable widgets that enables smooth scrolling with a mouse on all platforms.

<img src="https://raw.githubusercontent.com/Bluebar1/dyn_mouse_scroll/main/assets/scrolling.gif" width="200" height="350"/>

## Features
* Animate smooth scroll based on speed of user's scroll.
* Uses [universal_io](https://pub.dev/packages/universal_io) to detect if platform is mobile or desktop.
* Automatically detect if the wrong ScrollPhysics is being used and update using [provider](https://pub.dev/packages/provider).
* If you are using multiple scrolling widgets, wrap one ParentListener around your app to ensure all are using the same physics.
* Fully adjust the distance and duration of your scroll events.

## Problem:
Flutter does not animate smooth scrolls for pointers, causing choppy experiences for the end user.
One package, [web_smooth_scroll](https://pub.dev/packages/web_smooth_scroll), attempts to fix this problem
by disabling default scrolling entirely (mobile can't drag now) and listening for pointer events to animate
the scroll controller that can only move at one speed. 

## Solution:
To allow mobile default scrolling to still be accessible I detect the user's platform
and automatically update if the detection was wrong. To animate the scroll at the users scroll speed
I first calculate SPS (scrolls per second) and pass that value into an equation. As the user scrolls
faster, each scroll animation's distance increaes and duration decreases.

When the user is scrolling very quickly (60+ SPS), a flick scroll event will be triggered. The distance 
and duration of this animation will be much larger than the non-flick animations. While a flick animation is
active scroll events in the same direction are ignored, opposite direction cancels (stops) the scroll animation.


## Basic Usage
* Providing children will automatically wrap them as slivers.
```dart
DynMouseScroll(children: List<Widget>)
```
* Providing the widgets as slivers will not wrap them.
```dart
DynMouseScroll(slivers: List<Widget>)
```
* Or if you want full control of your children widgets use builder.
```dart
DynMouseScroll(
  builder: (context, controller, physics) => MyScrollableWidget(
    controller: controller,
    physics: physics))
```
* To link the ScrollPhysics of multiple DynMouseScroll Widgets, wrap them in a SINGLE ParentListener and set hasParentListener to true.
```dart
ParentListener(
  child: Row(children: [
    DynMouseScroll(hasParentListener: true, children: ...),
    DynMouseScroll(hasParentListener: true, children: ...),
  ]))
```
## Tuning
Normal and flick scroll events each have their own distance and duration equation values.
Each equation has min/max SPS values. By default these values are:
* Normal scroll event: 1 -> 60
* Flick scroll event: 60 -> 200  
### Upper and lower bounds of distance/duration
Each equation also has lower and upper Y values than can be either distance or duration.
The 'lower' value corresponds to the minSPS X value (left side), make this greater than 'upper' for negative slope.
For example, because I want duration to decrease as speed increases, I will make lowerValue > upperValue.
* SPS 1 (lower)                     = Distance:80, Duration:120
* SPS 59 (normal upper bound)       = Distance:200, Duration:80
* SPS 60 (flick lower bound)        = Distance:400, Duraton:500
* SPS 60+ (incr dist, decr dur)     = Distance:400+, Duration: 500-



## Additional information
#### How distance and duration values are calulated:
```dart
double val(double x) => Tween<double>(begin: lowerValue, end: upperValue)
      .transform(curve.transform(x / maxSPS));
```

