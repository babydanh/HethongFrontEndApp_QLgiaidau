import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/core/widgets/app_text_field.dart';

/// Màn hình chỉnh sửa thông tin câu lạc bộ.
///
/// Gọi API PATCH /communities/:id để cập nhật:
/// - Tên, mô tả, địa điểm, môn thể thao, hình thức tham gia
/// - Logo, banner, số thành viên tối đa, quy tắc, social links
class EditClubScreen extends ConsumerStatefulWidget {
  final String clubId;

  const EditClubScreen({super.key, required this.clubId});

  @override
  ConsumerState<EditClubScreen> createState() => _EditClubScreenState();
}

class _EditClubScreenState extends ConsumerState<EditClubScreen> {
  static const _log = AppLogger('EditClub');
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _maxMembersCtrl = TextEditingController();
  final _rulesCtrl = TextEditingController();

  String _selectedSport = AppConstants.sportBadminton;
  String _joinMode = 'OPEN';
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _maxMembersCtrl.dispose();
    _rulesCtrl.dispose();
    super.dispose();
  }

  void _initFromClub(dynamic club) {
    if (_initialized || club == null) return;
    _nameCtrl.text = club.name ?? '';
    _descCtrl.text = club.description ?? '';
    _locationCtrl.text = club.locationAddress ?? '';
    _selectedSport = (club.sports is List && club.sports.isNotEmpty)
        ? _getSportKey(club.sports.first.toString())
        : AppConstants.sportBadminton;
    _joinMode = club.joinMode ?? 'OPEN';
    _initialized = true;
  }

  String _getSportKey(String sportName) {
    for (final entry in AppConstants.sportNames.entries) {
      if (entry.value == sportName) return entry.key;
    }
    return AppConstants.sportBadminton;
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.colors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: context.colors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.primary),
              title: const Text('Chụp ảnh mới'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppTheme.primary),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (source != null) {
      // TODO: upload logo/banner
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    _log.info('Bắt đầu cập nhật CLB: ${widget.clubId}');

    try {
      final repo = ref.read(communityRepositoryProvider);
      await repo.updateCommunity(widget.clubId, {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'locationAddress': _locationCtrl.text.trim(),
        'categoryIds': [_selectedSport],
        'joinMode': _joinMode,
        if (_maxMembersCtrl.text.trim().isNotEmpty)
          'maxMembers': int.tryParse(_maxMembersCtrl.text.trim()),
        if (_rulesCtrl.text.trim().isNotEmpty)
          'rules': _rulesCtrl.text.trim(),
      });

      _log.success('Cập nhật CLB thành công');
      ref.invalidate(communityDetailProvider(widget.clubId));
      ref.invalidate(communitiesProvider(null));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã cập nhật thông tin CLB'),
            backgroundColor: context.colors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e, stack) {
      _log.error('Lỗi cập nhật CLB', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: context.colors.error,
            behavior: SnackBarBehavior.floating,
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
    final clubAsync = ref.watch(communityDetailProvider(widget.clubId));

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: colors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Chỉnh sửa CLB',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800, fontSize: 17),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Lưu', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        ],
      ),
      body: clubAsync.when(
        data: (club) {
          _initFromClub(club);
          return _buildForm(colors);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildError(colors, () => ref.invalidate(communityDetailProvider(widget.clubId))),
      ),
    );
  }

  Widget _buildForm(AppColorsExtension colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar & Banner
            _label('Ảnh đại diện & Ảnh bìa', colors),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border, style: BorderStyle.solid),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined, color: colors.textMuted, size: 28),
                      const SizedBox(height: 4),
                      Text('Chạm để thay đổi ảnh', style: TextStyle(fontSize: 12, color: colors.textMuted)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tên CLB
            _label('Tên câu lạc bộ *', colors),
            const SizedBox(height: 6),
            AppTextFormField(
              controller: _nameCtrl,
              hint: 'VD: CLB Cầu lông ABC',
              prefixIcon: Icons.edit_rounded,
              validator: (v) => (v == null || v.trim().length < 3) ? 'Tên phải ít nhất 3 ký tự' : null,
            ),
            const SizedBox(height: 20),

            // Môn thể thao
            _label('Môn thể thao', colors),
            const SizedBox(height: 6),
            _buildSportSelector(),
            const SizedBox(height: 20),

            // Mô tả
            _label('Mô tả', colors),
            const SizedBox(height: 6),
            AppTextFormField(
              controller: _descCtrl,
              hint: 'Giới thiệu về câu lạc bộ...',
              maxLines: 3,
              prefixIcon: Icons.notes_rounded,
            ),
            const SizedBox(height: 20),

            // Địa điểm
            _label('Địa điểm', colors),
            const SizedBox(height: 6),
            AppTextFormField(
              controller: _locationCtrl,
              hint: 'VD: Hà Nội, TP. Hồ Chí Minh...',
              prefixIcon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 20),

            // Hình thức tham gia
            _label('Hình thức tham gia', colors),
            const SizedBox(height: 6),
            _buildJoinModeSelector(),
            const SizedBox(height: 20),

            // Số thành viên tối đa
            _label('Số thành viên tối đa (không bắt buộc)', colors),
            const SizedBox(height: 6),
            AppTextFormField(
              controller: _maxMembersCtrl,
              hint: 'VD: 200',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.people_alt_outlined,
            ),
            const SizedBox(height: 20),

            // Quy tắc CLB
            _label('Quy tắc CLB (không bắt buộc)', colors),
            const SizedBox(height: 6),
            AppTextFormField(
              controller: _rulesCtrl,
              hint: 'Nội quy, điều kiện tham gia...',
              maxLines: 3,
              prefixIcon: Icons.rule_rounded,
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _save,
                icon: _isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded),
                label: Text(_isLoading ? 'Đang lưu...' : 'Lưu thay đổi', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
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

  Widget _buildError(AppColorsExtension colors, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: colors.textMuted),
            const SizedBox(height: 12),
            Text('Không thể tải thông tin CLB', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary)),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
