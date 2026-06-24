import 'package:flutter/material.dart';

class OutlinedTextFormField extends StatelessWidget {
  const OutlinedTextFormField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.validator,
  });

  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: labelText, border: const OutlineInputBorder(), hintText: hintText),
      validator: validator,
    );
  }
}
