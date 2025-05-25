import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TextFieldWithLabel extends StatefulWidget {
  const TextFieldWithLabel({
    super.key,
    required this.label,
    required this.textFieldLabel,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmit,
    this.isPasswordType = false,
    this.suffixIcon,
    this.focusNode,
  });

  final String label;
  final String textFieldLabel;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmit;
  final bool obscureText;
  final bool isPasswordType;
  final Widget? suffixIcon;

  @override
  State<TextFieldWithLabel> createState() => _TextFieldWithLabelState();
}

class _TextFieldWithLabelState extends State<TextFieldWithLabel> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isObscured = !_isObscured;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget? effectiveSuffixIcon = widget.suffixIcon;
    if (effectiveSuffixIcon == null && widget.isPasswordType) {
      effectiveSuffixIcon = IconButton(
        icon: Icon(
          _isObscured ? Icons.visibility_off : Icons.visibility,
          color: Theme.of(context).colorScheme.outline,
        ),
        onPressed: _togglePasswordVisibility,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        TextFormField(
          decoration: InputDecoration(
            hintStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            hintText: widget.textFieldLabel,
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
            suffixIcon: effectiveSuffixIcon,
          ),
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          controller: widget.controller,
          validator: widget.validator,
          focusNode: widget.focusNode,
          obscureText: _isObscured,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmit,
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
      ],
    );
  }
}
