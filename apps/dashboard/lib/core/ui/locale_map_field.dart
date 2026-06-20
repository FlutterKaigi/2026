import 'package:dashboard/core/ui/outlined_text_form_field.dart';
import 'package:flutter/material.dart';

class LocaleMapField extends StatelessWidget {
  const LocaleMapField({
    super.key,
    required this.label,
    required this.jaController,
    required this.enController,
    this.jaValidator,
    this.enValidator,
  });

  final String label;
  final TextEditingController jaController;
  final TextEditingController enController;
  final FormFieldValidator<String>? jaValidator;
  final FormFieldValidator<String>? enValidator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        OutlinedTextFormField(controller: jaController, labelText: '日本語', validator: jaValidator),
        const SizedBox(height: 8),
        OutlinedTextFormField(controller: enController, labelText: 'English', validator: enValidator),
      ],
    );
  }
}
