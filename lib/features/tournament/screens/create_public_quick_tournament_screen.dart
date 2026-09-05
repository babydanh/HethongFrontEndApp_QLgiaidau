import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/domain/entities/lite_tournament_create_result.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Tạo giải nhanh (Quick Lite) trên mobile app.
/// Hỗ trợ cả tạo Công khai ngoài Public và tạo gắn liền với CLB (communityId).
class CreatePublicQuickTournamentScreen extends ConsumerStatefulWidget {
  final String? communityId;

  const CreatePublicQuickTournamentScreen({super.key, this.communityId});

  @override
  ConsumerState<CreatePublicQuickTournamentScreen> createState() =>
      _CreatePublicQuickTournamentScreenState();
}

class _CreatePublicQuickTournamentScreenState
    extends ConsumerState<CreatePublicQuickTournamentScreen> {
  static const _log = AppLogger('CreatePublicQuickTournament');
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _maxTeamsController = TextEditingController(text: '16');

  String _sport = AppConstants.sportBadminton;
  String _formatKey = 'MALE_DOUBLES'; // MALE_SINGLES, FEMALE_SINGLES, MALE_DOUBLES, FEMALE_DOUBLES, MIXED_DOUBLES, FOOTBALL_MALE, FOOTBALL_FEMALE, FOOTBALL_MIXED
  String _bracket = AppConstants.bracketSingleElimination;
  String _visibility = 'PUBLIC';
  String _registrationMode = 'APPROVAL';
  DateTime? _startDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  int _durationHours = 1;
  int _durationMinutes = 30;
  bool _isSubmitting = false;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    if (widget.communityId != null && widget.communityId!.isNotEmpty) {
      _visibility = 'PRIVATE';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _maxTeamsController.dispose();
    super.dispose();
  }

  String _mapSportSlug() {
    switch (_sport) {
      case AppConstants.sportBadminton:
        return 'badminton';
      case AppConstants.sportTennis:
        return 'tennis';
      case AppConstants.sportPickleball:
        return 'pickleball';
      case AppConstants.sportTableTennis:
        return 'table_tennis';
      case AppConstants.sportFootball:
        return 'football';
      default:
        return 'badminton';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final maxTeams = int.tryParse(_maxTeamsController.text.trim()) ?? 16;

    setState(() => _isSubmitting = true);
    try {
      String apiFormat = 'doubles';
      String? genderRestriction;

      if (_formatKey == 'MALE_SINGLES') {
        apiFormat = 'singles';
        genderRestriction = 'MALE';
      } else if (_formatKey == 'FEMALE_SINGLES') {
        apiFormat = 'singles';
        genderRestriction = 'FEMALE';
      } else if (_formatKey == 'MALE_DOUBLES') {
        apiFormat = 'doubles';
        genderRestriction = 'MALE';
      } else if (_formatKey == 'FEMALE_DOUBLES') {
        apiFormat = 'doubles';
        genderRestriction = 'FEMALE';
      } else if (_formatKey == 'MIXED_DOUBLES') {
        apiFormat = 'doubles';
        genderRestriction = 'MIXED';
      } else if (_formatKey == 'FOOTBALL_MALE') {
        apiFormat = 'doubles';
        genderRestriction = 'MALE';
      } else if (_formatKey == 'FOOTBALL_FEMALE') {
        apiFormat = 'doubles';
        genderRestriction = 'FEMALE';
      } else if (_formatKey == 'FOOTBALL_MIXED') {
        apiFormat = 'doubles';
        genderRestriction = 'MIXED';
      }

      final payload = <String, dynamic>{
        'name': name,
        if (widget.communityId != null && widget.communityId!.isNotEmpty)
          'communityId': widget.communityId,
        'sport': _mapSportSlug(),
        'format': apiFormat,
        'genderRestriction': ?genderRestriction,
        'bracketType': _bracket,
        'maxTeams': maxTeams,
        'visibility': _visibility,
        'registrationMode': _registrationMode,
        'isRanked': false,
        if (_descController.text.trim().isNotEmpty)
          'description': _descController.text.trim(),
        'durationMinutes': (_durationHours * 60) + _durationMinutes,
        'durationHours': ((_durationHours * 60) + _durationMinutes) / 60.0,
        if (_startDate != null) ...{
          'startDate': DateTime(
            _startDate!.year,
            _startDate!.month,
            _startDate!.day,
            _startTime.hour,
            _startTime.minute,
          ).toUtc().toIso8601String(),
          'startTime':
              '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
          'endDate': DateTime(
            _startDate!.year,
            _startDate!.month,
            _startDate!.day,
            _startTime.hour,
            _startTime.minute,
          )
              .add(Duration(minutes: (_durationHours * 60) + _durationMinutes))
              .toUtc()
              .toIso8601String(),
        },
      };

      _log.info('Gửi yêu cầu tạo giải nhanh: $name');
      final response = await ref
          .read(dioClientProvider)
          .dio
          .post('/tournaments/lite', data: payload);

      final raw = response.data;
      final dataJson = raw is Map<String, dynamic>
          ? (raw['data'] as Map<String, dynamic>? ?? raw)
          : <String, dynamic>{};

      final result = LiteTournamentCreateResult.fromJson(dataJson);
      _log.info('Tạo giải nhanh thành công ID: ${result.id}');

      if (widget.communityId != null && widget.communityId!.isNotEmpty) {
        ref.invalidate(communityTournamentsProvider(widget.communityId!));
        ref.invalidate(communityDetailProvider(widget.communityId!));
      }

      if (mounted) {
        // Tự động điều hướng thẳng vào trang quản lý giải đấu ngay khi tạo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tạo giải đấu "${result.name}" thành công!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pushReplacement('/lite-manage/${result.id}');
      }
    } catch (error, stack) {
      _log.error('Lỗi khi tạo giải nhanh', error, stack);
      if (mounted) {
        _showError(ErrorParser.parse(error, l10n.quickCreateSubmitError));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.colors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isClub = widget.communityId != null && widget.communityId!.isNotEmpty;

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        title: Text(isClub ? 'Tạo Giải Nhanh' : l10n.quickCreateTitle),
        centerTitle: false,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () {
              final query = widget.communityId != null
                  ? '?communityId=${widget.communityId}'
                  : '';
              context.pushReplacement('/tournaments/create-advanced$query');
            },
            icon: const Icon(Icons.tune_rounded, size: 16),
            label: const Text(
              'Nâng cao',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            // ─── Banner Thông tin ───
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Color(0xFF2563EB),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isClub
                              ? 'Tạo nhanh giải đấu nội bộ cho câu lạc bộ'
                              : 'Khởi tạo giải đấu công khai trong 30 giây',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Sơ đồ nhánh đấu và danh sách thi đấu sẽ được tự động thiết lập.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: colors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ─── Tên giải đấu ───
            _sectionLabel('Tên giải đấu *', colors),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'VD: Giải Giao Lưu Mùa Hè 2026',
                prefixIcon: const Icon(Icons.emoji_events_outlined, size: 20),
                filled: true,
                fillColor: colors.bgSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return l10n.quickCreateNameRequired;
                }
                if (val.trim().length < 3) {
                  return 'Tên giải đấu phải có ít nhất 3 ký tự';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),

            // ─── Môn thể thao ───
            _sectionLabel('Môn thể thao *', colors),
            const SizedBox(height: 8),
            _buildSportGrid(colors),
            const SizedBox(height: 18),

            // ─── Thể thức thi đấu ───
            _sectionLabel('Sơ đồ thi đấu *', colors),
            const SizedBox(height: 8),
            _buildBracketSelector(colors),
            const SizedBox(height: 18),

            // ─── Nội dung thi đấu (Bao gồm Giới tính) ───
            _sectionLabel('Nội dung thi đấu & Giới tính', colors),
            const SizedBox(height: 8),
            _buildFormatPills(colors),
            const SizedBox(height: 18),

            // ─── Quy mô & Giới hạn số đội ───
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Số đội / VĐV tối đa', colors),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _maxTeamsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '16',
                          prefixIcon: const Icon(Icons.people_outline_rounded, size: 20),
                          filled: true,
                          fillColor: colors.bgSurface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.border),
                          ),
                        ),
                        validator: (val) {
                          final n = int.tryParse(val?.trim() ?? '');
                          if (n == null || n < 2 || n > 64) {
                            return 'Số đội từ 2 đến 64';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Quyền riêng tư', colors),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _visibility,
                        isExpanded: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: colors.bgSurface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.border),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'PUBLIC',
                            child: Text(
                              'Công khai',
                              style: TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'PRIVATE',
                            child: Text(
                              'Nội bộ',
                              style: TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _visibility = val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ─── Thời gian diễn ra ───
            _sectionLabel('Ngày & Giờ khai mạc', colors),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: _pickStartDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: colors.bgSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 18, color: colors.textMuted),
                          const SizedBox(width: 8),
                          Text(
                            _startDate != null
                                ? DateFormat('dd/MM/yyyy').format(_startDate!)
                                : 'Chọn ngày thi đấu',
                            style: TextStyle(
                              fontSize: 13,
                              color: _startDate != null ? colors.textPrimary : colors.textMuted,
                              fontWeight: _startDate != null ? FontWeight.w600 : FontWeight.normal,
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
                    onTap: _pickStartTime,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: colors.bgSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 18, color: colors.textMuted),
                          const SizedBox(width: 8),
                          Text(
                            '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
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

            // ─── Thời lượng thi đấu ───
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.bgSurface,
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
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() {
                        _durationHours = val;
                        if (_durationHours == 0 && _durationMinutes < 15) {
                          _durationMinutes = 15;
                        }
                      });
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
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() {
                        _durationMinutes = val;
                        if (_durationHours == 0 && _durationMinutes < 15) {
                          _durationMinutes = 15;
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ─── Chế độ xét duyệt đăng ký ───
            _sectionLabel('Chế độ đăng ký tham gia', colors),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _registrationMode,
              decoration: InputDecoration(
                filled: true,
                fillColor: colors.bgSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'APPROVAL',
                  child: Text('Ban tổ chức duyệt đơn đăng ký'),
                ),
                DropdownMenuItem(
                  value: 'OPEN',
                  child: Text('Đăng ký tự do (Vào thẳng nhánh đấu)'),
                ),
                DropdownMenuItem(
                  value: 'INVITE_ONLY',
                  child: Text('Chỉ nhận người có mã mời'),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _registrationMode = val);
              },
            ),
            const SizedBox(height: 14),

            const SizedBox(height: 8),

            // ─── Ghi chú / Điều lệ tóm tắt ───
            _sectionLabel('Ghi chú hoặc địa điểm thi đấu (Tùy chọn)', colors),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'VD: Sân Cầu Lông Kỳ Hòa, Quận 10. Lệ phí 50k/người...',
                filled: true,
                fillColor: colors.bgSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ─── Nút Tạo giải đấu ───
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.flash_on_rounded, size: 20),
                label: Text(
                  _isSubmitting ? 'Đang tạo giải đấu...' : 'Hoàn Tất & Tạo Giải Đấu',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String title, AppColorsExtension colors) => Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: colors.textSecondary,
        ),
      );

  Widget _buildSportGrid(AppColorsExtension colors) {
    final activeCategories = ref.watch(categoriesProvider).value ?? const [];

    final sportsMeta = {
      'badminton': ('Cầu lông', Icons.sports_tennis_rounded),
      'pickleball': ('Pickleball', Icons.sports_baseball_rounded),
      'tennis': ('Tennis', Icons.sports_tennis_outlined),
      'table_tennis': ('Bóng bàn', Icons.sports_cricket_rounded),
      'football': ('Bóng đá', Icons.sports_soccer_rounded),
    };

    // Chỉ hiển thị các môn thể thao đang ACTIVE từ backend, tuyệt đối không fallback hiển thị môn đã tắt
    final sports = activeCategories.where((cat) => cat.isActive).map((cat) {
      final slug = cat.slug.toLowerCase();
      final metaKey = sportsMeta.keys.firstWhere(
        (k) => slug.contains(k) || k.contains(slug),
        orElse: () => 'badminton',
      );
      final meta = sportsMeta[metaKey] ?? (cat.name, Icons.sports_rounded);
      return (metaKey, cat.name.isNotEmpty ? cat.name : meta.$1, meta.$2);
    }).toList();

    if (sports.isNotEmpty && !sports.any((s) => s.$1 == _sport)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _sport = sports.first.$1);
      });
    }

    if (sports.isEmpty) {
      return const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return Row(
      children: sports.map((s) {
        final selected = _sport == s.$1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: s != sports.last ? 8 : 0),
            child: GestureDetector(
              onTap: () => setState(() {
                _sport = s.$1;
                if (s.$1 == AppConstants.sportFootball) {
                  _formatKey = 'FOOTBALL_MALE';
                } else if (_formatKey.startsWith('FOOTBALL_')) {
                  _formatKey = 'MALE_DOUBLES';
                }
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.primary.withValues(alpha: 0.12)
                      : colors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AppTheme.primary : colors.border,
                    width: selected ? 1.8 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      s.$3,
                      size: 24,
                      color: selected ? AppTheme.primary : colors.textSecondary,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.$2,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: selected ? AppTheme.primary : colors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFormatPills(AppColorsExtension colors) {
    final isFootball = _sport == AppConstants.sportFootball;
    final formats = isFootball
        ? [
            ('FOOTBALL_MALE', 'Bóng đá Nam'),
            ('FOOTBALL_FEMALE', 'Bóng đá Nữ'),
            ('FOOTBALL_MIXED', 'Bóng đá Nam Nữ'),
          ]
        : [
            ('MALE_DOUBLES', 'Đôi Nam'),
            ('FEMALE_DOUBLES', 'Đôi Nữ'),
            ('MIXED_DOUBLES', 'Đôi Nam Nữ'),
            ('MALE_SINGLES', 'Đơn Nam'),
            ('FEMALE_SINGLES', 'Đơn Nữ'),
          ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: formats.map((f) {
        final selected = _formatKey == f.$1;
        return GestureDetector(
          onTap: () => setState(() => _formatKey = f.$1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.primary.withValues(alpha: 0.12)
                  : colors.bgSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? AppTheme.primary : colors.border,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Text(
              f.$2,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? AppTheme.primary : colors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBracketSelector(AppColorsExtension colors) {
    final brackets = [
      (
        AppConstants.bracketSingleElimination,
        'Loại trực tiếp (Knockout)',
        'Thua 1 trận bị loại ngay. Nhanh gọn, kịch tính.',
        Icons.account_tree_outlined,
      ),
      (
        AppConstants.bracketDoubleElimination,
        'Nhánh thắng - Nhánh thua',
        'Có cơ hội sửa sai ở nhánh dưới. Nhiều trận hơn.',
        Icons.call_split_rounded,
      ),
      (
        AppConstants.bracketRoundRobin,
        'Vòng tròn tính điểm',
        'Tất cả các đội đều gặp nhau. Công bằng tối đa.',
        Icons.sync_rounded,
      ),
      (
        AppConstants.bracketGroupStageKnockout,
        'Vòng bảng + Knockout',
        'Chia bảng đá vòng tròn, lấy đội đầu bảng vào tứ kết/bán kết.',
        Icons.grid_view_rounded,
      ),
    ];

    return Column(
      children: brackets.map((b) {
        final selected = _bracket == b.$1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => setState(() => _bracket = b.$1),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.primary.withValues(alpha: 0.08)
                    : colors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? AppTheme.primary : colors.border,
                  width: selected ? 1.6 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primary
                          : AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? AppTheme.primary
                            : AppTheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(
                      b.$4,
                      size: 18,
                      color: selected ? Colors.white : AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.$2,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: selected ? AppTheme.primary : colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          b.$3,
                          style: TextStyle(fontSize: 11, color: colors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    selected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: selected ? AppTheme.primary : colors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }
}

