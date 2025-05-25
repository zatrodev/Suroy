import 'package:app/utils/command.dart';
import 'package:flutter/material.dart';

class ListenableButton extends StatelessWidget {
  const ListenableButton({
    super.key,
    required this.label,
    this.icon,
    this.buttonStyle,
    this.loadingIconColor,
    required this.command,
    required this.onPressed,
  });

  final String label;
  final IconData? icon;
  final ButtonStyle? buttonStyle;
  final Color? loadingIconColor;
  final Command command;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: command,
      builder: (context, _) {
        final bool isLoading = command.running;
        return FilledButton.icon(
          icon:
              isLoading
                  ? Padding(
                    padding: EdgeInsets.only(right: 4.0),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: loadingIconColor,
                      ),
                    ),
                  )
                  : icon != null
                  ? Icon(icon)
                  : SizedBox.shrink(),
          label: Padding(padding: EdgeInsets.all(8.0), child: Text(label)),
          style: buttonStyle,
          onPressed: isLoading ? null : onPressed,
        );
      },
    );
  }
}
