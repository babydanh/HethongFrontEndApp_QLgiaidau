import 'dart:math' as math;

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/swiss.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/sport_rule_presets.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/swiss_config_editor.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_manage_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Nhận dạng: 7 lựa chọn định dạng của Web (match-format-options.ts) ───

/// Đủ 7 lựa chọn nhận dạng Web; không có dữ liệu `categoryConfig` trên App
/// nên luôn hiển thị hết (Web chỉ lọc khi giải có cấu hình hạng mục).
const List<String> divisionFormatOptions = [
  'MALE_SINGLES',
  'FEMALE_SINGLES',
  'OPEN_SINGLES',
  'MALE_DOUBLES',
  'FEMALE_DOUBLES',
  'MIXED_DOUBLES',
  'OPEN_DOUBLES',
];

const List<String> _bracketTypes = [
  'SINGLE_ELIMINATION',
  'DOUBLE_ELIMINATION',
  'ROUND_ROBIN',
  'GROUP_STAGE_KNOCKOUT',
  'SWISS',
];

/// Port `MATCH_FORMAT_API_MAPPING`: lựa chọn UI → cặp lưu DB
/// (`OPEN_DOUBLES` là sentinel UI, lưu thành DOUBLES không giới hạn giới tính).
({String matchType, String? genderRestriction}) matchFormatApiMapping(
  String option,
) => switch (option) {
  'MALE_SINGLES' => (matchType: 'SINGLES', genderRestriction: 'MALE'),
  'FEMALE_SINGLES' => (matchType: 'SINGLES', genderRestriction: 'FEMALE'),
  'OPEN_SINGLES' => (matchType: 'SINGLES', genderRestriction: null),
  'MALE_DOUBLES' => (matchType: 'DOUBLES', genderRestriction: 'MALE'),
  'FEMALE_DOUBLES' => (matchType: 'DOUBLES', genderRestriction: 'FEMALE'),
  'MIXED_DOUBLES' => (matchType: 'MIXED_DOUBLES', genderRestriction: 'MIXED'),
  _ => (matchType: 'DOUBLES', genderRestriction: null),
};

/// Port `getMatchFormatOptionFromDivision`: ngược lại, từ trường đã lưu.
String matchFormatOptionFromDivision(
  String? matchType,
  String? genderRestriction,
) {
  final type = matchType?.toUpperCase() ?? '';
  final gender = genderRestriction?.toUpperCase();
  if (type == 'MIXED_DOUBLES' || gender == 'MIXED') return 'MIXED_DOUBLES';
  if (type == 'SINGLES') {
    if (gender == 'FEMALE') return 'FEMALE_SINGLES';
    if (gender == 'MALE') return 'MALE_SINGLES';
    return 'OPEN_SINGLES';
  }
  if (gender == 'MALE') return 'MALE_DOUBLES';
  if (gender == 'FEMALE') return 'FEMALE_DOUBLES';
  return 'OPEN_DOUBLES';
}

/// Chọn định dạng mặc định khi tạo mới, suy từ định dạng của giải
/// (`format` App là slug như `men_doubles`, có thể là `singles` thuần).
String matchFormatOptionFromTournament(Tournament tournament) {
  final format = tournament.format.toUpperCase().replaceAll(' ', '_');
  final gender = tournament.genderRestriction?.toUpperCase();
  return switch (format) {
    'MEN_SINGLES' || 'MALE_SINGLES' => 'MALE_SINGLES',
    'WOMEN_SINGLES' || 'FEMALE_SINGLES' => 'FEMALE_SINGLES',
    'SINGLES' =>
      gender == 'MALE'
          ? 'MALE_SINGLES'
          : gender == 'FEMALE'
          ? 'FEMALE_SINGLES'
          : 'OPEN_SINGLES',
    'MEN_DOUBLES' || 'MALE_DOUBLES' => 'MALE_DOUBLES',
    'WOMEN_DOUBLES' || 'FEMALE_DOUBLES' => 'FEMALE_DOUBLES',
    'MIXED_DOUBLES' => 'MIXED_DOUBLES',
    _ =>
      gender == 'MALE'
          ? 'MALE_DOUBLES'
          : gender == 'FEMALE'
          ? 'FEMALE_DOUBLES'
          : 'OPEN_DOUBLES',
  };
}

// ─── Lệ phí riêng (port registration-fee.ts) ───

/// Giá trị khởi tạo ô phí: phí riêng nội dung khi bật override, không thì phí giải.
String divisionFeeInputValue(
  Map<String, dynamic>? division,
  double? tournamentEntryFee,
) {
  if (division?['entryFeeOverrideEnabled'] == true) {
    final own =
        _feeNumber(division?['entryFeeOverride']) ??
        _feeNumber(division?['entryFee']);
    if (own != null) return _feeText(own);
  }
  return _feeText(tournamentEntryFee ?? 0);
}

/// Port `divisionFeePayload`: ô trống hoặc bằng phí giải → theo phí giải;
/// số khác (kể cả 0) → bật phí riêng.
({bool entryFeeOverrideEnabled, int? entryFee}) divisionFeePayload(
  String input,
  double? tournamentEntryFee,
) {
  final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
  final tournamentFee = _feeNumber(tournamentEntryFee) ?? 0;
  if (digits.isEmpty || (int.tryParse(digits) ?? -1) == tournamentFee) {
    return (entryFeeOverrideEnabled: false, entryFee: null);
  }
  return (entryFeeOverrideEnabled: true, entryFee: int.parse(digits));
}

num? _feeNumber(Object? value) {
  if (value == null || value == '') return null;
  final parsed = num.tryParse(value.toString());
  return parsed?.isFinite == true ? parsed : null;
}

String _feeText(num value) =>
    value % 1 == 0 ? value.toInt().toString() : value.toString();

// ─── Gộp roundConfig (port round-config-merge.ts) ───

Map<String, dynamic>? _asMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

Map<String, dynamic> _mergeGroupsConfig(
  Object? existing,
  Map<String, dynamic> incoming,
) {
  final previous = _asMap(existing);
  final merged = <String, dynamic>{...?previous, ...incoming};
  if (incoming.containsKey('groups')) return merged;
  final previousGroups = previous?['groups'] is List
      ? previous!['groups'] as List
      : null;
  final resultingNumGroups = merged['numGroups'] is num
      ? (merged['numGroups'] as num).toInt()
      : previousGroups?.length;
  if (previousGroups != null && resultingNumGroups != previousGroups.length) {
    merged.remove('groups');
  }
  return merged;
}

Map<String, dynamic> _mergeRoundConfig(
  Object? existing,
  Map<String, dynamic> incoming,
) {
  final previous = _asMap(existing);
  final merged = <String, dynamic>{...?previous, ...incoming};
  for (final key in const [
    'advancementConfig',
    'playoffConfig',
    'scoring',
    'tiebreakerRules',
    'rounds',
  ]) {
    final previousChild = _asMap(previous?[key]);
    final incomingChild = _asMap(incoming[key]);
    if (previousChild != null && incomingChild != null) {
      merged[key] = {...previousChild, ...incomingChild};
    }
  }
  final incomingGroups = _asMap(incoming['groupsConfig']);
  if (incomingGroups != null) {
    merged['groupsConfig'] = _mergeGroupsConfig(
      previous?['groupsConfig'],
      incomingGroups,
    );
  }
  return merged;
}

// ─── Sheet ───

/// Sheet hạng mục đầy đủ cho cả tạo và sửa (OpenSpec `quan-ly-giai-web-parity`
/// task 2.1, thay 3 dialog thêm/đổi tên/cấu hình cũ):
/// nhận dạng (định dạng + tên + thể thức), chuyển Luật chuẩn/Lite, giới hạn
/// (sức chứa, ELO, phí riêng), luật theo môn + preset nhanh, số lượt vòng
/// tròn, vòng bảng + playoff + seeding, và `SwissConfigEditor` cho Swiss.
///
/// Lưu thực hiện ngay trong sheet (busy nội bộ, chống double-tap, khung
/// `TournamentManageSheet` trong `build`): tạo/sửa gọi
/// `createDivision`/`updateDivision`; Swiss đã có stage thì chỉ vá stage
/// (Backend chặn sửa division sau khi có sơ đồ). Kết cấu (định dạng, thể
/// thức, cấu hình vòng) bị khoá khi [lockContent] (đã có bracket).
class DivisionEditorSheet extends ConsumerStatefulWidget {
  const DivisionEditorSheet({
    super.key,
    required this.tournament,
    this.division,
    this.swissStage,
    this.swissMinPlayedRounds = 0,
    this.lockContent = false,
  });

  final Tournament tournament;

  /// Hạng mục đang sửa (map từ `GET /tournaments/:id/divisions`);
  /// null = tạo mới.
  final Map<String, dynamic>? division;

  /// Stage Swiss của hạng mục (đã có sơ đồ) — lưu thì vá stage thay vì division.
  final SwissStageInfo? swissStage;

  /// Số vòng Swiss đã ghép cặp (không giảm dưới mức này).
  final int swissMinPlayedRounds;

  /// Đã có sơ đồ: khoá kết cấu, chỉ còn sửa giới hạn/luật (Swiss qua stage).
  final bool lockContent;

  /// Mở sheet hạng mục. Trả về `true` khi đã lưu thành công.
  ///
  /// Mở bằng `showModalBottomSheet` trực tiếp (khung `TournamentManageSheet`
  /// nằm trong `build` của state để nhận `busy` động, như các sheet quản lý
  /// khác); drag tắt từ đầu vì sheet có thể vào trạng thái busy ngay.
  static Future<bool?> show(
    BuildContext context, {
    required Tournament tournament,
    Map<String, dynamic>? division,
    SwissStageInfo? swissStage,
    int swissMinPlayedRounds = 0,
    bool lockContent = false,
  }) => showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    showDragHandle: false,
    builder: (_) => DivisionEditorSheet(
      tournament: tournament,
      division: division,
      swissStage: swissStage,
      swissMinPlayedRounds: swissMinPlayedRounds,
      lockContent: lockContent,
    ),
  );

  @override
  ConsumerState<DivisionEditorSheet> createState() =>
      _DivisionEditorSheetState();
}

class _DivisionEditorSheetState extends ConsumerState<DivisionEditorSheet> {
  late final bool _isEditing = widget.division != null;
  late final Map<String, dynamic>? _divisionRoundConfig = _asMap(
    widget.division?['roundConfig'],
  );

  late final TextEditingController _name = TextEditingController(
    text: widget.division?['name']?.toString() ?? '',
  );
  late final TextEditingController _max = TextEditingController(
    text: _isEditing
        ? (widget.division?['maxParticipants']?.toString() ?? '')
        : '16',
  );
  late final TextEditingController _minElo = TextEditingController(
    text: widget.division?['minElo']?.toString() ?? '',
  );
  late final TextEditingController _maxElo = TextEditingController(
    text: widget.division?['maxElo']?.toString() ?? '',
  );
  late final TextEditingController _fee = TextEditingController(
    text: divisionFeeInputValue(widget.division, widget.tournament.entryFee),
  );

  late String _formatOption = _isEditing
      ? matchFormatOptionFromDivision(
          widget.division?['matchType']?.toString(),
          widget.division?['genderRestriction']?.toString(),
        )
      : matchFormatOptionFromTournament(widget.tournament);
  late String _bracketType = _normalize(
    _isEditing
        ? (widget.division?['bracketType'] ?? 'SINGLE_ELIMINATION').toString()
        : widget.tournament.bracketType,
    _bracketTypes,
    'SINGLE_ELIMINATION',
  );
  late bool _limitEnabled = _isEditing
      ? (widget.division?['maxParticipants'] != null)
      : true;
  late bool _eloEnabled =
      _isEditing &&
      (widget.division?['minElo'] != null ||
          widget.division?['maxElo'] != null);

  // Luật theo môn (chỉ dùng khi tắt Lite).
  late SportRulePresetKind _sportKind;
  late int _setsToWin;
  late int _pointsPerSet;
  late bool _winByTwo;
  late int _maxDeucePoints;
  late bool _superTiebreakEnabled;
  late int _superTiebreakSetIndex;
  late int _superTiebreakPoints;
  late bool _isLiteMode;

  // Vòng tròn / vòng bảng + playoff.
  late int _rrRounds;
  late int _numGroups;
  late int _teamsPerGroup;
  late int _teamsAdvancing;
  late int _groupRounds;
  late String _playoffType;
  late String _seedingType;

  // Swiss.
  late final int _participantCount = swissDivisionTeamCount(
    widget.division ?? const {},
  );
  late final SwissConfig _swissInitial;
  late SwissConfig _swiss;
  late final bool _swissSavedHasTotal;

  bool _busy = false;
  bool _eloInvalid = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _loadSportRules();
    final rawSwiss =
        widget.swissStage?.rawRoundConfig['swiss'] ??
        _divisionRoundConfig?['swiss'];
    _swissInitial = swissConfigOrDefault(
      rawSwiss,
      _participantCount,
      widget.swissMinPlayedRounds,
    );
    _swiss = _swissInitial;
    _swissSavedHasTotal = rawSwiss is Map && rawSwiss['totalRounds'] is num;
  }

  /// Khởi tạo luật theo môn: sửa thì đọc `roundConfig` đã lưu, tạo thì dùng
  /// mặc định của môn suy từ giải (đối chiếu Web `applyNewDivisionScoringDraft`
  /// + `resetDivisionEditor`).
  void _loadSportRules() {
    final fallbackKind = inferSportRuleKindFromText(
      widget.tournament.sportRules?['kind'],
      widget.tournament.sport,
    );
    if (_isEditing) {
      final view = resolveSportRuleView(_divisionRoundConfig, fallbackKind);
      _sportKind = view.kind;
      _setsToWin = view.setsToWin;
      _pointsPerSet = view.pointsPerSet;
      _winByTwo = view.winByTwo;
      _maxDeucePoints = view.maxPoints;
      _superTiebreakEnabled = view.hasCustomTiebreakTarget;
      _superTiebreakSetIndex = view.bestOf;
      _superTiebreakPoints = view.tiebreakPoints;
      // Legacy roundConfig không ghi mode tường minh: rơi về mode của giải
      // (đối chiếu Web applyDivisionFormValues đọc sportRules kế tiếp).
      _isLiteMode =
          (explicitScoringMode(_divisionRoundConfig) ??
              explicitScoringMode(widget.tournament.sportRules) ??
              'LITE') !=
          'STRICT';
      _rrRounds = view.roundsToPlay;
    } else {
      final defaults = sportRuleDefaults(fallbackKind);
      _sportKind = fallbackKind;
      _setsToWin = defaults.setsToWin;
      _pointsPerSet = defaults.pointsPerSet;
      _winByTwo = defaults.winByTwo;
      _maxDeucePoints = defaults.maxPoints;
      _superTiebreakEnabled = defaults.tiebreakPoints != null;
      _superTiebreakSetIndex = defaults.setsToWin * 2 - 1;
      _superTiebreakPoints = defaults.tiebreakPoints ?? defaults.pointsPerSet;
      _isLiteMode = true;
      _rrRounds = 1;
    }
    final groupsConfig = _asMap(_divisionRoundConfig?['groupsConfig']);
    final advancementConfig = _asMap(
      _divisionRoundConfig?['advancementConfig'],
    );
    final playoffConfig = _asMap(_divisionRoundConfig?['playoffConfig']);
    final rawGroups = groupsConfig?['groups'];
    _numGroups =
        _readInt(groupsConfig?['numGroups']) ??
        (rawGroups is List
            ? math.max(1, rawGroups.length)
            : _isEditing
            ? (widget.division?['bracketType'] == 'ROUND_ROBIN'
                  ? 1
                  : (widget.division?['maxParticipants'] is num &&
                            (widget.division?['maxParticipants'] as num) >= 16
                        ? 4
                        : 2))
            : 4);
    _teamsPerGroup = _readInt(groupsConfig?['teamsPerGroup']) ?? 4;
    _teamsAdvancing = _readInt(advancementConfig?['teamsAdvancing']) ?? 2;
    _groupRounds = _readInt(groupsConfig?['roundsToPlay']) ?? 1;
    _playoffType = playoffConfig?['type'] == 'DOUBLE_ELIMINATION'
        ? 'DOUBLE_ELIMINATION'
        : 'SINGLE_ELIMINATION';
    _seedingType = playoffConfig?['seedingType'] == 'RANDOM'
        ? 'RANDOM'
        : 'SEEDED';
  }

  @override
  void dispose() {
    _name.dispose();
    _max.dispose();
    _minElo.dispose();
    _maxElo.dispose();
    _fee.dispose();
    _pointsController.dispose();
    _maxDeuceController.dispose();
    _tiebreakSetController.dispose();
    _tiebreakPointsController.dispose();
    _rrRoundsController.dispose();
    _numGroupsController.dispose();
    _groupRoundsController.dispose();
    _teamsPerGroupController.dispose();
    _teamsAdvancingController.dispose();
    super.dispose();
  }

  int? _readInt(Object? value) => value is num ? value.toInt() : null;

  int? _parseField(TextEditingController controller) =>
      int.tryParse(controller.text.trim());

  /// Sức chứa Swiss hiệu lực (Web `effectiveCount`): số VĐV thật, không thì
  /// sức chứa đặt trong sheet, không thì 16.
  int get _effectiveTeamCount {
    if (_participantCount > 0) return _participantCount;
    final parsed = _parseField(_max);
    return _limitEnabled && parsed != null && parsed > 0 ? parsed : 16;
  }

  bool get _supportsTiebreak =>
      _sportKind == SportRulePresetKind.tennis ||
      _sportKind == SportRulePresetKind.pickleballSideOut;

  bool get _isPickleball =>
      _sportKind == SportRulePresetKind.pickleballRally ||
      _sportKind == SportRulePresetKind.pickleballSideOut;

  String get _divisionId =>
      (widget.division?['id'] ?? widget.division?['divisionId'] ?? '')
          .toString();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TournamentManageSheet(
      title: _isEditing
          ? l10n.divisionEditorEditTitle
          : l10n.tournamentManagementAddDivision,
      busy: _busy,
      actions: [
        FilledButton(
          key: const ValueKey('division-editor-save'),
          onPressed: _busy ? null : _save,
          child: Text(
            _isEditing
                ? l10n.divisionEditorSaveChanges
                : l10n.tournamentManagementAddDivision,
          ),
        ),
        TextButton(
          key: const ValueKey('division-editor-cancel'),
          onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
          child: Text(l10n.tournamentManagementCancel),
        ),
      ],
      child: _buildBody(context, l10n),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _buildIdentity(l10n),
      const SizedBox(height: 8),
      SwitchListTile(
        key: const ValueKey('division-editor-standard-rules'),
        contentPadding: EdgeInsets.zero,
        title: Text(
          l10n.divisionEditorStandardRules,
          style: TextStyle(color: context.colors.textPrimary),
        ),
        value: !_isLiteMode,
        onChanged: _busy || widget.lockContent
            ? null
            : (value) => setState(() => _isLiteMode = !value),
      ),
      _buildLimits(l10n),
      const SizedBox(height: 12),
      if (_errorText != null)
        Padding(
          key: const ValueKey('division-editor-error'),
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            _errorText!,
            style: TextStyle(color: context.colors.error),
          ),
        ),
      // Khối luật chỉ mở khi tắt Lite hoặc thể thức có cấu hình riêng
      // (đối chiếu `rulesPaneOpen` của Web; Lite giữ nguyên cấu hình mặc định).
      if (!_isLiteMode ||
          _bracketType == 'ROUND_ROBIN' ||
          _bracketType == 'GROUP_STAGE_KNOCKOUT' ||
          _bracketType == 'SWISS') ...[
        Text(
          l10n.divisionEditorRulesPaneTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (!_isLiteMode) _buildStrictRules(l10n),
        if (_bracketType == 'ROUND_ROBIN') _buildRoundRobin(l10n),
        if (_bracketType == 'GROUP_STAGE_KNOCKOUT') _buildGroupStage(l10n),
        if (_bracketType == 'SWISS')
          SwissConfigEditor(
            value: _swiss,
            teamCount: _effectiveTeamCount,
            minPlayedRounds: widget.swissMinPlayedRounds,
            enabled: !_busy,
            onChanged: (value) => _swiss = value,
          ),
      ],
    ],
  );

  // ─── Nhận dạng ───

  Widget _buildIdentity(AppLocalizations l10n) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(l10n.divisionEditorTypeLabel, style: _sectionTitleStyle(context)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final option in divisionFormatOptions)
            ChoiceChip(
              key: ValueKey('division-editor-format-$option'),
              label: Text(_formatLabel(l10n, option)),
              selected: _formatOption == option,
              onSelected: _busy || widget.lockContent
                  ? null
                  : (_) => _selectFormat(option),
            ),
        ],
      ),
      const SizedBox(height: 12),
      TextField(
        key: const ValueKey('division-editor-name'),
        controller: _name,
        enabled: !_busy,
        maxLength: 255,
        decoration: InputDecoration(
          labelText: l10n.tournamentManagementDivisionName,
          helperText: l10n.divisionEditorNameHint,
          counterText: '',
          border: const OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        l10n.tournamentManagementBracketType,
        style: _sectionTitleStyle(context),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final bracketType in _bracketTypes)
            ChoiceChip(
              key: ValueKey('division-editor-bracket-$bracketType'),
              label: Text(_bracketLabel(l10n, bracketType)),
              selected: _bracketType == bracketType,
              onSelected: _busy || widget.lockContent
                  ? null
                  : (_) => _selectBracketType(bracketType),
            ),
        ],
      ),
    ],
  );

  /// Chọn định dạng điền luôn tên theo loại (đối chiếu Web
  /// `handleFormatSelect`: tên luôn theo định dạng vừa chọn).
  void _selectFormat(String option) {
    setState(() {
      _formatOption = option;
      _name.text = _formatLabel(AppLocalizations.of(context)!, option);
    });
  }

  /// Đổi thể thức: vòng tròn 1 bảng, vòng bảng mặc định 4 bảng (đối chiếu
  /// handler `setBracketType` của Web).
  void _selectBracketType(String bracketType) {
    setState(() {
      _bracketType = bracketType;
      if (bracketType == 'ROUND_ROBIN') _numGroups = 1;
      if (bracketType == 'GROUP_STAGE_KNOCKOUT') _numGroups = 4;
    });
  }

  String _formatLabel(AppLocalizations l10n, String option) => switch (option) {
    'MALE_SINGLES' => l10n.tournamentCategoryMenSingles,
    'FEMALE_SINGLES' => l10n.tournamentCategoryWomenSingles,
    'OPEN_SINGLES' => l10n.divisionEditorFormatOpenSingles,
    'MALE_DOUBLES' => l10n.tournamentCategoryMenDoubles,
    'FEMALE_DOUBLES' => l10n.tournamentCategoryWomenDoubles,
    'MIXED_DOUBLES' => l10n.tournamentCategoryMixedDoubles,
    _ => l10n.divisionEditorFormatOpenDoubles,
  };

  String _bracketLabel(
    AppLocalizations l10n,
    String bracketType,
  ) => switch (bracketType) {
    'SINGLE_ELIMINATION' => l10n.tournamentManagementBracketSingleElimination,
    'DOUBLE_ELIMINATION' => l10n.tournamentManagementBracketDoubleElimination,
    'ROUND_ROBIN' => l10n.tournamentManagementBracketRoundRobin,
    'GROUP_STAGE_KNOCKOUT' => l10n.tournamentManagementBracketGroupThenKnockout,
    'SWISS' => l10n.tournamentManagementBracketSwiss,
    _ => l10n.tournamentManagementStatusOther,
  };

  // ─── Giới hạn và phí ───

  Widget _buildLimits(AppLocalizations l10n) {
    final colors = context.colors;
    final feeCustom = divisionFeePayload(
      _fee.text,
      widget.tournament.entryFee,
    ).entryFeeOverrideEnabled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.divisionEditorLimitsTitle,
          style: _sectionTitleStyle(context),
        ),
        const SizedBox(height: 4),
        CheckboxListTile(
          key: const ValueKey('division-editor-limit-switch'),
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(
            l10n.divisionEditorParticipantLimit,
            style: TextStyle(color: colors.textPrimary),
          ),
          value: _limitEnabled,
          onChanged: _busy
              ? null
              : (value) => setState(() => _limitEnabled = value == true),
        ),
        if (_limitEnabled)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: SizedBox(
              width: 160,
              child: TextField(
                key: const ValueKey('division-editor-max'),
                controller: _max,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: InputDecoration(
                  labelText: l10n.divisionEditorMaxCount,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ),
        CheckboxListTile(
          key: const ValueKey('division-editor-elo-switch'),
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(
            l10n.divisionEditorEloLimit,
            style: TextStyle(color: colors.textPrimary),
          ),
          value: _eloEnabled,
          onChanged: _busy
              ? null
              : (value) => setState(() => _eloEnabled = value == true),
        ),
        if (_eloEnabled)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const ValueKey('division-editor-elo-min'),
                        controller: _minElo,
                        enabled: !_busy,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: l10n.divisionEditorEloMin,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        key: const ValueKey('division-editor-elo-max'),
                        controller: _maxElo,
                        enabled: !_busy,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: l10n.divisionEditorEloMax,
                          errorText: _eloInvalid
                              ? l10n.divisionEditorEloRangeError
                              : null,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.divisionEditorEloBlankHint,
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('division-editor-fee'),
          controller: _fee,
          enabled: !_busy,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(12),
          ],
          decoration: InputDecoration(
            labelText: l10n.divisionEditorEntryFee,
            hintText: l10n.divisionEditorEntryFeePlaceholder,
            helperText: feeCustom
                ? l10n.divisionEditorEntryFeeCustomHint
                : l10n.divisionEditorEntryFeeFollowsHint,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  // ─── Luật theo môn ───

  Widget _buildStrictRules(AppLocalizations l10n) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (_isPickleball) ...[
        Text(
          l10n.divisionEditorPickleballMode,
          style: _sectionTitleStyle(context),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (kind, label) in [
              (
                SportRulePresetKind.pickleballRally,
                l10n.divisionEditorRallyScoring,
              ),
              (
                SportRulePresetKind.pickleballSideOut,
                l10n.divisionEditorSideOutScoring,
              ),
            ])
              ChoiceChip(
                key: ValueKey('division-editor-scoring-${kind.apiValue}'),
                label: Text(label),
                selected: _sportKind == kind,
                onSelected: _busy || widget.lockContent
                    ? null
                    : (_) => _applySportRuleKind(kind),
              ),
          ],
        ),
        const SizedBox(height: 12),
      ],
      Text(l10n.divisionEditorPresets, style: _sectionTitleStyle(context)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          // Web chỉ hiện 2 preset đầu (`getQuickPresets(..., 2)`); mô tả
          // preset hiện trong tooltip (Web dùng thuộc tính title).
          for (final preset in getSportRulePresets(_sportKind).take(2))
            Tooltip(
              message: divisionEditorPresetDescription(l10n, preset.id),
              child: ChoiceChip(
                key: ValueKey('division-editor-preset-${preset.id}'),
                label: Text(
                  '${divisionEditorPresetLabel(l10n, preset.id)} · ${preset.setsToWin}×${preset.pointsPerSet}',
                ),
                selected:
                    _setsToWin == preset.setsToWin &&
                    _pointsPerSet == preset.pointsPerSet &&
                    _winByTwo == preset.winByTwo,
                onSelected: _busy || widget.lockContent
                    ? null
                    : (_) => _applyPreset(preset),
              ),
            ),
        ],
      ),
      const SizedBox(height: 12),
      Text(l10n.divisionEditorScoreTitle, style: _sectionTitleStyle(context)),
      const SizedBox(height: 8),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              key: const ValueKey('division-editor-sets-to-win'),
              initialValue: _setsToWin,
              decoration: InputDecoration(
                labelText: l10n.divisionEditorSetsToWin,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final value in _setsToWinOptions)
                  DropdownMenuItem(
                    value: value,
                    child: Text(
                      divisionEditorSetOptionLabel(l10n, _sportKind, value),
                    ),
                  ),
              ],
              onChanged: _busy || widget.lockContent
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() {
                          _setsToWin = value;
                          _superTiebreakSetIndex = math.max(1, value * 2 - 1);
                        });
                      }
                    },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              key: const ValueKey('division-editor-points-per-set'),
              controller: _pointsController,
              enabled: !_busy && !widget.lockContent,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: divisionEditorSetUnitLabel(l10n, _sportKind),
                border: const OutlineInputBorder(),
              ),
              onChanged: _clampPoints,
            ),
          ),
        ],
      ),
      CheckboxListTile(
        key: const ValueKey('division-editor-win-by-two'),
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text(
          l10n.divisionEditorWinByTwo,
          style: TextStyle(color: context.colors.textPrimary),
        ),
        value: _winByTwo,
        onChanged: _busy || widget.lockContent
            ? null
            : (value) => setState(() => _winByTwo = value == true),
      ),
      if (_winByTwo)
        SizedBox(
          width: 160,
          child: TextField(
            key: const ValueKey('division-editor-max-deuce'),
            controller: _maxDeuceController,
            enabled: !_busy && !widget.lockContent,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.divisionEditorMaxDeucePoints,
              border: const OutlineInputBorder(),
            ),
            onChanged: _clampMaxDeuce,
          ),
        )
      else
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            l10n.divisionEditorNoDeuceLimit,
            style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
          ),
        ),
      if (_supportsTiebreak) ...[
        CheckboxListTile(
          key: const ValueKey('division-editor-super-tiebreak'),
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(
            l10n.divisionEditorSuperTiebreak,
            style: TextStyle(color: context.colors.textPrimary),
          ),
          value: _superTiebreakEnabled,
          onChanged: _busy || widget.lockContent
              ? null
              : (value) =>
                    setState(() => _superTiebreakEnabled = value == true),
        ),
        if (_superTiebreakEnabled)
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('division-editor-tiebreak-set'),
                  controller: _tiebreakSetController,
                  enabled: !_busy && !widget.lockContent,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.divisionEditorTiebreakSet,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (text) => _clampTiebreakSet(text),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  key: const ValueKey('division-editor-tiebreak-points'),
                  controller: _tiebreakPointsController,
                  enabled: !_busy && !widget.lockContent,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.divisionEditorTiebreakPoints,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (text) {
                    final parsed = int.tryParse(text.trim());
                    if (parsed == null) return;
                    final clamped = math.max(1, parsed);
                    setState(() => _superTiebreakPoints = clamped);
                    if (clamped != parsed) {
                      _tiebreakPointsController.text = '$clamped';
                    }
                  },
                ),
              ),
            ],
          ),
      ],
    ],
  );

  /// Ô số của luật: dùng controller riêng, cập nhật khi preset/đổi môn dựng lại.
  late final TextEditingController _pointsController = TextEditingController(
    text: '$_pointsPerSet',
  );
  late final TextEditingController _maxDeuceController = TextEditingController(
    text: '$_maxDeucePoints',
  );
  late final TextEditingController _tiebreakSetController =
      TextEditingController(text: '$_superTiebreakSetIndex');
  late final TextEditingController _tiebreakPointsController =
      TextEditingController(text: '$_superTiebreakPoints');

  List<int> get _setsToWinOptions {
    final options = sportRuleSetOptions(_sportKind);
    // Giá trị đã lưu nằm ngoài danh sách chuẩn của môn thì thêm vào để
    // dropdown không vỡ (ví dụ tennis lưu 4 set).
    if (options.contains(_setsToWin)) return options;
    return [...options, _setsToWin]..sort();
  }

  /// Ô điểm/set: tối thiểu 1; khi kẹp khác số vừa gõ thì hiện lại số đã kẹp
  /// (đối chiếu input controlled của Web).
  void _clampPoints(String text) {
    final parsed = int.tryParse(text.trim());
    if (parsed == null) return;
    final clamped = math.max(1, parsed);
    setState(() => _pointsPerSet = clamped);
    if (clamped != parsed) _pointsController.text = '$clamped';
  }

  /// Trần deuce không bao giờ thấp hơn điểm/set (Web `Math.max(pointsPerSet, …)`).
  void _clampMaxDeuce(String text) {
    final parsed = int.tryParse(text.trim());
    if (parsed == null) return;
    final clamped = math.max(_pointsPerSet, parsed);
    setState(() => _maxDeucePoints = clamped);
    if (clamped != parsed) _maxDeuceController.text = '$clamped';
  }

  void _clampTiebreakSet(String text) {
    final parsed = int.tryParse(text.trim());
    if (parsed == null) return;
    final maxSet = math.max(1, _setsToWin * 2 - 1);
    final clamped = parsed.clamp(1, maxSet).toInt();
    setState(() => _superTiebreakSetIndex = clamped);
    if (clamped != parsed) _tiebreakSetController.text = '$clamped';
  }

  /// Áp preset: điền sẵn số set/điểm/trần/tiebreak, vẫn sửa tay được
  /// (đối chiếu handler preset của Web `DivisionStrictRulesSection`).
  void _applyPreset(SportRulePreset preset) {
    setState(() {
      _setsToWin = preset.setsToWin;
      _pointsPerSet = preset.pointsPerSet;
      _winByTwo = preset.winByTwo;
      _maxDeucePoints = preset.maxPoints;
      _superTiebreakEnabled = preset.tiebreakPoints != null;
      _superTiebreakSetIndex = preset.setsToWin * 2 - 1;
      _superTiebreakPoints = preset.tiebreakPoints ?? preset.pointsPerSet;
      _pointsController.text = '${preset.pointsPerSet}';
      _maxDeuceController.text = '${preset.maxPoints}';
      _tiebreakSetController.text = '${preset.setsToWin * 2 - 1}';
      _tiebreakPointsController.text =
          '${preset.tiebreakPoints ?? preset.pointsPerSet}';
    });
  }

  /// Đổi chế độ Pickleball: reset luật về mặc định của chế độ đó (Web
  /// `applySportRuleKind`).
  void _applySportRuleKind(SportRulePresetKind kind) {
    final defaults = sportRuleDefaults(kind);
    setState(() {
      _sportKind = kind;
      _setsToWin = defaults.setsToWin;
      _pointsPerSet = defaults.pointsPerSet;
      _winByTwo = defaults.winByTwo;
      _maxDeucePoints = defaults.maxPoints;
      _superTiebreakEnabled = defaults.tiebreakPoints != null;
      _superTiebreakSetIndex = defaults.setsToWin * 2 - 1;
      _superTiebreakPoints = defaults.tiebreakPoints ?? defaults.pointsPerSet;
      _pointsController.text = '${defaults.pointsPerSet}';
      _maxDeuceController.text = '${defaults.maxPoints}';
      _tiebreakSetController.text = '${defaults.setsToWin * 2 - 1}';
      _tiebreakPointsController.text =
          '${defaults.tiebreakPoints ?? defaults.pointsPerSet}';
    });
  }

  // ─── Vòng tròn / vòng bảng + playoff ───

  Widget _buildRoundRobin(AppLocalizations l10n) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('division-editor-rr-rounds'),
          controller: _rrRoundsController,
          enabled: !_busy && !widget.lockContent,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: l10n.divisionEditorRoundsToPlay,
            border: const OutlineInputBorder(),
          ),
          onChanged: (text) {
            final parsed = int.tryParse(text.trim());
            if (parsed == null) return;
            setState(() => _rrRounds = parsed.clamp(1, 4).toInt());
          },
        ),
      ],
    ),
  );

  late final TextEditingController _rrRoundsController = TextEditingController(
    text: '${_rrRounds.clamp(1, 4).toInt()}',
  );

  Widget _buildGroupStage(AppLocalizations l10n) {
    final colors = context.colors;
    final advancingUpper = math.max(1, _teamsPerGroup - 1);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.divisionEditorStage1Title,
                  style: _sectionTitleStyle(context),
                ),
              ),
              Text(
                l10n.divisionEditorConfiguredTeams(_numGroups * _teamsPerGroup),
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _numberField(
            key: 'division-editor-num-groups',
            label: l10n.divisionEditorNumGroups,
            controller: _numGroupsController,
            enabled: !_busy && !widget.lockContent,
            onChanged: (value) => setState(() => _numGroups = value),
          ),
          const SizedBox(height: 8),
          _numberField(
            key: 'division-editor-group-rounds',
            label: l10n.divisionEditorGroupStageRounds,
            controller: _groupRoundsController,
            enabled: !_busy && !widget.lockContent,
            onChanged: (value) => setState(() => _groupRounds = value),
          ),
          const SizedBox(height: 8),
          _numberField(
            key: 'division-editor-teams-per-group',
            label: l10n.divisionEditorTeamsPerGroup,
            controller: _teamsPerGroupController,
            enabled: !_busy && !widget.lockContent,
            onChanged: (value) => setState(() {
              _teamsPerGroup = value;
              // Đi tiếp không thể bằng hoặc vượt số đội mỗi bảng (Web).
              _teamsAdvancing = math.min(
                _teamsAdvancing,
                math.max(1, value - 1),
              );
              _teamsAdvancingController.text = '$_teamsAdvancing';
            }),
          ),
          const SizedBox(height: 8),
          _numberField(
            key: 'division-editor-teams-advancing',
            label: l10n.divisionEditorTeamsAdvancing,
            controller: _teamsAdvancingController,
            enabled: !_busy && !widget.lockContent,
            onChanged: (value) => setState(
              () => _teamsAdvancing = value.clamp(1, advancingUpper).toInt(),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.divisionEditorAdvanceSummary(
              _numGroups,
              _teamsAdvancing,
              _numGroups * _teamsAdvancing,
            ),
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.divisionEditorStage2Title,
            style: _sectionTitleStyle(context),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.divisionEditorPlayoffFormat,
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (value, label) in [
                ('SINGLE_ELIMINATION', l10n.divisionEditorPlayoffSingle),
                ('DOUBLE_ELIMINATION', l10n.divisionEditorPlayoffDouble),
              ])
                ChoiceChip(
                  key: ValueKey('division-editor-playoff-$value'),
                  label: Text(label),
                  selected: _playoffType == value,
                  onSelected: _busy || widget.lockContent
                      ? null
                      : (_) => setState(() => _playoffType = value),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.divisionEditorSeedingType,
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (value, label) in [
                ('SEEDED', l10n.divisionEditorSeededByElo),
                ('RANDOM', l10n.divisionEditorRandomSeeding),
              ])
                ChoiceChip(
                  key: ValueKey('division-editor-seeding-$value'),
                  label: Text(label),
                  selected: _seedingType == value,
                  onSelected: _busy || widget.lockContent
                      ? null
                      : (_) => setState(() => _seedingType = value),
                ),
            ],
          ),
        ],
      ),
    );
  }

  late final TextEditingController _numGroupsController = TextEditingController(
    text: '$_numGroups',
  );
  late final TextEditingController _groupRoundsController =
      TextEditingController(text: '$_groupRounds');
  late final TextEditingController _teamsPerGroupController =
      TextEditingController(text: '$_teamsPerGroup');
  late final TextEditingController _teamsAdvancingController =
      TextEditingController(text: '$_teamsAdvancing');

  Widget _numberField({
    required String key,
    required String label,
    required TextEditingController controller,
    required bool enabled,
    required ValueChanged<int> onChanged,
  }) => TextField(
    key: ValueKey(key),
    controller: controller,
    enabled: enabled,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      isDense: true,
    ),
    onChanged: (text) {
      final parsed = int.tryParse(text.trim());
      if (parsed != null) onChanged(parsed);
    },
  );

  TextStyle? _sectionTitleStyle(BuildContext context) =>
      Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: context.colors.textPrimary,
      );

  // ─── Lưu ───

  /// Sức chứa chuẩn hoá khi lưu (Web: rỗng/không hợp lệ → 2, kẹp 2..128).
  int _normalizedMaxParticipants() {
    final parsed = _parseField(_max);
    if (parsed == null || parsed <= 0) return 2;
    return parsed.clamp(2, 128).toInt();
  }

  Future<void> _save() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    // Sức chứa: Web không chặn lưu mà tự chuẩn hoá (rỗng/không hợp lệ → 2,
    // kẹp 2..128) — kẹp luôn ở đây và hiện lại vào ô.
    if (_limitEnabled) {
      final normalized = _normalizedMaxParticipants().toString();
      if (_max.text.trim() != normalized) _max.text = normalized;
    }
    final minElo = _parseField(_minElo);
    final maxElo = _parseField(_maxElo);
    final invalidElo =
        _eloEnabled && minElo != null && maxElo != null && minElo > maxElo;
    if (invalidElo) {
      setState(() => _eloInvalid = invalidElo);
      return;
    }
    setState(() {
      _busy = true;
      _errorText = null;
    });
    try {
      final plan = _buildSavePlan();
      if (plan.stageRoundConfig != null && widget.swissStage != null) {
        // Đã có sơ đồ Swiss: Backend chặn sửa division, chỉ vá stage.
        await ref
            .read(tournamentRepositoryProvider)
            .updateStageRoundConfig(
              widget.tournament.id,
              widget.swissStage!.stageId,
              plan.stageRoundConfig!,
            );
        ref.invalidate(
          swissStageProvider((
            tournamentId: widget.tournament.id,
            divisionId: _divisionId,
          )),
        );
      } else if (_isEditing) {
        await ref
            .read(tournamentManagementRepositoryProvider)
            .updateDivision(_divisionId, plan.divisionPayload!);
      } else {
        await ref
            .read(tournamentManagementRepositoryProvider)
            .createDivision(widget.tournament.id, plan.divisionPayload!);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorText =
              tournamentSheetServerMessage(error) ??
              l10n.tournamentManagementActionError;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Dựng payload lưu (port `handleCreateDivision` của Web):
  /// khối luật nhét vào `roundConfig`, thêm cấu hình riêng theo thể thức,
  /// Swiss thì giao cho [planSwissSave] (division hoặc stage).
  SwissSavePlan _buildSavePlan() {
    final mapped = matchFormatApiMapping(_formatOption);
    final divisionName = _name.text.trim().isEmpty
        ? _formatLabel(AppLocalizations.of(context)!, _formatOption)
        : _name.text.trim();
    final configuredGroupRounds =
        (_bracketType == 'ROUND_ROBIN' ? _rrRounds : _groupRounds)
            .clamp(1, 20)
            .toInt();
    final scoringConfig = buildSportRulesPayload(
      kind: _sportKind,
      setsToWin: _setsToWin,
      pointsPerSet: _pointsPerSet,
      winByTwo: _winByTwo,
      maxPoints: _winByTwo ? _maxDeucePoints : null,
      tiebreakPoints: _superTiebreakEnabled ? _superTiebreakPoints : null,
      roundsToPlay: configuredGroupRounds,
      mode: _isLiteMode ? 'LITE' : 'STRICT',
    );
    var roundConfig = _isEditing
        ? _mergeRoundConfig(_divisionRoundConfig, scoringConfig)
        : scoringConfig;
    if (_bracketType == 'ROUND_ROBIN') {
      roundConfig = {
        ...roundConfig,
        'groupsConfig': _mergeGroupsConfig(
          _divisionRoundConfig?['groupsConfig'],
          {
            'numGroups': 1,
            'roundsToPlay': configuredGroupRounds.clamp(1, 4).toInt(),
          },
        ),
      };
    } else if (_bracketType == 'GROUP_STAGE_KNOCKOUT') {
      final existingAdvancement =
          _asMap(_divisionRoundConfig?['advancementConfig']) ?? const {};
      roundConfig = {
        ...roundConfig,
        'groupsConfig':
            _mergeGroupsConfig(_divisionRoundConfig?['groupsConfig'], {
              'numGroups': _numGroups.clamp(2, 32).toInt(),
              'teamsPerGroup': _teamsPerGroup.clamp(2, 128).toInt(),
              'roundsToPlay': configuredGroupRounds.clamp(1, 20).toInt(),
            }),
        'advancementConfig': {
          ...existingAdvancement,
          'teamsAdvancing': _teamsAdvancing
              .clamp(1, math.max(1, _teamsPerGroup - 1))
              .toInt(),
          'allowWildcardThird': false,
          'wildcardTeamsAdvancing': 0,
        },
        'playoffConfig': {'type': _playoffType, 'seedingType': _seedingType},
      };
    }

    final fee = divisionFeePayload(_fee.text, widget.tournament.entryFee);
    final payload = <String, dynamic>{
      'name': divisionName,
      'matchType': mapped.matchType,
      'genderRestriction': mapped.genderRestriction,
      'bracketType': _bracketType,
      // Web gửi ngày giải làm lịch mặc định cho hạng mục (useManageState.ts
      // handleCreateDivision); repo create của App vốn strip endDate nên
      // chỉ gửi startDate.
      'startDate': widget.tournament.startDate?.toIso8601String(),
      'isConfigOverride': true,
      'roundConfig': roundConfig,
      'minElo': _eloEnabled ? _parseField(_minElo) : null,
      'maxElo': _eloEnabled ? _parseField(_maxElo) : null,
      'maxParticipants': _limitEnabled ? _normalizedMaxParticipants() : null,
      'entryFeeOverrideEnabled': fee.entryFeeOverrideEnabled,
      'entryFee': fee.entryFee,
    };
    final isSwiss = _bracketType == 'SWISS';
    return planSwissSave(
      basePayload: payload,
      divisionRoundConfig: roundConfig,
      swiss: isSwiss ? _swiss : null,
      stage: isSwiss ? widget.swissStage : null,
      // Chưa từng lưu tổng số vòng và không biết số đội: bỏ totalRounds để
      // Backend tự suy khi sinh sơ đồ (đối chiếu lưu Swiss cũ của App).
      omitTotalRounds:
          !_swissSavedHasTotal &&
          _participantCount <= 0 &&
          _swiss.totalRounds == _swissInitial.totalRounds,
    );
  }
}

String _normalize(String value, List<String> values, String fallback) =>
    values.contains(value.toUpperCase()) ? value.toUpperCase() : fallback;

// ─── Nhãn luật theo môn, dùng chung cho division editor và sheet vòng ───

String divisionEditorSetUnitLabel(
  AppLocalizations l10n,
  SportRulePresetKind kind,
) => switch (kind) {
  SportRulePresetKind.badminton => l10n.divisionEditorSetUnitBadminton,
  SportRulePresetKind.tableTennis => l10n.divisionEditorSetUnitTableTennis,
  SportRulePresetKind.pickleballRally =>
    l10n.divisionEditorSetUnitPickleballRally,
  SportRulePresetKind.pickleballSideOut =>
    l10n.divisionEditorSetUnitPickleballSideOut,
  SportRulePresetKind.tennis => l10n.divisionEditorSetUnitTennis,
  SportRulePresetKind.football => l10n.divisionEditorSetUnitFootball,
};

String divisionEditorSetOptionLabel(
  AppLocalizations l10n,
  SportRulePresetKind kind,
  int value,
) => switch (kind) {
  SportRulePresetKind.badminton => switch (value) {
    1 => l10n.divisionEditorBadmintonSet1,
    2 => l10n.divisionEditorBadmintonSet2,
    _ => l10n.divisionEditorBadmintonSet3,
  },
  SportRulePresetKind.tableTennis => switch (value) {
    1 => l10n.divisionEditorTableTennisSet1,
    2 => l10n.divisionEditorTableTennisSet2,
    3 => l10n.divisionEditorTableTennisSet3,
    _ => l10n.divisionEditorTableTennisSet4,
  },
  SportRulePresetKind.pickleballRally => switch (value) {
    1 => l10n.divisionEditorPickleballRallySet1,
    2 => l10n.divisionEditorPickleballRallySet2,
    _ => l10n.divisionEditorPickleballRallySet3,
  },
  SportRulePresetKind.pickleballSideOut => switch (value) {
    1 => l10n.divisionEditorPickleballSideOutSet1,
    2 => l10n.divisionEditorPickleballSideOutSet2,
    _ => l10n.divisionEditorPickleballSideOutSet3,
  },
  SportRulePresetKind.tennis => switch (value) {
    1 => l10n.divisionEditorTennisSet1,
    2 => l10n.divisionEditorTennisSet2,
    _ => l10n.divisionEditorTennisSet3,
  },
  SportRulePresetKind.football => l10n.divisionEditorFootballSet1,
};

String divisionEditorPresetLabel(AppLocalizations l10n, String id) =>
    switch (id) {
      'badminton-quick' => l10n.divisionEditorPresetBadmintonQuick,
      'badminton-standard' => l10n.divisionEditorPresetBadmintonStandard,
      'badminton-short' => l10n.divisionEditorPresetBadmintonShort,
      'table-tennis-bo3' => l10n.divisionEditorPresetTableTennisBo3,
      'table-tennis-bo5' => l10n.divisionEditorPresetTableTennisBo5,
      'table-tennis-single' => l10n.divisionEditorPresetTableTennisSingle,
      'pickleball-rally-quick' => l10n.divisionEditorPresetPickleballRallyQuick,
      'pickleball-rally-standard' =>
        l10n.divisionEditorPresetPickleballRallyStandard,
      'pickleball-rally-extended' =>
        l10n.divisionEditorPresetPickleballRallyExtended,
      'pickleball-sideout-standard' =>
        l10n.divisionEditorPresetPickleballSideoutStandard,
      'pickleball-sideout-15' => l10n.divisionEditorPresetPickleballSideout15,
      'pickleball-sideout-finals' =>
        l10n.divisionEditorPresetPickleballSideoutFinals,
      'tennis-pro-set' => l10n.divisionEditorPresetTennisProSet,
      'tennis-standard' => l10n.divisionEditorPresetTennisStandard,
      'tennis-short-set' => l10n.divisionEditorPresetTennisShortSet,
      _ => l10n.divisionEditorPresetFootballStandard,
    };

String divisionEditorPresetDescription(
  AppLocalizations l10n,
  String id,
) => switch (id) {
  'badminton-quick' => l10n.divisionEditorPresetBadmintonQuickDesc,
  'badminton-standard' => l10n.divisionEditorPresetBadmintonStandardDesc,
  'badminton-short' => l10n.divisionEditorPresetBadmintonShortDesc,
  'table-tennis-bo3' => l10n.divisionEditorPresetTableTennisBo3Desc,
  'table-tennis-bo5' => l10n.divisionEditorPresetTableTennisBo5Desc,
  'table-tennis-single' => l10n.divisionEditorPresetTableTennisSingleDesc,
  'pickleball-rally-quick' => l10n.divisionEditorPresetPickleballRallyQuickDesc,
  'pickleball-rally-standard' =>
    l10n.divisionEditorPresetPickleballRallyStandardDesc,
  'pickleball-rally-extended' =>
    l10n.divisionEditorPresetPickleballRallyExtendedDesc,
  'pickleball-sideout-standard' =>
    l10n.divisionEditorPresetPickleballSideoutStandardDesc,
  'pickleball-sideout-15' => l10n.divisionEditorPresetPickleballSideout15Desc,
  'pickleball-sideout-finals' =>
    l10n.divisionEditorPresetPickleballSideoutFinalsDesc,
  'tennis-pro-set' => l10n.divisionEditorPresetTennisProSetDesc,
  'tennis-standard' => l10n.divisionEditorPresetTennisStandardDesc,
  'tennis-short-set' => l10n.divisionEditorPresetTennisShortSetDesc,
  _ => l10n.divisionEditorPresetFootballStandardDesc,
};
