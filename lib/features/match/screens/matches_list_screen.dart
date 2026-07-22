import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:intl/intl.dart';

/// Trang hiển thị danh sách trận đấu với filter và search.
class MatchesListScreen extends ConsumerStatefulWidget {
  const MatchesListScreen({super.key});

  @override
  ConsumerState<MatchesListScreen> createState() => _MatchesListScreenState();
}

class _MatchesListScreenState extends ConsumerState<MatchesListScreen> {
  final _searchController = TextEditingController();
  String _selectedSport = '';
  String _selectedStatus = '';
  DateTimeRange? _selectedDateRange;
  String _selectedLocation = '';
  bool _isLoading = false;
  List<MatchModel> _allMatches = [];
  List<MatchModel> _filteredMatches = [];
  String? _error;

  // Status filters
  static const _statusOptions = [
    '',
    'scheduled',
    'live',
    'completed',
    'walkover',
  ];
  static const _statusLabels = {
    '': 'Tất cả',
    'scheduled': 'Sắp diễn ra',
    'live': 'Đang thi đấu',
    'completed': 'Hoàn thành',
    'walkover': 'Bỏ cuộc',
  };
  static const _statusColors = {
    'scheduled': Color(0xFF64748B),
    'live': Color(0xFF2979FF),
    'completed': Color(0xFF10B981),
    'walkover': Color(0xFFEF4444),
  };

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilters);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load categories
      ref.read(categoriesProvider);

      // Load matches
      final repo = ref.read(matchRepositoryProvider);
      final matches = await repo.getMatches(publicOnly: true);

      if (mounted) {
        setState(() {
          _allMatches = matches;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Không thể tải danh sách trận đấu. Hãy thử lại.';
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredMatches = _allMatches.where((m) {
        // Search filter
        if (query.isNotEmpty) {
          final team1 = m.team1Name.toLowerCase();
          final team2 = m.team2Name.toLowerCase();
          final members1 = m.team1Members?.join(' ').toLowerCase() ?? '';
          final members2 = m.team2Members?.join(' ').toLowerCase() ?? '';
          if (!team1.contains(query) &&
              !team2.contains(query) &&
              !members1.contains(query) &&
              !members2.contains(query)) {
            return false;
          }
        }

        // Sport filter
        if (_selectedSport.isNotEmpty &&
            m.sportKey != _selectedSport) {
          return false;
        }

        // Status filter
        if (_selectedStatus.isNotEmpty &&
            m.status != _selectedStatus) {
          return false;
        }

        // Date range filter
        if (_selectedDateRange != null) {
          final matchDate = m.scheduledTime ?? m.updatedAt;
          if (matchDate.isBefore(_selectedDateRange!.start) ||
              matchDate.isAfter(_selectedDateRange!.end)) {
            return false;
          }
        }

        // Location filter
        if (_selectedLocation.isNotEmpty) {
          final court = m.court.toLowerCase();
          if (!court.contains(_selectedLocation.toLowerCase())) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
      locale: const Locale('vi'),
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _applyFilters();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: colors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Trận đấu',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: colors.textPrimary),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(colors)
              : Column(
                  children: [
                    _buildSearchBar(colors),
                    _buildFilterRow(colors),
                    _buildActiveFilters(colors),
                    Expanded(
                      child: _filteredMatches.isEmpty
                          ? _buildEmpty(colors)
                          : _buildGroupedList(colors),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSearchBar(AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: TextField(
          controller: _searchController,
          style: TextStyle(color: colors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Tìm theo tên VĐV / CLB...',
            hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded, color: colors.textMuted, size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded, color: colors.textMuted, size: 18),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow(AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Status Pills
            _StatusFilterPill(
              label: 'Vừa kết thúc',
              isSelected: _selectedStatus == 'completed',
              activeBgColor: const Color(0xFFF3F4F1),
              activeTextColor: const Color(0xFF4A4E4D),
              onTap: () {
                setState(() {
                  _selectedStatus = _selectedStatus == 'completed' ? '' : 'completed';
                  _applyFilters();
                });
              },
            ),
            const SizedBox(width: 8),
            _StatusFilterPill(
              label: 'Đang diễn ra',
              isSelected: _selectedStatus == 'live',
              activeBgColor: const Color(0xFFEBF5FF),
              activeTextColor: const Color(0xFF1E56A0),
              onTap: () {
                setState(() {
                  _selectedStatus = _selectedStatus == 'live' ? '' : 'live';
                  _applyFilters();
                });
              },
            ),
            const SizedBox(width: 8),
            _StatusFilterPill(
              label: 'Mở đăng ký',
              isSelected: _selectedStatus == 'registration',
              activeBgColor: const Color(0xFFEFF8E9),
              activeTextColor: const Color(0xFF386629),
              onTap: () {
                setState(() {
                  _selectedStatus = _selectedStatus == 'registration' ? '' : 'registration';
                  _applyFilters();
                });
              },
            ),
            const SizedBox(width: 8),
            _StatusFilterPill(
              label: 'Sắp diễn ra',
              isSelected: _selectedStatus == 'scheduled',
              activeBgColor: const Color(0xFFFFF5E6),
              activeTextColor: const Color(0xFF995C00),
              onTap: () {
                setState(() {
                  _selectedStatus = _selectedStatus == 'scheduled' ? '' : 'scheduled';
                  _applyFilters();
                });
              },
            ),
            const SizedBox(width: 8),
            _StatusFilterPill(
              label: 'Đã kết thúc',
              isSelected: _selectedStatus == 'finished',
              activeBgColor: const Color(0xFFF1F5F9),
              activeTextColor: const Color(0xFF64748B),
              onTap: () {
                setState(() {
                  _selectedStatus = _selectedStatus == 'finished' ? '' : 'finished';
                  _applyFilters();
                });
              },
            ),
            const SizedBox(width: 12),
            // Sport filter
            _FilterChip(
              label: _selectedSport.isEmpty
                  ? 'Môn thể thao'
                  : AppConstants.sportNames[_selectedSport] ?? _selectedSport,
              icon: Icons.sports_rounded,
              isActive: _selectedSport.isNotEmpty,
              colors: colors,
              onTap: () => _showSportPicker(colors),
            ),
            const SizedBox(width: 8),
            // Date filter
            _FilterChip(
              label: _selectedDateRange != null
                  ? DateFormat('dd/MM').format(_selectedDateRange!.start)
                  : 'Ngày',
              icon: Icons.calendar_month_rounded,
              isActive: _selectedDateRange != null,
              colors: colors,
              onTap: _pickDateRange,
            ),
            const SizedBox(width: 8),
            // Location filter
            _FilterChip(
              label: _selectedLocation.isEmpty ? 'Địa điểm' : _selectedLocation,
              icon: Icons.location_on_rounded,
              isActive: _selectedLocation.isNotEmpty,
              colors: colors,
              onTap: () => _showLocationInput(colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilters(AppColorsExtension colors) {
    final chips = <Widget>[];
    if (_selectedSport.isNotEmpty) {
      chips.add(_buildActiveChip(
        AppConstants.sportNames[_selectedSport] ?? _selectedSport,
        () => setState(() { _selectedSport = ''; _applyFilters(); }),
        colors,
      ));
    }
    if (_selectedStatus.isNotEmpty) {
      chips.add(_buildActiveChip(
        _statusLabels[_selectedStatus] ?? '',
        () => setState(() { _selectedStatus = ''; _applyFilters(); }),
        colors,
      ));
    }
    if (_selectedDateRange != null) {
      final fmt = DateFormat('dd/MM');
      chips.add(_buildActiveChip(
        '${fmt.format(_selectedDateRange!.start)} - ${fmt.format(_selectedDateRange!.end)}',
        () => setState(() { _selectedDateRange = null; _applyFilters(); }),
        colors,
      ));
    }
    if (_selectedLocation.isNotEmpty) {
      chips.add(_buildActiveChip(
        _selectedLocation,
        () => setState(() { _selectedLocation = ''; _applyFilters(); }),
        colors,
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: chips,
      ),
    );
  }

  Widget _buildActiveChip(String label, VoidCallback onRemove, AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.info.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.info)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 14, color: colors.info),
          ),
        ],
      ),
    );
  }

  void _showSportPicker(AppColorsExtension colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chọn môn thể thao', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colors.textPrimary)),
            const SizedBox(height: 16),
            _buildSportOption(ctx, colors, '', 'Tất cả', null),
            ...AppConstants.sportNames.entries.map((e) => _buildSportOption(ctx, colors, e.key, e.value, e.key)),
          ],
        ),
      ),
    );
  }

  Widget _buildSportOption(BuildContext ctx, AppColorsExtension colors, String value, String label, String? sportKey) {
    final isSelected = _selectedSport == value;
    return ListTile(
      leading: Icon(
        sportKey != null ? Icons.sports_tennis_rounded : Icons.all_inclusive_rounded,
        color: isSelected ? colors.info : colors.textMuted,
      ),
      title: Text(label, style: TextStyle(color: isSelected ? colors.info : colors.textPrimary, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
      trailing: isSelected ? Icon(Icons.check_rounded, color: colors.info) : null,
      onTap: () {
        setState(() { _selectedSport = value; _applyFilters(); });
        Navigator.pop(ctx);
      },
    );
  }

  void _showStatusPicker(AppColorsExtension colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chọn trạng thái', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colors.textPrimary)),
            const SizedBox(height: 16),
            ..._statusOptions.map((s) {
              final isSelected = _selectedStatus == s;
              return ListTile(
                leading: Icon(
                  s.isEmpty ? Icons.all_inclusive_rounded : Icons.flag_rounded,
                  color: isSelected
                      ? (s.isEmpty ? colors.info : _statusColors[s])
                      : colors.textMuted,
                ),
                title: Text(
                  _statusLabels[s] ?? '',
                  style: TextStyle(
                    color: isSelected
                        ? (s.isEmpty ? colors.info : _statusColors[s])
                        : colors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                trailing: isSelected ? Icon(Icons.check_rounded, color: colors.info) : null,
                onTap: () {
                  setState(() { _selectedStatus = s; _applyFilters(); });
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showLocationInput(AppColorsExtension colors) {
    final controller = TextEditingController(text: _selectedLocation);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Nhập địa điểm', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Tên địa điểm, sân...',
            hintStyle: TextStyle(color: colors.textMuted),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy', style: TextStyle(color: colors.textMuted)),
          ),
          FilledButton(
            onPressed: () {
              setState(() { _selectedLocation = controller.text.trim(); _applyFilters(); });
              Navigator.pop(ctx);
            },
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList(AppColorsExtension colors) {
    // Group matches by tournament name
    final grouped = <String, List<MatchModel>>{};
    for (final m in _filteredMatches) {
      final key = m.tournamentName ?? 'Khác';
      grouped.putIfAbsent(key, () => []).add(m);
    }

    final sortedKeys = grouped.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: sortedKeys.length,
        itemBuilder: (context, index) {
          final tournamentName = sortedKeys[index];
          final matches = grouped[tournamentName]!;
          return _buildTournamentGroup(tournamentName, matches, colors);
        },
      ),
    );
  }

  Widget _buildTournamentGroup(
      String tournamentName, List<MatchModel> matches, AppColorsExtension colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(Icons.emoji_events_rounded, size: 16, color: colors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tournamentName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: colors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${matches.length} trận',
                style: TextStyle(fontSize: 11, color: colors.textMuted),
              ),
            ],
          ),
        ),
        ...matches.map((m) => _buildMatchCard(m, colors)),
      ],
    );
  }

  Widget _buildMatchCard(MatchModel match, AppColorsExtension colors) {
    final isLive = match.isLive;

    return GestureDetector(
      onTap: () {
        if (match.tournamentName != null) {
          // Navigate to the match detail via live-score
          context.push('/live/${match.id}');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isLive
                ? const Color(0xFF2979FF).withValues(alpha: 0.3)
                : colors.border,
          ),
        ),
        child: Row(
          children: [
            // Team 1
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match.team1Name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (match.team1Members != null && match.team1Members!.isNotEmpty)
                    Text(
                      match.team1Members!.join(', '),
                      style: TextStyle(fontSize: 10, color: colors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            // Score / vs
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                match.isCompleted || match.isLive
                    ? '${match.score1} - ${match.score2}'
                    : 'VS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isLive
                      ? const Color(0xFF2979FF)
                      : match.isCompleted
                          ? colors.success
                          : colors.textPrimary,
                ),
              ),
            ),
            // Team 2
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    match.team2Name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                  if (match.team2Members != null && match.team2Members!.isNotEmpty)
                    Text(
                      match.team2Members!.join(', '),
                      style: TextStyle(fontSize: 10, color: colors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(AppColorsExtension colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.sports_tennis_rounded,
              size: 40,
              color: colors.textMuted.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy trận đấu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Thử thay đổi bộ lọc hoặc tìm kiếm khác',
            style: TextStyle(fontSize: 13, color: colors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildError(AppColorsExtension colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: colors.textMuted),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Filter Chip Widget ───

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final AppColorsExtension colors;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = colors.info;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.12) : colors.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? activeColor.withValues(alpha: 0.4) : colors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isActive ? activeColor : colors.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? activeColor : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Status Filter Pill (Hình 1 design) ───

class _StatusFilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeBgColor;
  final Color activeTextColor;
  final VoidCallback onTap;

  const _StatusFilterPill({
    required this.label,
    required this.isSelected,
    required this.activeBgColor,
    required this.activeTextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBgColor : colors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeTextColor.withValues(alpha: 0.3) : colors.border,
            width: isSelected ? 1.2 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? activeTextColor : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
