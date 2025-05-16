import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum SlideDirection { leftToRight, rightToLeft, topToBottom, bottomToTop }

class SlideTransitionPage extends CustomTransitionPage<void> {
  SlideTransitionPage({
    required LocalKey super.key,
    required super.child,
    this.slideDirection = SlideDirection.rightToLeft, // Default slide direction
    this.duration = const Duration(milliseconds: 300), // Default duration
    this.reverseDuration, // Optional reverse duration
    this.curve = Curves.easeOutCubic, // Default curve for the transition
  }) : super(
         transitionDuration: duration,
         reverseTransitionDuration: reverseDuration ?? duration,
         transitionsBuilder: (
           BuildContext context,
           Animation<double> animation,
           Animation<double> secondaryAnimation,
           Widget child,
         ) {
           // Define the beginning offset based on the slide direction
           Offset beginOffset;
           switch (slideDirection) {
             case SlideDirection.leftToRight:
               beginOffset = const Offset(-1.0, 0.0);
               break;
             case SlideDirection.rightToLeft:
               beginOffset = const Offset(1.0, 0.0);
               break;
             case SlideDirection.topToBottom:
               beginOffset = const Offset(0.0, -1.0);
               break;
             case SlideDirection.bottomToTop:
               beginOffset = const Offset(0.0, 1.0);
               break;
           }

           // Create a Tween for the Offset
           final Tween<Offset> tween = Tween<Offset>(
             begin: beginOffset,
             end: Offset.zero, // End at the original position
           );

           // Apply the curve to the animation
           // Similar to animation.drive(CurveTween(curve: curve))
           final CurvedAnimation curvedAnimation = CurvedAnimation(
             parent: animation,
             curve: curve,
             reverseCurve:
                 Curves.easeInCubic, // Optional: different curve for reverse
           );

           return SlideTransition(
             position: tween.animate(curvedAnimation),
             child: child,
           );
         },
       );

  final SlideDirection slideDirection;
  final Duration duration;
  final Duration? reverseDuration;
  final Curve curve;

  // You could also keep a static CurveTween if you always want the same curve,
  // but making it a parameter offers more flexibility.
  // static final _curveTween = CurveTween(curve: Curves.easeOutCubic);
}
