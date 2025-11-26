import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

/// URL veya asset path'i destekleyen Image widget'ı
/// Panelden yüklenen görseller Supabase Storage URL'si olarak gelir,
/// yerel asset'ler ise asset path olarak kalır
/// 
/// Basitleştirilmiş çözüm: Standart boyutlarda görseller (Doktor: 300x300px, Hastane: 400x300px)
/// - Cache desteği ile hızlı yükleme
/// - FadeIn animasyonu ile smooth geçiş
Widget buildImage(String? imagePath, {
  BoxFit fit = BoxFit.cover,
  Widget? errorWidget,
  double? width,
  double? height,
  double? aspectRatio,
  BorderRadius? borderRadius,
}) {
  if (imagePath == null || imagePath.isEmpty) {
    return errorWidget ?? const SizedBox.shrink();
  }
  
  // Placeholder widget
  final Widget placeholderWidget = Container(
    color: AppTheme.inputFieldGray,
    child: Center(
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.tealBlue.withOpacity(0.5)),
      ),
    ),
  );
  
  // Error widget
  final Widget finalErrorWidget = errorWidget ?? Container(
    color: AppTheme.inputFieldGray,
    child: const Icon(
      Icons.image,
      size: 40,
      color: AppTheme.iconGray,
    ),
  );
  
  // URL ise (http/https ile başlıyorsa) CachedNetworkImage kullan
  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    Widget imageWidget = CachedNetworkImage(
      imageUrl: imagePath,
      fit: fit,
      // Bellek optimizasyonu: 2x çözünürlük yeterli
      memCacheWidth: width != null ? (width * 2).toInt() : null,
      memCacheHeight: height != null ? (height * 2).toInt() : null,
      // FadeIn animasyonu
      fadeInDuration: const Duration(milliseconds: 300),
      fadeInCurve: Curves.easeIn,
      // Placeholder
      placeholder: (context, url) => width != null && height != null
          ? SizedBox(width: width, height: height, child: placeholderWidget)
          : placeholderWidget,
      // Error widget
      errorWidget: (context, url, error) => width != null && height != null
          ? SizedBox(width: width, height: height, child: finalErrorWidget)
          : finalErrorWidget,
      // Cache key
      cacheKey: imagePath,
    );
    
    // BorderRadius ekle
    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius,
        child: imageWidget,
      );
    }
    
    // Width ve height varsa SizedBox ile sınırla
    if (width != null && height != null) {
      return SizedBox(
        width: width,
        height: height,
        child: imageWidget,
      );
    } else if (aspectRatio != null) {
      // Sadece aspectRatio varsa AspectRatio kullan (geriye dönük uyumluluk)
      return AspectRatio(
        aspectRatio: aspectRatio,
        child: imageWidget,
      );
    }
    
    return imageWidget;
  }
  
  // Asset path ise Image.asset kullan (yerel görseller için)
  Widget assetWidget = Image.asset(
    imagePath,
    fit: fit,
    width: width,
    height: height,
    errorBuilder: (context, error, stackTrace) => finalErrorWidget,
  );
  
  // BorderRadius ekle
  if (borderRadius != null) {
    assetWidget = ClipRRect(
      borderRadius: borderRadius,
      child: assetWidget,
    );
  }
  
  // Sadece aspectRatio varsa ve width/height yoksa AspectRatio kullan (geriye dönük uyumluluk)
  if (width == null && height == null && aspectRatio != null) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: assetWidget,
    );
  }
  
  return assetWidget;
}


