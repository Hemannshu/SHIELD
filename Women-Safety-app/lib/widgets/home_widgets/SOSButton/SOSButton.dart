import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:title_proj/utils/app_theme.dart';

class SOSButton extends StatefulWidget {
  final Future<void> Function() onPressed;

  const SOSButton({super.key, required this.onPressed});

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton> {
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: GestureDetector(
        onTap: _isSending
            ? null
            : () async {
                setState(() => _isSending = true);
                try {
                  await widget.onPressed();
                } finally {
                  if (mounted) setState(() => _isSending = false);
                }
              },
        child: Container(
          width: MediaQuery.of(context).size.width * 0.65,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: AppTheme.sosGradient,
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.4),
                blurRadius: 20, offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.sos_rounded, color: Colors.white, size: 22),
                    ),
                    const Spacer(),
                    if (_isSending)
                      const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SOS EMERGENCY',
                      style: GoogleFonts.inter(
                        color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('Press for immediate help',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.8), fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
