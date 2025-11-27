import 'package:flutter/material.dart';

/// Uygulamanın logo görselini tek bir yerden yöneten widget.
/// Eğer logo asset'i bulunamazsa eski ikonlu görünüm geri düşer.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 54,
    this.withBackground = true,
    this.backgroundOpacity,
    this.fallbackIconColor,
  });

  /// Logo görselinin assets yolu.
  static const String _assetPath = 'assets/images/app_logo.png';

  /// Logo kutusunun genişlik / yüksekliği.
  final double size;

  /// Arkadaki yumuşak arka plan kullanılacak mı.
  final bool withBackground;

  /// Opsiyonel olarak arka planın opaklığını özelleştir.
  final double? backgroundOpacity;

  /// Asset bulunamazsa gösterilecek ikon rengi.
  final Color? fallbackIconColor;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      _assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        Icons.health_and_safety_rounded,
        size: size * 0.65,
        color: fallbackIconColor ?? Colors.white,
      ),
    );

    if (!withBackground) {
      return SizedBox(
        width: size,
        height: size,
        child: image,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(backgroundOpacity ?? 0.2),
        borderRadius: BorderRadius.circular(size * 0.35),
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.18),
        child: image,
      ),
    );
  }
}

