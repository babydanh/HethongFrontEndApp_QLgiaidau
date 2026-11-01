import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// One plain chat row for the landscape overlay (system rows are excluded).
class LiveChatLine {
  const LiveChatLine({required this.id, required this.name, required this.text});

  final String id;
  final String name;
  final String text;
}

/// Transparent chat drawn over the right side of the video in landscape.
/// [lines] is newest-first, like the portrait chat feed.
class LiveLandscapeChat extends StatelessWidget {
  const LiveLandscapeChat({
    super.key,
    required this.lines,
    required this.canPost,
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.onCheer,
    required this.onLogin,
  });

  static const _maxLines = 30;

  final List<LiveChatLine> lines;
  final bool canPost;
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onCheer;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final width = (MediaQuery.of(context).size.width * 0.34).clamp(220.0, 340.0);
    final shown = lines.take(_maxLines).toList();

    return Positioned(
      top: 56,
      right: 0,
      bottom: 0,
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [Colors.black.withValues(alpha: 0.55), Colors.transparent],
          ),
        ),
        child: SafeArea(
          top: false,
          left: false,
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(24, 8, 12, 8),
                  itemCount: shown.length,
                  itemBuilder: (_, i) => _Line(line: shown[i]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: canPost
                          ? TextField(
                              controller: controller,
                              enabled: !sending,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              decoration: InputDecoration(
                                hintText: l10n.liveCommentHint,
                                hintStyle: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 13,
                                ),
                                isDense: true,
                                filled: true,
                                fillColor: Colors.black38,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(99),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onSubmitted: (_) => onSend(),
                            )
                          : Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: onLogin,
                                child: Text(l10n.liveLogin),
                              ),
                            ),
                    ),
                    IconButton(
                      onPressed: onCheer,
                      icon: const Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFFE11D48),
                      ),
                    ),
                    if (canPost)
                      IconButton(
                        onPressed: sending ? null : onSend,
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.line});

  final LiveChatLine line;

  @override
  Widget build(BuildContext context) {
    const shadow = [Shadow(blurRadius: 3, color: Colors.black87)];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${line.name}  ',
              style: const TextStyle(
                color: Color(0xFF93C5FD),
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: line.text,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        style: const TextStyle(fontSize: 13, shadows: shadow),
      ),
    );
  }
}
