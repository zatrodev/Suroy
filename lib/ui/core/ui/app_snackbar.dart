import 'package:flutter/material.dart';

class AppSnackBar {
  AppSnackBar._();

  static SnackBar show({
    required BuildContext context, 
    required Widget content,
    required String type, 
    String actionLabel = "Dismiss", 
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
        backgroundColor = Theme.of(context).snackBarTheme.backgroundColor ?? Colors.grey.shade800;
        contentColor = Theme.of(context).snackBarTheme.contentTextStyle?.color ?? Colors.white;
        
        break;
    }

    
    final effectiveContent = (content is Text)
        ? Text((content).data!, style: (content).style?.copyWith(color: contentColor) ?? TextStyle(color: contentColor))
        : content;

    return SnackBar(
      backgroundColor: backgroundColor,
      content: effectiveContent,
      shape: RoundedRectangleBorder( 
        borderRadius: BorderRadius.circular(8.0),
      ),
      action: onPressed != null
          ? SnackBarAction(
              label: actionLabel,
              onPressed: onPressed,
              
              textColor: contentColor, 
            )
          : null, 
    );
  }
}
