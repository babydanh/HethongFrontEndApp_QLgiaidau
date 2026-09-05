import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// DTO cấu hình cho từng phân hạng thi đấu trong giải nâng cao
class AdvancedDivisionDraft {
  final String id;
  String name;
  String matchType; // SINGLES, DOUBLES, MIXED_DOUBLES
  String? genderRestriction; // MALE, FEMALE, MIXED
  String bracketType;
  int maxParticipants;
  int? minElo;
  int? maxElo;

  AdvancedDivisionDraft({
    required this.id,
    required this.name,
    required this.matchType,
    this.genderRestriction,
    required this.bracketType,
    required this.maxParticipants,
    this.minElo,
    this.maxElo,
  });
}

/// Màn hình Tạo Giải Đấu Nâng Cao (4-Step Wizard) cho Mobile App
class CreateAdvancedTournamentScreen extends ConsumerStatefulWidget {
  final String? communityId;

  const CreateAdvancedTournamentScreen({super.key, this.communityId});

  @override
  ConsumerState<CreateAdvancedTournamentScreen> createState() =>
      _CreateAdvancedTournamentScreenState();
}

class _CreateAdvancedTournamentScreenState
    extends ConsumerState<CreateAdvancedTournamentScreen> {
  static const _log = AppLogger('CreateAdvancedTournament');

  int _currentStep = 0;
  bool _isSubmitting = false;

  // ─── Bước 1: Thông tin chung ───
  final _step1FormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _sport = AppConstants.sportPickleball;
  String _visibility = 'PUBLIC';
  bool _isRanked = true;

  // ─── Bước 2: Phân hạng & Thể thức ───
  final List<AdvancedDivisionDraft> _divisions = [];

  // ─── Bước 3: Lịch trình, Địa điểm & Lệ phí ───
  final _step3FormKey = GlobalKey<FormState>();
  DateTime? _regStartDate;
  DateTime? _regEndDate;
  DateTime? _startDate;
  DateTime? _endDate;
  final _venueController = TextEditingController();
  final _addressController = TextEditingController();
  final _entryFeeController = TextEditingController(text: '0');
  String _registrationMode = 'OPEN';

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    if (widget.communityId != null && widget.communityId!.isNotEmpty) {
      _visibility = 'PRIVATE';
    }
    _initDefaultDivisions();
  }

  void _initDefaultDivisions() {
    _divisions.clear();
    _divisions.addAll([
      AdvancedDivisionDraft(
        id: 'div_1',
        name: 'Đôi Nam Nữ Mở Rộng',
        matchType: 'MIXED_DOUBLES',
        genderRestriction: 'MIXED',
        bracketType: AppConstants.bracketSingleElimination,
        maxParticipants: 16,
      ),
      AdvancedDivisionDraft(
        id: 'div_2',
        name: 'Đôi Nam Trình 6.0',
        matchType: 'DOUBLES',
        genderRestriction: 'MALE',
        bracketType: AppConstants.bracketSingleElimination,
        maxParticipants: 16,
      ),
    ]);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _venueController.dispose();
    _addressController.dispose();
    _entryFeeController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_step1FormKey.currentState!.validate()) return;
    } else if (_currentStep == 1) {
      if (_divisions.isEmpty) {
        _showError('Vui lòng thêm ít nhất 1 nội dung thi đấu');
        return;
      }
    } else if (_currentStep == 2) {
      if (!_step3FormKey.currentState!.validate()) return;
      if (_startDate == null) {
        _showError('Vui lòng chọn ngày khai mạc giải');
        return;
      }
    }
    setState(() => _currentStep = (_currentStep + 1).clamp(0, 3));
  }

  void _prevStep() {
    setState(() => _currentStep = (_currentStep - 1).clamp(0, 3));
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
        return 'pickleball';
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final dio = ref.read(dioClientProvider).dio;
      final categoryRes = await dio.get('/categories');
      final rawCat = categoryRes.data;
      final catList = rawCat is Map<String, dynamic>
          ? (rawCat['data'] as List<dynamic>? ?? const [])
          : (rawCat as List<dynamic>? ?? const []);

      String? categoryId;
      for (final item in catList) {
        if (item is Map<String, dynamic>) {
          final slug = (item['slug'] ?? '').toString().toLowerCase();
          if (slug == _mapSportSlug()) {
            categoryId = item['id']?.toString();
            break;
          }
        }
      }

      final primaryDiv = _divisions.first;
      final fee = int.tryParse(_entryFeeController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

      final now = DateTime.now();
      final start = _startDate ?? now.add(const Duration(days: 7));
      final end = _endDate ?? start.add(const Duration(days: 1));
      final regStart = _regStartDate ?? now;
      final regEnd = _regEndDate ?? start.subtract(const Duration(days: 1));

      final payload = <String, dynamic>{
        'name': _nameController.text.trim(),
        if (categoryId != null && categoryId.isNotEmpty)
          'categoryId': categoryId,
        'description': _descController.text.trim(),
        'tournamentType': widget.communityId != null && widget.communityId!.isNotEmpty ? 'CLUB' : 'PUBLIC',
        if (widget.communityId != null && widget.communityId!.isNotEmpty)
          'communityId': widget.communityId,
        'visibility': _visibility,
        'matchType': primaryDiv.matchType,
        'genderRestriction': primaryDiv.genderRestriction,
        'isRanked': _isRanked,
        'entryFee': fee,
        'maxParticipants': primaryDiv.maxParticipants,
        'startDate': start.toIso8601String(),
        'endDate': end.toIso8601String(),
        'registrationStartDate': regStart.toIso8601String(),
        'registrationEndDate': regEnd.toIso8601String(),
        'venueName': _venueController.text.trim().isNotEmpty ? _venueController.text.trim() : null,
        'locationAddress': _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        'tournamentConfig': {
          'bracketType': primaryDiv.bracketType,
          'maxTeams': primaryDiv.maxParticipants,
          'registrationMode': _registrationMode,
          'mode': 'STRICT',
          'divisions': _divisions.map((d) => {
            'name': d.name,
            'matchType': d.matchType,
            'genderRestriction': d.genderRestriction,
            'bracketType': d.bracketType,
            'maxParticipants': d.maxParticipants,
            'minElo': d.minElo,
            'maxElo': d.maxElo,
          }).toList(),
        },
      };

      _log.info('Gửi yêu cầu tạo giải nâng cao: ${_nameController.text}');
      final response = await dio.post('/tournaments', data: payload);

      final raw = response.data;
      final dataJson = raw is Map<String, dynamic>
          ? (raw['data'] as Map<String, dynamic>? ?? raw)
          : <String, dynamic>{};

      final tournamentId = dataJson['id']?.toString() ?? '';
      _log.info('Tạo giải nâng cao thành công: $tournamentId');

      if (widget.communityId != null && widget.communityId!.isNotEmpty) {
        ref.invalidate(communityTournamentsProvider(widget.communityId!));
        ref.invalidate(communityDetailProvider(widget.communityId!));
      }

      if (mounted) {
        // Tự động điều hướng thẳng vào trang Trung tâm Điều hành giải đấu
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tạo giải đấu "${_nameController.text.trim()}" thành công!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pushReplacement('/organizer/tournaments/$tournamentId/ops');
      }
    } catch (error, stack) {
      _log.error('Lỗi khi tạo giải nâng cao', error, stack);
      if (mounted) {
        _showError(ErrorParser.parse(error, 'Không thể tạo giải đấu nâng cao. Vui lòng kiểm tra lại.'));
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
        title: Text(isClub ? 'Tạo Giải Nâng Cao' : 'Tạo Giải Đấu Nâng Cao'),
        centerTitle: false,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () {
              final query = widget.communityId != null
                  ? '?communityId=${widget.communityId}'
                  : '';
              context.pushReplacement('/tournaments/create$query');
            },
            icon: const Icon(Icons.flash_on_rounded, size: 16),
            label: const Text(
              'Tạo nhanh',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildStepProgress(colors),
          Expanded(
            child: IndexedStack(
              index: _currentStep,
              children: [
                _buildStep1(colors),
                _buildStep2(colors),
                _buildStep3(colors),
                _buildStep4(colors),
              ],
            ),
          ),
          _buildBottomBar(colors),
        ],
      ),
    );
  }

  Widget _buildStepProgress(AppColorsExtension colors) {
    final stepTitles = ['Thông tin', 'Nội dung', 'Lịch & Phí', 'Xác nhận'];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index == _currentStep;
          final isPast = index < _currentStep;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPast
                        ? colors.success
                        : isActive
                            ? AppTheme.primary
                            : colors.bgSurface,
                    border: Border.all(
                      color: isPast
                          ? colors.success
                          : isActive
                              ? AppTheme.primary
                              : colors.border,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: isPast
                        ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isActive ? Colors.white : colors.textMuted,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    stepTitles[index],
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                      color: isActive
                          ? AppTheme.primary
                          : isPast
                              ? colors.textPrimary
                              : colors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (index < 3)
                  Container(
                    width: 16,
                    height: 1.5,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: isPast ? colors.success : colors.border,
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ─── BƯỚC 1: THÔNG TIN CHUNG ───
  Widget _buildStep1(AppColorsExtension colors) {
    return Form(
      key: _step1FormKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _label('Tên giải đấu *', colors),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'VD: Giải Vô Địch Pickleball Mở Rộng 2026',
              prefixIcon: const Icon(Icons.emoji_events_outlined, size: 20),
              filled: true,
              fillColor: colors.bgSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) => v == null || v.trim().length < 5 ? 'Tên giải tối thiểu 5 ký tự' : null,
          ),
          const SizedBox(height: 18),

          _label('Môn thi đấu *', colors),
          const SizedBox(height: 8),
          _buildSportGrid(colors),
          const SizedBox(height: 18),

          _label('Quyền riêng tư', colors),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _visibility,
            decoration: InputDecoration(
              filled: true,
              fillColor: colors.bgSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: const [
              DropdownMenuItem(value: 'PUBLIC', child: Text('Công khai (Mọi người có thể tìm và xem)')),
              DropdownMenuItem(value: 'PRIVATE', child: Text('Nội bộ (Chỉ người có liên kết / thành viên CLB)')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _visibility = v);
            },
          ),
          const SizedBox(height: 18),

          Container(
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: SwitchListTile(
              title: const Text('Tính điểm xếp hạng ELO', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              subtitle: Text('Tự động cập nhật thứ hạng VĐV theo kết quả thi đấu', style: TextStyle(fontSize: 11.5, color: colors.textMuted)),
              value: _isRanked,
              activeThumbColor: AppTheme.primary,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              onChanged: (v) => setState(() => _isRanked = v),
            ),
          ),
          const SizedBox(height: 18),

          _label('Mô tả & Điều lệ vắn tắt', colors),
          const SizedBox(height: 6),
          TextFormField(
            controller: _descController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Nhập thông tin ban tổ chức, quy định đăng ký, giải thưởng...',
              filled: true,
              fillColor: colors.bgSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── BƯỚC 2: PHÂN HẠNG THI ĐẤU (DIVISIONS) ───
  IconData _getFormatIcon(String? bracketType) {
    final t = (bracketType ?? '').toUpperCase();
    if (t.contains('ROUND_ROBIN') || t.contains('ROBIN') || t.contains('VÒNG TRÒN')) {
      return Icons.sync_rounded;
    }
    if (t.contains('GROUP_STAGE') || t.contains('GROUP') || t.contains('BẢNG')) {
      return Icons.grid_view_rounded;
    }
    if (t.contains('DOUBLE_ELIMINATION') || t.contains('DOUBLE_ELIM') || t.contains('NHÁNH KÉP') || t.contains('THẮNG/THUA') || t.contains('THẮNG THUA')) {
      return Icons.call_split_rounded;
    }
    return Icons.account_tree_outlined;
  }

  String _getFormatLabel(String? bracketType) {
    final t = (bracketType ?? '').toUpperCase();
    if (t.contains('ROUND_ROBIN') || t.contains('ROBIN') || t.contains('VÒNG TRÒN')) {
      return 'Vòng tròn tính điểm';
    }
    if (t.contains('GROUP_STAGE') || t.contains('GROUP') || t.contains('BẢNG')) {
      return 'Vòng bảng + loại trực tiếp';
    }
    if (t.contains('DOUBLE_ELIMINATION') || t.contains('DOUBLE_ELIM') || t.contains('NHÁNH KÉP') || t.contains('THẮNG/THUA') || t.contains('THẮNG THUA')) {
      return 'Nhánh thắng/thua';
    }
    return 'Loại trực tiếp';
  }

  Widget _buildStep2(AppColorsExtension colors) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Danh sách nội dung thi đấu', colors),
                Text('Thêm các bảng/hạng mục thi đấu riêng biệt', style: TextStyle(fontSize: 11.5, color: colors.textMuted)),
              ],
            ),
            FilledButton.tonalIcon(
              onPressed: _openAddDivisionModal,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Thêm nội dung', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (_divisions.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border, style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Icon(Icons.layers_clear_rounded, size: 48, color: colors.textMuted),
                const SizedBox(height: 10),
                const Text('Chưa có nội dung nào', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Hãy bấm nút "Thêm nội dung" ở trên để cấu hình bảng đấu.', style: TextStyle(fontSize: 12, color: colors.textMuted), textAlign: TextAlign.center),
              ],
            ),
          )
        else
          ..._divisions.map((div) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: Icon(_getFormatIcon(div.bracketType), color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(div.name, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: colors.bgSurface, borderRadius: BorderRadius.circular(6)),
                              child: Text('${div.maxParticipants} đội', style: TextStyle(fontSize: 11, color: colors.textSecondary)),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: colors.bgSurface, borderRadius: BorderRadius.circular(6)),
                              child: Text(_getFormatLabel(div.bracketType), style: TextStyle(fontSize: 11, color: colors.textSecondary)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _divisions.remove(div)),
                    icon: Icon(Icons.delete_outline_rounded, color: colors.error, size: 20),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ─── BƯỚC 3: LỊCH TRÌNH & LỆ PHÍ ───
  Widget _buildStep3(AppColorsExtension colors) {
    return Form(
      key: _step3FormKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _label('Ngày khai mạc thi đấu *', colors),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _startDate ?? DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _startDate = picked);
            },
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
                    _startDate != null ? DateFormat('dd/MM/yyyy').format(_startDate!) : 'Chọn ngày khai mạc',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: _startDate != null ? colors.textPrimary : colors.textMuted,
                      fontWeight: _startDate != null ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          _label('Chế độ nhận đơn đăng ký', colors),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _registrationMode,
            decoration: InputDecoration(
              filled: true,
              fillColor: colors.bgSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: const [
              DropdownMenuItem(value: 'OPEN', child: Text('Tự do (Vào thẳng danh sách)')),
              DropdownMenuItem(value: 'APPROVAL', child: Text('Ban tổ chức kiểm duyệt từng đơn')),
              DropdownMenuItem(value: 'INVITE_ONLY', child: Text('Chỉ nhận người có mã mời')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _registrationMode = v);
            },
          ),
          const SizedBox(height: 18),

          _label('Địa điểm / Tên sân thi đấu', colors),
          const SizedBox(height: 6),
          TextFormField(
            controller: _venueController,
            decoration: InputDecoration(
              hintText: 'VD: Cụm Sân Pickleball Hồ Xuân Hương',
              prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
              filled: true,
              fillColor: colors.bgSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 18),

          _label('Địa chỉ chi tiết', colors),
          const SizedBox(height: 6),
          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              hintText: 'Số nhà, tên đường, Quận/Huyện, Tỉnh/TP',
              filled: true,
              fillColor: colors.bgSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 18),

          _label('Lệ phí tham gia mỗi VĐV / Đội (VNĐ)', colors),
          const SizedBox(height: 6),
          TextFormField(
            controller: _entryFeeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '0 (Miễn phí)',
              prefixIcon: const Icon(Icons.monetization_on_outlined, size: 20),
              filled: true,
              fillColor: colors.bgSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── BƯỚC 4: XÁC NHẬN & TỔNG QUAN ───
  Widget _buildStep4(AppColorsExtension colors) {
    final isClub = widget.communityId != null && widget.communityId!.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isClub ? 'GIẢI CLB NÂNG CAO' : 'GIẢI NÂNG CAO',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.primary),
                    ),
                  ),
                  const Spacer(),
                  if (_isRanked)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'TÍNH ĐIỂM ELO',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: colors.success),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(_nameController.text.trim(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              if (_descController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(_descController.text.trim(), style: TextStyle(fontSize: 13, color: colors.textSecondary)),
              ],
              const Divider(height: 24),

              _summaryRow('Môn thi đấu', _sport.toUpperCase(), colors),
              _summaryRow('Số phân hạng', '${_divisions.length} nội dung', colors),
              _summaryRow('Ngày khai mạc', _startDate != null ? DateFormat('dd/MM/yyyy').format(_startDate!) : 'Chưa định', colors),
              if (_venueController.text.trim().isNotEmpty)
                _summaryRow('Địa điểm', _venueController.text.trim(), colors),
              _summaryRow('Lệ phí thi đấu', '${_entryFeeController.text.trim()} VNĐ', colors),
            ],
          ),
        ),
        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(Icons.shield_outlined, color: colors.textMuted, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sau khi tạo thành công, giải đấu sẽ được đưa vào Trung tâm Điều hành (Organizer Ops) để quản lý bốc thăm và cập nhật tỉ số.',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: colors.textMuted)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildBottomBar(AppColorsExtension colors) {
    final isLast = _currentStep == 3;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: colors.bgCard,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Quay lại', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: _isSubmitting ? null : (isLast ? _submit : _nextStep),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      isLast ? 'Hoàn Tất & Xuất Bản Giải' : 'Tiếp tục bước tiếp theo',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text, AppColorsExtension colors) {
    return Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textSecondary));
  }

  Widget _buildSportGrid(AppColorsExtension colors) {
    final activeCategories = ref.watch(categoriesProvider).value ?? const [];

    final sportsMeta = {
      'pickleball': ('Pickleball', Icons.sports_baseball_rounded),
      'badminton': ('Cầu lông', Icons.sports_tennis_rounded),
      'tennis': ('Tennis', Icons.sports_tennis_outlined),
      'table_tennis': ('Bóng bàn', Icons.sports_cricket_rounded),
      'football': ('Bóng đá', Icons.sports_soccer_rounded),
    };

    // Chỉ hiển thị các môn thể thao đang ACTIVE từ backend, tuyệt đối không fallback môn đã tắt
    final sports = activeCategories.where((cat) => cat.isActive).map((cat) {
      final slug = cat.slug.toLowerCase();
      final metaKey = sportsMeta.keys.firstWhere(
        (k) => slug.contains(k) || k.contains(slug),
        orElse: () => 'pickleball',
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
              onTap: () => setState(() => _sport = s.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary.withValues(alpha: 0.12) : colors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? AppTheme.primary : colors.border, width: selected ? 1.8 : 1),
                ),
                child: Column(
                  children: [
                    Icon(s.$3, size: 24, color: selected ? AppTheme.primary : colors.textSecondary),
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

  void _openAddDivisionModal() {
    final nameCtrl = TextEditingController(text: 'Nội dung ${_divisions.length + 1}');
    final teamsCtrl = TextEditingController(text: '16');
    String matchType = 'DOUBLES';
    String bracket = AppConstants.bracketSingleElimination;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final colors = context.colors;
          return Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 36, height: 4, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),
                const Text('Thêm Phân Hạng / Bảng Đấu', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),

                _label('Tên nội dung', colors),
                const SizedBox(height: 6),
                TextField(controller: nameCtrl, decoration: InputDecoration(hintText: 'VD: Đôi Nam Nữ Trình 5.0', filled: true, fillColor: colors.bgSurface)),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Định dạng', colors),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: matchType,
                            items: const [
                              DropdownMenuItem(value: 'SINGLES', child: Text('Đơn')),
                              DropdownMenuItem(value: 'DOUBLES', child: Text('Đôi')),
                              DropdownMenuItem(value: 'MIXED_DOUBLES', child: Text('Đôi Nam Nữ')),
                            ],
                            onChanged: (v) {
                              if (v != null) setModalState(() => matchType = v);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Số đội tối đa', colors),
                          const SizedBox(height: 6),
                          TextField(controller: teamsCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: '16', filled: true, fillColor: colors.bgSurface)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                _label('Thể thức thi đấu', colors),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: bracket,
                  items: const [
                    DropdownMenuItem(
                      value: AppConstants.bracketSingleElimination,
                      child: Row(
                        children: [
                          Icon(Icons.account_tree_outlined, size: 18, color: AppTheme.primary),
                          SizedBox(width: 8),
                          Text('Loại trực tiếp'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: AppConstants.bracketDoubleElimination,
                      child: Row(
                        children: [
                          Icon(Icons.call_split_rounded, size: 18, color: AppTheme.primary),
                          SizedBox(width: 8),
                          Text('Nhánh thắng/thua'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: AppConstants.bracketRoundRobin,
                      child: Row(
                        children: [
                          Icon(Icons.sync_rounded, size: 18, color: AppTheme.primary),
                          SizedBox(width: 8),
                          Text('Vòng tròn tính điểm'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: AppConstants.bracketGroupStageKnockout,
                      child: Row(
                        children: [
                          Icon(Icons.grid_view_rounded, size: 18, color: AppTheme.primary),
                          SizedBox(width: 8),
                          Text('Vòng bảng + loại trực tiếp'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setModalState(() => bracket = v);
                  },
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () {
                      final n = nameCtrl.text.trim();
                      final teams = int.tryParse(teamsCtrl.text.trim()) ?? 16;
                      if (n.isEmpty) return;

                      setState(() {
                        _divisions.add(
                          AdvancedDivisionDraft(
                            id: 'div_${DateTime.now().millisecondsSinceEpoch}',
                            name: n,
                            matchType: matchType,
                            genderRestriction: matchType == 'MIXED_DOUBLES' ? 'MIXED' : 'MALE',
                            bracketType: bracket,
                            maxParticipants: teams,
                          ),
                        );
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text('Thêm vào danh sách', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
