import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:title_proj/utils/app_theme.dart';

class SecondaryButton extends StatelessWidget {
  final String title;
  final Function onPressed;

  const SecondaryButton(
      {Key? key, required this.title, required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => onPressed(),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isDark ? Colors.white24 : AppTheme.neutralGrey300,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : AppTheme.neutralGrey700,
          ),
        ),
      ),
    );
  }
}