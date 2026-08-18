import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/providers/regions_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/features/community/social/community_feed_notifier.dart';

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
  final _rulesCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _questionCtrl = TextEditingController();

  String _selectedSport = AppConstants.sportBadminton;
  String _joinMode = 'OPEN';
  String _visibility = 'PUBLIC';
  String? _provinceCode;
  String? _wardCode;
  String? _logoUrl;
  String? _bannerUrl;
  final List<String> _joinQuestions = [];
  bool _isUploadingLogo = false;
  bool _isUploadingBanner = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _rulesCtrl.dispose();
    _locationCtrl.dispose();
    _questionCtrl.dispose();
    super.dispose();
  }

  Future<String> _resolveCategoryId() async {
    final categories = await ref.read(categoriesProvider.future);
    final selected = categories.where((category) {
      final slug = category.slug.trim().toLowerCase();
      final name = category.name.trim().toLowerCase();
      return slug == _selectedSport.toLowerCase() ||
          name == (AppConstants.sportNames[_selectedSport] ?? '').toLowerCase();
    }).firstOrNull;
    if (selected == null || selected.id.isEmpty) {
      throw StateError('Không tìm thấy môn thể thao đã chọn. Vui lòng thử lại.');
    }
    return selected.id;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_provinceCode == null || _provinceCode!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn tỉnh/thành phố')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioProvider);

      final provinces = ref.read(provincesProvider).asData?.value ?? const <Province>[];
      final wards = _provinceCode == null
          ? const <Ward>[]
          : (await ref.read(wardsProvider(_provinceCode!).future));
      final provinceName = provinces
          .where((item) => item.code == _provinceCode)
          .map((item) => item.name)
          .firstOrNull;
      final wardName = wards
          .where((item) => item.code == _wardCode)
          .map((item) => item.name)
          .firstOrNull;
      final locationParts = [
        _locationCtrl.text.trim(),
        wardName,
        provinceName,
      ].whereType<String>().where((value) => value.isNotEmpty).toList();

      final body = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'rules': _rulesCtrl.text.trim(),
        'locationAddress': locationParts.join(', '),
        'provinceCode': _provinceCode,
        'wardCode': _wardCode,
        // Backend yêu cầu UUID category, không nhận slug như "pickleball".
        'categoryIds': [await _resolveCategoryId()],
        'joinMode': _joinMode,
        'visibility': _visibility,
        'joinQuestions': _joinQuestions,
        if (_logoUrl != null) 'logoUrl': _logoUrl,
        if (_bannerUrl != null) 'bannerUrl': _bannerUrl,
      };

      _log.info('Tạo CLB: ${body['name']}');
      final response = await dio.post('/communities', data: body);
      final clubId = response.data['data']?['id']?.toString() ?? '';

      _log.success('Tạo CLB thành công: $clubId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tạo câu lạc bộ thành công!'),
            backgroundColor: context.colors.success,
          ),
        );
        invalidateCommunityCollections(ref);
        context.go('/club/$clubId');
      }
    } catch (e, stack) {
      _log.error('Lỗi tạo CLB', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: context.colors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _chooseAndUploadImage({required bool banner}) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.bgSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 36, height: 4, decoration: BoxDecoration(color: context.colors.border, borderRadius: BorderRadius.circular(99))),
              const SizedBox(height: 14),
              Text(banner ? 'Chọn ảnh bìa' : 'Chọn logo / avatar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _sourceAction(
                    context: sheetContext,
                    icon: Icons.photo_library_outlined,
                    label: 'Thư viện ảnh',
                    source: ImageSource.gallery,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _sourceAction(
                    context: sheetContext,
                    icon: Icons.photo_camera_outlined,
                    label: 'Chụp ảnh',
                    source: ImageSource.camera,
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;
    await _pickAndUploadImage(banner: banner, source: source);
  }

  Widget _sourceAction({
    required BuildContext context,
    required IconData icon,
    required String label,
    required ImageSource source,
  }) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(source),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: context.colors.bgSurface,
          border: Border.all(color: context.colors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primary, size: 27),
            const SizedBox(height: 7),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage({required bool banner, required ImageSource source}) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: banner ? 1800 : 1000,
    );
    if (picked == null) return;
    if (banner) {
      setState(() => _isUploadingBanner = true);
    } else {
      setState(() => _isUploadingLogo = true);
    }
    try {
      final bytes = await picked.readAsBytes();
      if (bytes.length > (banner ? 10 : 5) * 1024 * 1024) {
        throw StateError('Ảnh ${banner ? 'bìa' : 'logo'} không được vượt quá ${banner ? 10 : 5}MB');
      }
      final url = await ref.read(communitySocialRepositoryProvider).uploadImage(
            bytes,
            picked.name,
          );
      if (!mounted) return;
      setState(() {
        if (banner) {
          _bannerUrl = url;
        } else {
          _logoUrl = url;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingBanner = false;
          _isUploadingLogo = false;
        });
      }
    }
  }

  void _addJoinQuestion() {
    final question = _questionCtrl.text.trim();
    if (question.isEmpty || _joinQuestions.length >= 5) return;
    setState(() {
      _joinQuestions.add(question);
      _questionCtrl.clear();
    });
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
          'Tạo câu lạc bộ',
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
              _label('Tên câu lạc bộ *', colors),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameCtrl,
                validator: (v) => (v == null || v.trim().length < 3)
                    ? 'Tên phải ít nhất 3 ký tự'
                    : null,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'VD: CLB Cầu lông ABC',
                  hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                ),
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
                maxLength: 1000,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Giới thiệu về câu lạc bộ...',
                  hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),

              _label('Nội quy (không bắt buộc)', colors),
              const SizedBox(height: 6),
              TextFormField(
                controller: _rulesCtrl,
                maxLines: 4,
                maxLength: 5000,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: '1. Tôn trọng lẫn nhau\n2. Đúng giờ...',
                  hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                ),
              ),
              const SizedBox(height: 8),

              _label('Khu vực hoạt động', colors),
              const SizedBox(height: 6),
              TextFormField(
                controller: _locationCtrl,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'VD: Hà Nội, TP. Hồ Chí Minh...',
                  hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                ),
              ),
              const SizedBox(height: 10),
              _buildRegionSelectors(),
              const SizedBox(height: 20),

              _buildImagePickers(),
              const SizedBox(height: 20),

              _label('Hiển thị câu lạc bộ', colors),
              const SizedBox(height: 6),
              _buildVisibilitySelector(),
              const SizedBox(height: 20),

              _label('Hình thức tham gia', colors),
              const SizedBox(height: 6),
              _buildJoinModeSelector(),
              if (_joinMode == 'APPROVAL') ...[
                const SizedBox(height: 10),
                _buildJoinQuestions(),
              ],
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _isLoading || _isUploadingLogo || _isUploadingBanner
                      ? null
                      : _submit,
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
                    _isLoading ? 'Đang tạo...' : 'Tạo câu lạc bộ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
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

  Widget _buildRegionSelectors() {
    final colors = context.colors;
    final provincesAsync = ref.watch(provincesProvider);
    final wardsAsync = _provinceCode == null
        ? const AsyncData<List<Ward>>([])
        : ref.watch(wardsProvider(_provinceCode!));
    return Row(
      children: [
        Expanded(
          child: provincesAsync.when(
            data: (items) => DropdownButtonFormField<String>(
              initialValue: _provinceCode,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Tỉnh/thành phố *'),
              items: items
                  .map((item) => DropdownMenuItem(value: item.code, child: Text(item.name, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (value) => setState(() {
                _provinceCode = value;
                _wardCode = null;
              }),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, s) => Text('Không tải được tỉnh/thành', style: TextStyle(color: colors.error, fontSize: 11)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: wardsAsync.when(
            data: (items) => DropdownButtonFormField<String>(
              initialValue: _wardCode,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Phường/xã'),
              items: items
                  .map((item) => DropdownMenuItem(value: item.code, child: Text(item.name, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: _provinceCode == null ? null : (value) => setState(() => _wardCode = value),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, s) => Text('Không tải được phường/xã', style: TextStyle(color: colors.error, fontSize: 11)),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePickers() {
    return Row(
      children: [
        Expanded(child: _imagePickerCard(
          title: 'Logo / avatar',
          url: _logoUrl,
          loading: _isUploadingLogo,
          circle: true,
          onTap: () => _chooseAndUploadImage(banner: false),
        )),
        const SizedBox(width: 10),
        Expanded(child: _imagePickerCard(
          title: 'Ảnh bìa',
          url: _bannerUrl,
          loading: _isUploadingBanner,
          onTap: () => _chooseAndUploadImage(banner: true),
        )),
      ],
    );
  }

  Widget _imagePickerCard({
    required String title,
    required String? url,
    required bool loading,
    required VoidCallback onTap,
    bool circle = false,
  }) {
    final colors = context.colors;
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.textSecondary)),
        const SizedBox(height: 8),
        InkWell(
          onTap: loading ? null : onTap,
          borderRadius: BorderRadius.circular(circle ? 48 : 12),
          child: Container(
            width: double.infinity,
            height: 92,
            decoration: BoxDecoration(
              shape: circle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: circle ? null : BorderRadius.circular(12),
              color: colors.bgSurface,
              border: Border.all(color: url == null ? colors.border : AppTheme.primary),
            ),
            clipBehavior: Clip.antiAlias,
            child: loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : url == null
                    ? Icon(Icons.add_photo_alternate_outlined, color: colors.textMuted, size: 28)
                    : Image.network(
                        url.startsWith('http') ? url : 'https://sporto.asia$url',
                        fit: BoxFit.cover,
                        errorBuilder: (c, o, s) => Icon(Icons.broken_image_outlined, color: colors.textMuted),
                      ),
          ),
        ),
        if (url != null && !loading)
          TextButton(
            onPressed: () => setState(() {
              if (circle) {
                _logoUrl = null;
              } else {
                _bannerUrl = null;
              }
            }),
            child: const Text('Gỡ ảnh', style: TextStyle(fontSize: 11)),
          ),
      ],
    );
  }

  Widget _buildJoinQuestions() {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bgSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Câu hỏi xin vào (tối đa 5)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.textPrimary)),
          const SizedBox(height: 8),
          ..._joinQuestions.asMap().entries.map((entry) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(entry.value, style: TextStyle(fontSize: 12, color: colors.textPrimary)),
                trailing: IconButton(icon: Icon(Icons.close, size: 16, color: colors.textMuted), onPressed: () => setState(() => _joinQuestions.removeAt(entry.key)),),
              )),
          if (_joinQuestions.length < 5)
            Row(children: [
              Expanded(child: TextField(controller: _questionCtrl, maxLength: 255, decoration: const InputDecoration(hintText: 'Ví dụ: Bạn đang chơi ở trình độ nào?'))),
              IconButton(onPressed: _addJoinQuestion, icon: const Icon(Icons.add_circle_rounded, color: AppTheme.primary)),
            ]),
        ],
      ),
    );
  }

  Widget _buildVisibilitySelector() {
    final options = [
      ('PUBLIC', 'Công khai', 'Ai cũng có thể tìm thấy CLB'),
      ('PRIVATE', 'Riêng tư', 'Chỉ thành viên mới xem được nội dung'),
      ('RESTRICTED', 'Hạn chế', 'Hiện khi tìm kiếm, cần tham gia để xem'),
    ];
    return Column(
      children: options.map((option) {
        final selected = _visibility == option.$1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => setState(() => _visibility = option.$1),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primary.withValues(alpha: 0.08) : context.colors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected ? AppTheme.primary : context.colors.border),
              ),
              child: Row(children: [
                Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? AppTheme.primary : context.colors.textMuted, size: 19),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(option.$2, style: TextStyle(fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
                  Text(option.$3, style: TextStyle(fontSize: 11, color: context.colors.textMuted)),
                ])),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSportSelector() {
    final sports = [
      (AppConstants.sportBadminton, 'Cầu lông', '🏸'),
      (AppConstants.sportPickleball, 'Pickleball', '🏓'),
      (AppConstants.sportTennis, 'Tennis', '🎾'),
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
                    Text(s.$3, style: const TextStyle(fontSize: 20)),
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
