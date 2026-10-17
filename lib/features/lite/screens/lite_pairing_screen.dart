import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/lite_management_notifier.dart';
import 'package:app_quanly_giaidau/core/utils/bracket_generation_summary.dart';
import 'package:app_quanly_giaidau/core/utils/api_error_message.dart';
import 'package:app_quanly_giaidau/core/utils/pair_generation_summary.dart';
import 'package:app_quanly_giaidau/core/utils/tournament_division_id.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/lite/widgets/lite_division_picker.dart';

/// Compact organizer screen for Lite tournament pairing.
/// Supports manual pair, RANDOM/ELO_BALANCED generate, and unpair.
class LitePairingScreen extends ConsumerStatefulWidget {
  final String tournamentId;

  const LitePairingScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<LitePairingScreen> createState() => _LitePairingScreenState();
}

class _LitePairingScreenState extends ConsumerState<LitePairingScreen> {
  static const _log = AppLogger('LitePairing');

  bool _loading = true;
  String? _error;
  String? _tournamentMatchType;
  bool _isFootball = false;
  String? _tournamentName;
  List<LiteParticipant> _participants = [];
  List<LiteParticipant> _pairedParticipants = [];
  final Set<String> _selectedIds = {};
  bool _pairing = false;
  bool _generating = false;
  String? _generatingStrategy;
  List<TournamentDivision> _divisions = const [];
  String? _selectedDivisionId;

  @override
  void initState() {
    super.initState();
    _fetchTournament();
    _fetchParticipants();
  }

  bool _isFootballPayload(Map<String, dynamic> payload) {
    final sport = payload['sport']?.toString().trim().toLowerCase() ?? '';
    final category = payload['category']?.toString().trim().toLowerCase() ?? '';
    return sport == 'football' ||
        sport == 'soccer' ||
        category == 'football' ||
        category.contains('bóng đá');
  }

  /// Nội dung đang chọn trên màn; null nếu chưa chọn.
  TournamentDivision? get _selectedDivision {
    final id = _selectedDivisionId;
    if (id == null) return null;
    for (final division in _divisions) {
      if (division.id == id) return division;
    }
    return null;
  }

  /// Giải có từ hai nội dung trở lên mà BTC chưa chọn: phải hỏi trước khi ghi.
  bool get _needsDivisionChoice =>
      _divisions.length >= 2 && _selectedDivision == null;

  /// Nội dung backend sẽ ghi: nội dung đang chọn, hoặc nội dung duy nhất.
  String? get _writeDivisionId =>
      _selectedDivision?.id ?? soleActiveTournamentDivisionId(_divisions);

  /// Loại thi đấu theo nội dung đang chọn (hoặc nội dung duy nhất).
  /// Giải nhiều nội dung chưa chọn thì null: không suy đoán từ nội dung đầu.
  String? get _effectiveMatchType {
    if (_isFootball) return 'SINGLES';
    final division =
        _selectedDivision ?? (_divisions.length == 1 ? _divisions.single : null);
    if (division != null) return _divisionMatchType(division);
    return _divisions.isEmpty ? _tournamentMatchType : null;
  }

  String _divisionMatchType(TournamentDivision division) {
    final matchType = division.matchType.trim().toUpperCase();
    final gender = division.genderRestriction?.trim().toUpperCase();
    if (matchType == 'MIXED_DOUBLES' ||
        (matchType == 'DOUBLES' && gender == 'MIXED')) {
      return 'MIXED_DOUBLES';
    }
    if (matchType.isNotEmpty) return matchType;
    return _tournamentMatchType ?? 'SINGLES';
  }

  /// Giải nhiều nội dung: danh sách chỉ hiện VĐV của nội dung đang chọn.
  bool _inSelectedDivision(LiteParticipant participant) {
    if (_divisions.length < 2) return true;
    final selected = _selectedDivisionId;
    return selected != null && participant.tournamentDivisionId == selected;
  }

  Future<void> _fetchTournament() async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      final res = await dio.get('/tournaments/${widget.tournamentId}');
      final envelope = res.data;
      final payload = envelope is Map ? envelope['data'] : envelope;
      if (mounted && payload is Map) {
        final payloadMap = Map<String, dynamic>.from(payload);
        final isFootball = _isFootballPayload(payloadMap);
        setState(() {
          _isFootball = isFootball;
          _tournamentMatchType = payloadMap['matchType']
              ?.toString()
              .trim()
              .toUpperCase();
          _tournamentName = payloadMap['name']?.toString();
          _divisions = _parseDivisions(payloadMap);
        });
      }
    } catch (e) {
      // Non-critical: pairing screen still works with default title
      _log.warning('Không tải được thông tin giải: $e');
    }
  }

  /// Chỉ giữ nội dung dùng được (không huỷ, có id lưu được) để hiện bộ chọn.
  List<TournamentDivision> _parseDivisions(Map<String, dynamic> payload) {
    final raw = payload['divisions'];
    if (raw is! List) return const [];
    return usableTournamentDivisions([
      for (final item in raw)
        if (item is Map)
          TournamentDivision.fromJson(Map<String, dynamic>.from(item)),
    ]);
  }

  void _selectDivision(String divisionId) {
    setState(() {
      _selectedDivisionId = divisionId;
      _selectedIds.clear();
    });
  }

  Future<void> _pickDivision() async {
    final picked = await showLiteDivisionPicker(context, _divisions);
    if (picked == null || !mounted) return;
    _selectDivision(picked);
  }

  /// Giải nhiều nội dung chưa chọn thì hỏi BTC trước khi ghi. Trả false nếu BTC huỷ.
  Future<bool> _ensureDivisionChosen() async {
    if (!_needsDivisionChoice) return true;
    await _pickDivision();
    return _selectedDivision != null;
  }

  Future<void> _fetchParticipants() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioClientProvider).dio;
      final res = await dio.get(
        '/tournaments/lite/${widget.tournamentId}/participants',
      );
      final envelope = res.data;
      final payload = envelope is Map ? envelope['data'] : envelope;
      final rawParticipants = payload is List ? payload : const <dynamic>[];

      if (mounted) {
        setState(() {
          _participants = rawParticipants
              .map(
                (e) => LiteParticipant.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList();
          _pairedParticipants = const [];
          _selectedIds.clear();
          _loading = false;
        });
      }
    } catch (e, stack) {
      _log.error('Lỗi tải danh sách người tham gia', e, stack);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _error = l10n.lite_loadParticipantsError;
          _loading = false;
        });
      }
    }
  }

  Future<void> _manualPair() async {
    if (_selectedIds.length != 2) return;
    final l10n = AppLocalizations.of(context)!;
    final ids = _selectedIds.toList();
    setState(() => _pairing = true);
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.post(
        '/tournaments/lite/${widget.tournamentId}/pairs',
        data: {'participant1Id': ids[0], 'participant2Id': ids[1]},
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.lite_pairSuccess)));
        _fetchParticipants();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${l10n.lite_pairError}${e.toString().replaceAll('Exception: ', '').replaceAll('DioException: ', '')}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _pairing = false);
    }
  }

  Future<void> _generatePairs(String strategy) async {
    if (!await _ensureDivisionChosen() || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.lite_generateConfirmTitle),
        content: Text(
          strategy == 'RANDOM'
              ? l10n.lite_generateRandomConfirm
              : l10n.lite_generateEloConfirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.matchesCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.lite_confirmButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _generating = true;
      _generatingStrategy = strategy;
    });
    try {
      final dio = ref.read(dioClientProvider).dio;
      final res = await dio.post(
        '/tournaments/lite/${widget.tournamentId}/pairs/generate',
        data: {
          'strategy': strategy,
          'divisionId': ?_writeDivisionId,
        },
      );
      final pairLabels = pairGeneratedLabels(res.data);
      final unpairedNames = pairUnpairedNames(res.data, {
        for (final p in _participants) p.id: p.displayName,
      });

      if (mounted) {
        final parts = <String>[
          pairLabels.isEmpty
              ? l10n.lite_autoPairSuccess
              : '${l10n.lite_autoPairSuccess}: ${pairLabels.join('; ')}',
          if (unpairedNames.isNotEmpty)
            '${l10n.lite_autoPairSuccessOdd(unpairedNames.length)}: ${unpairedNames.join(', ')}',
        ];
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(parts.join('\n'))));
        _fetchParticipants();
      }
    } catch (e) {
      if (mounted) {
        // Backend từ chối (ví dụ chưa đủ cặp) thì hiện nguyên văn message.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              backendErrorMessage(e) ??
                  '${l10n.lite_pairGenerateError}${e.toString().replaceAll('Exception: ', '').replaceAll('DioException: ', '')}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _generating = false;
          _generatingStrategy = null;
        });
      }
    }
  }

  Future<void> _unpair(String participantId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.lite_unpairTitle),
        content: Text(l10n.lite_unpairContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.lite_keepPair),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.lite_unpair),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.post(
        '/tournaments/lite/${widget.tournamentId}/pairs/$participantId/unpair',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.lite_unpairSuccess)));
        _fetchParticipants();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${l10n.lite_unpairErrorTitle}${e.toString().replaceAll('Exception: ', '').replaceAll('DioException: ', '')}',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _tournamentName ?? l10n.lite_pairingTitle,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: colors.textPrimary),
            onPressed: _loading ? null : _fetchParticipants,
          ),
        ],
      ),
      body: _buildBody(colors),
    );
  }

  Widget _buildBody(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 40, color: colors.error),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchParticipants,
                child: Text(l10n.infoRetry),
              ),
            ],
          ),
        ),
      );
    }

    final visibleParticipants = _participants
        .where(_inSelectedDivision)
        .toList();
    final pending = visibleParticipants.where((p) => p.isPending).toList();
    final allPaired = [
      ..._pairedParticipants,
      ..._participants.where((p) => p.isComplete),
    ];
    final isDoubles =
        !_isFootball &&
        (_effectiveMatchType == 'DOUBLES' ||
            _effectiveMatchType == 'MIXED_DOUBLES');

    return RefreshIndicator(
      onRefresh: _fetchParticipants,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (_divisions.length >= 2) ...[
            SizedBox(width: double.infinity, child: _divisionSelector(l10n)),
            const SizedBox(height: 12),
          ],
          if (isDoubles) ...[
            // ─── Pending Section ───
            _sectionHeader(
              colors,
              '${l10n.lite_waitingPair} (${pending.length})',
              Icons.people_outline_rounded,
            ),
            const SizedBox(height: 8),
            if (pending.isEmpty)
              _emptyCard(colors, l10n.lite_noPendingPairs)
            else
              ...pending.map((p) => _pendingTile(p, colors)),

            // ─── Manual pair button ───
            if (_selectedIds.length == 2) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton.icon(
                  onPressed: _pairing ? null : _manualPair,
                  icon: _pairing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.link_rounded, size: 18),
                  label: Text(
                    _pairing ? l10n.lite_pairing : l10n.lite_pairSelected,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                    ),
                  ),
                ),
              ),
            ],

            // ─── Auto generate section ───
            if (pending.length >= 2) ...[
              const SizedBox(height: 16),
              _sectionHeader(
                colors,
                l10n.lite_autoPairing,
                Icons.auto_fix_high_rounded,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _generating
                          ? null
                          : () => _generatePairs('RANDOM'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusXL,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _generating && _generatingStrategy == 'RANDOM'
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              l10n.lite_random,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _generating
                          ? null
                          : () => _generatePairs('ELO_BALANCED'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusXL,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child:
                          _generating && _generatingStrategy == 'ELO_BALANCED'
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              l10n.lite_eloBalanced,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],

            // ─── Odd notice ───
            if (pending.length.isOdd) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  border: Border.all(
                    color: colors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: colors.warning,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.lite_oddNotice,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ─── Paired Section ───
            if (allPaired.isNotEmpty) ...[
              const SizedBox(height: 24),
              _sectionHeader(
                colors,
                '${l10n.lite_paired} (${allPaired.length})',
                Icons.check_circle_outline_rounded,
              ),
              const SizedBox(height: 8),
              ...allPaired.map((p) => _pairedTile(p, colors)),
            ],
          ] else ...[
            // ─── Singles: just participant list, no pairing ───
            if (_needsDivisionChoice)
              _emptyCard(colors, l10n.registerSelectDivision)
            else if (visibleParticipants.isEmpty)
              _emptyCard(colors, l10n.noParticipants)
            else
              ...visibleParticipants.map((p) => _singlesTile(p, colors)),
          ],

          // ─── Bracket generation ───
          if (allPaired.isNotEmpty ||
              (_participants.isNotEmpty && !isDoubles)) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _generating ? null : _generateBracket,
                icon: _generating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.emoji_events_rounded, size: 20),
                label: Text(
                  _generating ? l10n.lite_creating : l10n.lite_createBracket,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _divisionSelector(AppLocalizations l10n) {
    final selected = _selectedDivision;
    return OutlinedButton(
      onPressed: _pickDivision,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.category_outlined, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              selected?.name ?? l10n.registerSelectDivision,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateBracket() async {
    if (!await _ensureDivisionChosen() || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.lite_createBracketTitle),
        content: Text(l10n.lite_createBracketConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.matchesCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.lite_createBracket),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _generating = true);
    try {
      final dio = ref.read(dioClientProvider).dio;
      // Lite has a protected endpoint with its own participant/bracket gate.
      // The generic endpoint is for advanced tournaments and rejects Lite data.
      final res = await dio.post(
        '/tournaments/lite/${widget.tournamentId}/bracket',
        data: {'divisionId': ?_writeDivisionId},
      );
      if (mounted) {
        final unpairedNames = bracketUnpairedNames(res.data);
        final parts = <String>[
          l10n.lite_bracketCreated,
          if (bracketAutoPairedLabels(res.data).isNotEmpty)
            '${l10n.lite_autoPairSuccess}: ${bracketAutoPairedLabels(res.data).join('; ')}',
          if (unpairedNames.isNotEmpty)
            '${l10n.lite_autoPairSuccessOdd(unpairedNames.length)}: ${unpairedNames.join(', ')}',
        ];
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(parts.join('\n'))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              backendErrorMessage(e) ??
                  '${l10n.lite_createBracketNotAvailable}${e.toString().replaceAll('Exception: ', '').replaceAll('DioException: ', '')}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Widget _sectionHeader(
    AppColorsExtension colors,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colors.textSecondary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _emptyCard(AppColorsExtension colors, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: colors.textMuted, fontSize: 13),
      ),
    );
  }

  Widget _pendingTile(LiteParticipant participant, AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    final selected = _selectedIds.contains(participant.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: selected
            ? AppTheme.primary.withValues(alpha: 0.06)
            : colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(
          color: selected ? AppTheme.primary : colors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            if (selected) {
              _selectedIds.remove(participant.id);
            } else {
              if (_selectedIds.length >= 2) {
                _selectedIds.remove(_selectedIds.first);
              }
              _selectedIds.add(participant.id);
            }
          });
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 22,
                color: selected ? AppTheme.primary : colors.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      participant.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (participant.members.isNotEmpty)
                      Text(
                        participant.members.map((m) => m.fullName).join(', '),
                        style: TextStyle(fontSize: 11, color: colors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  l10n.lite_pendingPair,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colors.warning,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _singlesTile(LiteParticipant participant, AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.person_rounded, size: 20, color: colors.info),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                if (participant.members.isNotEmpty)
                  Text(
                    participant.members.map((m) => m.fullName).join(', '),
                    style: TextStyle(fontSize: 11, color: colors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              l10n.joined,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: colors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pairedTile(LiteParticipant participant, AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(Icons.group_rounded, size: 20, color: colors.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                if (participant.members.isNotEmpty)
                  Text(
                    participant.members.map((m) => m.fullName).join(', '),
                    style: TextStyle(fontSize: 11, color: colors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (participant.members.length >= 2)
            SizedBox(
              height: 32,
              child: OutlinedButton(
                onPressed: () => _unpair(participant.id),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.error,
                  side: BorderSide(color: colors.error.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                ),
                child: Text(
                  l10n.lite_unpair,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
