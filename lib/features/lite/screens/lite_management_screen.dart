import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/utils/vietnam_address_parser.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/region.dart';
import 'package:app_quanly_giaidau/providers/lite_management_notifier.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_view_screen.dart';
import 'package:app_quanly_giaidau/features/lite/widgets/football_registration_groups.dart';
import 'package:app_quanly_giaidau/domain/entities/lite_tournament_create_result.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations_extensions.dart';

class LiteManagementScreen extends ConsumerStatefulWidget {
  final String tournamentId;

  const LiteManagementScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<LiteManagementScreen> createState() =>
      _LiteManagementScreenState();
}

class _LiteManagementScreenState extends ConsumerState<LiteManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _loadWatchdog;
  String? _formatDraft;
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _venueNameController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _durationHours = 1;
  int _durationMinutes = 30;
  Timer? _descDebounce;
  Timer? _locationDebounce;
  Timer? _maxPartDebounce;
  bool _controllersInitialized = false;

  List<Region> _provinces = [];
  List<Region> _wards = [];
  String? _selectedProvinceCode;
  String? _selectedWardCode;
  bool _loadingProvinces = false;
  bool _loadingWards = false;
  Region? _aiDetectedProvince;
  Region? _aiDetectedWard;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadProvinces();
    // Wait until the first frame so auth/provider state is ready before the
    // first protected Lite request. Manual refresh already runs after this.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(liteManagementProvider.notifier).init(widget.tournamentId);
      _loadWatchdog = Timer(const Duration(seconds: 18), () {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        final state = ref.read(liteManagementProvider);
        if (state.loading && state.error == null) {
          ref
              .read(liteManagementProvider.notifier)
              .markLoadFailed(l10n.lite_loadFailed);
        }
      });
    });
  }

  Future<void> _loadProvinces() async {
    setState(() => _loadingProvinces = true);
    try {
      final list = await ref.read(regionRepositoryProvider).getProvinces();
      if (!mounted) return;
      setState(() {
        _provinces = list;
        _loadingProvinces = false;
      });
      _detectAddressAI(_locationController.text);
    } catch (_) {
      if (mounted) setState(() => _loadingProvinces = false);
    }
  }

  Future<void> _loadWardsForProvince(String provinceCode, {String? targetWardCode}) async {
    setState(() => _loadingWards = true);
    try {
      final list = await ref.read(regionRepositoryProvider).getWardsByProvince(provinceCode);
      if (!mounted) return;
      setState(() {
        _wards = list;
        _loadingWards = false;
        if (targetWardCode != null && list.any((w) => w.code == targetWardCode)) {
          _selectedWardCode = targetWardCode;
        } else if (_selectedWardCode != null && !list.any((w) => w.code == _selectedWardCode)) {
          _selectedWardCode = null;
        }
      });
      _detectAddressAI(_locationController.text);
    } catch (_) {
      if (mounted) setState(() => _loadingWards = false);
    }
  }

  void _detectAddressAI(String addressText) {
    if (addressText.trim().isEmpty || _provinces.isEmpty) {
      if (_aiDetectedProvince != null || _aiDetectedWard != null) {
        setState(() {
          _aiDetectedProvince = null;
          _aiDetectedWard = null;
        });
      }
      return;
    }

    final detectedP = VietnamAddressParser.detectProvince<Region>(
      rawAddress: addressText,
      provinces: _provinces,
      getCode: (r) => r.code,
      getName: (r) => r.name,
      getFullName: (r) => r.fullName ?? r.name,
    );

    Region? detectedW;
    if (_wards.isNotEmpty) {
      detectedW = VietnamAddressParser.detectWard<Region>(
        rawAddress: addressText,
        wards: _wards,
        getCode: (r) => r.code,
        getName: (r) => r.name,
        getFullName: (r) => r.fullName ?? r.name,
      );
    }

    if (detectedP != _aiDetectedProvince || detectedW != _aiDetectedWard) {
      setState(() {
        _aiDetectedProvince = detectedP;
        _aiDetectedWard = detectedW;
      });
    }
  }

  void _applyAiSuggestion(LiteManagementNotifier notifier) {
    if (_aiDetectedProvince != null) {
      final pCode = _aiDetectedProvince!.code;
      setState(() {
        _selectedProvinceCode = pCode;
      });
      _loadWardsForProvince(pCode, targetWardCode: _aiDetectedWard?.code);
      notifier.updateLocation(
        widget.tournamentId,
        venueName: _venueNameController.text,
        locationAddress: _locationController.text,
        province: _aiDetectedProvince!.name,
        ward: _aiDetectedWard?.name,
      );
    }
  }

  @override
  void didUpdateWidget(covariant LiteManagementScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tournamentId == widget.tournamentId) return;
    _controllersInitialized = false;
    _formatDraft = null;
    _loadWatchdog?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(liteManagementProvider.notifier).init(widget.tournamentId);
    });
  }

  @override
  void dispose() {
    _descDebounce?.cancel();
    _locationDebounce?.cancel();
    _maxPartDebounce?.cancel();
    _descriptionController.dispose();
    _locationController.dispose();
    _venueNameController.dispose();
    _maxParticipantsController.dispose();
    _loadWatchdog?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(liteManagementProvider);
    final notifier = ref.read(liteManagementProvider.notifier);
    if (!_controllersInitialized && state.tournament != null) {
      _controllersInitialized = true;
      _descriptionController.text = state.description ?? state.tournament?.description ?? "";
      _locationController.text = state.locationAddress ?? state.tournament?.locationAddress ?? "";
      _venueNameController.text = state.venueName ?? state.tournament?.venueName ?? "";
      _maxParticipantsController.text = (state.maxParticipants ?? state.tournament?.maxTeams ?? 16).toString();
      if (state.startDate != null) {
        _selectedDate = state.startDate;
        _selectedTime = TimeOfDay(hour: state.startDate!.hour, minute: state.startDate!.minute);
      }
      final dur = state.durationMinutes ?? 90;
      _durationHours = dur ~/ 60;
      _durationMinutes = dur % 60;

      final pName = state.province;
      final wName = state.ward;
      if (pName != null && pName.isNotEmpty && _provinces.isNotEmpty) {
        final pMatch = _provinces.where((p) => p.name.toLowerCase() == pName.toLowerCase() || (p.fullName != null && p.fullName!.toLowerCase() == pName.toLowerCase())).firstOrNull;
        if (pMatch != null) {
          _selectedProvinceCode = pMatch.code;
          _loadWardsForProvince(pMatch.code).then((_) {
            if (wName != null && wName.isNotEmpty && mounted) {
              final wMatch = _wards.where((w) => w.name.toLowerCase() == wName.toLowerCase() || (w.fullName != null && w.fullName!.toLowerCase() == wName.toLowerCase())).firstOrNull;
              if (wMatch != null) {
                setState(() => _selectedWardCode = wMatch.code);
              }
            }
          });
        }
      } else {
        _detectAddressAI(_locationController.text);
      }
    }

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          state.tournamentName ?? l10n.lite_managementTitle,
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
            onPressed: state.loading
                ? null
                : () => notifier.refresh(widget.tournamentId),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: colors.textMuted,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: [
            Tab(
              icon: const Icon(Icons.dashboard_outlined, size: 18),
              text: l10n.organizer_tabOverview,
            ),
            Tab(
              icon: const Icon(Icons.people_outline_rounded, size: 18),
              text: l10n.lite_participantsTab,
            ),
            Tab(
              icon: const Icon(Icons.account_tree_outlined, size: 18),
              text: l10n.lite_bracketAndMatches,
            ),
          ],
        ),
      ),
      body: state.loading && state.error == null && state.participants.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.tournament == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      size: 44,
                      color: colors.textMuted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => notifier.init(widget.tournamentId),
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(l10n.infoRetry),
                    ),
                  ],
                ),
              ),
            )
          : AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                Widget frame(Widget child) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: child,
                    ),
                  );
                }

                switch (_tabController.index) {
                  case 0:
                    return frame(_buildOverviewTab(colors, state, notifier));
                  case 1:
                    return frame(
                      _buildParticipantsTab(colors, state, notifier),
                    );
                  case 2:
                    {
                      // Do not call the public bracket endpoint before the organizer
                      // has created a Lite bracket. A Lite tournament normally has
                      // one division; pass its identity so edit-mode PATCH requests
                      // target the same division that was loaded for the diagram.
                      final liteDivision =
                          state.tournament?.divisions.isNotEmpty == true
                          ? state.tournament!.divisions.first
                          : null;
                      final divisions = state.tournament?.divisions ?? const [];
                      final hasSingleDivision = divisions.length == 1;
                      final bracketType =
                          (liteDivision?.bracketType ??
                                  state.tournament?.bracketType ??
                                  AppConstants.bracketSingleElimination)
                              .trim()
                              .toLowerCase();
                      return state.hasBracket
                          ? frame(
                              BracketViewScreen(
                                tournamentId: widget.tournamentId,
                                divisionId: liteDivision?.id,
                                bracketType: bracketType,
                                isEmbedded: true,
                                isLite: true,
                                canEditBracket:
                                    hasSingleDivision &&
                                    liteDivision?.id.isNotEmpty == true &&
                                    bracketType ==
                                        AppConstants.bracketSingleElimination,
                              ),
                            )
                          : frame(_buildBracketTab(colors, state, notifier));
                    }
                  default:
                    return const SizedBox.shrink();
                }
              },
            ),
    );
  }

  // ═══════════════════════════════════════════
  // TAB 1: TỔNG QUAN
  // ═══════════════════════════════════════════

  Widget _buildOverviewTab(
    AppColorsExtension colors,
    LiteManagementState state,
    LiteManagementNotifier notifier,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final tournament = state.tournament;
    final sportLabel = tournament != null
        ? l10n.sportDisplayName(tournament.sport)
        : '--';
    final formatLabel = tournament != null
        ? switch (tournament.format.trim().toLowerCase()) {
            AppConstants.formatSingles ||
            AppConstants.formatDoubles ||
            AppConstants.formatMixedDoubles => l10n.formatDisplayName(
              tournament.format,
            ),
            AppConstants.categoryMenSingles ||
            AppConstants.categoryWomenSingles ||
            AppConstants.categoryMenDoubles ||
            AppConstants.categoryWomenDoubles ||
            AppConstants.categoryMixedDoubles => l10n.categoryDisplayName(
              tournament.format,
            ),
            _ => tournament.format.replaceAll('_', ' '),
          }
        : '--';
    final bracketLabel = tournament != null
        ? l10n.bracketDisplayName(tournament.bracketType)
        : '--';

    return RefreshIndicator(
      onRefresh: () => notifier.refresh(widget.tournamentId),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ─── Header Card ───
          _buildHeaderCard(colors, state),
          const SizedBox(height: 20),
          _buildLiteFlow(colors, state),
          const SizedBox(height: 24),

          // ─── Info Grid ───
          _sectionHeader(
            colors,
            l10n.lite_tournamentInfo,
            Icons.info_outline_rounded,
          ),
          const SizedBox(height: 10),
          _infoGrid(colors, [
            (l10n.sportLabel, sportLabel),
            (l10n.formatLabel, formatLabel),
            (l10n.lite_bracketFormat, bracketLabel),
            (l10n.maxTeamsLabel, tournament?.maxTeams.toString() ?? '--'),
            (l10n.lite_participants, '${state.participants.length}'),
            (
              l10n.matchesTitle,
              state.hasBracket ? l10n.lite_created : l10n.lite_notCreated,
            ),
          ]),
          const SizedBox(height: 16),
          _buildScheduleCard(colors, state, notifier),
          const SizedBox(height: 20),
          _buildFormatSettingCard(colors, state, notifier),
          const SizedBox(height: 20),
          _buildVenueAndLocationCard(colors, state, notifier),
          const SizedBox(height: 20),
          _buildDescriptionCard(colors, state, notifier),
          const SizedBox(height: 24),

          // ─── Invite Code ───
          if (state.inviteCode != null && state.inviteCode!.isNotEmpty) ...[
            _sectionHeader(
              colors,
              l10n.lite_inviteCodeTitle,
              Icons.link_rounded,
            ),
            const SizedBox(height: 10),
            _inviteCodeCard(colors, state.inviteCode!),
            const SizedBox(height: 20),

            // ─── QR Code ───
            _sectionHeader(
              colors,
              l10n.lite_qrCodeTitle,
              Icons.qr_code_rounded,
            ),
            const SizedBox(height: 10),
            _qrCodeCard(colors, state.inviteCode!),
          ],
        ],
      ),
    );
  }

  Widget _buildInlineSaveIndicator(AppColorsExtension colors, String status) {
    final l10n = AppLocalizations.of(context)!;
    if (status == 'saving') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
          const SizedBox(width: 6),
          Text(
            l10n.lite_autoSaving,
            style: TextStyle(fontSize: 11, color: colors.textMuted, fontWeight: FontWeight.w500),
          ),
        ],
      );
    }
    if (status == 'saved') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 14, color: colors.success),
          const SizedBox(width: 4),
          Text(
            l10n.lite_saved,
            style: TextStyle(fontSize: 11, color: colors.success, fontWeight: FontWeight.w600),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildScheduleCard(
    AppColorsExtension colors,
    LiteManagementState state,
    LiteManagementNotifier notifier,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final t = state.tournament;
    final locked = t == null ||
        {'IN_PROGRESS', 'ONGOING', 'COMPLETED', 'CANCELLED'}
            .contains(t.status.toUpperCase());

    final now = DateTime.now();
    final dateDisplay = _selectedDate != null
        ? '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}'
        : '--/--/----';
    final timeDisplay = _selectedTime != null
        ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
        : '08:00';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: colors.border.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_rounded, size: 20, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.lite_scheduleCardTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              _buildInlineSaveIndicator(colors, state.detailsSaveStatus),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: InkWell(
                  onTap: locked
                      ? null
                      : () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate ?? now,
                            firstDate: now.subtract(const Duration(days: 30)),
                            lastDate: now.add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                            _autoSaveSchedule(notifier);
                          }
                        },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: colors.bgDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.today_rounded, size: 16, color: colors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.lite_startDate,
                                style: TextStyle(fontSize: 10, color: colors.textMuted),
                              ),
                              Text(
                                dateDisplay,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: locked
                      ? null
                      : () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _selectedTime ?? const TimeOfDay(hour: 8, minute: 0),
                          );
                          if (picked != null) {
                            setState(() => _selectedTime = picked);
                            _autoSaveSchedule(notifier);
                          }
                        },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: colors.bgDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 16, color: colors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.lite_startTime,
                                style: TextStyle(fontSize: 10, color: colors.textMuted),
                              ),
                              Text(
                                timeDisplay,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Duration selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.bgDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, size: 16, color: colors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.lite_duration,
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ),
                DropdownButton<int>(
                  value: _durationHours,
                  underline: const SizedBox.shrink(),
                  dropdownColor: colors.bgCard,
                  items: List.generate(24, (i) => i)
                      .map((h) => DropdownMenuItem(
                            value: h,
                            child: Text(
                              '$h ${l10n.lite_hours}',
                              style: TextStyle(fontSize: 13, color: colors.textPrimary),
                            ),
                          ))
                      .toList(),
                  onChanged: locked
                      ? null
                      : (val) {
                          if (val == null) return;
                          setState(() {
                            _durationHours = val;
                            if (_durationHours == 0 && _durationMinutes < 15) {
                              _durationMinutes = 15;
                            }
                          });
                          _autoSaveSchedule(notifier);
                        },
                ),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _durationMinutes,
                  underline: const SizedBox.shrink(),
                  dropdownColor: colors.bgCard,
                  items: [0, 15, 30, 45]
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(
                              '$m ${l10n.lite_minutes}',
                              style: TextStyle(fontSize: 13, color: colors.textPrimary),
                            ),
                          ))
                      .toList(),
                  onChanged: locked
                      ? null
                      : (val) {
                          if (val == null) return;
                          setState(() {
                            _durationMinutes = val;
                            if (_durationHours == 0 && _durationMinutes < 15) {
                              _durationMinutes = 15;
                            }
                          });
                          _autoSaveSchedule(notifier);
                        },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _autoSaveSchedule(LiteManagementNotifier notifier) {
    if (_selectedDate == null) return;
    final time = _selectedTime ?? const TimeOfDay(hour: 8, minute: 0);
    final combined = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      time.hour,
      time.minute,
    );
    final totalMin = (_durationHours * 60) + _durationMinutes;
    notifier.updateSchedule(
      widget.tournamentId,
      startDate: combined,
      durationMinutes: totalMin > 0 ? totalMin : 90,
    );
  }

  Widget _buildVenueAndLocationCard(
    AppColorsExtension colors,
    LiteManagementState state,
    LiteManagementNotifier notifier,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final t = state.tournament;
    final locked = t == null ||
        {'IN_PROGRESS', 'ONGOING', 'COMPLETED', 'CANCELLED'}
            .contains(t.status.toUpperCase());

    final selectedProvince = _provinces.where((p) => p.code == _selectedProvinceCode).firstOrNull;
    final selectedWard = _wards.where((w) => w.code == _selectedWardCode).firstOrNull;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: colors.border.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 20, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.lite_venueAddress,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              _buildInlineSaveIndicator(colors, state.detailsSaveStatus),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _venueNameController,
            enabled: !locked,
            decoration: InputDecoration(
              labelText: l10n.lite_venueName,
              hintText: l10n.lite_venueNamePlaceholder,
              filled: true,
              fillColor: colors.bgDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border),
              ),
            ),
            onChanged: (text) {
              _locationDebounce?.cancel();
              _locationDebounce = Timer(const Duration(milliseconds: 900), () {
                notifier.updateLocation(
                  widget.tournamentId,
                  venueName: _venueNameController.text,
                  locationAddress: _locationController.text,
                  province: selectedProvince?.name,
                  ward: selectedWard?.name,
                );
              });
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _locationController,
            enabled: !locked,
            decoration: InputDecoration(
              labelText: l10n.lite_venueAddress,
              hintText: l10n.lite_venueAddressPlaceholder,
              filled: true,
              fillColor: colors.bgDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border),
              ),
            ),
            onChanged: (text) {
              _detectAddressAI(text);
              _locationDebounce?.cancel();
              _locationDebounce = Timer(const Duration(milliseconds: 900), () {
                notifier.updateLocation(
                  widget.tournamentId,
                  venueName: _venueNameController.text,
                  locationAddress: _locationController.text,
                  province: selectedProvince?.name,
                  ward: selectedWard?.name,
                );
              });
            },
          ),
          // ─── AI Detected Address Helper Banner ───
          if (!locked && (_aiDetectedProvince != null || _aiDetectedWard != null)) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, size: 16, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${l10n.lite_aiDetectedAddress}: ${_aiDetectedProvince?.name ?? ''}${_aiDetectedWard != null ? ' > ${_aiDetectedWard?.name}' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _applyAiSuggestion(notifier),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text(
                        l10n.filterApply,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          // ─── Dropdown Tỉnh/Thành phố & Phường/Xã ───
          Row(
            children: [
              // Tỉnh / Thành phố
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedProvinceCode,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.lite_province,
                    filled: true,
                    fillColor: colors.bgDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  dropdownColor: colors.bgCard,
                  hint: Text(
                    _loadingProvinces ? l10n.lite_loadingWards : l10n.lite_selectProvince,
                    style: TextStyle(fontSize: 13, color: colors.textMuted),
                  ),
                  items: _provinces.map((p) {
                    return DropdownMenuItem<String>(
                      value: p.code,
                      child: Text(
                        p.name,
                        style: TextStyle(fontSize: 13, color: colors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: locked || _loadingProvinces
                      ? null
                      : (val) {
                          if (val == null || val == _selectedProvinceCode) return;
                          setState(() {
                            _selectedProvinceCode = val;
                            _selectedWardCode = null;
                            _wards = [];
                          });
                          _loadWardsForProvince(val);
                          final pObj = _provinces.where((p) => p.code == val).firstOrNull;
                          notifier.updateLocation(
                            widget.tournamentId,
                            venueName: _venueNameController.text,
                            locationAddress: _locationController.text,
                            province: pObj?.name,
                            ward: null,
                          );
                        },
                ),
              ),
              const SizedBox(width: 10),
              // Phường / Xã
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedWardCode,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.lite_ward,
                    filled: true,
                    fillColor: colors.bgDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  dropdownColor: colors.bgCard,
                  hint: Text(
                    _loadingWards
                        ? l10n.lite_loadingWards
                        : (_selectedProvinceCode == null
                            ? l10n.lite_selectProvinceFirst
                            : l10n.lite_selectWard),
                    style: TextStyle(fontSize: 13, color: colors.textMuted),
                  ),
                  items: _wards.map((w) {
                    return DropdownMenuItem<String>(
                      value: w.code,
                      child: Text(
                        w.name,
                        style: TextStyle(fontSize: 13, color: colors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: locked || _loadingWards || _wards.isEmpty
                      ? null
                      : (val) {
                          if (val == null || val == _selectedWardCode) return;
                          setState(() => _selectedWardCode = val);
                          final wObj = _wards.where((w) => w.code == val).firstOrNull;
                          final pObj = _provinces.where((p) => p.code == _selectedProvinceCode).firstOrNull;
                          notifier.updateLocation(
                            widget.tournamentId,
                            venueName: _venueNameController.text,
                            locationAddress: _locationController.text,
                            province: pObj?.name,
                            ward: wObj?.name,
                          );
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(
    AppColorsExtension colors,
    LiteManagementState state,
    LiteManagementNotifier notifier,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final t = state.tournament;
    final locked = t == null ||
        {'IN_PROGRESS', 'ONGOING', 'COMPLETED', 'CANCELLED'}
            .contains(t.status.toUpperCase());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: colors.border.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes_rounded, size: 20, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.lite_tournamentDescription,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              _buildInlineSaveIndicator(colors, state.detailsSaveStatus),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _descriptionController,
            enabled: !locked,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.lite_tournamentDescription,
              hintText: l10n.lite_tournamentDescPlaceholder,
              filled: true,
              fillColor: colors.bgDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border),
              ),
            ),
            onChanged: (text) {
              _descDebounce?.cancel();
              _descDebounce = Timer(const Duration(milliseconds: 900), () {
                notifier.updateLiteDetails(
                  widget.tournamentId,
                  description: _descriptionController.text,
                  locationAddress: _locationController.text,
                  venueName: _venueNameController.text,
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFormatSettingCard(
    AppColorsExtension colors,
    LiteManagementState state,
    LiteManagementNotifier notifier,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final tournament = state.tournament;
    final division = tournament?.divisions.isNotEmpty == true
        ? tournament!.divisions.first
        : null;
    final rawMatchType = (division?.matchType ?? state.matchType ?? 'SINGLES')
        .trim()
        .toUpperCase();
    final currentMatchType =
        rawMatchType == 'DOUBLES' &&
            division?.genderRestriction?.trim().toUpperCase() == 'MIXED'
        ? 'MIXED_DOUBLES'
        : rawMatchType;
    final isFootball = state.isFootball;
    final status = tournament?.status.toUpperCase() ?? '';
    final locked =
        state.hasBracket ||
        state.rosterConfirmed ||
        state.participants.isNotEmpty ||
        (division?.participantCount ?? 0) > 0 ||
        {'IN_PROGRESS', 'ONGOING', 'COMPLETED', 'CANCELLED'}.contains(status);
    // Football is persisted as generic SINGLES for team-vs-team. Do not
    // expose it as DOUBLES in the Lite format control.
    final selected = isFootball
        ? 'SINGLES'
        : (_formatDraft ?? currentMatchType);
    final canSave =
        !isFootball &&
        !locked &&
        !state.formatSaving &&
        division != null &&
        selected != currentMatchType;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: colors.border.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.lite_formatSettingTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      l10n.lite_formatSettingDescription,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (state.formatSaving)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _maxParticipantsController,
                  enabled: !locked && !state.hasBracket,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.lite_maxParticipantsLimit,
                    filled: true,
                    fillColor: colors.bgDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.border),
                    ),
                  ),
                  onChanged: (val) {
                    final n = int.tryParse(val.trim());
                    if (n != null && n >= 2 && n <= 128) {
                      _maxPartDebounce?.cancel();
                      _maxPartDebounce = Timer(const Duration(milliseconds: 900), () {
                        notifier.updateMaxParticipants(widget.tournamentId, n);
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: selected,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.formatLabel,
              filled: true,
              fillColor: colors.bgDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border),
              ),
            ),
            items: [
              DropdownMenuItem(
                value: 'SINGLES',
                child: Text(
                  isFootball
                      ? l10n.lite_formatSettingFootball
                      : l10n.lite_singles,
                ),
              ),
              if (!isFootball)
                DropdownMenuItem(
                  value: 'DOUBLES',
                  child: Text(l10n.lite_doubles),
                ),
              if (!isFootball)
                DropdownMenuItem(
                  value: 'MIXED_DOUBLES',
                  child: Text(l10n.lite_mixedDoubles),
                ),
            ],
            onChanged: locked || isFootball || state.formatSaving
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() => _formatDraft = value);
                  },
          ),
          if (locked)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.lite_formatSettingLocked,
                style: TextStyle(
                  color: colors.warning,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else if (isFootball)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.lite_formatSettingFootball,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: canSave
                  ? () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: Text(l10n.lite_formatSettingTitle),
                          content: Text(l10n.lite_formatSaveConfirm),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: Text(l10n.matchCancel),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              child: Text(l10n.lite_confirmButton),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true || !mounted) return;
                      final ok = await notifier.updateMatchType(
                        widget.tournamentId,
                        selected,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? l10n.lite_formatSaveSuccess
                                : l10n.lite_formatSaveError,
                          ),
                        ),
                      );
                      if (ok) setState(() => _formatDraft = selected);
                    }
                  : null,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: Text(l10n.matchSaveChanges),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiteFlow(AppColorsExtension colors, LiteManagementState state) {
    final l10n = AppLocalizations.of(context)!;
    final steps = [
      (
        l10n.lite_participants,
        state.participants.isNotEmpty,
        Icons.people_outline_rounded,
      ),
      (
        l10n.lite_stepPairing,
        state.isDoubles ? state.completeParticipants.isNotEmpty : true,
        Icons.link_rounded,
      ),
      (l10n.lite_createBracket, state.hasBracket, Icons.account_tree_outlined),
      (
        l10n.lite_stepFollowMatches,
        state.hasBracket,
        Icons.sports_tennis_rounded,
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: colors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.lite_progressTitle,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
          // Perfect Aligned Progress Bar
          LayoutBuilder(
            builder: (context, constraints) {
              final stepWidth = (constraints.maxWidth) / steps.length;
              return Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Center Line Divider running behind circles
                  Positioned(
                    top: 16, // Center of 32px CircleAvatar
                    left: stepWidth / 2,
                    right: stepWidth / 2,
                    child: Container(height: 2, color: colors.border),
                  ),
                  // Progress active lines
                  Positioned(
                    top: 16,
                    left: stepWidth / 2,
                    right: stepWidth / 2,
                    child: Row(
                      children: [
                        for (var i = 0; i < steps.length - 1; i++)
                          Expanded(
                            child: Container(
                              height: 2,
                              color: steps[i].$2 && steps[i + 1].$2
                                  ? AppTheme.primary
                                  : Colors.transparent,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Steps Nodes
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < steps.length; i++)
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: steps[i].$2
                                    ? AppTheme.primary
                                    : colors.bgSurface,
                                child: Icon(
                                  steps[i].$3,
                                  size: 15,
                                  color: steps[i].$2
                                      ? Colors.white
                                      : colors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 28,
                                child: Text(
                                  steps[i].$1,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    height: 1.2,
                                    fontWeight: steps[i].$2
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: steps[i].$2
                                        ? AppTheme.primary
                                        : colors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(
    AppColorsExtension colors,
    LiteManagementState state,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final tournament = state.tournament;
    final status = tournament?.status ?? '';
    final statusLabel = StatusHelper.getTournamentStatusLabel(status);
    final statusColor = StatusHelper.getTournamentStatusColor(status, context);
    final headerMatchType = state.matchType?.toUpperCase();
    final matchTypeLabel = headerMatchType == 'MIXED_DOUBLES'
        ? l10n.lite_mixedDoubles
        : state.isDoubles
        ? l10n.lite_doubles
        : l10n.lite_singles;

    final logoOrBanner = tournament?.logoUrl ?? tournament?.bannerUrl;
    final resolvedImageUrl = logoOrBanner != null && logoOrBanner.isNotEmpty
        ? LiteTournamentCreateResult.resolveUrl(logoOrBanner)
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Tournament Logo / Badge
              Container(
                width: 48,
                height: 48,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [AppTheme.primary.withValues(alpha: 0.8), AppTheme.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: resolvedImageUrl != null
                      ? Image.network(
                          resolvedImageUrl,
                          fit: BoxFit.cover,
                          width: 48,
                          height: 48,
                          errorBuilder: (ctx, err, stack) => const Center(
                            child: Icon(Icons.emoji_events_rounded, color: Colors.white, size: 24),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.emoji_events_rounded, color: Colors.white, size: 24),
                        ),
                ),
              ),
              Expanded(
                child: Text(
                  state.tournamentName ?? l10n.navTournaments,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.sports_rounded, size: 16, color: colors.textSecondary),
              const SizedBox(width: 6),
              Text(
                tournament != null
                    ? l10n.sportDisplayName(tournament.sport)
                    : '--',
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
              const SizedBox(width: 20),
              Icon(
                Icons.people_outline_rounded,
                size: 16,
                color: colors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                matchTypeLabel,

                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.groups_rounded, size: 16, color: colors.textSecondary),
              const SizedBox(width: 6),
              Text(
                '${l10n.maxTeamsLabel}: ${tournament?.maxTeams ?? '--'} ${l10n.teamsUnit}',
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoGrid(AppColorsExtension colors, List<(String, String)> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final (label, value) = items[index];
          final isLast = index == items.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Row(
              children: [
                SizedBox(
                  width: 130,
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 13, color: colors.textMuted),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _inviteCodeCard(AppColorsExtension colors, String inviteCode) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.lite_inviteCode,
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  inviteCode,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: FilledButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: inviteCode));
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.lite_inviteCopied)));
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: Text(l10n.lite_copy, style: const TextStyle(fontSize: 13)),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qrCodeCard(AppColorsExtension colors, String inviteCode) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: QrImageView(
              // Mã QR phải chứa URL đầy đủ (mở thẳng luồng tham gia), không phải
              // mã thô — khớp với web LiteInviteQr.
              data: LiteTournamentCreateResult.resolveUrl(
                '/lite/tournaments/join/$inviteCode',
              ),
              version: QrVersions.auto,
              size: 160,
              backgroundColor: Colors.white,
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.lite_qrInstruction,
            style: TextStyle(fontSize: 12, color: colors.textMuted),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // TAB 2: NGƯỜI THAM GIA
  // ═══════════════════════════════════════════

  Widget _buildParticipantsTab(
    AppColorsExtension colors,
    LiteManagementState state,
    LiteManagementNotifier notifier,
  ) {
    final l10n = AppLocalizations.of(context)!;

    if (state.loading && state.participants.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.participants.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 40, color: colors.error),
              const SizedBox(height: 12),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => notifier.refresh(widget.tournamentId),
                child: Text(l10n.infoRetry),
              ),
            ],
          ),
        ),
      );
    }

    final pending = state.pendingParticipants;
    final allPaired = state.completeParticipants;
    final isDoubles = state.isDoubles;

    return RefreshIndicator(
      onRefresh: () => notifier.refresh(widget.tournamentId),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ─── Loading banner ───
          if (state.loading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(),
            ),

          if (state.hasBracket) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.info.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: colors.info),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.lite_recreateBracketNotice,
                      style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ─── Roster confirmation (only show when there are participants, matching Web) ───
          if (state.participants.isNotEmpty)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.fact_check_outlined, color: Colors.amber),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.lite_rosterConfirmationDescription,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    state.rosterConfirmed
                        ? Chip(label: Text(l10n.lite_rosterConfirmed))
                        : OutlinedButton(
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(l10n.lite_rosterConfirmTitle),
                                  content: Text(l10n.lite_rosterConfirmContent),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: Text(l10n.commonCancel),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: Text(l10n.lite_confirmRosterButton),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed != true || !mounted) return;
                              try {
                                await notifier.confirmRoster(widget.tournamentId);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l10n.lite_rosterConfirmedSuccess,
                                      ),
                                    ),
                                  );
                                }
                              } on DioException catch (error) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        error.response?.data?['message']
                                                ?.toString() ??
                                            l10n.lite_rosterConfirmError,
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            child: Text(l10n.lite_rosterConfirmAction),
                          ),
                  ],
                ),
              ),
            ),

          // ─── Mock tools ───
          Row(
            children: [
              if (state.participants.isNotEmpty)
                TextButton.icon(
                  onPressed: state.mockLoading
                      ? null
                      : () => _confirmClearMock(colors, notifier),
                  icon: Icon(
                    Icons.delete_sweep_outlined,
                    size: 18,
                    color: colors.error,
                  ),
                  label: Text(
                    l10n.lite_clearMockPlayers,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.error,
                    ),
                  ),
                ),
              const Spacer(),
              TextButton.icon(
                onPressed: state.mockLoading
                    ? null
                    : () => _promptSeedMock(colors, notifier),
                icon: state.mockLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.science_outlined,
                        size: 18,
                        color: colors.warning,
                      ),
                label: Text(
                  state.mockLoading
                      ? l10n.lite_creating
                      : l10n.lite_createMockPlayers,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.warning,
                  ),
                ),
              ),
            ],
          ),

          if (state.isFootball) ...[
            _sectionHeader(
              colors,
              l10n.lite_footballRegisteredTeams(state.participants.length),
              Icons.shield_outlined,
            ),
            const SizedBox(height: 8),
            if (state.participants.isEmpty)
              _emptyCard(colors, l10n.lite_noRegisteredFootballTeams)
            else
              FootballRegistrationGroups(
                participants: state.participants,
                colors: colors,
                rosterConfirmed: state.rosterConfirmed,
                onKickParticipant: (participant, reason) =>
                    _kickFootballParticipant(
                      colors,
                      notifier,
                      participant,
                      reason,
                    ),
              ),
          ] else if (isDoubles) ...[
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
              ...pending.map((p) => _pendingTile(colors, state, notifier, p)),

            // ─── Manual pair button ───
            if (state.selectedIds.length == 2) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton.icon(
                  onPressed: state.pairing
                      ? null
                      : () => notifier.manualPair(widget.tournamentId),
                  icon: state.pairing
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
                    state.pairing ? l10n.lite_pairing : l10n.lite_pairSelected,
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
                      onPressed: state.generating
                          ? null
                          : () => notifier.generatePairs(
                              widget.tournamentId,
                              'RANDOM',
                            ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusXL,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child:
                          state.generating &&
                              state.generatingStrategy == 'RANDOM'
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
                      onPressed: state.generating
                          ? null
                          : () => notifier.generatePairs(
                              widget.tournamentId,
                              'ELO_BALANCED',
                            ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusXL,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child:
                          state.generating &&
                              state.generatingStrategy == 'ELO_BALANCED'
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
              ...allPaired.map((p) => _pairedTile(colors, notifier, p)),
            ],
          ] else ...[
            // ─── Singles: just participant list ───
            _sectionHeader(
              colors,
              '${l10n.lite_participants} (${state.participants.length})',
              Icons.people_rounded,
            ),
            const SizedBox(height: 6),
            if (state.participants.isEmpty)
              _emptyCard(colors, l10n.noParticipants)
            else
              ...state.participants.map((p) => _singlesTile(colors, p)),
          ],

          // ─── Bracket generation button ───
          if (state.bracketEligibleCount >= 2 ||
              allPaired.isNotEmpty ||
              (state.participants.isNotEmpty && !isDoubles)) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed:
                    state.creatingBracket ||
                        state.bracketEligibleCount < 2
                    ? null
                    : () => _createBracket(colors, notifier),
                icon: state.creatingBracket
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
                  state.creatingBracket
                      ? l10n.lite_creating
                      : l10n.lite_createBracket,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  ),
                ),
              ),
            ),
            if (state.bracketEligibleCount < 2) ...[
              const SizedBox(height: 8),
              Text(
                l10n.lite_bracketMinimumParticipants(2),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: colors.warning),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _promptSeedMock(
    AppColorsExtension colors,
    LiteManagementNotifier notifier,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController(text: '8');
    final count = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.lite_createMockPlayers),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.lite_quantity,
            hintText: l10n.lite_quantityHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.matchesCancel),
          ),
          FilledButton(
            onPressed: () {
              final n = int.tryParse(ctrl.text.trim()) ?? 0;
              if (n < 1 || n > 50) return;
              Navigator.pop(ctx, n);
            },
            child: Text(l10n.lite_create),
          ),
        ],
      ),
    );
    if (count != null) {
      try {
        await notifier.seedMock(widget.tournamentId, count);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.lite_mockPlayersCreated(count)),
              backgroundColor: colors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          String message = e.toString();
          if (e is DioException && e.response?.data != null) {
            final data = e.response!.data;
            if (data is Map && data['message'] != null) {
              message = data['message'].toString();
            }
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.lite_mockPlayersFailed(message)),
              backgroundColor: colors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmClearMock(
    AppColorsExtension colors,
    LiteManagementNotifier notifier,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.lite_clearMockConfirmTitle),
        content: Text(l10n.lite_clearMockConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.matchesCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.lite_clearMockPlayers),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await notifier.clearMock(widget.tournamentId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.lite_mockPlayersCleared),
              backgroundColor: colors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          String message = e.toString();
          if (e is DioException && e.response?.data != null) {
            final data = e.response!.data;
            if (data is Map && data['message'] != null) {
              message = data['message'].toString();
            }
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.lite_mockPlayersFailed(message)),
              backgroundColor: colors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _kickFootballParticipant(
    AppColorsExtension colors,
    LiteManagementNotifier notifier,
    LiteParticipant participant,
    String reason,
  ) async {
    try {
      await notifier.kickParticipant(
        widget.tournamentId,
        participant.id,
        reason,
      );
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.lite_kickParticipantSuccess(participant.teamName)),
          backgroundColor: colors.success,
        ),
      );
    } on DioException catch (error) {
      if (!mounted) return;
      final data = error.response?.data;
      final message = data is Map && data['message'] != null
          ? data['message'].toString()
          : AppLocalizations.of(context)!.lite_kickParticipantError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: colors.error),
      );
    }
  }

  Future<void> _createBracket(
    AppColorsExtension colors,
    LiteManagementNotifier notifier,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final replacingExisting = ref.read(liteManagementProvider).hasBracket;

    try {
      if (replacingExisting) {
        await notifier.resetBracket(widget.tournamentId);
      } else {
        await notifier.createBracket(widget.tournamentId);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              replacingExisting
                  ? l10n.lite_recreatedBracket
                  : l10n.lite_bracketCreated,
            ),
            backgroundColor: colors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final message = e is DioException && e.response?.statusCode == 401
            ? l10n.lite_sessionExpired
            : e is DioException && e.response?.statusCode == 403
            ? l10n.lite_unauthorized
            : e
                  .toString()
                  .replaceAll('Exception: ', '')
                  .replaceAll('DioException: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorPrefix}: $message'),
            backgroundColor: colors.error,
          ),
        );
      }
    }
  }

  // ═══════════════════════════════════════════
  // TAB 3: BRACKET
  // ═══════════════════════════════════════════

  Widget _buildBracketTab(
    AppColorsExtension colors,
    LiteManagementState state,
    LiteManagementNotifier notifier,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              state.hasBracket
                  ? Icons.emoji_events_rounded
                  : Icons.dashboard_customize_rounded,
              size: 56,
              color: colors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              state.hasBracket ? l10n.lite_bracketCreated : l10n.lite_noBracket,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.hasBracket
                  ? l10n.lite_viewBracketDesc
                  : l10n.lite_createBracketDesc,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: colors.textSecondary),
            ),
            const SizedBox(height: 24),
            if (state.hasBracket)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      context.push('/tournaments/${widget.tournamentId}');
                    },
                    icon: const Icon(Icons.visibility_rounded, size: 18),
                    label: Text(l10n.viewBracket),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: state.creatingBracket
                        ? null
                        : () => _createBracket(colors, notifier),
                    icon: state.creatingBracket
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                      state.creatingBracket
                          ? l10n.lite_creating
                          : l10n.lite_recreateBracket,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.warning,
                      side: BorderSide(color: colors.warning),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                      ),
                    ),
                  ),
                ],
              )
            else ...[
              SizedBox(
                width: 200,
                height: 48,
                child: FilledButton.icon(
                  onPressed:
                      state.creatingBracket ||
                          state.bracketEligibleCount < 2
                      ? null
                      : () => _createBracket(colors, notifier),
                  icon: state.creatingBracket
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_rounded, size: 20),
                  label: Text(
                    state.creatingBracket
                        ? l10n.lite_creating
                        : l10n.lite_createBracket,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                    ),
                  ),
                ),
              ),
              if (state.bracketEligibleCount < 2) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.lite_bracketMinimumParticipants(2),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: colors.warning),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════ // SHARED WIDGETS
  // ═══════════════════════════════════════════

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

  Widget _buildUserAvatar(
    AppColorsExtension colors, {
    required String? avatarUrl,
    required String displayName,
    required Color accentColor,
    VoidCallback? onTap,
    double size = 38,
  }) {
    final initial = displayName.trim().isNotEmpty ? displayName.trim()[0].toUpperCase() : '?';
    final resolvedUrl = avatarUrl != null && avatarUrl.trim().isNotEmpty
        ? LiteTournamentCreateResult.resolveUrl(avatarUrl.trim())
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accentColor.withValues(alpha: 0.85),
              accentColor,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: resolvedUrl != null && resolvedUrl.isNotEmpty
              ? Image.network(
                  resolvedUrl,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: size * 0.38,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: size * 0.38,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _pendingTile(
    AppColorsExtension colors,
    LiteManagementState state,
    LiteManagementNotifier notifier,
    LiteParticipant participant,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final selected = state.selectedIds.contains(participant.id);
    final firstMember = participant.members.isNotEmpty
        ? participant.members.first
        : null;
    final subtitle = participant.members.map((m) => m.fullName).join(', ');

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
        onTap: () => notifier.toggleSelection(participant.id),
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
              const SizedBox(width: 10),
              _buildUserAvatar(
                colors,
                avatarUrl: firstMember?.avatarUrl,
                displayName: participant.displayName,
                accentColor: colors.warning,
                onTap: firstMember != null && firstMember.id.isNotEmpty
                    ? () => context.push('/user/${firstMember.id}')
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: firstMember != null && firstMember.id.isNotEmpty
                      ? () => context.push('/user/${firstMember.id}')
                      : null,
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
                      if (subtitle.isNotEmpty &&
                          subtitle != participant.displayName)
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
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

  Widget _singlesTile(AppColorsExtension colors, LiteParticipant participant) {
    final l10n = AppLocalizations.of(context)!;
    final firstMember = participant.members.isNotEmpty
        ? participant.members.first
        : null;
    final subtitle = participant.members.map((m) => m.fullName).join(', ');

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
          _buildUserAvatar(
            colors,
            avatarUrl: firstMember?.avatarUrl,
            displayName: participant.displayName,
            accentColor: colors.info,
            onTap: firstMember != null && firstMember.id.isNotEmpty
                ? () => context.push('/user/${firstMember.id}')
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: firstMember != null && firstMember.id.isNotEmpty
                  ? () => context.push('/user/${firstMember.id}')
                  : null,
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
                  if (subtitle.isNotEmpty &&
                      subtitle != participant.displayName)
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: colors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
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

  Widget _pairedTile(
    AppColorsExtension colors,
    LiteManagementNotifier notifier,
    LiteParticipant participant,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final members = participant.members;
    final hasTwoMembers = members.length >= 2;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: hasTwoMembers
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Member 1
                      InkWell(
                        onTap: members[0].id.isNotEmpty
                            ? () => context.push('/user/${members[0].id}')
                            : null,
                        child: Row(
                          children: [
                            _buildUserAvatar(
                              colors,
                              avatarUrl: members[0].avatarUrl,
                              displayName: members[0].fullName,
                              accentColor: colors.success,
                              size: 32,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                members[0].fullName.isNotEmpty
                                    ? members[0].fullName
                                    : l10n.infoPlayer,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Member 2
                      InkWell(
                        onTap: members[1].id.isNotEmpty
                            ? () => context.push('/user/${members[1].id}')
                            : null,
                        child: Row(
                          children: [
                            _buildUserAvatar(
                              colors,
                              avatarUrl: members[1].avatarUrl,
                              displayName: members[1].fullName,
                              accentColor: AppTheme.primary,
                              size: 32,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                members[1].fullName.isNotEmpty
                                    ? members[1].fullName
                                    : l10n.infoPlayer,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      _buildUserAvatar(
                        colors,
                        avatarUrl: members.isNotEmpty ? members.first.avatarUrl : null,
                        displayName: participant.displayName,
                        accentColor: colors.success,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          participant.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(width: 10),
          if (hasTwoMembers)
            SizedBox(
              height: 32,
              child: OutlinedButton(
                onPressed: () => _confirmUnpair(colors, notifier, participant),
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

  Future<void> _confirmUnpair(
    AppColorsExtension colors,
    LiteManagementNotifier notifier,
    LiteParticipant participant,
  ) async {
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
      await notifier.unpair(widget.tournamentId, participant.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.lite_unpairSuccess)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is DioException && e.response?.statusCode == 404
                  ? l10n.lite_unpairApiNotFound
                  : l10n.lite_unpairError,
            ),
          ),
        );
      }
    }
  }
}
