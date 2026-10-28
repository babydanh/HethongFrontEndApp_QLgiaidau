import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/services/roster_template_service.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/add_athlete_sheet.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/mock_participants_sheet.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/roster_import_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_people_section.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/pairing_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/wildcard_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/shared/widgets/search_filter_bar.dart';

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

  /// Last loaded list, kept across reloads so the search bar (which lives
  /// outside the FutureBuilder) can keep counting while a reload is running.
  List<OrganizerOpsParticipant> _loaded = const [];

  @override
  void initState() {
    super.initState();
    _participantsFuture = _load();
  }

  Future<List<OrganizerOpsParticipant>> _load() => ref
      .read(tournamentRepositoryProvider)
      .getOrganizerParticipants(widget.tournament.id)
      .then((list) {
        if (mounted) setState(() => _loaded = list);
        return list;
      });

  void _reload() => setState(() => _participantsFuture = _load());

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

  List<SearchFilterGroup> _searchGroups(AppLocalizations l10n) => [
    SearchFilterGroup(
      id: 'approval',
      label: l10n.athleteFilterApproval,
      options: [
        (value: 'pending', label: l10n.participantFilterPending),
        (value: 'pendingPartner', label: l10n.participantFilterPendingPartner),
        (value: 'approved', label: l10n.participantFilterApproved),
        (value: 'rejected', label: l10n.participantFilterRejected),
      ],
    ),
    SearchFilterGroup(
      id: 'fee',
      label: l10n.athleteFilterFee,
      options: [
        (value: 'paid', label: l10n.athleteFeePaid),
        (value: 'unpaid', label: l10n.participantFilterUnpaid),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final searchKey = '${widget.tournament.id}:athletes';
    final groups = _searchGroups(l10n);
    final search = ref.watch(searchFilterProvider(searchKey)).pruned(groups);
    final matches = search.isActive ? participantSearchMatcher(search) : null;
    final matched = matches == null
        ? _loaded
        : [
            for (final item in _loaded)
              if (matches(item)) item,
          ];
    // The toolbar and search bar stay outside the FutureBuilder: a reload (add,
    // import, pairing) must not tear them down or reset the keyboard.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 6, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.tournamentManagementTabAthletes,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SearchFilterToggle(tabKey: searchKey),
            ],
          ),
        ),
        SearchFilterBar(
          tabKey: searchKey,
          hint: l10n.athleteSearchHint,
          groups: groups,
          resultCount: matched.length,
        ),
        _buildList(search.isActive, {for (final item in matched) item.divisionId}),
      ],
    );
  }

  Widget _buildList(bool searching, Set<String?> matchedDivisionIds) {
    final divisions = widget.tournament.divisions;
    final searchKey = '${widget.tournament.id}:athletes';
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
                if (!searching || matchedDivisionIds.contains(division.id))
                  _DivisionRow(
                    division: division,
                    participants: participants
                        .where((item) => item.divisionId == division.id)
                        .toList(growable: false),
                    tournament: widget.tournament,
                    searchKey: searchKey,
                    expanded: _expandedDivisionId == division.id,
                    duration: _expandDuration,
                    onToggle: () => _toggle(division.id),
                    onAddAthlete: (list) => _addAthlete(division, list),
                    onImportExcel: () => _importRoster(division),
                    onDownloadTemplate: _downloadTemplate,
                    onOpenMockParticipants: () =>
                        _openMockParticipants(division),
                    onOpenWildcard: () => _openWildcard(division),
                    onOpenPairing: () => _openPairing(division),
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
    required this.searchKey,
    required this.expanded,
    required this.duration,
    required this.onToggle,
    required this.onAddAthlete,
    required this.onImportExcel,
    required this.onDownloadTemplate,
    required this.onOpenMockParticipants,
    required this.onOpenWildcard,
    required this.onOpenPairing,
  });

  final TournamentDivision division;
  final List<OrganizerOpsParticipant> participants;
  final Tournament tournament;
  final String searchKey;
  final bool expanded;
  final Duration duration;
  final VoidCallback onToggle;
  final void Function(List<OrganizerOpsParticipant>) onAddAthlete;
  final VoidCallback onImportExcel;
  final VoidCallback onDownloadTemplate;
  final VoidCallback onOpenMockParticipants;
  final VoidCallback onOpenWildcard;
  final VoidCallback onOpenPairing;

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
                      child: Text(
                        division.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      max != null && max > 0 ? '$count/$max' : '$count',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton.icon(
                                onPressed: () => onAddAthlete(participants),
                                icon: const Icon(
                                  Icons.person_add_alt_1_rounded,
                                ),
                                label: Text(l10n.opsAddAthlete),
                              ),
                              OutlinedButton.icon(
                                key: const ValueKey('athletes-import-excel'),
                                onPressed: onImportExcel,
                                icon: const Icon(Icons.upload_file_rounded),
                                label: Text(l10n.rosterImportOpen),
                              ),
                              OutlinedButton.icon(
                                key: const ValueKey(
                                  'athletes-download-template',
                                ),
                                onPressed: onDownloadTemplate,
                                icon: const Icon(Icons.download_rounded),
                                label: Text(l10n.rosterImportDownloadTemplate),
                              ),
                              OutlinedButton.icon(
                                key: const ValueKey('athletes-mock-data'),
                                onPressed: onOpenMockParticipants,
                                icon: const Icon(Icons.auto_awesome_rounded),
                                label: Text(l10n.mockParticipantsOpen),
                              ),
                              OutlinedButton.icon(
                                key: const ValueKey('athletes-wildcard'),
                                onPressed: onOpenWildcard,
                                icon: const Icon(
                                  Icons.workspace_premium_rounded,
                                ),
                                label: Text(l10n.wildcardOpen),
                              ),
                              // Web chỉ hiện nút ghép khi giải có nội dung
                              // đôi (hasTournamentDoubles); App hiện theo
                              // từng hạng mục đôi.
                              if (division.isDoubles)
                                OutlinedButton.icon(
                                  key: const ValueKey('athletes-pairing'),
                                  onPressed: onOpenPairing,
                                  icon: const Icon(Icons.handshake_rounded),
                                  label: Text(l10n.pairingOpen),
                                ),
                            ],
                          ),
                        ),
                        TournamentManagementPeopleSection(
                          tournament: tournament,
                          showRegistration: true,
                          searchKey: searchKey,
                          divisionId: division.id,
                          divisionName: division.name,
                          embedded: true,
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
