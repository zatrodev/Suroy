import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TextFieldWithLabel extends StatelessWidget {
  const TextFieldWithLabel({
    super.key,
    required this.label,
    required this.textFieldLabel,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
  });

  final String label;
  final String textFieldLabel;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        TextFormField(
          decoration: InputDecoration(
            hintStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            hintText: textFieldLabel,
            border: OutlineInputBorder(),
          ),
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          controller: controller,
          validator: validator,
          obscureText: obscureText,
        ),
      ],
    );
  }
}
