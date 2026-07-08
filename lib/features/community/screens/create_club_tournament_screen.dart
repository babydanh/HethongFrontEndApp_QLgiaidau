import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';

/// Tạo giải đấu Lite trong câu lạc bộ
/// Gọi POST /tournaments/lite — đơn giản, không cần categoryId UUID
class CreateClubTournamentScreen extends ConsumerStatefulWidget {
  final String clubId;
  const CreateClubTournamentScreen({super.key, required this.clubId});

  @override
  ConsumerState<CreateClubTournamentScreen> createState() => _CreateClubTournamentScreenState();
}

class _CreateClubTournamentScreenState extends ConsumerState<CreateClubTournamentScreen> {
  static const _log = AppLogger('CreateClubTournament');
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _maxTeamsCtrl = TextEditingController(text: '16');

  String _selectedSport = AppConstants.sportBadminton;
  String _selectedFormat = AppConstants.formatSingles;
  String _selectedBracket = AppConstants.bracketSingleElimination;
  bool _isLoading = false;

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
      case AppConstants.sportBadminton: return 'badminton';
      case AppConstants.sportTennis: return 'tennis';
      case AppConstants.sportPickleball: return 'pickleball';
      case AppConstants.sportTableTennis: return 'table_tennis';
      default: return 'badminton';
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
      };

      _log.info('Tạo giải Lite trong CLB: ${body['name']}');
      final response = await dio.post('/tournaments/lite', data: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _log.success('Tạo giải Lite thành công');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo giải đấu thành công!'), backgroundColor: Color(0xFF059669)),
        );
        ref.invalidate(communityTournamentsProvider(widget.clubId));
        ref.invalidate(communityDetailProvider(widget.clubId));
        context.pop();
      }
    } catch (e, stack) {
      _log.error('Lỗi tạo giải đấu trong CLB', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '').replaceAll('DioException: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800, fontSize: 17),
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
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên giải đấu' : null,
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
                  if (n == null || n < 2 || n > 128) return 'Từ 2-128 đội';
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
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: colors.bgSurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.lock_rounded, size: 18, color: Color(0xFFF97316)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Giải đóng mặc định', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                          Text('Giải CLB tạo từ app sẽ mặc định ở chế độ PRIVATE, chỉ người có quyền hoặc có mã mời mới vào được.', style: TextStyle(fontSize: 11, color: colors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ─── Nút Submit ───
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.add_rounded),
                  label: Text(
                    _isLoading ? 'Đang tạo...' : 'Tạo giải đấu',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
    return Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textSecondary));
  }

  Widget _buildSportSelector() {
    final sports = [
      (AppConstants.sportBadminton, 'Cầu lông', '🏸'),
      (AppConstants.sportTennis, 'Tennis', '🎾'),
      (AppConstants.sportPickleball, 'Pickleball', '🥒'),
      (AppConstants.sportTableTennis, 'Bóng bàn', '🏓'),
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
                  color: selected ? AppTheme.primary.withValues(alpha: 0.1) : context.colors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? AppTheme.primary : context.colors.border, width: selected ? 1.5 : 1),
                ),
                child: Column(
                  children: [
                    Text(s.$3, style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 4),
                    Text(s.$2, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: selected ? AppTheme.primary : context.colors.textSecondary)),
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
                  color: selected ? AppTheme.primary.withValues(alpha: 0.1) : context.colors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? AppTheme.primary : context.colors.border, width: selected ? 1.5 : 1),
                ),
                child: Center(
                  child: Text(f.$2, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? AppTheme.primary : context.colors.textSecondary)),
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
      (AppConstants.bracketSingleElimination, 'Loại trực tiếp', 'Loại ngay khi thua'),
      (AppConstants.bracketDoubleElimination, 'Loại kép', 'Có nhánh thắng/thua'),
      (AppConstants.bracketRoundRobin, 'Vòng tròn', 'Tất cả gặp nhau'),
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
                color: selected ? AppTheme.primary.withValues(alpha: 0.08) : context.colors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected ? AppTheme.primary : context.colors.border, width: selected ? 1.5 : 1),
              ),
              child: Row(
                children: [
                  Icon(
                    selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color: selected ? AppTheme.primary : context.colors.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.$2, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: selected ? AppTheme.primary : context.colors.textPrimary)),
                        Text(b.$3, style: TextStyle(fontSize: 11, color: context.colors.textMuted)),
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
