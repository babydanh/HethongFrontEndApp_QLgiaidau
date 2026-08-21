import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ChatImageViewer extends StatelessWidget {
  final String imageUrl;
  final String? senderName;
  final DateTime? timestamp;

  const ChatImageViewer({
    super.key,
    required this.imageUrl,
    this.senderName,
    this.timestamp,
  });

  static Future<void> show(
    BuildContext context, {
    required String imageUrl,
    String? senderName,
    DateTime? timestamp,
  }) {
    return Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.95),
        pageBuilder: (ctx, anim, _) => FadeTransition(
          opacity: anim,
          child: ChatImageViewer(
            imageUrl: imageUrl,
            senderName: senderName,
            timestamp: timestamp,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Zoomable & Pannable Image
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              clipBehavior: Clip.none,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
                errorBuilder: (_, error, stackTrace) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.broken_image_rounded,
                        color: Colors.white60,
                        size: 48,
                      ),
                      SizedBox(height: 8),
                      Text(
                        l10n?.chatImageLoadError ?? 'Unable to load image',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Top Header Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                12,
                MediaQuery.of(context).padding.top + 8,
                12,
                12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    tooltip: l10n?.chatImageClose ?? 'Close',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (senderName != null)
                          Text(
                            senderName!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        if (timestamp != null)
                          Text(
                            '${timestamp!.hour.toString().padLeft(2, '0')}:${timestamp!.minute.toString().padLeft(2, '0')} · ${timestamp!.day}/${timestamp!.month}/${timestamp!.year}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
