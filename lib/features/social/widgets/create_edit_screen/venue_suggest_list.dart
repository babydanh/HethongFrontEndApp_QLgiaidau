import 'dart:async';

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
        found = await ref.read(socialLocationRepositoryProvider).search(query);
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
    return Material(
      type: MaterialType.transparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final place in _places)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                place.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                place.formattedAddress,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => widget.onPick(place),
            ),
        ],
      ),
    );
  }
}
