/// Result of POST /social-sessions/:id/bracket.
class SocialBracketResult {
  final String tournamentId;
  final String bracketType;
  final String matchType;
  final int participantCount;

  const SocialBracketResult({
    required this.tournamentId,
    required this.bracketType,
    required this.matchType,
    required this.participantCount,
  });

  factory SocialBracketResult.fromJson(Map<String, dynamic> json) {
    final tournamentId = json['tournamentId']?.toString();
    if (tournamentId == null || tournamentId.isEmpty) {
      throw const FormatException('Bracket response has no tournamentId');
    }
    return SocialBracketResult(
      tournamentId: tournamentId,
      bracketType: json['bracketType']?.toString() ?? '',
      matchType: json['matchType']?.toString() ?? '',
      participantCount: (json['participantCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// 409 SOCIAL_BRACKET_EXISTS: the session already has a bracket; open that one.
class SocialBracketExistsException implements Exception {
  final String tournamentId;

  const SocialBracketExistsException(this.tournamentId);

  @override
  String toString() => 'SocialBracketExistsException($tournamentId)';
}
