import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/utils/match_visibility.dart';
import 'package:app_quanly_giaidau/core/utils/navigation_helpers.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/core/widgets/province_picker.dart';
import 'package:app_quanly_giaidau/core/widgets/tournament_avatar.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations_extensions.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/providers/regions_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class _SearchFilterDraft {
  _SearchFilterDraft.fromState(_GlobalSearchScreenState state)
    : matchSport = state._matchSport,
      matchStatus = state._matchStatus,
      matchDateRange = state._matchDateRange,
      matchLocation = state._matchLocationController.text,
      tournamentSport = state._tournamentSport,
      tournamentStatus = state._tournamentStatus,
      tournamentDateRange = state._tournamentDateRange,
      tournamentProvinceCode = state._tournamentProvinceCode,
      clubSport = state._clubSport,
      clubProvince = state._clubProvince,
      athleteSport = state._athleteSport,
      athleteGender = state._athleteGender,
      athleteProvince = state._athleteProvince;

  String matchSport;
  String matchStatus;
  DateTimeRange? matchDateRange;
  String matchLocation;
  String tournamentSport;
  String tournamentStatus;
  DateTimeRange? tournamentDateRange;
  String tournamentProvinceCode;
  String clubSport;
  String? clubProvince;
  String athleteSport;
  String athleteGender;
  String? athleteProvince;

  void reset() {
    matchSport = 'all';
    matchStatus = 'all';
    matchDateRange = null;
    matchLocation = '';
    tournamentSport = 'all';
    tournamentStatus = 'all';
    tournamentDateRange = null;
    tournamentProvinceCode = '';
    clubSport = 'all';
    clubProvince = null;
    athleteSport = 'all';
    athleteGender = 'all';
    athleteProvince = null;
  }
}

class GlobalSearchScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;
  final String initialQuery;
  final bool showFiltersInitially;

  const GlobalSearchScreen({
    super.key,
    required this.initialTabIndex,
    required this.initialQuery,
    this.showFiltersInitially = false,
  });

  static Future<void> show({
    required BuildContext context,
    required int initialTabIndex,
    required String initialQuery,
    bool showFiltersInitially = false,
  }) {
    return showGeneralDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: MediaQuery.of(context).disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 360),
      pageBuilder: (context, animation, secondaryAnimation) =>
          GlobalSearchScreen(
            initialTabIndex: initialTabIndex,
            initialQuery: initialQuery,
            showFiltersInitially: showFiltersInitially,
          ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final reducedMotion = MediaQuery.of(context).disableAnimations;
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: reducedMotion
              ? const AlwaysStoppedAnimation(Offset.zero)
              : Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(curved),
          child: child,
        );
      },
    );
  }

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  static const _scopes = [1, 0, 3, 4, 5];

  late final TextEditingController _queryController;
  late final TextEditingController _matchLocationController;
  late int _scope;
  int _unrenderableMatchCount = 0;
  Widget _buildFilterButton(AppColorsExtension colors, AppLocalizations l10n) {
    final isActive = _activeFilterCount > 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: _activeFilterCount == 0
              ? l10n.homeGlobalSearchAdvancedFilters
              : '${l10n.homeGlobalSearchAdvancedFilters} ($_activeFilterCount)',
          onPressed: _showFilterSheet,
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            backgroundColor: isActive ? AppTheme.primary : colors.bgDark,
            foregroundColor: isActive ? Colors.white : colors.textSecondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
          icon: const Icon(Icons.tune_rounded, size: 20),
        ),
        if (_activeFilterCount > 0)
          Positioned(
            top: -4,
            right: -3,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                border: Border.all(color: AppTheme.primary),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$_activeFilterCount',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showFilterSheet() async {
    FocusScope.of(context).unfocus();
    final draft = _SearchFilterDraft.fromState(this);
    final locationController = TextEditingController(text: draft.matchLocation);
    final colors = context.colors;
    final screenHeight = MediaQuery.sizeOf(context).height;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : null,
      useSafeArea: true,
      backgroundColor: colors.bgDark,
      constraints: BoxConstraints(maxHeight: screenHeight * 0.9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Consumer(
        builder: (context, ref, _) {
          final l10n = AppLocalizations.of(context)!;
          final sheetColors = context.colors;
          final categories =
              ref.watch(categoriesProvider).asData?.value ??
              const <CategoryModel>[];

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.72,
            minChildSize: 0.46,
            maxChildSize: 1,
            builder: (context, scrollController) => StatefulBuilder(
              builder: (context, setSheetState) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 6),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: sheetColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 8, 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 20,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.homeGlobalSearchAdvancedFilters,
                            style: TextStyle(
                              color: sheetColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).closeButtonTooltip,
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: sheetColors.border),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      children: _buildFilterFields(
                        l10n,
                        sheetColors,
                        categories,
                        draft,
                        locationController,
                        setSheetState,
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    minimum: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Container(
                      padding: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: sheetColors.border),
                        ),
                      ),
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              setSheetState(draft.reset);
                              locationController.clear();
                            },
                            child: Text(l10n.homeGlobalSearchClearFilters),
                          ),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: () {
                              draft.matchLocation = locationController.text;
                              _applyFilterDraft(draft);
                              Navigator.of(sheetContext).pop();
                            },
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: Text(l10n.filterApply),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    locationController.dispose();
  }

  void _applyFilterDraft(_SearchFilterDraft draft) {
    setState(() {
      _matchSport = draft.matchSport;
      _matchStatus = draft.matchStatus;
      _matchDateRange = draft.matchDateRange;
      _tournamentSport = draft.tournamentSport;
      _tournamentStatus = draft.tournamentStatus;
      _tournamentDateRange = draft.tournamentDateRange;
      _tournamentProvinceCode = draft.tournamentProvinceCode;
      _clubSport = draft.clubSport;
      _clubProvince = draft.clubProvince;
      _athleteSport = draft.athleteSport;
      _athleteGender = draft.athleteGender;
      _athleteProvince = draft.athleteProvince;
    });
    _matchLocationController.text = draft.matchLocation;
    _loadScope();
  }

  List<Widget> _buildFilterFields(
    AppLocalizations l10n,
    AppColorsExtension colors,
    List<CategoryModel> categories,
    _SearchFilterDraft draft,
    TextEditingController locationController,
    StateSetter setSheetState,
  ) {
    final sportBySlug = <(String, String)>[
      ('all', l10n.filterAll),
      ...categories.map((category) => (category.slug, category.name)),
    ];
    final sportById = <(String, String)>[
      ('all', l10n.filterAll),
      ...categories.map((category) => (category.id, category.name)),
    ];
    final provinces = <(String, String)>[
      ('', l10n.filterAll),
      ...ProvinceData.all.map((province) => (province.code, province.name)),
    ];
    final children = <Widget>[];
    void add(
      String label,
      String value,
      List<(String, String)> options,
      ValueChanged<String> onChanged,
    ) {
      children.add(
        _dropdown(label, value, options, (next) {
          if (next != null) setSheetState(() => onChanged(next));
        }, colors),
      );
    }

    if (_scope == 0 || _scope == 5) {
      add(
        l10n.homeGlobalSearchSport,
        draft.matchSport,
        sportBySlug,
        (value) => draft.matchSport = value,
      );
      add(l10n.homeGlobalSearchStatus, draft.matchStatus, [
        ('all', l10n.filterAll),
        ('scheduled', l10n.matchesFilterScheduled),
        ('live', l10n.matchesStatusLive),
        ('completed', l10n.matchesStatusCompleted),
      ], (value) => draft.matchStatus = value);
      children.add(
        _dateFilter(l10n, colors, draft.matchDateRange, (range) {
          setSheetState(() => draft.matchDateRange = range);
        }),
      );
      children.add(
        _textFilter(
          label: l10n.homeGlobalSearchLocation,
          controller: locationController,
          colors: colors,
        ),
      );
    } else if (_scope == 1) {
      add(
        l10n.homeGlobalSearchSport,
        draft.tournamentSport,
        sportBySlug,
        (value) => draft.tournamentSport = value,
      );
      add(l10n.homeGlobalSearchStatus, draft.tournamentStatus, [
        ('all', l10n.filterAll),
        ('registration', l10n.matchesFilterRegistration),
        ('upcoming', l10n.matchesFilterScheduled),
        ('in_progress', l10n.homeInProgressStatus),
        ('completed', l10n.matchesStatusCompleted),
      ], (value) => draft.tournamentStatus = value);
      add(
        l10n.homeGlobalSearchProvince,
        draft.tournamentProvinceCode,
        provinces,
        (value) => draft.tournamentProvinceCode = value,
      );
      children.add(
        _dateFilter(l10n, colors, draft.tournamentDateRange, (range) {
          setSheetState(() => draft.tournamentDateRange = range);
        }),
      );
    } else if (_scope == 3) {
      add(
        l10n.homeGlobalSearchSport,
        draft.clubSport,
        sportById,
        (value) => draft.clubSport = value,
      );
      add(
        l10n.homeGlobalSearchProvince,
        draft.clubProvince ?? '',
        provinces,
        (value) => draft.clubProvince = value.isEmpty ? null : value,
      );
    } else if (_scope == 4) {
      add(
        l10n.homeGlobalSearchSport,
        draft.athleteSport,
        sportById,
        (value) => draft.athleteSport = value,
      );
      add(l10n.homeGlobalSearchGender, draft.athleteGender, [
        ('all', l10n.filterAll),
        ('MALE', l10n.clubRankingMale),
        ('FEMALE', l10n.clubRankingFemale),
      ], (value) => draft.athleteGender = value);
      add(
        l10n.homeGlobalSearchProvince,
        draft.athleteProvince ?? '',
        provinces,
        (value) => draft.athleteProvince = value.isEmpty ? null : value,
      );
    }

    return [
      for (var index = 0; index < children.length; index++) ...[
        if (index > 0) const SizedBox(height: 12),
        children[index],
      ],
    ];
  }

  Timer? _debounce;
  int _requestVersion = 0;
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _nextCursor;
  String? _error;

  List<MatchModel> _matches = [];
  List<Tournament> _tournaments = [];
  List<Community> _clubs = [];
  List<PlayerRanking> _athletes = [];

  String _matchSport = 'all';
  String _matchStatus = 'all';
  DateTimeRange? _matchDateRange;
  String _tournamentSport = 'all';
  String _tournamentStatus = 'all';
  DateTimeRange? _tournamentDateRange;
  String _tournamentProvinceCode = '';
  String _clubSport = 'all';
  String? _clubProvince;
  String _athleteSport = 'all';
  String _athleteGender = 'all';
  String? _athleteProvince;

  @override
  void initState() {
    super.initState();
    _scope = _scopes.contains(widget.initialTabIndex)
        ? widget.initialTabIndex
        : 0;
    _queryController = TextEditingController(text: widget.initialQuery);
    _matchLocationController = TextEditingController();
    _queryController.addListener(_onQueryChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadScope();
      if (widget.showFiltersInitially) _showFilterSheet();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController
      ..removeListener(_onQueryChanged)
      ..dispose();
    _matchLocationController.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _loadScope);
  }

  void _selectScope(int scope) {
    if (_scope == scope) return;
    setState(() {
      _scope = scope;
      _error = null;
    });
    _loadScope();
  }

  Future<void> _loadScope({bool append = false}) async {
    final version = ++_requestVersion;
    final query = _queryController.text.trim();
    if (!append) {
      setState(() {
        _loading = true;
        _loadingMore = false;
        _error = null;
        _hasMore = false;
        _nextCursor = null;
        _unrenderableMatchCount = 0;
      });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      switch (_scope) {
        case 0:
        case 5:
          final categories =
              ref.read(categoriesProvider).asData?.value ??
              const <CategoryModel>[];
          CategoryModel? selectedCategory;
          for (final category in categories) {
            if (category.slug == _matchSport) {
              selectedCategory = category;
              break;
            }
          }
          var cursor = append ? _nextCursor : null;
          var fetchMore = true;
          final accumulated = <MatchModel>[];
          var totalHidden = 0;
          var lastHasMore = false;
          String? lastNextCursor;

          while (fetchMore && accumulated.length < 10) {
            final result = await ref
                .read(matchRepositoryProvider)
                .getPublicMatchesPaged(
                  cursor: cursor,
                  limit: 20,
                  search: _scope == 0 && query.isNotEmpty ? query : null,
                  categoryId: selectedCategory?.id,
                  status: _matchStatus == 'all' ? null : _matchStatus,
                  startDate: _matchDateRange?.start,
                  endDate: _matchDateRange?.end,
                );
            if (!mounted || version != _requestVersion) return;

            final pageMatches = result.matches
                .where(isRenderablePublicMatch)
                .toList(growable: false);
            final hiddenCount = result.matches.length - pageMatches.length;
            totalHidden += hiddenCount;
            accumulated.addAll(pageMatches);

            lastHasMore =
                result.hasMore && (result.nextCursor?.isNotEmpty ?? false);
            lastNextCursor = result.nextCursor;
            cursor = result.nextCursor;

            // Stop looping if backend has no more or we got enough matches
            if (!lastHasMore || cursor == null || accumulated.length >= 10) {
              fetchMore = false;
            }
          }

          _unrenderableMatchCount = append
              ? _unrenderableMatchCount + totalHidden
              : totalHidden;
          _matches = append ? [..._matches, ...accumulated] : accumulated;
          _nextCursor = lastNextCursor;
          _hasMore = lastHasMore;
          break;
        case 1:
          final result = await ref
              .read(tournamentRepositoryProvider)
              .getPublicTournamentsPaged(
                cursor: append ? _nextCursor : null,
                limit: 10,
                sport: _tournamentSport == 'all' ? null : _tournamentSport,
                status: _tournamentStatus == 'all' ? null : _tournamentStatus,
                search: query.isEmpty ? null : query,
                province: _tournamentProvinceCode.isEmpty
                    ? null
                    : ProvinceData.all
                          .firstWhere(
                            (item) => item.code == _tournamentProvinceCode,
                          )
                          .name,
                startDate: _tournamentDateRange?.start,
                rethrowOnError: true,
              );
          if (!mounted || version != _requestVersion) return;
          _tournaments = append
              ? [..._tournaments, ...result.tournaments]
              : result.tournaments;
          _nextCursor = result.nextCursor;
          _hasMore = result.hasMore && (result.nextCursor?.isNotEmpty ?? false);
          break;
        case 3:
          final result = await ref
              .read(communityRepositoryProvider)
              .getCommunitiesPaged(
                cursor: append ? _nextCursor : null,
                limit: 10,
                search: query.isEmpty ? null : query,
                provinceCode: _clubProvince,
                categoryId: _clubSport == 'all' ? null : _clubSport,
                rethrowOnError: true,
              );
          if (!mounted || version != _requestVersion) return;
          _clubs = append
              ? [..._clubs, ...result.communities]
              : result.communities;
          _nextCursor = result.nextCursor;
          _hasMore = result.hasMore && (result.nextCursor?.isNotEmpty ?? false);
          break;
        case 4:
          final categories = await ref.read(categoriesProvider.future);
          if (!mounted || version != _requestVersion) return;
          if (categories.isEmpty) {
            _athletes = [];
            _hasMore = false;
            _nextCursor = null;
            break;
          }
          final category = _athleteSport == 'all'
              ? categories.first
              : categories.firstWhere(
                  (item) =>
                      item.id == _athleteSport || item.slug == _athleteSport,
                  orElse: () => categories.first,
                );
          final result = await ref
              .read(rankingRepositoryProvider)
              .getRankingsPaged(
                categoryId: category.id,
                cursor: append ? _nextCursor : null,
                limit: 10,
                genderRestriction: _athleteGender == 'all'
                    ? null
                    : _athleteGender,
                provinceCode: _athleteProvince,
              );
          if (!mounted || version != _requestVersion) return;
          _athletes = append
              ? [..._athletes, ...result.rankings]
              : result.rankings;
          _nextCursor = result.nextCursor;
          _hasMore = result.hasMore && (result.nextCursor?.isNotEmpty ?? false);
          break;
      }
      if (mounted && version == _requestVersion) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    } catch (_) {
      if (mounted && version == _requestVersion) {
        setState(() {
          _loading = false;
          _loadingMore = false;
          _error = 'load';
        });
      }
    }
  }

  void _loadMore() {
    if (!_loadingMore && _hasMore) _loadScope(append: true);
  }

  List<MatchModel> get _visibleMatches {
    final query = _queryController.text.trim().toLowerCase();
    final location = _matchLocationController.text.trim().toLowerCase();
    final matches = _matches.where((match) {
      if (_matchSport != 'all' && match.sportKey != _matchSport) return false;
      if (_matchStatus != 'all' && match.status.toLowerCase() != _matchStatus) {
        return false;
      }
      final searchable = _scope == 5
          ? [match.court, match.courtAddress]
          : [
              match.team1Name,
              match.team2Name,
              match.tournamentName ?? '',
              match.court,
              match.courtAddress,
              ...(match.team1Members ?? const <String>[]),
              ...(match.team2Members ?? const <String>[]),
            ];
      if (query.isNotEmpty &&
          !searchable.any((value) => value.toLowerCase().contains(query))) {
        return false;
      }
      if (location.isNotEmpty &&
          !match.court.toLowerCase().contains(location) &&
          !match.courtAddress.toLowerCase().contains(location)) {
        return false;
      }
      final scheduled = match.scheduledTime;
      if (_matchDateRange != null &&
          (scheduled == null ||
              scheduled.isBefore(_startOfDay(_matchDateRange!.start)) ||
              scheduled.isAfter(_endOfDay(_matchDateRange!.end)))) {
        return false;
      }
      return true;
    }).toList();
    matches.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return matches;
  }

  List<Tournament> get _visibleTournaments {
    final query = _queryController.text.trim().toLowerCase();
    final tournaments = _tournaments.where((tournament) {
      return query.isEmpty ||
          tournament.name.toLowerCase().contains(query) ||
          tournament.venueName?.toLowerCase().contains(query) == true;
    }).toList();
    tournaments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tournaments;
  }

  List<Community> get _visibleClubs {
    final query = _queryController.text.trim().toLowerCase();
    final clubs = _clubs.where((club) {
      return query.isEmpty ||
          club.name.toLowerCase().contains(query) ||
          (club.description ?? '').toLowerCase().contains(query);
    }).toList();
    clubs.sort(
      (a, b) => _newestFirst(
        DateTime.tryParse(a.createdAt),
        DateTime.tryParse(b.createdAt),
      ),
    );
    return clubs;
  }

  List<PlayerRanking> get _visibleAthletes {
    final query = _queryController.text.trim().toLowerCase();
    final athletes = _athletes
        .where(
          (player) =>
              query.isEmpty || player.fullName.toLowerCase().contains(query),
        )
        .toList();
    return athletes;
  }

  int _newestFirst(DateTime? a, DateTime? b) {
    if (a == null) return b == null ? 0 : 1;
    if (b == null) return -1;
    return b.compareTo(a);
  }

  int get _visibleResultCount => switch (_scope) {
    0 => _visibleMatches.length,
    1 => _visibleTournaments.length,
    3 => _visibleClubs.length,
    4 => _visibleAthletes.length,
    5 => _venueEntries(_visibleMatches).length,
    _ => 0,
  };
  DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);
  DateTime _endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  int get _activeFilterCount => switch (_scope) {
    0 || 5 =>
      (_matchSport != 'all' ? 1 : 0) +
          (_matchStatus != 'all' ? 1 : 0) +
          (_matchLocationController.text.isNotEmpty ? 1 : 0) +
          (_matchDateRange != null ? 1 : 0),
    1 =>
      (_tournamentSport != 'all' ? 1 : 0) +
          (_tournamentStatus != 'all' ? 1 : 0) +
          (_tournamentProvinceCode.isNotEmpty ? 1 : 0) +
          (_tournamentDateRange != null ? 1 : 0),
    3 => (_clubSport != 'all' ? 1 : 0) + (_clubProvince != null ? 1 : 0),
    4 =>
      (_athleteSport != 'all' ? 1 : 0) +
          (_athleteGender != 'all' ? 1 : 0) +
          (_athleteProvince != null ? 1 : 0),
    _ => 0,
  };

  void _resetFilters() {
    setState(() {
      _matchSport = 'all';
      _matchStatus = 'all';
      _matchLocationController.clear();
      _matchDateRange = null;
      _tournamentSport = 'all';
      _tournamentStatus = 'all';
      _tournamentDateRange = null;
      _tournamentProvinceCode = '';
      _clubSport = 'all';
      _clubProvince = null;
      _athleteSport = 'all';
      _athleteGender = 'all';
      _athleteProvince = null;
    });
    _loadScope();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _closeSearch();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: colors.bgDark,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(l10n, colors),
              _buildScopeSelector(l10n, colors),
              if (_scope == 5)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    l10n.homeGlobalSearchVenueNote,
                    style: TextStyle(fontSize: 12, color: colors.textMuted),
                  ),
                ),
              Expanded(child: _buildResults(l10n, colors)),
            ],
          ),
        ),
      ),
    );
  }

  void _closeSearch() {
    FocusScope.of(context).unfocus();
    Navigator.of(context, rootNavigator: true).maybePop();
  }

  Widget _buildHeader(AppLocalizations l10n, AppColorsExtension colors) {
    return Material(
      color: colors.bgSurface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 2, 10, 2),
        child: Row(
          children: [
            IconButton(
              tooltip: l10n.homeGlobalSearchClose,
              onPressed: _closeSearch,
              icon: const Icon(Icons.arrow_back_rounded, size: 22),
              color: colors.textPrimary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 36, height: 48),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: colors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Expanded(
                      child: Semantics(
                        label: l10n.homeGlobalSearchInputLabel,
                        textField: true,
                        child: TextField(
                          controller: _queryController,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _loadScope(),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 14,
                          ),
                          cursorColor: AppTheme.primary,
                          decoration: InputDecoration(
                            hintText: _scopeHint(l10n),
                            isDense: true,
                            filled: false,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 0,
                              vertical: 6,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            suffixIconConstraints:
                                const BoxConstraints.tightFor(
                                  width: 48,
                                  height: 48,
                                ),
                            suffixIcon: _queryController.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: l10n.homeGlobalSearchClear,
                                    constraints: const BoxConstraints.tightFor(
                                      width: 48,
                                      height: 48,
                                    ),
                                    padding: EdgeInsets.zero,
                                    onPressed: _queryController.clear,
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _buildFilterButton(colors, l10n),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _scopeLabel(AppLocalizations l10n, int scope) => switch (scope) {
    0 => l10n.homeSearchScopeMatches,
    1 => l10n.homeSearchScopeTournaments,
    3 => l10n.homeSearchScopeClubs,
    4 => l10n.homeSearchScopeAthletes,
    5 => l10n.homeSearchScopeVenues,
    _ => l10n.homeSearchScopeMatches,
  };

  IconData _scopeIcon(int scope) => switch (scope) {
    0 => Icons.sports_tennis_rounded,
    1 => Icons.emoji_events_rounded,
    3 => Icons.groups_2_rounded,
    4 => Icons.person_search_rounded,
    5 => Icons.place_rounded,
    _ => Icons.search_rounded,
  };

  Widget _buildScopeSelector(AppLocalizations l10n, AppColorsExtension colors) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: _scopes.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final scope = _scopes[index];
          final selected = _scope == scope;
          return Semantics(
            button: true,
            selected: selected,
            label: _scopeLabel(l10n, scope),
            child: ChoiceChip(
              avatar: Icon(
                _scopeIcon(scope),
                size: 17,
                color: selected ? AppTheme.primary : colors.textSecondary,
              ),
              label: Text(_scopeLabel(l10n, scope)),
              selected: selected,
              onSelected: (_) => _selectScope(scope),
              selectedColor: AppTheme.primary.withValues(alpha: 0.12),
              backgroundColor: colors.bgCard,
              side: BorderSide(
                color: selected
                    ? AppTheme.primary.withValues(alpha: 0.4)
                    : colors.border,
              ),
              labelStyle: TextStyle(
                color: selected ? AppTheme.primary : colors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<(String, String)> items,
    ValueChanged<String?> onChanged,
    AppColorsExtension colors,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: colors.bgDark,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item.$1, child: Text(item.$2)))
          .toList(growable: false),
      onChanged: onChanged,
    );
  }

  Widget _textFilter({
    required String label,
    required TextEditingController controller,
    required AppColorsExtension colors,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: colors.bgDark,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
      ),
    );
  }

  Widget _dateFilter(
    AppLocalizations l10n,
    AppColorsExtension colors,
    DateTimeRange? value,
    ValueChanged<DateTimeRange?> onChanged,
  ) {
    final label = value == null
        ? l10n.homeGlobalSearchDate
        : '${DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(value.start)} – ${DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(value.end)}';
    return OutlinedButton.icon(
      onPressed: () async {
        final now = DateTime.now();
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(now.year - 3),
          lastDate: DateTime(now.year + 4),
          initialDateRange: value,
        );
        if (picked != null) onChanged(picked);
      },
      icon: const Icon(Icons.calendar_month_rounded),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        foregroundColor: colors.textPrimary,
        minimumSize: const Size.fromHeight(48),
        side: BorderSide(color: colors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildResults(AppLocalizations l10n, AppColorsExtension colors) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _messageState(
        icon: Icons.cloud_off_rounded,
        text: l10n.homeGlobalSearchLoadFailed,
        colors: colors,
        action: FilledButton.tonal(
          onPressed: () => _loadScope(),
          child: Text(l10n.homeGlobalSearchRetry),
        ),
      );
    }

    final matches = _visibleMatches;
    final venues = _scope == 5
        ? _venueEntries(matches)
        : const <MapEntry<String, List<MatchModel>>>[];
    final tournaments = _visibleTournaments;
    final clubs = _visibleClubs;
    final athletes = _visibleAthletes;
    final count = _visibleResultCount;
    if (count == 0) {
      if (!_hasMore) return _emptyState(l10n, colors);
      return Column(
        children: [
          Expanded(child: _emptyState(l10n, colors)),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextButton.icon(
              onPressed: _loadingMore ? null : _loadMore,
              icon: _loadingMore
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.expand_more_rounded),
              label: Text(l10n.homeGlobalSearchLoadMore),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadScope(),
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.extentAfter < 240 &&
                    _hasMore &&
                    !_loadingMore &&
                    !_loading) {
                  _loadMore();
                }
                return false;
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 4, bottom: 16),
                itemCount: count + (_hasMore || _loadingMore ? 1 : 0),
                separatorBuilder: (context, index) => _scope == 0 || _scope == 1
                    ? const SizedBox(height: 8)
                    : Divider(
                        height: 1,
                        thickness: 1,
                        color: colors.border.withValues(alpha: 0.75),
                      ),
                itemBuilder: (context, index) {
                  if (index >= count) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _loadingMore
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : TextButton.icon(
                                onPressed: _hasMore ? _loadMore : null,
                                icon: const Icon(Icons.expand_more_rounded),
                                label: Text(l10n.homeGlobalSearchLoadMore),
                              ),
                      ),
                    );
                  }
                  return switch (_scope) {
                    0 => _matchCard(matches[index], l10n, colors),
                    1 => _tournamentCard(tournaments[index], l10n, colors),
                    3 => _clubCard(clubs[index], l10n, colors),
                    4 => _athleteCard(athletes[index], colors),
                    5 => _venueCard(venues[index], colors),
                    _ => const SizedBox.shrink(),
                  };
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<MapEntry<String, List<MatchModel>>> _venueEntries(
    List<MatchModel> matches,
  ) {
    final venues = <String, List<MatchModel>>{};
    for (final match in matches) {
      final court = match.court.trim();
      final address = match.courtAddress.trim();
      final key = '$court\u0000$address';
      if (court.isNotEmpty || address.isNotEmpty) {
        venues.putIfAbsent(key, () => []).add(match);
      }
    }
    return venues.entries.toList(growable: false);
  }

  Widget _venueCard(
    MapEntry<String, List<MatchModel>> entry,
    AppColorsExtension colors,
  ) {
    final parts = entry.key.split('\u0000');
    final title = parts[0].isEmpty ? parts[1] : parts[0];
    final location = entry.value.isEmpty
        ? ''
        : _matchWardAndCity(entry.value.first);
    return _resultRow(
      colors: colors,
      title: title,
      details: [location],
      onTap: () {
        setState(() {
          _scope = 0;
        });
        _matchLocationController.text = title;
      },
    );
  }

  Widget _matchCard(
    MatchModel match,
    AppLocalizations l10n,
    AppColorsExtension colors,
  ) {
    final scheduled = match.scheduledTime;
    final status = match.isLive
        ? l10n.matchesStatusLive
        : StatusHelper.getStatusDisplayName(match.status, l10n: l10n);
    final showScore =
        match.isLive ||
        match.completedAt != null ||
        match.sets.isNotEmpty ||
        (match.scoreDetails?.isNotEmpty ?? false);
    final team1Avatar = match.team1MemberInfos.isEmpty
        ? null
        : match.team1MemberInfos.first.avatarUrl;
    final team2Avatar = match.team2MemberInfos.isEmpty
        ? null
        : match.team2MemberInfos.first.avatarUrl;
    final location = _joinLocation(match.court, _matchWardAndCity(match));
    final setScores = match.sets
        .map((set) => '${set.score1}–${set.score2}')
        .join('  ');
    final sport = match.sportKey?.isNotEmpty == true
        ? l10n.sportDisplayName(match.sportKey!)
        : null;

    return _resultRow(
      colors: colors,
      title: match.team1Name,
      details: const [],
      sportCard: true,
      onTap: match.tournamentId == null
          ? null
          : () => context.push(
              NavigationHelper.getLiveMatchRoute(match.tournamentId!, match.id),
            ),
      leadingWidget: _matchLogos(
        _preferredImageUrl(match.team1LogoUrl, team1Avatar),
        _preferredImageUrl(match.team2LogoUrl, team2Avatar),
        match.team1Name,
        match.team2Name,
        match.sportKey,
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (sport != null)
                _searchMetaTag(sport, Icons.sports_rounded, colors),
              _searchMetaTag(
                status,
                Icons.circle,
                colors,
                isLive: match.isLive,
              ),
            ],
          ),
          if (match.tournamentName?.trim().isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                match.tournamentName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 7),
          _matchTeamLine(match.team1Name, match.score1, showScore, colors),
          const SizedBox(height: 3),
          _matchTeamLine(match.team2Name, match.score2, showScore, colors),
          if (setScores.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                setScores,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (scheduled != null)
            _searchMetaLine(
              Icons.schedule_rounded,
              DateFormat.yMMMd(
                Localizations.localeOf(context).toString(),
              ).add_Hm().format(scheduled),
              colors,
            ),
          if (location.isNotEmpty)
            _searchMetaLine(Icons.place_outlined, location, colors),
        ],
      ),
    );
  }

  Widget _matchTeamLine(
    String teamName,
    int score,
    bool showScore,
    AppColorsExtension colors,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            teamName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (showScore)
          SizedBox(
            width: 22,
            child: Text(
              '$score',
              textAlign: TextAlign.end,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }

  Widget _searchMetaTag(
    String text,
    IconData icon,
    AppColorsExtension colors, {
    bool isLive = false,
  }) {
    final foreground = isLive ? colors.success : colors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: isLive
            ? colors.success.withValues(alpha: 0.12)
            : colors.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLive
              ? colors.success.withValues(alpha: 0.35)
              : colors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: foreground),
          const SizedBox(width: 4),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchMetaLine(
    IconData icon,
    String text,
    AppColorsExtension colors,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Icon(icon, size: 13, color: colors.textMuted),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.textMuted, fontSize: 10.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tournamentCard(
    Tournament tournament,
    AppLocalizations l10n,
    AppColorsExtension colors,
  ) {
    final sport = tournament.sport.isNotEmpty
        ? l10n.sportDisplayName(tournament.sport)
        : null;
    final status = StatusHelper.getTournamentStatusLabel(
      tournament.status,
      l10n: l10n,
    );
    final startDate = tournament.startDate == null
        ? null
        : DateFormat.yMMMd(
            Localizations.localeOf(context).toString(),
          ).format(tournament.startDate!);
    final location = _joinLocation(
      tournament.venueName,
      _tournamentWardAndCity(tournament),
    );

    return _resultRow(
      colors: colors,
      title: tournament.name,
      details: const [],
      sportCard: true,
      onTap: () => context.push('/intro/${tournament.id}'),
      imageUrl: _preferredImageUrl(
        tournament.logoUrl,
        _preferredImageUrl(tournament.bannerUrl, tournament.communityLogoUrl),
      ),
      sport: tournament.sport,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tournament.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (sport != null)
                _searchMetaTag(sport, Icons.sports_rounded, colors),
              _searchMetaTag(status, Icons.flag_outlined, colors),
            ],
          ),
          if (startDate != null)
            _searchMetaLine(Icons.event_outlined, startDate, colors),
          if (location.isNotEmpty)
            _searchMetaLine(Icons.place_outlined, location, colors),
        ],
      ),
    );
  }

  Widget _clubCard(
    Community club,
    AppLocalizations l10n,
    AppColorsExtension colors,
  ) {
    return _resultRow(
      colors: colors,
      title: club.name,
      details: [
        ...club.sports.map(l10n.sportDisplayName),
        _clubWardAndCity(club),
      ],
      onTap: () => context.push('/club/${club.id}'),
      imageUrl: _preferredImageUrl(club.logoUrl, club.bannerUrl),
      sport: club.sports.isEmpty ? null : club.sports.first,
    );
  }

  String _clubWardAndCity(Community club) {
    final provinceCode = club.provinceCode?.trim() ?? '';
    final provinceList =
        ref.watch(provincesProvider).asData?.value ?? const <Province>[];
    String? city;
    for (final province in provinceList) {
      if (province.code == provinceCode) {
        city = province.name;
        break;
      }
    }

    String? ward;
    final wardCode = club.wardCode?.trim() ?? '';
    if (provinceCode.isNotEmpty && wardCode.isNotEmpty) {
      final wards =
          ref.watch(wardsProvider(provinceCode)).asData?.value ??
          const <Ward>[];
      for (final item in wards) {
        if (item.code == wardCode) {
          ward = item.name;
          break;
        }
      }
    }
    return _joinLocation(ward, city);
  }

  String _tournamentWardAndCity(Tournament tournament) {
    final config = tournament.locationConfig;
    final nested = config?['location'];
    final location = nested is Map ? Map<String, dynamic>.from(nested) : config;
    return _wardAndCity(location, cityFallback: tournament.city);
  }

  String _matchWardAndCity(MatchModel match) {
    final config = match.tournamentConfig;
    final nested = config?['location'];
    final location = nested is Map ? Map<String, dynamic>.from(nested) : config;
    return _wardAndCity(location);
  }

  String _wardAndCity(Map<String, dynamic>? location, {String? cityFallback}) {
    final ward = (location?['ward'] ?? location?['wardName'])?.toString();
    final city = (location?['province'] ?? location?['city'] ?? cityFallback)
        ?.toString();
    return _joinLocation(ward, city);
  }

  String _joinLocation(String? ward, String? city) {
    final parts = <String>[];
    for (final value in [ward, city]) {
      final clean = value?.trim() ?? '';
      if (clean.isNotEmpty &&
          !parts.any((part) => part.toLowerCase() == clean.toLowerCase())) {
        parts.add(clean);
      }
    }
    return parts.join(', ');
  }

  Widget _athleteCard(PlayerRanking player, AppColorsExtension colors) {
    return _resultRow(
      colors: colors,
      title: player.fullName,
      details: [
        if (player.categoryName?.isNotEmpty == true) player.categoryName!,
        if (player.eloPoints > 0) 'ELO ${player.eloPoints}',
        player.tierName,
      ],
      onTap: player.userId.isEmpty
          ? null
          : () => context.push('/user/${player.userId}'),
      imageUrl: player.avatarUrl,
      sport: player.categoryName,
    );
  }

  Widget _matchLogos(
    String? team1Image,
    String? team2Image,
    String team1Name,
    String team2Name,
    String? sport,
  ) {
    if (team1Image == null && team2Image == null) {
      return _resultAvatar(null, '$team1Name · $team2Name', sport, size: 40);
    }

    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: _resultAvatar(team1Image, team1Name, sport, size: 27),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: _resultAvatar(team2Image, team2Name, sport, size: 27),
          ),
        ],
      ),
    );
  }

  Widget _resultAvatar(
    String? imageUrl,
    String label,
    String? sport, {
    double size = 40,
  }) {
    return TournamentAvatar(
      imageUrl: imageUrl,
      tournamentName: label,
      sport: sport,
      size: size,
      borderColor: context.colors.border.withValues(alpha: .7),
    );
  }

  String? _preferredImageUrl(String? primary, String? fallback) {
    final first = primary?.split(',').first.trim();
    if (first != null && first.isNotEmpty) return first;
    final second = fallback?.split(',').first.trim();
    return second == null || second.isEmpty ? null : second;
  }

  Widget _resultRow({
    required AppColorsExtension colors,
    required String title,
    required List<String> details,
    required VoidCallback? onTap,
    String? imageUrl,
    String? sport,
    Widget? leadingWidget,
    Widget? content,
    bool sportCard = false,
  }) {
    final visibleDetails = content == null
        ? details
              .map((detail) => detail.trim())
              .where((detail) => detail.isNotEmpty)
              .toList(growable: false)
        : const <String>[];
    final radius = BorderRadius.circular(sportCard ? 14 : 0);
    final row = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: sportCard ? 12 : 9,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: leadingWidget ?? _resultAvatar(imageUrl, title, sport),
          ),
          const SizedBox(width: 10),
          Expanded(
            child:
                content ??
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    if (visibleDetails.isNotEmpty)
                      Text(
                        visibleDetails.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 11,
                          height: 1.25,
                        ),
                      ),
                  ],
                ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: sportCard ? colors.info : colors.textMuted,
            ),
          ],
        ],
      ),
    );
    if (!sportCard) {
      return InkWell(onTap: onTap, child: row);
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Material(
            color: colors.bgCard,
            borderRadius: radius,
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border(
                    left: BorderSide(color: colors.info, width: 3),
                    top: BorderSide(color: colors.border),
                    right: BorderSide(color: colors.border),
                    bottom: BorderSide(color: colors.border),
                  ),
                ),
                child: row,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _messageState({
    required IconData icon,
    required String text,
    required AppColorsExtension colors,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: colors.textMuted),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary),
            ),
            if (action != null) ...[const SizedBox(height: 12), action],
          ],
        ),
      ),
    );
  }

  Widget _emptyState(AppLocalizations l10n, AppColorsExtension colors) {
    if (_scope == 0 &&
        _unrenderableMatchCount > 0 &&
        _activeFilterCount == 0 &&
        _queryController.text.trim().isEmpty) {
      return _messageState(
        icon: Icons.visibility_off_rounded,
        text: l10n.homeGlobalSearchHiddenMatches,
        colors: colors,
      );
    }
    if (_scope != 1) {
      return _messageState(
        icon: Icons.search_off_rounded,
        text: l10n.homeGlobalSearchEmpty,
        colors: colors,
      );
    }

    return _messageState(
      icon: Icons.search_off_rounded,
      text: l10n.homeGlobalSearchNoResultsQuestion,
      colors: colors,
      action: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          TextButton(
            onPressed: () => context.push('/tournaments/create'),
            child: Text(l10n.homeGlobalSearchCreateTournament),
          ),
          Text(
            l10n.homeGlobalSearchOr,
            style: TextStyle(color: colors.textMuted),
          ),
          TextButton(
            onPressed: () {
              if (_activeFilterCount > 0) {
                _resetFilters();
              } else {
                _showFilterSheet();
              }
            },
            child: Text(
              _activeFilterCount > 0
                  ? l10n.homeGlobalSearchClearFilters
                  : l10n.homeGlobalSearchExpandFilters,
            ),
          ),
        ],
      ),
    );
  }

  String _scopeHint(AppLocalizations l10n) => switch (_scope) {
    0 || 5 => l10n.homeSearchMatchesHint,
    1 => l10n.homeSearchTournamentsHint,
    3 => l10n.homeSearchClubsHint,
    4 => l10n.homeSearchAthletesHint,
    _ => l10n.homeSearchGenericHint,
  };
}
