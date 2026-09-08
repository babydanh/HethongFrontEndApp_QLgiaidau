import 'package:flutter/material.dart';
import '../config/app_constants.dart';

/// Shared delivery for public club media across cards, headers and galleries.
class ClubNetworkImage extends StatelessWidget {
  const ClubNetworkImage(
    this.url, {
    super.key,
    this.fit,
    this.loadingBuilder,
    required this.errorBuilder,
  });

  final String url;
  final BoxFit? fit;
  final ImageLoadingBuilder? loadingBuilder;
  final ImageErrorWidgetBuilder errorBuilder;

  static String deliveryUrl(String url) {
    final source = Uri.tryParse(url);
    if (source == null ||
        source.scheme != 'https' ||
        source.host != 'res.cloudinary.com' ||
        !source.path.contains('/image/upload/') ||
        source.hasQuery ||
        source.pathSegments.any((part) => part.startsWith('s--'))) {
      return url;
    }
    return Uri.parse(AppConstants.appDomain)
        .replace(
          path: '/_next/image',
          queryParameters: {'url': url, 'w': '640', 'q': '75'},
        )
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    final source = url.trim();
    final delivery = deliveryUrl(source);
    Widget render(String target, ImageErrorWidgetBuilder onError) =>
        Image.network(
          target,
          key: ValueKey(target),
          fit: fit,
          loadingBuilder: loadingBuilder,
          frameBuilder: (context, child, frame, synchronous) {
            if (synchronous || frame != null) return child;
            return const Center(
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
          errorBuilder: onError,
        );
    return render(delivery, (context, error, stack) {
      if (delivery == source) return errorBuilder(context, error, stack);
      return render(source, errorBuilder);
    });
  }
}
