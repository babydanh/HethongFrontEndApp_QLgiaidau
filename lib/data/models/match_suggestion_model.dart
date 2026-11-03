enum SuggestionKind { live, replay }

/// One row of `GET /livestream/matches/{matchId}/suggestions`: a match that is
/// live now or has a recording to replay.
class MatchSuggestion {
  const MatchSuggestion({
    required this.matchId,
    required this.kind,
    required this.tournamentId,
    required this.tournamentName,
    required this.roundLabel,
    required this.team1Name,
    required this.team2Name,
    required this.team1Score,
    required this.team2Score,
    required this.durationSec,
    required this.sameTournament,
  });

  /// Null when the row has no usable match id or an unknown kind.
  static MatchSuggestion? tryParse(Map<String, Object?> json) {
    final matchId = _text(json['matchId']);
    final kind = switch (json['kind']) {
      'LIVE' => SuggestionKind.live,
      'REPLAY' => SuggestionKind.replay,
      _ => null,
    };
    if (matchId == null || kind == null) return null;
    final duration = json['durationSec'];
    return MatchSuggestion(
      matchId: matchId,
      kind: kind,
      tournamentId: _text(json['tournamentId']) ?? '',
      tournamentName: _text(json['tournamentName']) ?? '',
      roundLabel: _text(json['roundLabel']),
      team1Name: _text(json['team1Name']) ?? '',
      team2Name: _text(json['team2Name']) ?? '',
      team1Score: _score(json['team1Score']),
      team2Score: _score(json['team2Score']),
      durationSec: duration is num && duration.isFinite
          ? duration.toInt()
          : null,
      sameTournament: json['sameTournament'] == true,
    );
  }

  final String matchId;
  final SuggestionKind kind;
  final String tournamentId;
  final String tournamentName;
  final String? roundLabel;
  final String team1Name;
  final String team2Name;
  final int team1Score;
  final int team2Score;
  final int? durationSec;
  final bool sameTournament;

  bool get isLive => kind == SuggestionKind.live;
}

/// One page of suggestions; [nextCursor] is null on the last page.
class MatchSuggestionsPage {
  MatchSuggestionsPage({
    required List<MatchSuggestion> items,
    required this.nextCursor,
  }) : items = List<MatchSuggestion>.unmodifiable(items);

  factory MatchSuggestionsPage.fromJson(Map<String, Object?> json) {
    final data = json['data'];
    final items = <MatchSuggestion>[];
    if (data is List) {
      for (final raw in data) {
        if (raw is! Map) continue;
        final item = MatchSuggestion.tryParse({
          for (final e in raw.entries)
            if (e.key is String) e.key as String: e.value,
        });
        if (item != null) items.add(item);
      }
    }
    final meta = json['meta'];
    final cursor = meta is Map && meta['hasMore'] == true
        ? _text(meta['nextCursor'])
        : null;
    return MatchSuggestionsPage(items: items, nextCursor: cursor);
  }

  final List<MatchSuggestion> items;
  final String? nextCursor;
}

String? _text(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

int _score(Object? value) => value is num && value.isFinite ? value.toInt() : 0;
