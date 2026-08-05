import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Displays network images with a project-wide loading policy.
///
/// Web builds prefer an HTML image element so that public images hosted on
/// origins without CORS headers remain displayable. Other platforms keep using
/// [CachedNetworkImageProvider] for native image caching.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.placeholderBuilder,
    this.errorBuilder,
    this.webHtmlElementStrategy = WebHtmlElementStrategy.prefer,
    super.key,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final AlignmentGeometry alignment;
  final WidgetBuilder? placeholderBuilder;
  final ImageErrorWidgetBuilder? errorBuilder;
  final WebHtmlElementStrategy webHtmlElementStrategy;

  @override
  Widget build(BuildContext context) {
    return Image(
      image: _imageProvider,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      frameBuilder: placeholderBuilder == null
          ? null
          : (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded || frame != null) {
                return child;
              }
              return placeholderBuilder!(context);
            },
      errorBuilder: errorBuilder,
    );
  }

  ImageProvider<Object> get _imageProvider {
    if (kIsWeb) {
      return NetworkImage(
        imageUrl,
        webHtmlElementStrategy: webHtmlElementStrategy,
      );
    }
    return CachedNetworkImageProvider(imageUrl);
  }
}

/// Circular network image that follows [AppNetworkImage]'s loading policy.
class AppNetworkAvatar extends StatelessWidget {
  const AppNetworkAvatar({
    required this.imageUrl,
    this.radius,
    this.fallback,
    this.backgroundColor,
    super.key,
  });

  final String? imageUrl;
  final double? radius;
  final Widget? fallback;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final normalizedImageUrl = imageUrl?.trim();
    final hasImage = normalizedImageUrl != null && normalizedImageUrl.isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: hasImage
          ? ClipOval(
              child: SizedBox.expand(
                child: AppNetworkImage(
                  imageUrl: normalizedImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => fallback ?? const SizedBox.shrink(),
                ),
              ),
            )
          : fallback,
    );
  }
}
