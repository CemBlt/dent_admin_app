import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/image_widget.dart';

class HospitalLogo extends StatelessWidget {
  const HospitalLogo({
    super.key,
    required this.imageUrl,
    this.size = 64,
  });

  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: AppTheme.dividerLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.18),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? buildImage(
              imageUrl,
              fit: BoxFit.contain,
              errorWidget: _fallbackLogo(),
            )
          : _fallbackLogo(),
    );
  }

  Widget _fallbackLogo() {
    return AppLogo(
      size: size * 0.75,
      withBackground: false,
      fallbackIconColor: AppTheme.tealBlue,
    );
  }
}

