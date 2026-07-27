import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/domain/entities/lite_tournament_create_result.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Tạo giải đấu Lite trong câu lạc bộ
/// Gọi POST /tournaments/lite — đơn giản, không cần categoryId UUID
class CreateClubTournamentScreen extends ConsumerStatefulWidget {
  final String clubId;
  const CreateClubTournamentScreen({super.key, required this.clubId});

  @override
  ConsumerState<CreateClubTournamentScreen> createState() =>
      _CreateClubTournamentScreenState();
}

class _CreateClubTournamentScreenState
    extends ConsumerState<CreateClubTournamentScreen> {
  static const _log = AppLogger('CreateClubTournament');
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _maxTeamsCtrl = TextEditingController(text: '16');

  String _selectedSport = AppConstants.sportBadminton;
  String _selectedFormat = AppConstants.formatSingles;
  String _selectedBracket = AppConstants.bracketSingleElimination;
  bool _isLoading = false;
  bool _isRanked = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _maxTeamsCtrl.dispose();
    super.dispose();
  }

  /// Map App sport slug → backend slug
  String _mapSportSlug() {
    switch (_selectedSport) {
      case AppConstants.sportBadminton:
        return 'badminton';
      case AppConstants.sportTennis:
        return 'tennis';
      case AppConstants.sportPickleball:
        return 'pickleball';
      case AppConstants.sportTableTennis:
        return 'table_tennis';
      default:
        return 'badminton';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioClientProvider).dio;

      final body = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'communityId': widget.clubId,
        'sport': _mapSportSlug(),
        'format': _selectedFormat,
        'bracketType': _selectedBracket,
        'maxTeams': int.tryParse(_maxTeamsCtrl.text) ?? 16,
        'description': _descCtrl.text.trim(),
        'isRanked': _isRanked,
      };

      _log.info('Tạo giải Lite trong CLB: ${body['name']}');
      final response = await dio.post('/tournaments/lite', data: body);

      if (mounted) {
        final raw = response.data;
        final dataJson = raw is Map<String, dynamic>
            ? (raw['data'] as Map<String, dynamic>? ?? raw)
            : <String, dynamic>{};
        final result = LiteTournamentCreateResult.fromJson(dataJson);

        ref.invalidate(communityTournamentsProvider(widget.clubId));
        ref.invalidate(communityDetailProvider(widget.clubId));

        _showSuccessSheet(result);
      }
    } catch (e, stack) {
      _log.error('Lỗi tạo giải đấu trong CLB', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi: ${e.toString().replaceAll('Exception: ', '').replaceAll('DioException: ', '')}',
            ),
            backgroundColor: context.colors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessSheet(LiteTournamentCreateResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LiteSuccessSheet(
        result: result,
        onManage: () {
          context.pop();
          context.push('/lite-manage/${result.id}');
        },
        onClose: () {
          context.pop();
          context.pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Tạo giải đấu trong CLB',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Tên giải đấu ───
              _label('Tên giải đấu *', colors),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameCtrl,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Vui lòng nhập tên giải đấu'
                    : null,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'VD: Giải Cầu lông Mở rộng 2026',
                  hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),

              // ─── Môn thể thao ───
              _label('Môn thể thao', colors),
              const SizedBox(height: 6),
              _buildSportSelector(),
              const SizedBox(height: 20),

              // ─── Hình thức ───
              _label('Hình thức', colors),
              const SizedBox(height: 6),
              _buildFormatSelector(),
              const SizedBox(height: 20),

              // ─── Thể thức ───
              _label('Thể thức thi đấu', colors),
              const SizedBox(height: 6),
              _buildBracketSelector(),
              const SizedBox(height: 20),

              // ─── Số đội tối đa ───
              _label('Số đội tối đa', colors),
              const SizedBox(height: 6),
              TextFormField(
                controller: _maxTeamsCtrl,
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 2 || n > 32) return 'Từ 2-32 đội';
                  return null;
                },
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: '16',
                  hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),

              // ─── Mô tả ───
              _label('Mô tả (không bắt buộc)', colors),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Thông tin thêm về giải đấu...',
                  hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                ),
              ),
              const SizedBox(height: 32),

              // ─── Xếp hạng ELO toggle ───
              Container(
                decoration: BoxDecoration(
                  color: _isRanked
                      ? AppTheme.primary.withValues(alpha: 0.08)
                      : context.colors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isRanked ? AppTheme.primary : context.colors.border,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isRanked ? 'Xếp hạng ELO' : 'Phong trào',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _isRanked
                                  ? AppTheme.primary
                                  : context.colors.textPrimary,
                            ),
                          ),
                          Text(
                            _isRanked
                                ? 'Kết quả ảnh hưởng đến điểm ELO'
                                : 'Giải giao hữu, không tính xếp hạng',
                            style: TextStyle(
                              fontSize: 11,
                              color: context.colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _isRanked,
                      onChanged: (v) => setState(() => _isRanked = v),
                      activeTrackColor: AppTheme.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ─── Nút Submit ───
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_rounded),
                  label: Text(
                    _isLoading ? 'Đang tạo...' : 'Tạo giải đấu',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text, AppColorsExtension colors) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: colors.textSecondary,
      ),
    );
  }

  Widget _buildSportSelector() {
    final sports = [
      (AppConstants.sportBadminton, 'Cầu lông', Icons.sports_tennis),
      (AppConstants.sportTennis, 'Tennis', Icons.sports_tennis),
      (AppConstants.sportPickleball, 'Pickleball', Icons.sports_tennis),
      (AppConstants.sportTableTennis, 'Bóng bàn', Icons.sports_tennis),
    ];
    return Row(
      children: sports.map((s) {
        final selected = _selectedSport == s.$1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: s != sports.last ? 8 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _selectedSport = s.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.primary.withValues(alpha: 0.1)
                      : context.colors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AppTheme.primary : context.colors.border,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      s.$3,
                      size: 22,
                      color: selected
                          ? AppTheme.primary
                          : context.colors.textSecondary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.$2,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? AppTheme.primary
                            : context.colors.textSecondary,
                      ),
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

  Widget _buildFormatSelector() {
    final formats = [
      (AppConstants.formatSingles, 'Đánh đơn'),
      (AppConstants.formatDoubles, 'Đánh đôi'),
    ];
    return Row(
      children: formats.map((f) {
        final selected = _selectedFormat == f.$1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: f != formats.last ? 8 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFormat = f.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.primary.withValues(alpha: 0.1)
                      : context.colors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AppTheme.primary : context.colors.border,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    f.$2,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppTheme.primary
                          : context.colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBracketSelector() {
    final brackets = [
      (
        AppConstants.bracketSingleElimination,
        'Loại trực tiếp',
        'Loại ngay khi thua',
      ),
      (
        AppConstants.bracketDoubleElimination,
        'Loại kép',
        'Có nhánh thắng/thua',
      ),
      (AppConstants.bracketRoundRobin, 'Vòng tròn', 'Tất cả gặp nhau'),
      (
        AppConstants.bracketGroupStageKnockout,
        'Vòng bảng + Loại trực tiếp',
        'Tối thiểu 4 đội, hệ thống tự động chia đều',
      ),
    ];
    return Column(
      children: brackets.map((b) {
        final selected = _selectedBracket == b.$1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => setState(() => _selectedBracket = b.$1),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.primary.withValues(alpha: 0.08)
                    : context.colors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? AppTheme.primary : context.colors.border,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: selected
                        ? AppTheme.primary
                        : context.colors.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.$2,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? AppTheme.primary
                                : context.colors.textPrimary,
                          ),
                        ),
                        Text(
                          b.$3,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Bottom sheet hiển thị sau khi tạo giải Lite thành công
/// Gồm QR, link mời, các nút Sao chép / Chia sẻ / Vào quản lý nhanh
class _LiteSuccessSheet extends StatelessWidget {
  const _LiteSuccessSheet({
    required this.result,
    required this.onManage,
    required this.onClose,
  });

  final LiteTournamentCreateResult result;
  final VoidCallback onManage;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final link = result.resolvedJoinUrl;

    return Container(
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── Drag handle ───
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // ─── Success icon ───
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: colors.success,
                  size: 32,
                ),
              ),
              const SizedBox(height: 14),

              // ─── Title ───
              Text(
                'Tạo giải thành công!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                result.name,
                style: TextStyle(fontSize: 13, color: colors.textMuted),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),

              // ─── QR Code ───
              if (result.resolvedQrPayload.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: QrImageView(
                    data: result.resolvedQrPayload,
                    version: QrVersions.auto,
                    size: 160,
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                  ),
                ),
              if (result.resolvedQrPayload.isNotEmpty)
                const SizedBox(height: 16),

              // ─── Link ───
              if (link.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    link,
                    style: TextStyle(fontSize: 12, color: colors.textMuted),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (link.isNotEmpty) const SizedBox(height: 20),

              // ─── Buttons ───
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: link));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã sao chép link mời!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text(
                        'Sao chép link',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        SharePlus.instance.share(
                          ShareParams(
                            text: 'Tham gia giải ${result.name}: $link',
                          ),
                        );
                      },
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text(
                        'Chia sẻ',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ─── Vào quản lý nhanh ───
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: onManage,
                  icon: const Icon(Icons.speed_rounded, size: 20),
                  label: const Text(
                    'Vào quản lý nhanh',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ─── Đóng ───
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onClose,
                  child: Text(
                    'Đóng',
                    style: TextStyle(color: colors.textMuted, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
