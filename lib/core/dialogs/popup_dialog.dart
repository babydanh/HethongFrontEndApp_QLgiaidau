import 'package:flutter/material.dart';

const _popupDuration = Duration(milliseconds: 260);
const _popupStartScale = 0.9;
const _popupSlideFrom = Offset(0, 0.04);

/// Motion for bottom sheets: a little slower than the Material default so the
/// slide is readable, and quicker on the way out.
const popupSheetAnimation = AnimationStyle(
  duration: Duration(milliseconds: 320),
  reverseDuration: Duration(milliseconds: 200),
  curve: Curves.easeOutCubic,
  reverseCurve: Curves.easeInCubic,
);

/// Drop-in for [showDialog] whose popup fades in, grows from 90% and rises a
/// few pixels, then leaves the same way. With "remove animations" turned on in
/// the system it appears and disappears at once.
Future<T?> showPopupDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  // Same as showDialog: keep the Theme the caller sees.
  final themes = InheritedTheme.capture(from: context, to: navigator.context);
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  return navigator.push<T>(
    RawDialogRoute<T>(
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: reduceMotion ? Duration.zero : _popupDuration,
      pageBuilder: (routeContext, _, _) =>
          themes.wrap(SafeArea(child: Builder(builder: builder))),
      transitionBuilder: (routeContext, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(
              begin: _popupSlideFrom,
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween(begin: _popupStartScale, end: 1.0).animate(curved),
              child: child,
            ),
          ),
        );
      },
    ),
  );
}
