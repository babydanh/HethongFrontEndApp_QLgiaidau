import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/services/roster_template_service.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/domain/entities/pairing.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/add_athlete_sheet.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/mock_participants_sheet.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/roster_import_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_people_section.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/pairing_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/wildcard_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';

/// Tab VĐV của hub quản lý: mỗi nội dung thi đấu là một row, bấm để mở ra danh
/// sách đội (kèm duyệt/từ chối đăng ký chờ) và nút thêm VĐV. Chỉ mở một row
/// một lúc, giống `expandedTeamId` của trang đội trên web.
class TournamentManagementAthletesTab extends ConsumerStatefulWidget {
  const TournamentManagementAthletesTab({super.key, required this.tournament});

  final Tournament tournament;

  @override
  ConsumerState<TournamentManagementAthletesTab> createState() =>
      _TournamentManagementAthletesTabState();
}

class _TournamentManagementAthletesTabState
    extends ConsumerState<TournamentManagementAthletesTab> {
  static const _expandDuration = Duration(milliseconds: 200);

  late Future<List<OrganizerOpsParticipant>> _participantsFuture;
  String? _expandedDivisionId;

  /// Check-in flips reported by the rows, so the header count stays in step.
  final Map<String, bool> _presence = {};
  bool _autoPairing = false;

  @override
  void initState() {
    super.initState();
    _participantsFuture = _load();
  }

  Future<List<OrganizerOpsParticipant>> _load() => ref
      .read(tournamentRepositoryProvider)
      .getOrganizerParticipants(widget.tournament.id);

  void _reload() => setState(() {
    _presence.clear();
    _participantsFuture = _load();
  });

  void _toggle(String divisionId) => setState(
    () => _expandedDivisionId = _expandedDivisionId == divisionId
        ? null
        : divisionId,
  );

  Future<void> _addAthlete(
    TournamentDivision division,
    List<OrganizerOpsParticipant> participants,
  ) async {
    // Phí theo nội dung chỉ có ở tournamentDivisionsProvider; không truyền
    // null vì sheet dùng nó để hiển thị và tính lệ phí.
    final raw = await ref.read(
      tournamentDivisionsProvider(widget.tournament.id).future,
    );
    final match = raw.where((item) => item['id']?.toString() == division.id);
    final json = match.isEmpty ? const <String, dynamic>{} : match.first;
    double? fee(String key) => json[key] is num
        ? (json[key] as num).toDouble()
        : double.tryParse(json[key]?.toString() ?? '');
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: false,
      builder: (_) => AddAthleteSheet(
        tournament: widget.tournament,
        divisionId: division.id,
        divisionName: division.name,
        divisionMatchType: division.matchType,
        divisionEntryFee: fee('entryFee'),
        effectiveEntryFee: fee('effectiveEntryFee'),
        participants: participants,
        onRefresh: () async {
          if (!mounted) return;
          ref.invalidate(tournamentDivisionsProvider(widget.tournament.id));
          _reload();
        },
      ),
    );
  }

  Future<void> _importRoster(TournamentDivision division) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: false,
      builder: (_) => RosterImportSheet(
        tournament: widget.tournament,
        defaultDivision: division,
        onRefresh: () async {
          if (!mounted) return;
          ref.invalidate(tournamentDivisionsProvider(widget.tournament.id));
          _reload();
        },
      ),
    );
  }

  /// Sheet sinh VĐV ảo của hạng mục (task 3.4); chọn sẵn hạng mục đang mở.
  Future<void> _openMockParticipants(TournamentDivision division) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: false,
      builder: (_) => MockParticipantsSheet(
        tournamentId: widget.tournament.id,
        divisions: widget.tournament.divisions,
        initialDivisionId: division.id,
        onRefresh: () async {
          if (!mounted) return;
          ref.invalidate(tournamentDivisionsProvider(widget.tournament.id));
          _reload();
        },
      ),
    );
  }

  /// Sheet gán suất đặc cách của hạng mục (task 3.5).
  Future<void> _openWildcard(TournamentDivision division) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: false,
      builder: (_) => WildcardSheet(
        tournamentId: widget.tournament.id,
        divisions: widget.tournament.divisions,
        initialDivisionId: division.id,
        onRefresh: () async {
          if (!mounted) return;
          ref.invalidate(tournamentDivisionsProvider(widget.tournament.id));
          _reload();
        },
      ),
    );
  }

  /// Sheet ghép cặp của hạng mục đôi (task 3.6/3.7); Web chỉ hiện nút ghép
  /// khi giải có nội dung đôi nên App hiện theo từng hạng mục đôi.
  Future<void> _openPairing(TournamentDivision division) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: false,
      builder: (_) => PairingSheet(
        tournamentId: widget.tournament.id,
        divisionId: division.id,
        divisionName: division.name,
        onRefresh: () async {
          if (!mounted) return;
          ref.invalidate(tournamentDivisionsProvider(widget.tournament.id));
          _reload();
        },
      ),
    );
  }

  /// "Tự ghép": pick one of the three strategies, confirm, then one POST for
  /// the open division only. Double taps are ignored while it runs.
  Future<void> _autoPair(TournamentDivision division) async {
    if (_autoPairing) return;
    final strategy = await showDialog<PairingStrategy>(
      context: context,
      builder: (_) => const _AutoPairDialog(),
    );
    if (strategy == null || !mounted || _autoPairing) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _autoPairing = true);
    try {
      final result = await ref
          .read(tournamentManagementRepositoryProvider)
          .pairGenerate(
            widget.tournament.id,
            strategy: strategy,
            divisionId: division.id,
          );
      if (!mounted) return;
      ref.invalidate(tournamentDivisionsProvider(widget.tournament.id));
      _reload();
      final text = result.pairedCount == 0
          ? l10n.pairingNoPairsFormed
          : result.unpairedCount > 0
          ? l10n.pairingSuccessWithUnpaired(
              result.pairedCount,
              result.unpairedCount,
            )
          : l10n.pairingSuccess(result.pairedCount);
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text)));
    } catch (_) {
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.pairingActionFailed)));
    } finally {
      if (mounted) setState(() => _autoPairing = false);
    }
  }

  /// Tải file mẫu xlsx đúng ngôn ngữ đang dùng. Lỗi hiện thông báo thay vì văng ra ngoài.
  Future<void> _downloadTemplate() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await shareRosterTemplate(
        locale: Localizations.localeOf(context).languageCode,
      );
    } catch (_) {
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.rosterImportTemplateFailed)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final divisions = widget.tournament.divisions;
    return FutureBuilder<List<OrganizerOpsParticipant>>(
      future: _participantsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 240,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return SizedBox(
            height: 320,
            child: TournamentManagementError(
              error: snapshot.error,
              onRetry: _reload,
            ),
          );
        }
        final participants = snapshot.data ?? const <OrganizerOpsParticipant>[];
        // Không padding ngang: row nội dung sát mép, ngăn cách bằng đường kẻ.
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final division in divisions)
                _DivisionRow(
                  division: division,
                  participants: participants
                      .where((item) => item.divisionId == division.id)
                      .toList(growable: false),
                  tournament: widget.tournament,
                  expanded: _expandedDivisionId == division.id,
                  duration: _expandDuration,
                  onToggle: () => _toggle(division.id),
                  onAddAthlete: (list) => _addAthlete(division, list),
                  onImportExcel: () => _importRoster(division),
                  onDownloadTemplate: _downloadTemplate,
                  onOpenMockParticipants: () => _openMockParticipants(division),
                  onOpenWildcard: () => _openWildcard(division),
                  onOpenPairing: () => _openPairing(division),
                  onAutoPair: () => _autoPair(division),
                  presence: _presence,
                  onPresenceChanged: (id, present) =>
                      setState(() => _presence[id] = present),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DivisionRow extends StatelessWidget {
  const _DivisionRow({
    required this.division,
    required this.participants,
    required this.tournament,
    required this.expanded,
    required this.duration,
    required this.onToggle,
    required this.onAddAthlete,
    required this.onImportExcel,
    required this.onDownloadTemplate,
    required this.onOpenMockParticipants,
    required this.onOpenWildcard,
    required this.onOpenPairing,
    required this.onAutoPair,
    required this.presence,
    required this.onPresenceChanged,
  });

  final TournamentDivision division;
  final List<OrganizerOpsParticipant> participants;
  final Tournament tournament;
  final bool expanded;
  final Duration duration;
  final VoidCallback onToggle;
  final void Function(List<OrganizerOpsParticipant>) onAddAthlete;
  final VoidCallback onImportExcel;
  final VoidCallback onDownloadTemplate;
  final VoidCallback onOpenMockParticipants;
  final VoidCallback onOpenWildcard;
  final VoidCallback onOpenPairing;
  final VoidCallback onAutoPair;
  final Map<String, bool> presence;
  final void Function(String participantId, bool present) onPresenceChanged;

  bool _isPending(OrganizerOpsParticipant item) => const {
    'PENDING',
    'PENDING_APPROVAL',
  }.contains(item.teamStatus.toUpperCase());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final max = division.maxParticipants;
    final count = participants.length;
    final pending = participants.where(_isPending).length;
    final present = participants
        .where((item) => presence[item.id] ?? item.isPresent)
        .length;
    final waitingPartner = participants
        .where((item) => item.teamStatus.toUpperCase() == 'PENDING_PARTNER')
        .length;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: expanded ? colors.bgSurface : null,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: expanded,
            label: division.name,
            child: InkWell(
              key: ValueKey('athlete-division-row-${division.id}'),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            division.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${l10n.athletesPresentCount} $present/$count',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    LavishPill(max != null && max > 0 ? '$count/$max' : '$count'),
                    if (pending > 0) ...[
                      const SizedBox(width: 8),
                      Tooltip(
                        message: l10n.tournamentManagementPendingApplications,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$pending',
                            style: TextStyle(
                              color: colors.warning,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: duration,
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: expanded ? AppTheme.primary : colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: duration,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
                    key: ValueKey('athlete-division-body-${division.id}'),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
                          child: _AthleteActionRow(
                            showPairing: division.isDoubles,
                            waitingPartner: waitingPartner,
                            onImportExcel: onImportExcel,
                            onOpenPairing: onOpenPairing,
                            onAutoPair: onAutoPair,
                            onAddAthlete: () => onAddAthlete(participants),
                            onDownloadTemplate: onDownloadTemplate,
                            onOpenWildcard: onOpenWildcard,
                            onOpenMockParticipants: onOpenMockParticipants,
                          ),
                        ),
                        TournamentManagementPeopleSection(
                          tournament: tournament,
                          showRegistration: true,
                          divisionId: division.id,
                          divisionName: division.name,
                          embedded: true,
                          onPresenceChanged: onPresenceChanged,
                          // Như web: nội dung đôi hoặc môn đồng đội (teamSize).
                          pairFormat:
                              tournament.teamSize != null ||
                              const {
                                'DOUBLES',
                                'MIXED_DOUBLES',
                              }.contains(division.matchType.toUpperCase()),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}


/// Design 2b: one row of equal boxes, icon above a one-line label; the main
/// action (add athlete) is filled and the rarely used ones sit in the more box.
class _AthleteActionRow extends StatelessWidget {
  const _AthleteActionRow({
    required this.showPairing,
    required this.waitingPartner,
    required this.onImportExcel,
    required this.onOpenPairing,
    required this.onAutoPair,
    required this.onAddAthlete,
    required this.onDownloadTemplate,
    required this.onOpenWildcard,
    required this.onOpenMockParticipants,
  });

  /// Pairing (manual + auto) only applies to doubles divisions.
  final bool showPairing;

  /// Athletes still waiting for a partner (badge on the pairing box).
  final int waitingPartner;
  final VoidCallback onImportExcel;
  final VoidCallback onOpenPairing;
  final VoidCallback onAutoPair;
  final VoidCallback onAddAthlete;
  final VoidCallback onDownloadTemplate;
  final VoidCallback onOpenWildcard;
  final VoidCallback onOpenMockParticipants;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const gap = SizedBox(width: 6);
    final compact = const EdgeInsets.symmetric(horizontal: 10);
    const labelStyle = TextStyle(fontSize: 12);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          FilledButton.icon(
            key: const ValueKey('athletes-add'),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: compact,
            ),
            onPressed: onAddAthlete,
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
            label: Text(l10n.opsAddAthlete, style: labelStyle),
          ),
          gap,
          OutlinedButton.icon(
            key: const ValueKey('athletes-import-excel'),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: compact,
            ),
            onPressed: onImportExcel,
            icon: const Icon(Icons.upload_file_rounded, size: 16),
            label: Text(l10n.rosterImportOpen, style: labelStyle),
          ),
          gap,
          OutlinedButton.icon(
            key: const ValueKey('athletes-download-template'),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: compact,
            ),
            onPressed: onDownloadTemplate,
            icon: const Icon(Icons.download_rounded, size: 16),
            label: Text(l10n.rosterImportDownloadTemplate, style: labelStyle),
          ),
          gap,
          OutlinedButton.icon(
            key: const ValueKey('athletes-mock-data'),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: compact,
            ),
            onPressed: onOpenMockParticipants,
            icon: const Icon(Icons.auto_awesome_rounded, size: 16),
            label: Text(l10n.mockParticipantsOpen, style: labelStyle),
          ),
          gap,
          OutlinedButton.icon(
            key: const ValueKey('athletes-wildcard'),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: compact,
            ),
            onPressed: onOpenWildcard,
            icon: const Icon(Icons.workspace_premium_rounded, size: 16),
            label: Text(l10n.wildcardOpen, style: labelStyle),
          ),
          if (showPairing) ...[
            gap,
            OutlinedButton.icon(
              key: const ValueKey('athletes-pairing'),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: compact,
              ),
              onPressed: onOpenPairing,
              icon: const Icon(Icons.handshake_rounded, size: 16),
              label: Text(
                waitingPartner > 0
                    ? '${l10n.pairingOpen} ($waitingPartner)'
                    : l10n.pairingOpen,
                style: labelStyle,
              ),
            ),
            gap,
            OutlinedButton.icon(
              key: const ValueKey('athletes-auto-pair'),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: compact,
              ),
              onPressed: onAutoPair,
              icon: const Icon(Icons.shuffle_rounded, size: 16),
              label: Text(l10n.athletesAutoPair, style: labelStyle),
            ),
          ],
        ],
      ),
    );
  }
}

class _AutoPairDialog extends StatefulWidget {
  const _AutoPairDialog();

  @override
  State<_AutoPairDialog> createState() => _AutoPairDialogState();
}

class _AutoPairDialogState extends State<_AutoPairDialog> {
  PairingStrategy _strategy = PairingStrategy.random;

  (String, String) _text(AppLocalizations l10n, PairingStrategy strategy) =>
      switch (strategy) {
        PairingStrategy.random => (
          l10n.pairingStrategyRandomLabel,
          l10n.pairingStrategyRandomHint,
        ),
        PairingStrategy.eloBalanced => (
          l10n.pairingStrategyEloBalancedLabel,
          l10n.pairingStrategyEloBalancedHint,
        ),
        PairingStrategy.sameLevel => (
          l10n.pairingStrategySameLevelLabel,
          l10n.pairingStrategySameLevelHint,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.pairingAutoTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.pairingAutoDescription),
            const SizedBox(height: 8),
            for (final strategy in PairingStrategy.values)
              ListTile(
                key: ValueKey('auto-pair-strategy-${strategy.name}'),
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(
                  _strategy == strategy
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: _strategy == strategy ? LavishColors.accent : null,
                ),
                title: Text(_text(l10n, strategy).$1),
                subtitle: Text(_text(l10n, strategy).$2),
                onTap: () => setState(() => _strategy = strategy),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('auto-pair-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          key: const ValueKey('auto-pair-confirm'),
          onPressed: () => Navigator.of(context).pop(_strategy),
          child: Text(l10n.pairingRandomConfirmAction),
        ),
      ],
    );
  }
}
