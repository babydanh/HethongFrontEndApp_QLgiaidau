import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/social_place.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Up to [_maxItems] directory venues matching [query], shown under a venue
/// name field so people pick an existing venue instead of retyping it.
/// Searching is a convenience: while the query is short, or when the search
/// fails, nothing is shown and typing carries on as before.
class VenueSuggestList extends ConsumerStatefulWidget {
  const VenueSuggestList({
    super.key,
    required this.query,
    required this.onPick,
  });

  final String query;
  final void Function(SocialPlace place) onPick;

  @override
  ConsumerState<VenueSuggestList> createState() => _VenueSuggestListState();
}

class _VenueSuggestListState extends ConsumerState<VenueSuggestList> {
  static const _debounce = Duration(milliseconds: 350);
  static const _minChars = 3;
  static const _maxItems = 5;

  Timer? _timer;
  int _seq = 0; // drops answers that belong to an older query
  List<SocialPlace> _places = const [];

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(VenueSuggestList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) _schedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _schedule() {
    _timer?.cancel();
    final query = widget.query.trim();
    final seq = ++_seq;
    if (query.length < _minChars) {
      _places = const [];
      return;
    }
    _timer = Timer(_debounce, () async {
      List<SocialPlace> found;
      try {
        // Tournaments only need name + region, so unpinned venues are fine here.
        found = await ref
            .read(socialLocationRepositoryProvider)
            .search(query, requirePin: false);
      } catch (_) {
        found = const [];
      }
      if (!mounted || seq != _seq) return;
      setState(() => _places = found.take(_maxItems).toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_places.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: colors.border.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < _places.length; i++) ...[
              if (i > 0) Divider(height: 1, color: colors.borderLight),
              _VenueRow(place: _places[i], onTap: () => widget.onPick(_places[i])),
            ],
          ],
        ),
      ),
    );
  }
}

class _VenueRow extends StatelessWidget {
  const _VenueRow({required this.place, required this.onTap});

  final SocialPlace place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.stadium_outlined,
                size: 18,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          place.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      if (place.isVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified,
                          size: 14,
                          color: AppTheme.primary,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    place.formattedAddress,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
