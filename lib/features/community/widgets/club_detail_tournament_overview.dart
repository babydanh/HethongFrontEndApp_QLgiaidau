part of '../screens/club_detail_screen.dart';

extension _ClubDetailTournamentOverview on _ClubDetailScreenState {
  bool _matchesTournamentStatus(String status, String filter) {
    if (filter == 'ALL') return true;
    if (filter == 'UPCOMING') {
      return StatusHelper.isTournamentUpcoming(status) ||
          StatusHelper.isTournamentRegistration(status);
    }
    if (filter == 'ONGOING') {
      return StatusHelper.isTournamentInProgress(status);
    }
    if (filter == 'COMPLETED') {
      return StatusHelper.isTournamentCompleted(status);
    }
    return true;
  }

  bool _matchesSessionStatus(String status, String filter) {
    if (status == 'CANCELLED') return false;
    if (filter == 'ALL') return true;
    if (filter == 'UPCOMING') return status == 'OPEN';
    if (filter == 'ONGOING') return status == 'LIVE';
    if (filter == 'COMPLETED') return status == 'CLOSED' || status == 'ENDED';
    return true;
  }

  String _tournamentSportLabel(String sport, AppLocalizations l10n) {
    final key = sport.trim().toLowerCase();
    final localized = l10n.sportDisplayName(key);
    return localized.isEmpty ? l10n.clubDetailOtherSport : localized;
  }

  Widget _buildTournamentFilters(
    AppColorsExtension colors,
    List<String> sports,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final options = <(String, String)>[
      ('ALL', l10n.clubDetailAllStatuses),
      ('UPCOMING', l10n.clubDetailUpcoming),
      ('ONGOING', l10n.clubDetailOngoing),
      ('COMPLETED', l10n.clubDetailCompleted),
      if (sports.length > 1)
        ...sports.map(
          (sport) => ('SPORT_$sport', _tournamentSportLabel(sport, l10n)),
        ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: options.map((option) {
          final isSportOption = option.$1.startsWith('SPORT_');
          final isSelected = isSportOption
              ? _tournamentSportFilter == option.$1.substring(6)
              : (_tournamentStatusFilter == option.$1 &&
                    _tournamentSportFilter == 'ALL');

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                option.$2,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              selected: isSelected,
              onSelected: (_) {
                _updateClubState(() {
                  if (isSportOption) {
                    final sportKey = option.$1.substring(6);
                    _tournamentSportFilter = _tournamentSportFilter == sportKey
                        ? 'ALL'
                        : sportKey;
                  } else {
                    _tournamentStatusFilter = option.$1;
                    _tournamentSportFilter = 'ALL';
                  }
                });
              },
              selectedColor: AppTheme.primary.withValues(alpha: 0.14),
              side: BorderSide(
                color: isSelected ? AppTheme.primary : colors.border,
              ),
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primary : colors.textSecondary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTournamentsTab(Community club, AppColorsExtension colors) {
    return _ClubTournamentsFullScreenView(
      club: club,
      colors: colors,
      clubDetailState: this,
    );
  }
}

class _ClubTournamentsFullScreenView extends ConsumerStatefulWidget {
  final Community club;
  final AppColorsExtension colors;
  final _ClubDetailScreenState clubDetailState;

  const _ClubTournamentsFullScreenView({
    required this.club,
    required this.colors,
    required this.clubDetailState,
  });

  @override
  ConsumerState<_ClubTournamentsFullScreenView> createState() =>
      _ClubTournamentsFullScreenViewState();
}

class _ClubTournamentsFullScreenViewState
    extends ConsumerState<_ClubTournamentsFullScreenView> {
  String _tournamentStatusFilter = 'ALL';
  String _tournamentSportFilter = 'ALL';

  Future<void> _refresh() async {
    ref.invalidate(communityTournamentsProvider(widget.club.id));
    ref.invalidate(clubMatchSessionsProvider(widget.club.id));
  }

  Widget _buildFilters(
    BuildContext context,
    AppColorsExtension colors,
    List<String> sports,
    AppLocalizations l10n,
  ) {
    final options = <(String, String)>[
      ('ALL', l10n.clubDetailAllStatuses),
      ('UPCOMING', l10n.clubDetailUpcoming),
      ('ONGOING', l10n.clubDetailOngoing),
      ('COMPLETED', l10n.clubDetailCompleted),
      if (sports.length > 1)
        ...sports.map(
          (sport) => (
            'SPORT_$sport',
            widget.clubDetailState._tournamentSportLabel(sport, l10n),
          ),
        ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: options.map((option) {
          final isSportOption = option.$1.startsWith('SPORT_');
          final isSelected = isSportOption
              ? _tournamentSportFilter == option.$1.substring(6)
              : (_tournamentStatusFilter == option.$1 &&
                    _tournamentSportFilter == 'ALL');

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                option.$2,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  if (isSportOption) {
                    final sportKey = option.$1.substring(6);
                    _tournamentSportFilter = _tournamentSportFilter == sportKey
                        ? 'ALL'
                        : sportKey;
                  } else {
                    _tournamentStatusFilter = option.$1;
                    _tournamentSportFilter = 'ALL';
                  }
                });
              },
              selectedColor: AppTheme.primary.withValues(alpha: 0.14),
              side: BorderSide(
                color: isSelected ? AppTheme.primary : colors.border,
              ),
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primary : colors.textSecondary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final club = widget.club;
    final colors = widget.colors;
    final clubDetailState = widget.clubDetailState;
    final clubId = club.id;

    final tourneysAsync = ref.watch(communityTournamentsProvider(clubId));
    final sessionsAsync = ref.watch(clubMatchSessionsProvider(clubId));

    final isTourneysLoading =
        tourneysAsync.isLoading && !tourneysAsync.hasValue;
    final isSessionsLoading =
        sessionsAsync.isLoading && !sessionsAsync.hasValue;

    final tourneys = tourneysAsync.asData?.value ?? const [];
    final sessions = sessionsAsync.asData?.value ?? const [];
    final hasData = tourneys.isNotEmpty || sessions.isNotEmpty;

    final isAdmin =
        clubDetailState._myMembership?.role == 'OWNER' ||
        clubDetailState._myMembership?.role == 'ADMIN' ||
        clubDetailState._myMembership?.role == 'MODERATOR';

    Widget body;
    if (isTourneysLoading && !hasData) {
      body = const Center(child: CircularProgressIndicator());
    } else if (isSessionsLoading && !hasData && !tourneysAsync.hasValue) {
      body = const Center(child: CircularProgressIndicator());
    } else if (!hasData) {
      if (tourneysAsync.hasError && sessionsAsync.hasError) {
        body = Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 48, color: colors.textMuted),
              const SizedBox(height: 12),
              Text(
                l10n.club_loadDataError,
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(l10n.infoRetry),
              ),
            ],
          ),
        );
      } else {
        body = RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 80),
              Icon(
                Icons.sports_tennis_rounded,
                size: 52,
                color: colors.textMuted,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.club_noTournaments,
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Center(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ClubMatchSessionsScreen(
                              communityId: clubId,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.groups_rounded, size: 18),
                      label: Text(l10n.clubMatchSessionTitle),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(l10n.infoRetry),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    } else {
      final sports = tourneys
          .map((t) => t.sport)
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();

      // Filter tournaments
      final filteredTourneys = tourneys.where((t) {
        if (!isAdmin && StatusHelper.isTournamentDraft(t.status)) {
          return false;
        }
        if (_tournamentSportFilter != 'ALL' &&
            t.sport != _tournamentSportFilter) {
          return false;
        }
        return clubDetailState._matchesTournamentStatus(
          t.status,
          _tournamentStatusFilter,
        );
      }).toList();

      // Filter sessions
      final filteredSessions = sessions.where((s) {
        return clubDetailState._matchesSessionStatus(
          s.status,
          _tournamentStatusFilter,
        );
      }).toList();

      final totalItems = filteredTourneys.length + filteredSessions.length;

      body = RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            _buildFilters(context, colors, sports, l10n),
            if (totalItems == 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 40),
                child: Column(
                  children: [
                    Icon(
                      Icons.filter_alt_off_rounded,
                      size: 42,
                      color: colors.textMuted,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.clubDetailNoFilteredTournaments,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _tournamentStatusFilter = 'ALL';
                        _tournamentSportFilter = 'ALL';
                      }),
                      child: Text(l10n.clubDetailClearFilters),
                    ),
                  ],
                ),
              )
            else ...[
              // Hiển thị danh sách Buổi giao lưu
              if (filteredSessions.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 6, 2, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0D9488),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.clubMatchSessionTitle.toUpperCase(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          '${filteredSessions.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0D9488),
                          ),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ClubMatchSessionsScreen(
                                communityId: clubId,
                              ),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.infoAll,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 14,
                              color: colors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ...filteredSessions.map(
                  (session) => clubDetailState._buildSessionCard(
                    session,
                    club,
                    colors,
                  ),
                ),
              ],

              // Hiển thị danh sách Giải đấu
              if (filteredTourneys.isNotEmpty) ...[
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    2,
                    filteredSessions.isNotEmpty ? 18 : 6,
                    2,
                    12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.club_tabTournaments.toUpperCase(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          '${filteredTourneys.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ...filteredTourneys.map(
                  (tourney) => clubDetailState._buildTourneyCard(
                    tourney,
                    club,
                    colors,
                  ),
                ),
              ],
            ],
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: colors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.bgCard.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close_rounded,
              color: colors.textPrimary,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.club_tabTournaments,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.infoRetry,
            onPressed: _refresh,
          ),
        ],
      ),
      body: body,
    );
  }
}
