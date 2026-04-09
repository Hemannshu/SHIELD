import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:title_proj/utils/app_theme.dart';

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
  final bool readOnly;

  const CustomTextField({
    Key? key,
    required this.hintText,
    this.prefix,
    this.suffix,
    this.isPassword = false,
    this.controller,
    this.keyboardType,
    this.validator,
    this.onSaved,
    this.maxLines,
    this.readOnly = false, required String prefixText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      readOnly: readOnly,
      maxLines: maxLines,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: isDark ? Colors.white : AppTheme.neutralGrey900,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.inter(fontSize: 14, color: AppTheme.neutralGrey400),
        prefixIcon: prefix,
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? Colors.white12 : AppTheme.neutralGrey200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? Colors.white12 : AppTheme.neutralGrey200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primaryPink, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: isDark ? AppTheme.darkElevated.withOpacity(0.5) : AppTheme.neutralGrey100,
      ),
      validator: validator,
      onSaved: onSaved,
    );
  }
}