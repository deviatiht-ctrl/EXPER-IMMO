import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool light;

  const AppLogo({
    super.key,
    this.size = 44,
    this.showText = true,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.ruby, AppColors.rubyDark],
            ),
            borderRadius: BorderRadius.circular(size * 0.27),
            boxShadow: [
              BoxShadow(
                color: AppColors.ruby.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            Icons.apartment_rounded,
            color: Colors.white,
            size: size * 0.5,
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 12),
          Text(
            'EXPERIMMO',
            style: GoogleFonts.inter(
              fontSize: size * 0.35,
              fontWeight: FontWeight.w700,
              color: light ? Colors.white : AppColors.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ],
    );
  }
}
