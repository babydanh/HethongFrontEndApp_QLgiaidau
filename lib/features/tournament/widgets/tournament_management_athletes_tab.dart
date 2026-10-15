import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/add_athlete_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_people_section.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
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

  @override
  void initState() {
    super.initState();
    _participantsFuture = _load();
  }

  Future<List<OrganizerOpsParticipant>> _load() => ref
      .read(tournamentRepositoryProvider)
      .getOrganizerParticipants(widget.tournament.id);

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
        final participants =
            snapshot.data ?? const <OrganizerOpsParticipant>[];
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
  });

  final TournamentDivision division;
  final List<OrganizerOpsParticipant> participants;
  final Tournament tournament;
  final bool expanded;
  final Duration duration;
  final VoidCallback onToggle;
  final void Function(List<OrganizerOpsParticipant>) onAddAthlete;

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
                          child: FilledButton.icon(
                            onPressed: () => onAddAthlete(participants),
                            icon: const Icon(Icons.person_add_alt_1_rounded),
                            label: Text(l10n.opsAddAthlete),
                          ),
                        ),
                        TournamentManagementPeopleSection(
                          tournament: tournament,
                          showRegistration: true,
                          divisionId: division.id,
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
