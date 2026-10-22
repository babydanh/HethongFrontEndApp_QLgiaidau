import 'dart:math' as math;

enum SwissTiebreak {
  buchholz,
  buchholzCut1,
  sonnebornBerger,
  pointDiff,
  wins,
  headToHead,
  seed;

  String get apiValue => switch (this) {
    SwissTiebreak.buchholz => 'BUCHHOLZ',
    SwissTiebreak.buchholzCut1 => 'BUCHHOLZ_CUT1',
    SwissTiebreak.sonnebornBerger => 'SONNEBORN_BERGER',
    SwissTiebreak.pointDiff => 'POINT_DIFF',
    SwissTiebreak.wins => 'WINS',
    SwissTiebreak.headToHead => 'HEAD_TO_HEAD',
    SwissTiebreak.seed => 'SEED',
  };

  static SwissTiebreak? fromApi(String value) => switch (value) {
    'BUCHHOLZ' => SwissTiebreak.buchholz,
    'BUCHHOLZ_CUT1' => SwissTiebreak.buchholzCut1,
    'SONNEBORN_BERGER' => SwissTiebreak.sonnebornBerger,
    'POINT_DIFF' => SwissTiebreak.pointDiff,
    'WINS' => SwissTiebreak.wins,
    'HEAD_TO_HEAD' => SwissTiebreak.headToHead,
    'SEED' => SwissTiebreak.seed,
    _ => null,
  };
}

class SwissConfig {
  const SwissConfig({
    required this.totalRounds,
    required this.tiebreakOrder,
    required this.firstRoundPairing,
  });

  final int totalRounds;
  final List<SwissTiebreak> tiebreakOrder;
  final String firstRoundPairing;

  static const List<SwissTiebreak> defaultTiebreakOrder = [
    SwissTiebreak.buchholz,
    SwissTiebreak.pointDiff,
    SwissTiebreak.headToHead,
    SwissTiebreak.seed,
  ];

  factory SwissConfig.fromJson(Map<String, dynamic> json) {
    final rawOrder = json['tiebreakOrder'];
    final tiebreakOrder = rawOrder is List
        ? rawOrder
              .map((value) => SwissTiebreak.fromApi(value.toString()))
              .whereType<SwissTiebreak>()
              .toList()
        : defaultTiebreakOrder;
    final rawPairing = json['firstRoundPairing'];

    return SwissConfig(
      totalRounds: json['totalRounds'] is num
          ? (json['totalRounds'] as num).toInt()
          : 1,
      tiebreakOrder: tiebreakOrder,
      firstRoundPairing: rawPairing == 'RANDOM' ? 'RANDOM' : 'SEED',
    );
  }

  Map<String, dynamic> toJson() => {
    'totalRounds': totalRounds,
    'tiebreakOrder': tiebreakOrder.map((item) => item.apiValue).toList(),
    'firstRoundPairing': firstRoundPairing,
  };

  static int defaultTotalRounds(int teamCount) =>
      math.max(1, (math.log(teamCount < 1 ? 1 : teamCount) / math.ln2).ceil());
}

class SwissWarning {
  const SwissWarning({
    required this.type,
    required this.participantIds,
    this.round,
    this.gap,
  });

  final String type;
  final List<String> participantIds;
  final int? round;
  final num? gap;

  factory SwissWarning.fromJson(Map<String, dynamic> json) => SwissWarning(
    type: json['type']?.toString() ?? '',
    participantIds: _stringList(json['participantIds']),
    round: _nullableInt(json['round']),
    gap: json['gap'] is num ? json['gap'] as num : null,
  );
}

class SwissError {
  const SwissError({required this.code, required this.participantIds});

  final String code;
  final List<String> participantIds;

  factory SwissError.fromJson(Map<String, dynamic> json) => SwissError(
    code: json['code']?.toString() ?? '',
    participantIds: _stringList(json['participantIds']),
  );
}

class SwissPreviewPair {
  const SwissPreviewPair({
    required this.board,
    required this.participant1Id,
    required this.participant2Id,
  });

  final int board;
  final String participant1Id;
  final String participant2Id;

  factory SwissPreviewPair.fromJson(Map<String, dynamic> json) =>
      SwissPreviewPair(
        board: _int(json['board']),
        participant1Id: json['participant1Id']?.toString() ?? '',
        participant2Id: json['participant2Id']?.toString() ?? '',
      );
}

class SwissPreviewParticipant {
  const SwissPreviewParticipant({
    required this.id,
    required this.teamName,
    this.logoUrl,
    this.seed,
    required this.totalPoints,
    required this.buchholz,
    required this.hadBye,
  });

  final String id;
  final String teamName;
  final String? logoUrl;
  final int? seed;
  final num totalPoints;
  final num buchholz;
  final bool hadBye;

  factory SwissPreviewParticipant.fromJson(Map<String, dynamic> json) =>
      SwissPreviewParticipant(
        id: json['id']?.toString() ?? '',
        teamName: json['teamName']?.toString() ?? '',
        logoUrl: json['logoUrl']?.toString(),
        seed: _nullableInt(json['seed']),
        totalPoints: _number(json['totalPoints']),
        buchholz: _number(json['buchholz']),
        hadBye: json['hadBye'] == true,
      );
}

class SwissPreview {
  const SwissPreview({
    required this.roundNumber,
    required this.totalRounds,
    required this.pairs,
    required this.byeParticipantId,
    required this.sitOutParticipantIds,
    required this.participants,
    required this.warnings,
  });

  final int roundNumber;
  final int totalRounds;
  final List<SwissPreviewPair> pairs;
  final String? byeParticipantId;
  final List<String> sitOutParticipantIds;
  final List<SwissPreviewParticipant> participants;
  final List<SwissWarning> warnings;

  factory SwissPreview.fromJson(Map<String, dynamic> json) => SwissPreview(
    roundNumber: _int(json['roundNumber']),
    totalRounds: _int(json['totalRounds']),
    pairs: _objectList(json['pairs'], SwissPreviewPair.fromJson),
    byeParticipantId: json['byeParticipantId']?.toString(),
    sitOutParticipantIds: _stringList(json['sitOutParticipantIds']),
    participants: _objectList(
      json['participants'],
      SwissPreviewParticipant.fromJson,
    ),
    warnings: _objectList(json['warnings'], SwissWarning.fromJson),
  );
}

class SwissValidateResult {
  const SwissValidateResult({
    required this.valid,
    required this.errors,
    required this.warnings,
  });

  final bool valid;
  final List<SwissError> errors;
  final List<SwissWarning> warnings;

  factory SwissValidateResult.fromJson(Map<String, dynamic> json) =>
      SwissValidateResult(
        valid: json['valid'] == true,
        errors: _objectList(json['errors'], SwissError.fromJson),
        warnings: _objectList(json['warnings'], SwissWarning.fromJson),
      );
}

class SwissNextRoundResult {
  const SwissNextRoundResult({
    required this.roundNumber,
    required this.matchIds,
  });

  final int roundNumber;
  final List<String> matchIds;

  factory SwissNextRoundResult.fromJson(Map<String, dynamic> json) =>
      SwissNextRoundResult(
        roundNumber: _int(json['roundNumber']),
        matchIds: _stringList(json['matchIds']),
      );
}

class SwissStageInfo {
  const SwissStageInfo({
    required this.stageId,
    required this.config,
    this.rawRoundConfig = const {},
    this.hasTotalRounds = true,
  });

  final String stageId;
  final SwissConfig config;

  /// The stage's whole `roundConfig` as sent by the server. The Backend
  /// replaces `roundConfig` on PATCH, so a save must send every key back.
  final Map<String, dynamic> rawRoundConfig;

  /// False when the server sent no `swiss.totalRounds`; [config] then holds a
  /// placeholder 1 that must not be shown or used as the real round count.
  final bool hasTotalRounds;

  int? get totalRounds => hasTotalRounds ? config.totalRounds : null;

  factory SwissStageInfo.fromJson(Map<String, dynamic> json) {
    final roundConfig = _map(json['roundConfig']);
    final swiss = _map(roundConfig['swiss']);
    return SwissStageInfo(
      stageId: json['id']?.toString() ?? '',
      config: SwissConfig.fromJson(swiss),
      rawRoundConfig: roundConfig,
      hasTotalRounds: swiss['totalRounds'] is num,
    );
  }
}

/// Valid team count of a division: `_count.participants` of
/// `GET /tournaments/:id/divisions`; 0 when the response does not carry it.
int swissDivisionTeamCount(Map<String, dynamic> division) {
  final counts = division['_count'];
  final count = counts is Map ? counts['participants'] : null;
  return count is num ? count.toInt() : 0;
}

/// A saved `roundConfig.swiss` with the contract defaults for what is missing
/// (the round count defaults to ceil(log2(teams)), never below [minPlayed]).
SwissConfig swissConfigOrDefault(Object? raw, int teamCount, int minPlayed) {
  final json = raw is Map
      ? Map<String, dynamic>.from(raw)
      : <String, dynamic>{};
  final saved = SwissConfig.fromJson(json);
  return SwissConfig(
    totalRounds: json['totalRounds'] is num
        ? saved.totalRounds
        : math.max(minPlayed, SwissConfig.defaultTotalRounds(teamCount)),
    tiebreakOrder: json['tiebreakOrder'] is List
        ? saved.tiebreakOrder
        : SwissConfig.defaultTiebreakOrder,
    firstRoundPairing: saved.firstRoundPairing,
  );
}

/// What a Swiss config save must send: [divisionPayload] for
/// `updateDivisionConfig` (null = skip) and [stageRoundConfig] for
/// `updateStageRoundConfig` (null = skip).
class SwissSavePlan {
  const SwissSavePlan({this.divisionPayload, this.stageRoundConfig});

  final Map<String, dynamic>? divisionPayload;
  final Map<String, dynamic>? stageRoundConfig;
}

/// Once the bracket exists the Backend refuses division config edits, so only
/// the stage is patched (with the stage's other `roundConfig` keys kept).
/// Before the bracket, the config rides in the division payload.
/// [omitTotalRounds] leaves `totalRounds` out so the Backend derives it.
SwissSavePlan planSwissSave({
  required Map<String, dynamic> basePayload,
  required Map<String, dynamic>? divisionRoundConfig,
  required SwissConfig? swiss,
  required SwissStageInfo? stage,
  bool omitTotalRounds = false,
}) {
  if (swiss == null) return SwissSavePlan(divisionPayload: basePayload);
  final swissJson = swiss.toJson();
  if (omitTotalRounds) swissJson.remove('totalRounds');

  if (stage != null) {
    final rawSwiss = stage.rawRoundConfig['swiss'];
    return SwissSavePlan(
      stageRoundConfig: {
        ...stage.rawRoundConfig,
        'swiss': {if (rawSwiss is Map) ...rawSwiss, ...swissJson},
      },
    );
  }
  final rawSwiss = divisionRoundConfig?['swiss'];
  return SwissSavePlan(
    divisionPayload: {
      ...basePayload,
      'isConfigOverride': true,
      'roundConfig': {
        ...?divisionRoundConfig,
        'swiss': {if (rawSwiss is Map) ...rawSwiss, ...swissJson},
      },
    },
  );
}

class SwissRoundDraftRequest {
  const SwissRoundDraftRequest({
    required this.divisionId,
    this.stageId,
    required this.pairs,
    this.byeParticipantId,
    this.sitOutParticipantIds = const [],
  });

  final String divisionId;
  final String? stageId;
  final List<({String participant1Id, String participant2Id})> pairs;
  final String? byeParticipantId;
  final List<String> sitOutParticipantIds;

  factory SwissRoundDraftRequest.fromJson(Map<String, dynamic> json) =>
      SwissRoundDraftRequest(
        divisionId: json['divisionId']?.toString() ?? '',
        stageId: json['stageId']?.toString(),
        pairs: _objectList(
          json['pairs'],
          (pair) => (
            participant1Id: pair['participant1Id']?.toString() ?? '',
            participant2Id: pair['participant2Id']?.toString() ?? '',
          ),
        ),
        byeParticipantId: json['byeParticipantId']?.toString(),
        sitOutParticipantIds: _stringList(json['sitOutParticipantIds']),
      );

  Map<String, dynamic> toJson({bool confirmWarnings = false}) => {
    'divisionId': divisionId,
    if (stageId != null) 'stageId': stageId,
    'pairs': [
      for (final pair in pairs)
        {
          'participant1Id': pair.participant1Id,
          'participant2Id': pair.participant2Id,
        },
    ],
    'byeParticipantId': byeParticipantId,
    'sitOutParticipantIds': sitOutParticipantIds,
    if (confirmWarnings) 'confirmWarnings': true,
  };
}

class SwissApiException implements Exception {
  const SwissApiException({
    this.status,
    this.code,
    this.warnings = const [],
    this.errors = const [],
    this.message,
  });

  final int? status;
  final String? code;
  final List<SwissWarning> warnings;

  /// `details.errors` of `SWISS_INVALID_PAIRING`.
  final List<SwissError> errors;
  final String? message;

  factory SwissApiException.fromJson(Map<String, dynamic> json) {
    final data = _map(json['data']);
    final details = _map(json['details']);
    final warnings =
        json['warnings'] ?? data['warnings'] ?? details['warnings'];
    final errors = json['errors'] ?? data['errors'] ?? details['errors'];
    return SwissApiException(
      status: _nullableInt(json['statusCode']),
      code: json['code']?.toString() ?? data['code']?.toString(),
      warnings: _objectList(warnings, SwissWarning.fromJson),
      errors: _objectList(errors, SwissError.fromJson),
      message: json['message']?.toString(),
    );
  }
}

int _int(Object? value) => value is num ? value.toInt() : 0;

int? _nullableInt(Object? value) => value is num ? value.toInt() : null;

num _number(Object? value) => value is num ? value : 0;

List<String> _stringList(Object? value) => value is List
    ? [
        for (final item in value)
          if (item != null) item.toString(),
      ]
    : const [];

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

List<T> _objectList<T>(Object? value, T Function(Map<String, dynamic>) parse) =>
    value is List
    ? [
        for (final item in value)
          if (item is Map) parse(Map<String, dynamic>.from(item)),
      ]
    : const [];
