import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// URL veya asset path'i destekleyen Image widget'ı
/// Panelden yüklenen görseller Supabase Storage URL'si olarak gelir,
/// yerel asset'ler ise asset path olarak kalır
Widget buildImage(String? imagePath, {
  BoxFit fit = BoxFit.cover,
  Widget? errorWidget,
  double? width,
  double? height,
}) {
  if (imagePath == null || imagePath.isEmpty) {
    return errorWidget ?? const SizedBox.shrink();
  }
  
  // URL ise (http/https ile başlıyorsa) Image.network kullan
  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    return Image.network(
      imagePath,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? Container(
          color: AppTheme.inputBackground,
          child: const Icon(
            Icons.image,
            size: 60,
            color: AppTheme.iconSecondary,
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: AppTheme.inputBackground,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
    );
  }
  
  // Asset path ise Image.asset kullan
  return Image.asset(
    imagePath,
    fit: fit,
    width: width,
    height: height,
    errorBuilder: (context, error, stackTrace) {
      return errorWidget ?? Container(
        color: AppTheme.inputBackground,
        child: const Icon(
          Icons.image,
          size: 60,
          color: AppTheme.iconSecondary,
        ),
      );
    },
  );
}


