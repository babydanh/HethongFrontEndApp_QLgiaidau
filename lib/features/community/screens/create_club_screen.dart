import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';

/// Tạo câu lạc bộ mới — form đơn giản
class CreateClubScreen extends ConsumerStatefulWidget {
  const CreateClubScreen({super.key});

  @override
  ConsumerState<CreateClubScreen> createState() => _CreateClubScreenState();
}

class _CreateClubScreenState extends ConsumerState<CreateClubScreen> {
  static const _log = AppLogger('CreateClub');
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  String _selectedSport = AppConstants.sportBadminton;
  String _joinMode = 'OPEN';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  String _getSportSlug() => _selectedSport;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioProvider);

      final body = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'locationAddress': _locationCtrl.text.trim(),
        'categoryIds': [_getSportSlug()],
        'joinMode': _joinMode,
        'visibility': 'PUBLIC',
        'lat': null,
        'lng': null,
      };

      _log.info('Tạo CLB: ${body['name']}');
      final response = await dio.post('/communities', data: body);
      final clubId = response.data['data']?['id']?.toString() ?? '';

      _log.success('Tạo CLB thành công: $clubId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo câu lạc bộ thành công!'), backgroundColor: Color(0xFF059669)),
        );
        ref.invalidate(communitiesProvider);
        context.go('/club/$clubId');
      }
    } catch (e, stack) {
      _log.error('Lỗi tạo CLB', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red),
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
        title: Text('Tạo câu lạc bộ', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800, fontSize: 17)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Tên câu lạc bộ *', colors),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameCtrl,
                validator: (v) => (v == null || v.trim().length < 3) ? 'Tên phải ít nhất 3 ký tự' : null,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(hintText: 'VD: CLB Cầu lông ABC', hintStyle: TextStyle(color: colors.textMuted, fontSize: 13)),
              ),
              const SizedBox(height: 20),

              _label('Môn thể thao', colors),
              const SizedBox(height: 6),
              _buildSportSelector(),
              const SizedBox(height: 20),

              _label('Mô tả (không bắt buộc)', colors),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(hintText: 'Giới thiệu về câu lạc bộ...', hintStyle: TextStyle(color: colors.textMuted, fontSize: 13)),
              ),
              const SizedBox(height: 20),

              _label('Địa điểm (không bắt buộc)', colors),
              const SizedBox(height: 6),
              TextFormField(
                controller: _locationCtrl,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(hintText: 'VD: Hà Nội, TP. Hồ Chí Minh...', hintStyle: TextStyle(color: colors.textMuted, fontSize: 13)),
              ),
              const SizedBox(height: 20),

              _label('Hình thức tham gia', colors),
              const SizedBox(height: 6),
              _buildJoinModeSelector(),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.add_rounded),
                  label: Text(_isLoading ? 'Đang tạo...' : 'Tạo câu lạc bộ', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
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
      (AppConstants.sportPickleball, 'Pickleball', '🏓'),
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
                child: Column(children: [
                  Text(s.$3, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 4),
                  Text(s.$2, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: selected ? AppTheme.primary : context.colors.textSecondary)),
                ]),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildJoinModeSelector() {
    final modes = [
      ('OPEN', 'Tự do', 'Bất kỳ ai cũng có thể tham gia'),
      ('APPROVAL', 'Xét duyệt', 'Cần được phê duyệt khi tham gia'),
      ('INVITE_ONLY', 'Chỉ mời', 'Chỉ thành viên được mời mới tham gia'),
    ];
    return Column(
      children: modes.map((m) {
        final selected = _joinMode == m.$1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => setState(() => _joinMode = m.$1),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primary.withValues(alpha: 0.08) : context.colors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected ? AppTheme.primary : context.colors.border, width: selected ? 1.5 : 1),
              ),
              child: Row(children: [
                Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined, color: selected ? AppTheme.primary : context.colors.textMuted, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.$2, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: selected ? AppTheme.primary : context.colors.textPrimary)),
                  Text(m.$3, style: TextStyle(fontSize: 11, color: context.colors.textMuted)),
                ])),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }
}
