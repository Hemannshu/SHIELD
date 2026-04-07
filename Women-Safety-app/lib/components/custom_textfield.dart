import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final Widget? prefix;
  final Widget? suffix;
  final bool isPassword;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Function(String?)? onSaved;
  final int? maxLines;
  final bool readOnly; // Add readOnly parameter

  const CustomTextField({
    Key? key,
    required this.hintText,
    this.prefix,
    this.suffix,
    this.isPassword = false,
    this.controller,
    this.keyboardType,
    this.validator, // This is the correct parameter name (validator, not validate)
    this.onSaved,
    this.maxLines,
    this.readOnly = false, required String prefixText, // Default to false
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      readOnly: readOnly, // Pass to TextFormField
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefix,
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      validator: validator, // Use validator (not validate)
      onSaved: onSaved,
      maxLines: maxLines,
    );
  }
}