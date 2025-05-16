import 'package:app/utils/command.dart';
import 'package:flutter/material.dart';

class ListenableButton extends StatelessWidget {
  const ListenableButton({
    super.key,
    required this.label,
    required this.command,
    required this.onPressed,
  });

  final String label;
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
                  ? const Padding(
                    padding: EdgeInsets.only(right: 4.0),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2.0),
                    ),
                  )
                  : const Icon(Icons.check_circle_outline),
          label: Padding(padding: EdgeInsets.all(8.0), child: Text(label)),
          onPressed: isLoading ? null : onPressed,
        );
      },
    );
  }
}
