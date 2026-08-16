import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/features/community/social/community_feed_notifier.dart';
import 'package:app_quanly_giaidau/features/community/widgets/club_region_selector.dart';
import 'package:app_quanly_giaidau/features/community/widgets/club_social_links_editor.dart';
import 'package:app_quanly_giaidau/features/community/widgets/club_visibility_selector.dart';
import 'package:app_quanly_giaidau/core/widgets/app_text_field.dart';

/// Màn hình chỉnh sửa thông tin câu lạc bộ — đồng bộ web (SettingsTab.tsx).
///
/// PATCH /communities/:id với: tên, mô tả, môn thể thao chính (đúng 1),
/// vùng hoạt động (tỉnh/quận/phường + ghép địa chỉ), visibility, joinMode,
/// câu hỏi xét duyệt (chỉ khi APPROVAL), social links động, maxMembers, nội quy.
/// Logo/banner upload riêng qua POST /upload/image + PATCH cộng đồng.
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
  final _joinQuestionCtrl = TextEditingController();

  final List<String> _joinQuestions = [];
  Map<String, String> _socialLinks = const {};
  ClubRegionSelection _region = const ClubRegionSelection();

  String _selectedSport = '';
  String _joinMode = 'OPEN';
  String _visibility = 'PUBLIC';
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _maxMembersCtrl.dispose();
    _rulesCtrl.dispose();
    _joinQuestionCtrl.dispose();
    super.dispose();
  }

  void _initFromClub(Community? club) {
    if (_initialized || club == null) return;
    _nameCtrl.text = club.name;
    _descCtrl.text = club.description ?? '';
    _locationCtrl.text = club.locationAddress ?? '';
    _rulesCtrl.text = club.rules ?? '';
    _maxMembersCtrl.text = club.maxMembers?.toString() ?? '';
    _selectedSport = club.sports.isNotEmpty ? club.sports.first : '';
    _joinMode = club.joinMode;
    _visibility = club.visibility;
    _joinQuestions.addAll(club.joinQuestions);
    _socialLinks = club.socialLinks;
    _initialized = true;
  }

  Future<String> _resolveCategoryId() async {
    final categories = await ref.read(categoriesProvider.future);
    final selected = categories.where((category) {
      final slug = category.slug.trim().toLowerCase();
      final name = category.name.trim().toLowerCase();
      return slug == _selectedSport.toLowerCase() ||
          name == _selectedSport.toLowerCase();
    }).firstOrNull;
    if (selected == null || selected.id.isEmpty) {
      throw StateError('Câu lạc bộ phải có đúng 1 môn thể thao chính.');
    }
    return selected.id;
  }

  Future<void> _pickAndUploadImage({required bool isLogo}) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.colors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.primary),
              title: const Text('Chụp ảnh mới'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppTheme.primary),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final picked = await ImagePicker().pickImage(source: source, imageQuality: 88);
    if (picked == null || !mounted) return;
    setState(() => _isLoading = true);
    try {
      final bytes = await picked.readAsBytes();
      final url = await ref
          .read(communitySocialRepositoryProvider)
          .uploadImage(bytes, picked.name);
      await ref.read(communityRepositoryProvider).updateCommunity(
            widget.clubId,
            {isLogo ? 'logoUrl' : 'bannerUrl': url},
          );
      ref.invalidate(communityDetailProvider(widget.clubId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isLogo
                ? 'Đã cập nhật ảnh đại diện (PNG, JPG tỉ lệ 1:1)'
                : 'Đã cập nhật ảnh bìa (khuyên dùng 1200x400 px)'),
          ),
        );
      }
    } catch (e, stack) {
      _log.error('Lỗi cập nhật ảnh CLB', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể cập nhật ảnh CLB')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Câu lạc bộ phải có đúng 1 môn thể thao chính.')),
      );
      return;
    }
    if (_region.provinceCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn tỉnh/thành phố.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    _log.info('Bắt đầu cập nhật CLB: ${widget.clubId}');

    try {
      final composedAddress = _region.composeAddress(_locationCtrl.text);
      final repo = ref.read(communityRepositoryProvider);
      await repo.updateCommunity(widget.clubId, {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'rules': _rulesCtrl.text.trim(),
        'visibility': _visibility,
        'joinMode': _joinMode,
        'joinQuestions': _joinQuestions,
        'socialLinks': _socialLinks,
        'categoryIds': [await _resolveCategoryId()],
        'maxMembers': int.tryParse(_maxMembersCtrl.text.trim()),
        'locationAddress': composedAddress.isEmpty ? null : composedAddress,
        'provinceCode': _region.provinceCode,
        'districtCode': _region.districtCode.isEmpty ? null : _region.districtCode,
        'wardCode': _region.wardCode.isEmpty ? null : _region.wardCode,
      });

      _log.success('Cập nhật CLB thành công');
      ref.invalidate(communityDetailProvider(widget.clubId));
      invalidateCommunityCollections(ref);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cập nhật cài đặt câu lạc bộ thành công!'),
            backgroundColor: context.colors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Deep-link (vào thẳng /club/:id/edit) không có stack để pop thì về chi tiết CLB.
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/club/${widget.clubId}');
        }
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
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/club/${widget.clubId}');
            }
          },
        ),
        title: Text(
          'Chỉnh sửa CLB',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Lưu',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
          ),
        ],
      ),
      body: clubAsync.when(
        data: (club) {
          _initFromClub(club);
          return _buildForm(colors, club);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildError(
          colors,
          () => ref.invalidate(communityDetailProvider(widget.clubId)),
        ),
      ),
    );
  }

  Widget _buildForm(AppColorsExtension colors, Community? club) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Ảnh đại diện & Ảnh bìa (preview riêng như web) ──
            _label('Ảnh đại diện & Ảnh bìa', colors),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _imagePickerCard(
                    colors: colors,
                    title: 'Logo CLB',
                    hint: 'PNG, JPG tỉ lệ 1:1',
                    imageUrl: club?.logoUrl,
                    isCircle: true,
                    onTap: () => _pickAndUploadImage(isLogo: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _imagePickerCard(
                    colors: colors,
                    title: 'Ảnh bìa',
                    hint: 'Khuyên dùng 1200x400 px',
                    imageUrl: club?.bannerUrl,
                    isCircle: false,
                    onTap: () => _pickAndUploadImage(isLogo: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Thông tin cơ bản ──
            _label('Tên câu lạc bộ *', colors),
            const SizedBox(height: 6),
            AppTextFormField(
              controller: _nameCtrl,
              hint: 'VD: CLB Cầu lông ABC',
              prefixIcon: Icons.edit_rounded,
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'Vui lòng nhập tên câu lạc bộ.';
                if (value.length > 255) return 'Tên tối đa 255 ký tự.';
                return null;
              },
            ),
            const SizedBox(height: 20),

            _label('Môn thể thao chính *', colors),
            const SizedBox(height: 6),
            Text(
              'Mỗi CLB chỉ có một môn thể thao chính.',
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
            const SizedBox(height: 6),
            _buildSportSelector(),
            const SizedBox(height: 20),

            _label('Mô tả', colors),
            const SizedBox(height: 6),
            AppTextFormField(
              controller: _descCtrl,
              hint: 'Giới thiệu về mục đích hoạt động, lịch sinh hoạt cố định...',
              maxLines: 3,
              prefixIcon: Icons.notes_rounded,
            ),
            const SizedBox(height: 24),

            // ── Địa điểm & Khu vực hoạt động ──
            _label('Địa điểm & Khu vực hoạt động', colors),
            const SizedBox(height: 8),
            ClubRegionSelector(
              initialProvinceCode: club?.provinceCode ?? '',
              initialDistrictCode: club?.districtCode ?? '',
              initialWardCode: club?.wardCode ?? '',
              onChanged: (selection) => _region = selection,
            ),
            const SizedBox(height: 12),
            AppTextFormField(
              controller: _locationCtrl,
              hint:
                  'Địa chỉ sân nhà / địa điểm sinh hoạt cụ thể (VD: Sân Thể Thao Tuổi Trẻ, Số 123 Lê Lợi...)',
              prefixIcon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 24),

            // ── Quyền riêng tư & Cách thức tham gia ──
            _label('Quyền riêng tư', colors),
            const SizedBox(height: 8),
            ClubVisibilitySelector(
              value: _visibility,
              onChanged: (value) => setState(() => _visibility = value),
            ),
            const SizedBox(height: 20),

            _label('Cách thức tham gia', colors),
            const SizedBox(height: 8),
            _buildJoinModeSelector(),
            const SizedBox(height: 20),

            AppTextFormField(
              controller: _maxMembersCtrl,
              label: 'Số thành viên tối đa',
              hint: 'Không giới hạn',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.people_alt_outlined,
            ),
            const SizedBox(height: 20),

            _label('Nội quy câu lạc bộ', colors),
            const SizedBox(height: 6),
            AppTextFormField(
              controller: _rulesCtrl,
              hint: 'Quy định ứng xử, thời gian sinh hoạt, đóng quỹ...',
              maxLines: 3,
              prefixIcon: Icons.rule_rounded,
            ),
            const SizedBox(height: 24),

            // ── Câu hỏi xét duyệt (chỉ khi joinMode == APPROVAL, như web) ──
            if (_joinMode == 'APPROVAL') ...[
              _label('Câu hỏi xét duyệt thành viên', colors),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: AppTextFormField(
                      controller: _joinQuestionCtrl,
                      hint:
                          'Nhập câu hỏi (VD: Trình độ ELO / DUPR hiện tại của bạn là bao nhiêu?)...',
                      prefixIcon: Icons.help_outline_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: () {
                      final question = _joinQuestionCtrl.text.trim();
                      if (question.isEmpty || _joinQuestions.contains(question)) {
                        return;
                      }
                      setState(() {
                        _joinQuestions.add(question);
                        _joinQuestionCtrl.clear();
                      });
                    },
                    icon: const Icon(Icons.add_rounded),
                    tooltip: 'Thêm câu hỏi',
                  ),
                ],
              ),
              ..._joinQuestions.asMap().entries.map(
                    (entry) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Text('${entry.key + 1}.'),
                      title: Text(entry.value),
                      trailing: IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => setState(
                          () => _joinQuestions.removeAt(entry.key),
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: 24),
            ],

            // ── Mạng xã hội & Kênh liên hệ ──
            _label('Mạng xã hội & Kênh liên hệ', colors),
            const SizedBox(height: 8),
            ClubSocialLinksEditor(
              initialLinks: _socialLinks,
              onChanged: (links) => _socialLinks = links,
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _save,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(
                  _isLoading ? 'Đang lưu...' : 'Lưu toàn bộ cài đặt',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildDangerZone(colors),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _imagePickerCard({
    required AppColorsExtension colors,
    required String title,
    required String hint,
    required String? imageUrl,
    required bool isCircle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 64,
              decoration: BoxDecoration(
                color: colors.bgSurface,
                shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: isCircle ? null : BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl == null || imageUrl.isEmpty
                  ? Icon(Icons.image_outlined, color: colors.textMuted, size: 24)
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.broken_image_outlined, color: colors.textMuted),
                    ),
            ),
            const SizedBox(height: 8),
            Text(title,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800, color: colors.textPrimary)),
            const SizedBox(height: 2),
            Text(hint, style: TextStyle(fontSize: 10, color: colors.textMuted)),
            const SizedBox(height: 4),
            Text(
              'Thay đổi',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone(AppColorsExtension colors) {
    return Card(
      color: colors.error.withValues(alpha: .06),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vùng nguy hiểm',
              style: TextStyle(color: colors.error, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Hành động này sẽ xóa vĩnh viễn Câu lạc bộ này cùng toàn bộ bài viết, '
              'bảng xếp hạng và lịch sử giải đấu. Không thể hoàn tác sau khi xác nhận.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _confirmDeleteClub,
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('Xoá vĩnh viễn câu lạc bộ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteClub() async {
    final club = ref.read(communityDetailProvider(widget.clubId)).asData?.value;
    final expected = club?.name.trim() ?? _nameCtrl.text.trim();
    final controller = TextEditingController();
    var typedName = '';
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Xoá vĩnh viễn câu lạc bộ'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bạn có chắc chắn muốn xoá câu lạc bộ "$expected"? Toàn bộ dữ liệu '
                  'thành viên, bài viết và hoạt động sẽ bị xoá vĩnh viễn và không thể khôi phục.',
                ),
                const SizedBox(height: 12),
                Text('Nhập tên câu lạc bộ $expected để xác nhận:'),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  onChanged: (value) => setDialogState(() => typedName = value),
                  decoration: const InputDecoration(labelText: 'Tên câu lạc bộ'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Huỷ'),
              ),
              FilledButton(
                onPressed: typedName.trim() == expected
                    ? () => Navigator.pop(dialogContext, true)
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: context.colors.error,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Xoá vĩnh viễn'),
              ),
            ],
          ),
        ),
      );
      if (confirmed != true || !mounted) return;
      setState(() => _isLoading = true);
      await ref.read(communityRepositoryProvider).deleteCommunity(widget.clubId);
      invalidateCommunityCollections(ref);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xoá câu lạc bộ thành công.')),
        );
        context.go('/home');
      }
    } catch (e, stack) {
      _log.error('Lỗi xóa CLB', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi khi thực hiện xoá câu lạc bộ: ${e.toString().replaceAll('Exception: ', '')}',
            ),
          ),
        );
      }
    } finally {
      controller.dispose();
      if (mounted) setState(() => _isLoading = false);
    }
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
    final categories =
        ref.watch(categoriesProvider).asData?.value ?? const <CategoryModel>[];
    if (categories.isEmpty) {
      return Text(
        'Đang tải danh sách môn thể thao...',
        style: TextStyle(color: context.colors.textMuted),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((category) {
        final selected =
            _selectedSport == category.slug || _selectedSport == category.name;
        return ChoiceChip(
          label: Text(category.name),
          selected: selected,
          onSelected: (_) => setState(() => _selectedSport = category.slug),
          selectedColor: AppTheme.primary.withValues(alpha: 0.15),
          side: BorderSide(
            color: selected ? AppTheme.primary : context.colors.border,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildJoinModeSelector() {
    final modes = [
      ('OPEN', 'Mở tự do', 'Thành viên nhấn tham gia là vào nhóm ngay.'),
      ('APPROVAL', 'Cần phê duyệt đơn',
          'Phải trả lời câu hỏi và chờ BQT chấp thuận.'),
      ('INVITE_ONLY', 'Chỉ nhận lời mời',
          'Chỉ thành viên được mời mới có thể tham gia.'),
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
                color: selected
                    ? AppTheme.primary.withValues(alpha: 0.08)
                    : context.colors.bgCard,
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
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
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
                          m.$2,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? AppTheme.primary
                                : context.colors.textPrimary,
                          ),
                        ),
                        Text(
                          m.$3,
                          style: TextStyle(
                              fontSize: 11, color: context.colors.textMuted),
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

  Widget _buildError(AppColorsExtension colors, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: colors.textMuted),
            const SizedBox(height: 12),
            Text(
              'Không thể tải thông tin CLB',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
