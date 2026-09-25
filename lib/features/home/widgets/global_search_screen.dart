import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/utils/match_visibility.dart';
import 'package:app_quanly_giaidau/core/utils/navigation_helpers.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/core/widgets/province_picker.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/providers/ranking_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
      transitionDuration: const Duration(milliseconds: 360),
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
  late bool _filtersExpanded;
  Timer? _debounce;
  int _requestVersion = 0;
  bool _loading = false;
  bool _loadingMore = false;
  bool _matchesLoaded = false;
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
    _filtersExpanded = widget.showFiltersInitially;
    _queryController = TextEditingController(text: widget.initialQuery);
    _matchLocationController = TextEditingController();
    _queryController.addListener(_onQueryChanged);
    _matchLocationController.addListener(_onQueryChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadScope());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController
      ..removeListener(_onQueryChanged)
      ..dispose();
    _matchLocationController
      ..removeListener(_onQueryChanged)
      ..dispose();
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
      });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      switch (_scope) {
        case 0:
        case 5:
          if (!_matchesLoaded) {
            final matches = await ref
                .read(matchRepositoryProvider)
                .getMatches(publicOnly: true);
            if (!mounted || version != _requestVersion) return;
            _matches = matches.where(isRenderablePublicMatch).toList();
            _matchesLoaded = true;
          }
          break;
        case 1:
          final result = await ref
              .read(tournamentRepositoryProvider)
              .getPublicTournamentsPaged(
                cursor: append ? _nextCursor : null,
                limit: 20,
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
                endDate: _tournamentDateRange?.end,
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
                limit: 20,
                search: query.isEmpty ? null : query,
                provinceCode: _clubProvince,
                categoryId: _clubSport == 'all' ? null : _clubSport,
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
            break;
          }
          final category = _athleteSport == 'all'
              ? categories.first
              : categories.firstWhere(
                  (item) =>
                      item.id == _athleteSport || item.slug == _athleteSport,
                  orElse: () => categories.first,
                );
          _athletes = await ref.read(
            rankingsProvider((
              categoryId: category.id,
              matchType: '',
              genderRestriction: _athleteGender == 'all'
                  ? null
                  : _athleteGender,
              provinceCode: _athleteProvince,
            )).future,
          );
          if (!mounted || version != _requestVersion) return;
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
    athletes.sort((a, b) {
      final byUpdated = _newestFirst(
        DateTime.tryParse(a.updatedAt ?? ''),
        DateTime.tryParse(b.updatedAt ?? ''),
      );
      return byUpdated != 0 ? byUpdated : a.rank.compareTo(b.rank);
    });
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
    final categories =
        ref.watch(categoriesProvider).asData?.value ?? const <CategoryModel>[];

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
              _buildFilterToolbar(l10n, colors),
              AnimatedSize(
                duration: MediaQuery.of(context).disableAnimations
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: _filtersExpanded
                    ? _buildFilters(l10n, colors, categories)
                    : const SizedBox.shrink(),
              ),
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
        padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
        child: Row(
          children: [
            IconButton(
              tooltip: l10n.homeGlobalSearchClose,
              onPressed: _closeSearch,
              icon: const Icon(Icons.arrow_back_rounded),
              color: colors.textPrimary,
              constraints: const BoxConstraints.tightFor(width: 44, height: 48),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: colors.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.border.withValues(alpha: .7),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Icon(Icons.search_rounded, color: colors.textMuted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Semantics(
                        label: l10n.homeGlobalSearchInputLabel,
                        textField: true,
                        child: TextField(
                          controller: _queryController,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _loadScope(),
                          onTap: () {
                            if (_filtersExpanded) {
                              setState(() => _filtersExpanded = false);
                            }
                          },
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 16,
                          ),
                          cursorColor: AppTheme.primary,
                          decoration: InputDecoration(
                            hintText: _scopeHint(l10n),
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            suffixIcon: _queryController.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: l10n.homeGlobalSearchClear,
                                    onPressed: _queryController.clear,
                                    icon: const Icon(Icons.close_rounded),
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

  Widget _buildFilterButton(AppColorsExtension colors, AppLocalizations l10n) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton.filled(
          tooltip: _activeFilterCount == 0
              ? l10n.homeGlobalSearchAdvancedFilters
              : '${l10n.homeGlobalSearchAdvancedFilters} ($_activeFilterCount)',
          onPressed: () {
            FocusScope.of(context).unfocus();
            setState(() => _filtersExpanded = !_filtersExpanded);
          },
          icon: const Icon(Icons.tune_rounded),
          style: IconButton.styleFrom(
            minimumSize: const Size(52, 52),
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
          ),
        ),
        if (_activeFilterCount > 0)
          Positioned(
            top: -3,
            right: -3,
            child: Container(
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                border: Border.all(color: AppTheme.primary),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_activeFilterCount',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterToolbar(AppLocalizations l10n, AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_scopeLabel(l10n, _scope).toUpperCase()} '
              '${l10n.homeGlobalSearchSuggested.toUpperCase()} '
              '($_visibleResultCount)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.swap_vert_rounded, size: 17, color: colors.textMuted),
          const SizedBox(width: 3),
          Text(
            '${l10n.homeGlobalSearchSort}: ${l10n.homeGlobalSearchSortNewest}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(
    AppLocalizations l10n,
    AppColorsExtension colors,
    List<CategoryModel> categories,
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
      ValueChanged<String?> onChanged,
    ) {
      children.add(_dropdown(label, value, options, onChanged, colors));
    }

    if (_scope == 0 || _scope == 5) {
      add(l10n.homeGlobalSearchSport, _matchSport, sportBySlug, (value) {
        if (value != null) setState(() => _matchSport = value);
      });
      add(
        l10n.homeGlobalSearchStatus,
        _matchStatus,
        [
          ('all', l10n.filterAll),
          ('scheduled', l10n.matchesFilterScheduled),
          ('live', l10n.matchesStatusLive),
          ('completed', l10n.matchesStatusCompleted),
        ],
        (value) {
          if (value != null) setState(() => _matchStatus = value);
        },
      );
      children.add(
        _dateFilter(
          l10n,
          colors,
          _matchDateRange,
          (range) => setState(() => _matchDateRange = range),
        ),
      );
      children.add(
        _textFilter(
          label: l10n.homeGlobalSearchLocation,
          controller: _matchLocationController,
          colors: colors,
        ),
      );
    } else if (_scope == 1) {
      add(l10n.homeGlobalSearchSport, _tournamentSport, sportBySlug, (value) {
        if (value == null) return;
        setState(() => _tournamentSport = value);
        _loadScope();
      });
      add(
        l10n.homeGlobalSearchStatus,
        _tournamentStatus,
        [
          ('all', l10n.filterAll),
          ('registration', l10n.matchesFilterRegistration),
          ('upcoming', l10n.matchesFilterScheduled),
          ('in_progress', l10n.homeInProgressStatus),
          ('completed', l10n.matchesStatusCompleted),
        ],
        (value) {
          if (value == null) return;
          setState(() => _tournamentStatus = value);
          _loadScope();
        },
      );
      add(l10n.homeGlobalSearchProvince, _tournamentProvinceCode, provinces, (
        value,
      ) {
        setState(() => _tournamentProvinceCode = value ?? '');
        _loadScope();
      });
      children.add(
        _dateFilter(l10n, colors, _tournamentDateRange, (range) {
          setState(() => _tournamentDateRange = range);
          _loadScope();
        }),
      );
    } else if (_scope == 3) {
      add(l10n.homeGlobalSearchSport, _clubSport, sportById, (value) {
        if (value == null) return;
        setState(() => _clubSport = value);
        _loadScope();
      });
      add(l10n.homeGlobalSearchProvince, _clubProvince ?? '', provinces, (
        value,
      ) {
        setState(() => _clubProvince = value?.isEmpty == true ? null : value);
        _loadScope();
      });
    } else if (_scope == 4) {
      add(l10n.homeGlobalSearchSport, _athleteSport, sportById, (value) {
        if (value == null) return;
        setState(() => _athleteSport = value);
        _loadScope();
      });
      add(
        l10n.homeGlobalSearchGender,
        _athleteGender,
        [
          ('all', l10n.filterAll),
          ('MALE', l10n.clubRankingMale),
          ('FEMALE', l10n.clubRankingFemale),
        ],
        (value) {
          if (value == null) return;
          setState(() => _athleteGender = value);
          _loadScope();
        },
      );
      add(l10n.homeGlobalSearchProvince, _athleteProvince ?? '', provinces, (
        value,
      ) {
        setState(
          () => _athleteProvince = value?.isEmpty == true ? null : value,
        );
        _loadScope();
      });
    }

    final availableHeight =
        MediaQuery.sizeOf(context).height -
        MediaQuery.viewInsetsOf(context).bottom -
        250;
    return Container(
      constraints: BoxConstraints(
        maxHeight: availableHeight.clamp(100.0, 280.0),
      ),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) const SizedBox(height: 8),
            children[index],
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _resetFilters,
              child: Text(l10n.homeGlobalSearchClearFilters),
            ),
          ),
        ],
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
    if (_loading && _scope != 4) {
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
      if (_scope == 4 && _loading) {
        return const Center(child: CircularProgressIndicator());
      }
      return _emptyState(l10n, colors);
    }

    return Column(
      children: [
        if (_scope == 4 && _loading)
          const LinearProgressIndicator(minHeight: 2),
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
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: count + (_loadingMore ? 1 : 0),
                separatorBuilder: (context, index) => const SizedBox(height: 2),
                itemBuilder: (context, index) {
                  if (index >= count) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return switch (_scope) {
                    0 => _matchCard(matches[index], l10n, colors),
                    1 => _tournamentCard(tournaments[index], l10n, colors),
                    3 => _clubCard(clubs[index], colors),
                    4 => _athleteCard(athletes[index], colors),
                    5 => _venueCard(venues[index], l10n, colors),
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
    AppLocalizations l10n,
    AppColorsExtension colors,
  ) {
    final parts = entry.key.split('\u0000');
    final title = parts[0].isEmpty ? parts[1] : parts[0];
    final address = parts[0].isEmpty || parts[1].isEmpty ? '' : parts[1];
    return _resultCard(
      colors: colors,
      icon: Icons.place_rounded,
      title: title,
      tags: [l10n.matchesCount(entry.value.length)],
      subtitle: address,
      onTap: () {
        setState(() {
          _scope = 0;
          _filtersExpanded = true;
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
    final details = [
      if (match.tournamentName?.isNotEmpty == true) match.tournamentName!,
      if (scheduled != null)
        DateFormat.yMMMd(
          Localizations.localeOf(context).toString(),
        ).add_Hm().format(scheduled),
      if (match.court.isNotEmpty) match.court,
    ];
    final status = match.isLive
        ? l10n.matchesStatusLive
        : StatusHelper.getStatusDisplayName(match.status, l10n: l10n);
    final team1Avatar = match.team1MemberInfos.isEmpty
        ? null
        : match.team1MemberInfos.first.avatarUrl;
    final team2Avatar = match.team2MemberInfos.isEmpty
        ? null
        : match.team2MemberInfos.first.avatarUrl;
    return _resultCard(
      colors: colors,
      icon: Icons.sports_tennis_rounded,
      title: '${match.team1Name} · ${match.team2Name}',
      tags: [if (match.sportKey?.isNotEmpty == true) match.sportKey!, status],
      subtitle: details.join(' · '),
      onTap: match.tournamentId == null
          ? null
          : () => context.push(
              NavigationHelper.getLiveMatchRoute(match.tournamentId!, match.id),
            ),
      leadingWidget: _matchLogos(
        match.team1LogoUrl ?? team1Avatar,
        match.team2LogoUrl ?? team2Avatar,
        colors,
      ),
    );
  }

  Widget _tournamentCard(
    Tournament tournament,
    AppLocalizations l10n,
    AppColorsExtension colors,
  ) {
    return _resultCard(
      colors: colors,
      icon: Icons.emoji_events_rounded,
      title: tournament.name,
      tags: [
        if (tournament.sport.isNotEmpty) tournament.sport,
        StatusHelper.getTournamentStatusLabel(tournament.status, l10n: l10n),
      ],
      subtitle: [
        if (tournament.venueName?.isNotEmpty == true) tournament.venueName!,
        if (tournament.city?.isNotEmpty == true) tournament.city!,
      ].join(' · '),
      onTap: () => context.push('/intro/${tournament.id}'),
      imageUrl: tournament.logoUrl ?? tournament.communityLogoUrl,
    );
  }

  Widget _clubCard(Community club, AppColorsExtension colors) {
    return _resultCard(
      colors: colors,
      icon: Icons.groups_2_rounded,
      title: club.name,
      tags: club.sports,
      subtitle: club.locationAddress ?? '',
      onTap: () => context.push('/club/${club.id}'),
      imageUrl: club.logoUrl,
    );
  }

  Widget _athleteCard(PlayerRanking player, AppColorsExtension colors) {
    return _resultCard(
      colors: colors,
      icon: Icons.person_rounded,
      title: player.fullName,
      tags: [
        if (player.categoryName?.isNotEmpty == true) player.categoryName!,
        if (player.eloPoints > 0) 'ELO ${player.eloPoints}',
        if (player.rank > 0) '#${player.rank}',
      ],
      subtitle: player.tierName,
      onTap: player.userId.isEmpty
          ? null
          : () => context.push('/user/${player.userId}'),
      imageUrl: player.avatarUrl,
    );
  }

  Widget _matchLogos(
    String? team1Image,
    String? team2Image,
    AppColorsExtension colors,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 0,
          left: 0,
          child: _imageBadge(
            team1Image,
            Icons.person_rounded,
            colors,
            size: 46,
            radius: 23,
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: _imageBadge(
            team2Image,
            Icons.person_rounded,
            colors,
            size: 46,
            radius: 23,
          ),
        ),
      ],
    );
  }

  Widget _resultCard({
    required AppColorsExtension colors,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    List<String> tags = const [],
    String? imageUrl,
    Widget? leadingWidget,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: colors.bgCard,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.border.withValues(alpha: 0.8)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child:
                    leadingWidget ??
                    _imageBadge(imageUrl, icon, colors, size: 72, radius: 14),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
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
                        fontSize: 16,
                      ),
                    ),
                    if (tags.any((tag) => tag.trim().isNotEmpty)) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          for (final tag in tags)
                            if (tag.trim().isNotEmpty)
                              _metadataBadge(tag, colors),
                        ],
                      ),
                    ],
                    if (subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '• $subtitle',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: colors.textMuted),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageBadge(
    String? imageUrl,
    IconData fallback,
    AppColorsExtension colors, {
    double size = 72,
    double radius = 14,
  }) {
    final url = imageUrl?.trim() ?? '';
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: url.isEmpty
          ? Icon(fallback, size: 28, color: AppTheme.primary)
          : Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
                  frame == null
                  ? Icon(fallback, size: 24, color: AppTheme.primary)
                  : child,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(fallback, size: 24, color: AppTheme.primary),
            ),
    );
  }

  Widget _metadataBadge(String label, AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.bgDark,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: colors.textSecondary, fontSize: 12),
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
                setState(() => _filtersExpanded = true);
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
