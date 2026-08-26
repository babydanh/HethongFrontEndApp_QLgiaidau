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
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final categories = await ref.read(categoriesProvider.future);
    final selected = categories.where((category) {
      final slug = category.slug.trim().toLowerCase();
      final name = category.name.trim().toLowerCase();
      return slug == _selectedSport.toLowerCase() ||
          name == _selectedSport.toLowerCase();
    }).firstOrNull;
    if (selected == null || selected.id.isEmpty) {
      throw StateError(l10n.editClub_primarySportError);
    }
    return selected.id;
  }

    Future<void> _pickAndUploadImage({required bool isLogo}) async {
    final l10n = AppLocalizations.of(context)!;
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
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: AppTheme.primary,
              ),
              title: Text(l10n.editClub_captureNew),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: AppTheme.primary,
              ),
              title: Text(l10n.editClub_chooseLibrary),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 88,
    );
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
            content: Text(
              isLogo
                  ? l10n.editClub_logoUpdated
                  : l10n.editClub_bannerUpdated,
            ),
          ),
        );
      }
    } catch (e, stack) {
      _log.error('Lỗi cập nhật ảnh CLB', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.editClub_imageUpdateError)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.editClub_primarySportError)),
      );
      return;
    }
    if (_region.provinceCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.editClub_provinceRequired)),
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
        'districtCode': null,
        'wardCode': _region.wardCode.isEmpty ? null : _region.wardCode,
      });

      _log.success('Cập nhật CLB thành công');
      ref.invalidate(communityDetailProvider(widget.clubId));
      invalidateCommunityCollections(ref);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.editClub_saved),
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
            content: Text(l10n.editClub_saveError(e.toString().replaceAll('Exception: ', ''))),
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
    final l10n = AppLocalizations.of(context)!;
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
          l10n.editClub_title,
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
                : Text(
                    l10n.editClub_save,
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
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card 1: Nhận diện thương hiệu (Logo & Ảnh bìa) ──
            _sectionCard(
              colors: colors,
              title: l10n.editClub_imagesSection,
              subtitle: l10n.editClub_imagesSubtitle,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: _imagePickerCard(
                      colors: colors,
                      title: l10n.editClub_logoTitle,
                      hint: l10n.editClub_logoHint,
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
                      title: l10n.editClub_bannerTitle,
                      hint: l10n.editClub_bannerHint,
                      imageUrl: club?.bannerUrl,
                      isCircle: false,
                      onTap: () => _pickAndUploadImage(isLogo: false),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Card 2: Thông tin cơ bản ──
            _sectionCard(
              colors: colors,
              title: l10n.editClub_basicSection,
              subtitle: l10n.editClub_basicSubtitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel(l10n.editClub_clubName, isRequired: true, colors: colors),
                  const SizedBox(height: 6),
                  AppTextFormField(
                    controller: _nameCtrl,
                    hint: l10n.editClub_clubNameHint,
                    prefixIcon: Icons.badge_outlined,
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return l10n.editClub_clubNameRequired;
                      if (value.length > 255) return l10n.editClub_clubNameMax;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _fieldLabel(l10n.editClub_primarySport, isRequired: true, colors: colors),
                  const SizedBox(height: 2),
                  Text(
                    l10n.editClub_primarySportDescription,
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  _buildSportSelector(),
                  const SizedBox(height: 16),

                  _fieldLabel(l10n.editClub_descriptionLabel, colors: colors),
                  const SizedBox(height: 6),
                  AppTextFormField(
                    controller: _descCtrl,
                    hint: l10n.editClub_descriptionHint,
                    maxLines: 3,
                    prefixIcon: Icons.description_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Card 3: Địa điểm hoạt động ──
            _sectionCard(
              colors: colors,
              title: l10n.editClub_locationSection,
              subtitle: l10n.editClub_locationSubtitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel(l10n.editClub_administrativeArea, isRequired: true, colors: colors),
                  const SizedBox(height: 6),
                  ClubRegionSelector(
                    initialProvinceCode: club?.provinceCode ?? '',
                    initialWardCode: club?.wardCode ?? '',
                    onChanged: (selection) => _region = selection,
                  ),
                  const SizedBox(height: 12),

                  _fieldLabel(l10n.editClub_detailedAddress, colors: colors),
                  const SizedBox(height: 6),
                  AppTextFormField(
                    controller: _locationCtrl,
                    hint: l10n.editClub_detailedAddressHint,
                    prefixIcon: Icons.location_on_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Card 4: Quyền riêng tư & Cách thức tham gia ──
            _sectionCard(
              colors: colors,
              title: l10n.editClub_privacySection,
              subtitle: l10n.editClub_privacySubtitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel(l10n.editClub_visibility, isRequired: true, colors: colors),
                  const SizedBox(height: 6),
                  ClubVisibilitySelector(
                    value: _visibility,
                    onChanged: (value) => setState(() => _visibility = value),
                  ),
                  const SizedBox(height: 16),

                  _fieldLabel(l10n.editClub_memberJoinMethod, isRequired: true, colors: colors),
                  const SizedBox(height: 6),
                  _buildJoinModeSelector(),
                  const SizedBox(height: 16),

                  _fieldLabel(l10n.editClub_memberLimit, colors: colors),
                  const SizedBox(height: 6),
                  AppTextFormField(
                    controller: _maxMembersCtrl,
                    hint: l10n.editClub_memberLimitHint,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.group_outlined,
                  ),
                  const SizedBox(height: 16),

                  _fieldLabel(l10n.editClub_rules, colors: colors),
                  const SizedBox(height: 6),
                  AppTextFormField(
                    controller: _rulesCtrl,
                    hint: l10n.editClub_rulesHint,
                    maxLines: 4,
                    prefixIcon: Icons.gavel_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Card 5: Câu hỏi xét duyệt (khi APPROVAL) ──
            if (_joinMode == 'APPROVAL') ...[
              _sectionCard(
                colors: colors,
                title: l10n.editClub_approvalSection,
                subtitle: l10n.editClub_approvalSubtitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppTextFormField(
                            controller: _joinQuestionCtrl,
                            hint: l10n.editClub_questionHint,
                            prefixIcon: Icons.help_outline_rounded,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: () {
                            final question = _joinQuestionCtrl.text.trim();
                            if (question.isEmpty ||
                                _joinQuestions.contains(question)) {
                              return;
                            }
                            setState(() {
                              _joinQuestions.add(question);
                              _joinQuestionCtrl.clear();
                            });
                          },
                          icon: const Icon(Icons.add_rounded, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.all(12),
                          ),
                          tooltip: l10n.editClub_addQuestion,
                        ),
                      ],
                    ),
                    if (_joinQuestions.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ..._joinQuestions.asMap().entries.map(
                        (entry) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: colors.bgDark,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: colors.border),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '${entry.key + 1}.',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close_rounded, size: 16, color: colors.textSecondary),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () =>
                                    setState(() => _joinQuestions.removeAt(entry.key)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Card 6: Mạng xã hội ──
            _sectionCard(
              colors: colors,
              title: l10n.editClub_socialSection,
              subtitle: l10n.editClub_socialSubtitle,
              child: ClubSocialLinksEditor(
                initialLinks: _socialLinks,
                onChanged: (links) => _socialLinks = links,
              ),
            ),
            const SizedBox(height: 24),

            // Nút Lưu chính
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
                    : const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: Text(
                  _isLoading ? l10n.editClub_saving : l10n.editClub_saveAll,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildDangerZone(colors),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required AppColorsExtension colors,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.primary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _fieldLabel(String text, {bool isRequired = false, required AppColorsExtension colors}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
        children: [
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Color(0xFFE11D48), fontWeight: FontWeight.bold),
            ),
        ],
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
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.bgSurface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 70,
              decoration: BoxDecoration(
                color: colors.bgDark,
                shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: isCircle ? null : BorderRadius.circular(8),
                border: Border.all(color: colors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl == null || imageUrl.isEmpty
                  ? Icon(
                      Icons.image_outlined,
                      color: colors.textSecondary,
                      size: 26,
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stackTrace) => Icon(
                        Icons.broken_image_outlined,
                        color: colors.textSecondary,
                      ),
                    ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              hint,
              style: TextStyle(fontSize: 10, color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                l10n.editClub_changeImage,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 18, color: colors.error),
              const SizedBox(width: 6),
              Text(
                l10n.editClub_dangerTitle,
                style: TextStyle(
                  color: colors.error,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.editClub_dangerDescription,
            style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _confirmDeleteClub,
            icon: Icon(Icons.delete_forever_rounded, size: 18, color: colors.error),
            label: Text(
              l10n.editClub_deleteClub,
              style: TextStyle(color: colors.error, fontWeight: FontWeight.w700, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colors.error.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteClub() async {
    final l10n = AppLocalizations.of(context)!;
    final club = ref.read(communityDetailProvider(widget.clubId)).asData?.value;
    final expected = club?.name.trim() ?? _nameCtrl.text.trim();
    final controller = TextEditingController();
    var typedName = '';
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: Text(l10n.editClub_deleteTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.editClub_deleteDescription(expected),
                ),
                const SizedBox(height: 12),
                Text(l10n.editClub_confirmName(expected)),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  onChanged: (value) => setDialogState(() => typedName = value),
                  decoration: InputDecoration(
                    labelText: l10n.editClub_clubNameLabel,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: typedName.trim() == expected
                    ? () => Navigator.pop(dialogContext, true)
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: context.colors.error,
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.editClub_deleteForever),
              ),
            ],
          ),
        ),
      );
      if (confirmed != true || !mounted) return;
      setState(() => _isLoading = true);
      await ref
          .read(communityRepositoryProvider)
          .deleteCommunity(widget.clubId);
      invalidateCommunityCollections(ref);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.editClub_deleted)),
        );
        context.go('/home');
      }
    } catch (e, stack) {
      _log.error('Lỗi xóa CLB', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.editClub_deleteError(e.toString().replaceAll('Exception: ', '')),
            ),
          ),
        );
      }
    } finally {
      controller.dispose();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildSportSelector() {
    final l10n = AppLocalizations.of(context)!;
    final categories =
        ref.watch(categoriesProvider).asData?.value ?? const <CategoryModel>[];
    if (categories.isEmpty) {
      return Text(
        l10n.editClub_loadingSports,
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
    final l10n = AppLocalizations.of(context)!;
    final modes = [
      ('OPEN', l10n.editClub_joinOpen, l10n.editClub_joinOpenDescription),
      (
        'APPROVAL',
        l10n.editClub_joinApproval,
        l10n.editClub_joinApprovalDescription,
      ),
      (
        'INVITE_ONLY',
        l10n.editClub_joinInviteOnly,
        l10n.editClub_joinInviteOnlyDescription,
      ),
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

  Widget _buildError(AppColorsExtension colors, VoidCallback onRetry) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: colors.textMuted),
            const SizedBox(height: 12),
            Text(
              l10n.editClub_loadError,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: Text(l10n.editClub_retry)),
          ],
        ),
      ),
    );
  }
}
