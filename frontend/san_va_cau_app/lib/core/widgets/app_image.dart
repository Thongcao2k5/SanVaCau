import 'package:flutter/material.dart';

import '../constants/api_config.dart';

class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.source,
    required this.fallback,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
  });

  final String source;
  final Widget fallback;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    if (source.isEmpty) {
      return fallback;
    }

    if (source.startsWith('assets/')) {
      return Image.asset(
        source,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => fallback,
      );
    }

    return Image.network(
      ApiConfig.resolveMediaUrl(source),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}
