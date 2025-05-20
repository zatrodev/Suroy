import 'package:flutter/material.dart';

class AppSnackBar {
  AppSnackBar._();

  static SnackBar show({
    required BuildContext context,
    required Widget content,
    required String type,
    String actionLabel = "Dismiss",
    SnackBarBehavior behavior = SnackBarBehavior.fixed,
    VoidCallback? onPressed,
  }) {
    final Color backgroundColor;
    final Color? contentColor;

    switch (type.toLowerCase()) {
      case "success":
        backgroundColor = Theme.of(context).colorScheme.tertiaryContainer;
        contentColor = Theme.of(context).colorScheme.onTertiaryContainer;
        break;
      case "error":
        backgroundColor = Theme.of(context).colorScheme.errorContainer;
        contentColor = Theme.of(context).colorScheme.onErrorContainer;
        break;
      default:
        backgroundColor = Theme.of(context).colorScheme.surfaceContainer;
        contentColor = Theme.of(context).colorScheme.onSurface;

        break;
    }

    final effectiveContent =
        (content is Text)
            ? Text(
              (content).data!,
              style:
                  (content).style?.copyWith(color: contentColor) ??
                  TextStyle(color: contentColor),
            )
            : content;

    return SnackBar(
      backgroundColor: backgroundColor,
      content: effectiveContent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      behavior: behavior,
      action:
          onPressed != null
              ? SnackBarAction(
                label: actionLabel,
                onPressed: onPressed,
                textColor: contentColor,
              )
              : SnackBarAction(
                label: actionLabel,
                onPressed: () {
                  ScaffoldMessenger.of(context).clearSnackBars();
                },
                textColor: contentColor,
              ),
    );
  }
}
