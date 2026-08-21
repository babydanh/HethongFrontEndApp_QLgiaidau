import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/app_text_field.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/domain/entities/region.dart';
import 'package:app_quanly_giaidau/data/models/club_notification_pref_model.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/features/profile/utils/email_verification_flow.dart';
import 'package:app_quanly_giaidau/features/profile/utils/phone_verification_flow.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/features/profile/widgets/language_setting_card.dart';
import 'package:app_quanly_giaidau/core/utils/vietnam_address_parser.dart';

/// Màn hình Cài đặt — 3 tab: Hồ sơ, Ngân hàng, Bảo mật.
///
/// Tính năng đồng bộ với web (/profile/edit):
/// - Hồ sơ: upload avatar + ảnh bìa, ngày sinh, giới tính (khóa + yêu cầu đổi),
///   khu vực tranh tài (tỉnh/thành từ API), validate giống backend
/// - Ngân hàng: chọn ví điện tử/ngân hàng, tên chủ TK tự viết hoa không dấu
/// - Bảo mật: xác minh email + SĐT, đổi mật khẩu, xóa tài khoản (vùng nguy hiểm)
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: colors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
        title: Text(
          l10n.settingsTitle,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          labelColor: AppTheme.primary,
          unselectedLabelColor: colors.textSecondary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: [
            Tab(text: l10n.settingsProfileTab),
            Tab(text: l10n.settingsBankTab),
            Tab(text: l10n.settingsSecurityTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_ProfileTab(), _BankTab(), _SecurityTab()],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  TAB 1: HỒ SƠ — avatar/bìa + PATCH /users/profile
// ═════════════════════════════════════════════════════════════════════════
class _ProfileTab extends ConsumerStatefulWidget {
  const _ProfileTab();

  @override
  ConsumerState<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<_ProfileTab> {
  static const _log = AppLogger('Settings.Profile');
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  /// Fallback khi API /regions/provinces lỗi — giữ nguyên danh mục cũ của app.
  static const List<Region> _fallbackProvinces = [
    Region(code: '1', name: 'Hà Nội'),
    Region(code: '31', name: 'Hải Phòng'),
    Region(code: '48', name: 'Đà Nẵng'),
    Region(code: '56', name: 'Khánh Hòa'),
    Region(code: '60', name: 'Bình Thuận'),
    Region(code: '68', name: 'Lâm Đồng'),
    Region(code: '74', name: 'Bình Dương'),
    Region(code: '75', name: 'Đồng Nai'),
    Region(code: '79', name: 'TP. Hồ Chí Minh'),
    Region(code: '89', name: 'An Giang'),
    Region(code: '92', name: 'Cần Thơ'),
  ];

  static const _genders = ['Chưa chọn', 'Nam', 'Nữ', 'Khác'];

  List<Region> _provinces = _fallbackProvinces;
  String _gender = 'Chưa chọn';
  String _provinceCode = '';
  DateTime? _dob;
  bool _isLoading = false;
  bool _initialized = false;
  bool _isUploadingAvatar = false;
  bool _isUploadingCover = false;
  Timer? _addressDebounce;
  String? _autoDetectedProvinceName;

  @override
  void initState() {
    super.initState();
    _loadProvinces();
    _addressCtrl.addListener(_onAddressInput);
  }

  void _onAddressInput() {
    _addressDebounce?.cancel();
    _addressDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final text = _addressCtrl.text.trim();
      if (text.length < 3) {
        if (_autoDetectedProvinceName != null) {
          setState(() => _autoDetectedProvinceName = null);
        }
        return;
      }
      final detected = VietnamAddressParser.detectProvince<Region>(
        rawAddress: text,
        provinces: _provinces,
        getCode: (p) => p.code,
        getName: (p) => p.name,
        getFullName: (p) => p.fullName ?? p.name,
      );
      if (detected != null && detected.code != _provinceCode) {
        setState(() {
          _provinceCode = detected.code;
          _autoDetectedProvinceName = detected.name;
        });
      }
    });
  }

  Future<void> _loadProvinces() async {
    final provinces = await ref.read(regionRepositoryProvider).getProvinces();
    if (provinces.isNotEmpty && mounted) {
      setState(() => _provinces = provinces);
    }
  }

  @override
  void dispose() {
    _addressDebounce?.cancel();
    _addressCtrl.removeListener(_onAddressInput);
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.colors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppTheme.primary,
                ),
                title: Text(l10n!.profileTakePhoto),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: AppTheme.primary,
                ),
                title: Text(l10n!.profileChooseFromGallery),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
    if (source == null) return;
    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (file == null) return;
    setState(() => _isUploadingAvatar = true);
    try {
      await ref
          .read(userRepositoryProvider)
          .uploadAvatar(await file.readAsBytes(), file.name);
      ref.invalidate(userProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.profileAvatarUpdated ??
                  'Profile photo updated',
            ),
            backgroundColor: context.colors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, stack) {
      _log.error('Lỗi tải ảnh đại diện', e, stack);
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _pickAndUploadCover() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.settingsImageSizeLimit ??
                  'Image size must not exceed 5 MB',
            ),
            backgroundColor: context.colors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    setState(() => _isUploadingCover = true);
    try {
      await ref.read(userRepositoryProvider).uploadCover(bytes, file.name);
      ref.invalidate(userProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.profileCoverUpdated ??
                  'Cover photo updated',
            ),
            backgroundColor: context.colors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, stack) {
      _log.error('Lỗi tải ảnh bìa', e, stack);
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _isUploadingCover = false);
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = _dob ?? DateTime(now.year - 18);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? initial : DateTime(now.year - 1),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: AppLocalizations.of(context)?.infoDob ?? 'Date of birth',
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _showGenderChangeRequestDialog() async {
    final l10n = AppLocalizations.of(context);
    var requestedGender = _gender.isNotEmpty && _gender != 'Chưa chọn'
        ? _gender
        : 'Nam';
    var isSubmitting = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            Future<void> submit() async {
              setState(() => isSubmitting = true);
              try {
                await ref
                    .read(userRepositoryProvider)
                    .createChangeRequest(
                      requestType: 'GENDER',
                      newValue: requestedGender,
                    );
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(l10n!.settingsRequestSent)),
                );
              } catch (e) {
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(l10n!.settingsRequestFailed)),
                );
              } finally {
                if (ctx.mounted) setState(() => isSubmitting = false);
              }
            }

            return AlertDialog(
              backgroundColor: context.colors.bgCard,
              title: Text(l10n!.settingsGenderChangeTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n!.settingsGenderLockedMessage,
                    style: const TextStyle(fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: requestedGender,
                    decoration: InputDecoration(
                      labelText: l10n!.settingsDesiredGender,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'Nam',
                        child: Text(l10n!.settingsGenderMale),
                      ),
                      DropdownMenuItem(
                        value: 'Nữ',
                        child: Text(l10n!.settingsGenderFemale),
                      ),
                      DropdownMenuItem(
                        value: 'Khác',
                        child: Text(l10n!.settingsGenderOther),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => requestedGender = value);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(ctx).pop(),
                  child: Text(l10n!.commonCancel),
                ),
                FilledButton(
                  onPressed: isSubmitting ? null : submit,
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n!.settingsSendRequest),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _save(bool genderLocked) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    _log.info('Bắt đầu cập nhật hồ sơ');

    try {
      final payload = <String, dynamic>{
        'fullName': _nameCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim(),
        if (_dob != null)
          'dateOfBirth':
              '${_dob!.year.toString().padLeft(4, '0')}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}',
        // Giới tính bị khóa sau khi hoàn thành giải — không gửi để tránh ghi đè.
        if (!genderLocked && _gender != 'Chưa chọn') 'gender': _gender,
        if (_addressCtrl.text.trim().isNotEmpty)
          'address': _addressCtrl.text.trim(),
        if (_provinceCode.isNotEmpty) 'provinceCode': _provinceCode,
        if (_bioCtrl.text.trim().isNotEmpty) 'bio': _bioCtrl.text.trim(),
      };

      await ref.read(userRepositoryProvider).updateProfile(payload);

      _log.success('Cập nhật hồ sơ thành công');
      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.settingsSaveChanges),
            backgroundColor: context.colors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, stack) {
      _log.error('Lỗi cập nhật hồ sơ', e, stack);
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${AppLocalizations.of(context)!.errorPrefix}: ${e.toString().replaceAll('Exception: ', '')}',
        ),
        backgroundColor: context.colors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (!_initialized) {
          _nameCtrl.text = profile.fullName ?? '';
          _phoneCtrl.text = profile.phoneNumber ?? '';
          _addressCtrl.text = profile.address ?? '';
          _bioCtrl.text = profile.bio ?? '';
          _gender = _genders.contains(profile.gender)
              ? (profile.gender ?? 'Chưa chọn')
              : 'Chưa chọn';
          _provinceCode = profile.provinceCode ?? '';
          _dob = DateTime.tryParse(profile.dateOfBirth ?? '');
          _initialized = true;
        }
        final genderLocked = profile.isGenderLocked == true;
        return _buildForm(
          colors,
          profile.avatarUrl,
          profile.coverUrl,
          profile.email,
          profile.fullName,
          genderLocked,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _buildErrorState(
        context,
        colors,
        AppLocalizations.of(context)?.settingsProfileLoadError ??
            'Unable to load profile',
        () => ref.invalidate(userProfileProvider),
      ),
    );
  }

  Widget _buildForm(
    AppColorsExtension colors,
    String? avatarUrl,
    String? coverUrl,
    String? email,
    String? fullName,
    bool genderLocked,
  ) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LanguageSettingCard(key: const ValueKey('settings-language-card')),
            const SizedBox(height: 16),
            // Ảnh bìa + ảnh đại diện
            _buildCoverAndAvatar(colors, avatarUrl, coverUrl, email, fullName),
            const SizedBox(height: 24),
            _card(colors, [
              _fieldLabel(colors, l10n!.fullNameLabel),
              const SizedBox(height: 6),
              AppTextFormField(
                controller: _nameCtrl,
                hint: l10n!.settingsFullNameHint,
                prefixIcon: Icons.person_outline,
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return l10n!.settingsFullNameRequired;
                  if (value.length < 2) return l10n!.settingsFullNameMin;
                  if (value.length > 100) return l10n!.settingsFullNameMax;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _fieldLabel(colors, l10n!.emailLabel),
              const SizedBox(height: 6),
              AppTextFormField(
                initialValue: email ?? '',
                hint: 'email@domain.com',
                prefixIcon: Icons.email_outlined,
                enabled: false,
              ),
              const SizedBox(height: 16),
              _fieldLabel(colors, l10n!.infoPhone),
              const SizedBox(height: 6),
              AppTextFormField(
                controller: _phoneCtrl,
                hint: '0912345678',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return null;
                  return RegExp(r'^[0-9]{10,11}$').hasMatch(value)
                      ? null
                      : l10n!.settingsPhoneInvalid;
                },
              ),
              const SizedBox(height: 16),
              _fieldLabel(colors, l10n!.infoDob),
              const SizedBox(height: 6),
              _dobField(colors),
              const SizedBox(height: 16),
              _fieldLabel(colors, l10n!.infoGender),
              const SizedBox(height: 6),
              _genderField(colors, genderLocked),
              const SizedBox(height: 16),
              _fieldLabel(colors, l10n!.settingsCompetitionRegion),
              const SizedBox(height: 6),
              _provinceField(colors),
              const SizedBox(height: 4),
              Text(
                l10n!.settingsCompetitionRegionHint,
                style: TextStyle(fontSize: 11, color: colors.textMuted),
              ),
              const SizedBox(height: 16),
              _fieldLabel(colors, l10n!.settingsDetailedAddress),
              const SizedBox(height: 6),
              AppTextFormField(
                controller: _addressCtrl,
                hint: l10n!.settingsDetailedAddressHint,
                prefixIcon: Icons.location_on_outlined,
                validator: (v) =>
                    (v ?? '').length > 255 ? l10n!.settingsAddressMax : null,
              ),
              if (_autoDetectedProvinceName != null &&
                  _provinceCode.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n!.settingsAutoDetected(_autoDetectedProvinceName!),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              _fieldLabel(colors, l10n!.settingsBio),
              const SizedBox(height: 6),
              AppTextFormField(
                controller: _bioCtrl,
                hint: l10n!.settingsBioHint,
                maxLines: 3,
                prefixIcon: Icons.edit_note_rounded,
                validator: (v) =>
                    (v ?? '').length > 500 ? l10n!.settingsBioMax : null,
              ),
              const SizedBox(height: 24),
              _saveButton(context, _isLoading, () => _save(genderLocked)),
            ]),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverAndAvatar(
    AppColorsExtension colors,
    String? avatarUrl,
    String? coverUrl,
    String? email,
    String? fullName,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Banner ảnh bìa
          Stack(
            fit: StackFit.loose,
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary,
                      AppTheme.primary.withValues(alpha: 0.6),
                    ],
                  ),
                ),
                child: coverUrl == null
                    ? null
                    : Image.network(
                        coverUrl,
                        fit: BoxFit.cover,
                        height: 120,
                        width: double.infinity,
                      ),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _isUploadingCover ? null : _pickAndUploadCover,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isUploadingCover)
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          else
                            const Icon(
                              Icons.camera_alt_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                          const SizedBox(width: 6),
                          Text(
                            _isUploadingCover
                                ? (AppLocalizations.of(
                                        context,
                                      )?.settingsUploading ??
                                      'Uploading...')
                                : (AppLocalizations.of(
                                        context,
                                      )?.settingsChangeCover ??
                                      'Change cover photo'),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Avatar
          Transform.translate(
            offset: const Offset(0, -36),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.bgCard, width: 4),
                    ),
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: colors.bgCard,
                      backgroundImage: avatarUrl == null
                          ? null
                          : NetworkImage(avatarUrl),
                      child: _isUploadingAvatar
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            )
                          : avatarUrl == null
                          ? Text(
                              (fullName?.isNotEmpty ?? false)
                                  ? fullName![0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt_rounded,
                      size: 12,
                      color: colors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)?.settingsTapToChangeAvatar ??
                          'Tap to change profile photo',
                      style: TextStyle(fontSize: 11, color: colors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  email ?? '',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dobField(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: _pickDob,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.cake_rounded, size: 18, color: colors.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _dob == null
                    ? l10n.settingsChooseDateOfBirth
                    : l10n.settingsDobDisplay(
                        _dob!.day.toString().padLeft(2, '0'),
                        _dob!.month.toString().padLeft(2, '0'),
                        _dob!.year.toString(),
                      ),
                style: TextStyle(
                  fontSize: 14,
                  color: _dob == null ? colors.textMuted : colors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.calendar_month_rounded,
              size: 18,
              color: colors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _genderField(AppColorsExtension colors, bool locked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _dropdown(
          colors,
          _gender,
          _genders,
          locked ? null : (v) => setState(() => _gender = v ?? 'Chưa chọn'),
          displayLabels: {
            'Chưa chọn':
                AppLocalizations.of(context)?.settingsGenderNotSelected ??
                'Not selected',
            'Nam': AppLocalizations.of(context)?.settingsGenderMale ?? 'Male',
            'Nữ':
                AppLocalizations.of(context)?.settingsGenderFemale ?? 'Female',
            'Khác':
                AppLocalizations.of(context)?.settingsGenderOther ?? 'Other',
          },
        ),
        if (locked)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)?.settingsGenderLocked ??
                        'Gender is locked after a tournament is completed.',
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
                ),
                TextButton(
                  onPressed: _showGenderChangeRequestDialog,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    AppLocalizations.of(context)?.settingsRequestGenderChange ??
                        'Request change',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _provinceField(AppColorsExtension colors) {
    // Mã tỉnh đã lưu không có trong danh sách (VD: API thiếu) — vẫn hiển thị để không mất dữ liệu.
    final codes = _provinces.map((province) => province.code).toSet();
    final items = [..._provinces];
    final currentName = _provinces
        .where((province) => province.code == _provinceCode)
        .firstOrNull
        ?.name;
    return _dropdown(
      colors,
      currentName ??
          (AppLocalizations.of(context)?.settingsNoTierSRegion ??
              'Not selected (not ranked in Tier S)'),
      [
        AppLocalizations.of(context)?.settingsNoTierSRegion ??
            'Not selected (not ranked in Tier S)',
        ...items.map((province) => province.name),
      ],
      (v) {
        if (v == null) return;
        setState(() {
          _provinceCode =
              v ==
                  (AppLocalizations.of(context)?.settingsNoTierSRegion ??
                      'Not selected (not ranked in Tier S)')
              ? ''
              : (_provinces
                        .where((province) => province.name == v)
                        .firstOrNull
                        ?.code ??
                    (_provinceCode.isNotEmpty && !codes.contains(_provinceCode)
                        ? _provinceCode
                        : ''));
        });
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  TAB 2: NGÂN HÀNG — PATCH /users/profile (bank fields)
// ═════════════════════════════════════════════════════════════════════════
class _BankTab extends ConsumerStatefulWidget {
  const _BankTab();

  @override
  ConsumerState<_BankTab> createState() => _BankTabState();
}

class _BankTabState extends ConsumerState<_BankTab> {
  static const _log = AppLogger('Settings.Bank');
  final _formKey = GlobalKey<FormState>();
  final _accountNumberCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();

  static const _noBank = 'Chưa chọn ngân hàng/ví';
  static const _wallets = ['Momo', 'ZaloPay', 'ShopeePay'];
  static const _banks = [
    'Vietcombank',
    'Techcombank',
    'Vietinbank',
    'BIDV',
    'Agribank',
    'MB Bank',
    'ACB',
    'VPBank',
    'TPBank',
    'Sacombank',
    'VIB',
  ];

  String _bankName = _noBank;
  bool _isLoading = false;
  bool _initialized = false;

  bool get _isWallet => _wallets.contains(_bankName);

  @override
  void dispose() {
    _accountNumberCtrl.dispose();
    _accountNameCtrl.dispose();
    super.dispose();
  }

  /// Viết hoa + bỏ dấu (NFD) như web: NGUYEN VAN A.
  String _normalizeAccountName(String value) {
    const diacriticsMap = {
      'À': 'A',
      'Á': 'A',
      'Ạ': 'A',
      'Ả': 'A',
      'Ã': 'A',
      'Â': 'A',
      'Ầ': 'A',
      'Ấ': 'A',
      'Ậ': 'A',
      'Ẩ': 'A',
      'Ẫ': 'A',
      'Ă': 'A',
      'Ằ': 'A',
      'Ắ': 'A',
      'Ặ': 'A',
      'Ẳ': 'A',
      'Ẵ': 'A',
      'Đ': 'D',
      'È': 'E',
      'É': 'E',
      'Ẹ': 'E',
      'Ẻ': 'E',
      'Ẽ': 'E',
      'Ê': 'E',
      'Ề': 'E',
      'Ế': 'E',
      'Ệ': 'E',
      'Ể': 'E',
      'Ễ': 'E',
      'Ì': 'I',
      'Í': 'I',
      'Ị': 'I',
      'Ỉ': 'I',
      'Ĩ': 'I',
      'Ò': 'O',
      'Ó': 'O',
      'Ọ': 'O',
      'Ỏ': 'O',
      'Õ': 'O',
      'Ô': 'O',
      'Ồ': 'O',
      'Ố': 'O',
      'Ộ': 'O',
      'Ổ': 'O',
      'Ỗ': 'O',
      'Ơ': 'O',
      'Ờ': 'O',
      'Ớ': 'O',
      'Ợ': 'O',
      'Ở': 'O',
      'Ỡ': 'O',
      'Ù': 'U',
      'Ú': 'U',
      'Ụ': 'U',
      'Ủ': 'U',
      'Ũ': 'U',
      'Ư': 'U',
      'Ừ': 'U',
      'Ứ': 'U',
      'Ự': 'U',
      'Ử': 'U',
      'Ữ': 'U',
      'Ỳ': 'Y',
      'Ỵ': 'Y',
      'Ỷ': 'Y',
      'Ỹ': 'Y',
    };
    return value
        .toUpperCase()
        .split('')
        .map((char) => diacriticsMap[char] ?? char)
        .join();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    _log.info('Bắt đầu lưu thông tin ngân hàng');

    try {
      final repo = ref.read(userRepositoryProvider);
      await repo.updateProfile({
        'bankName': _bankName == _noBank ? '' : _bankName,
        'bankAccountNumber': _accountNumberCtrl.text.trim(),
        'bankAccountName': _normalizeAccountName(_accountNameCtrl.text.trim()),
      });

      _log.success('Lưu thông tin ngân hàng thành công');
      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n!.settingsRefundSaved),
            backgroundColor: context.colors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, stack) {
      _log.error('Lỗi lưu thông tin ngân hàng', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n!.settingsBankUpdateError),
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
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (!_initialized) {
          final saved = profile.bankName ?? '';
          _bankName = saved.isEmpty ? _noBank : saved;
          _accountNumberCtrl.text = profile.bankAccountNumber ?? '';
          _accountNameCtrl.text = profile.bankAccountName ?? '';
          _initialized = true;
        }
        return _buildForm(colors);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _buildErrorState(
        context,
        colors,
        AppLocalizations.of(context)?.settingsBankLoadError ??
            'Unable to load bank information',
        () => ref.invalidate(userProfileProvider),
      ),
    );
  }

  Widget _buildForm(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context);
    final noBank = l10n!.settingsNoBank;
    String walletPrefix(String wallet) => l10n!.settingsWalletPrefix(wallet);
    final bankOptions = [noBank, ..._wallets.map(walletPrefix), ..._banks];
    // Giá trị đã lưu ngoài danh sách (nhập tay từ trước) — thêm vào cuối để không mất.
    final isKnown =
        _bankName == _noBank ||
        _wallets.contains(_bankName) ||
        _banks.contains(_bankName);
    final currentLabel = _bankName == _noBank
        ? noBank
        : _isWallet
        ? walletPrefix(_bankName)
        : _bankName;
    if (!isKnown) bankOptions.add(_bankName);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoBanner(colors),
            const SizedBox(height: 20),
            _card(colors, [
              _fieldLabel(colors, l10n!.settingsPayoutMethod),
              const SizedBox(height: 6),
              _dropdown(colors, currentLabel, bankOptions, (v) {
                if (v == null) return;
                setState(() {
                  if (v == noBank) {
                    _bankName = _noBank;
                    return;
                  }
                  String? selectedWallet;
                  for (final wallet in _wallets) {
                    if (walletPrefix(wallet) == v) {
                      selectedWallet = wallet;
                      break;
                    }
                  }
                  _bankName = selectedWallet ?? v;
                });
              }),
              const SizedBox(height: 16),
              _fieldLabel(
                colors,
                _isWallet
                    ? (l10n!.settingsWalletPhone)
                    : (l10n!.settingsAccountNumber),
              ),
              const SizedBox(height: 6),
              AppTextFormField(
                controller: _accountNumberCtrl,
                hint: _isWallet
                    ? (l10n!.settingsWalletNumberHint)
                    : (l10n!.settingsBankNumberHint),
                keyboardType: TextInputType.number,
                prefixIcon: Icons.numbers_rounded,
              ),
              const SizedBox(height: 16),
              _fieldLabel(colors, l10n!.settingsAccountHolder),
              const SizedBox(height: 6),
              AppTextFormField(
                controller: _accountNameCtrl,
                hint: l10n!.settingsAccountHolderHint,
                prefixIcon: Icons.person_rounded,
                onChanged: (value) {
                  final normalized = _normalizeAccountName(value);
                  if (normalized != value) {
                    final selection = _accountNameCtrl.selection;
                    _accountNameCtrl.value = TextEditingValue(
                      text: normalized,
                      selection: selection,
                    );
                  }
                },
              ),
              const SizedBox(height: 24),
              _saveButton(context, _isLoading, _save),
            ]),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _infoBanner(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_rounded,
            size: 18,
            color: AppTheme.primary.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n!.settingsRefundInfo,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  TAB 3: BẢO MẬT — xác minh, đổi mật khẩu, xóa tài khoản
// ═════════════════════════════════════════════════════════════════════════
class _SecurityTab extends ConsumerWidget {
  const _SecurityTab();

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final passwordCtrl = TextEditingController();
    var obscure = true;
    var isDeleting = false;
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            Future<void> delete() async {
              final password = passwordCtrl.text;
              if (password.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(l10n!.settingsPasswordRequired)),
                );
                return;
              }
              setState(() => isDeleting = true);
              try {
                await ref.read(userRepositoryProvider).deleteAccount(password);
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                await ref.read(authProvider.notifier).signOut();
                ref.invalidate(userProfileProvider);
                if (context.mounted) context.go('/home');
              } catch (e) {
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(l10n!.settingsDeleteFailed)),
                );
              } finally {
                if (ctx.mounted) setState(() => isDeleting = false);
              }
            }

            return AlertDialog(
              backgroundColor: colors.bgCard,
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: colors.error),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l10n!.settingsConfirmDeleteTitle)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n!.settingsDeleteIrreversible,
                    style: const TextStyle(fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordCtrl,
                    enabled: !isDeleting,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: l10n!.settingsConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () => setState(() => obscure = !obscure),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.of(ctx).pop(),
                  child: Text(l10n!.commonCancel),
                ),
                FilledButton(
                  onPressed: isDeleting ? null : delete,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.error,
                    foregroundColor: Colors.white,
                  ),
                  child: isDeleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n!.settingsConfirmDelete),
                ),
              ],
            );
          },
        );
      },
    );

    passwordCtrl.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(userProfileProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trạng thái xác thực
          _sectionTitle(colors, l10n!.settingsVerificationStatus),
          const SizedBox(height: 10),
          _card(colors, [
            ...profileAsync.when(
              data: (profile) => [
                _securityRow(
                  context,
                  colors,
                  icon: Icons.email_outlined,
                  title: 'Email',
                  verified: profile.isEmailVerified == true,
                  fallbackText: profile.email,
                ),
                _divider(colors),
                _securityRow(
                  context,
                  colors,
                  icon: Icons.phone_android_rounded,
                  title: l10n!.infoPhone,
                  verified: profile.isPhoneVerified == true,
                  fallbackText:
                      profile.phoneNumber ?? (l10n!.settingsPhoneNotUpdated),
                ),
                if (profile.isEmailVerified != true) ...[
                  _divider(colors),
                  _actionRow(
                    colors,
                    icon: Icons.mark_email_unread_rounded,
                    title: l10n!.settingsVerifyEmail,
                    subtitle: l10n!.settingsVerifyEmailSubtitle,
                    onTap: () => startEmailVerificationFlow(
                      context,
                      ref,
                      profile.email ?? '',
                    ),
                  ),
                ],
                if (profile.isPhoneVerified != true) ...[
                  _divider(colors),
                  _actionRow(
                    colors,
                    icon: Icons.sms_rounded,
                    title: l10n!.settingsVerifyPhone,
                    subtitle: l10n!.settingsVerifyPhoneSubtitle,
                    onTap: () => startPhoneVerificationFlow(
                      context,
                      ref,
                      profile.phoneNumber ?? '',
                    ),
                  ),
                ],
              ],
              loading: () => [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (_, _) => [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n!.settingsStatusLoadError,
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ),
              ],
            ),
          ]),
          const SizedBox(height: 24),

          // Đổi mật khẩu
          _sectionTitle(colors, l10n!.settingsPasswordSection),
          const SizedBox(height: 10),
          _card(colors, [
            _actionRow(
              colors,
              icon: Icons.lock_outline_rounded,
              title: l10n!.settingsChangePassword,
              subtitle: l10n!.settingsChangePasswordSubtitle,
              onTap: () => context.push('/profile/change-password'),
            ),
            _divider(colors),
            _actionRow(
              colors,
              icon: Icons.security_rounded,
              title: l10n!.settingsStrongPassword,
              subtitle: l10n!.settingsStrongPasswordSubtitle,
              trailing: Icon(
                Icons.check_circle_rounded,
                color: colors.success,
                size: 20,
              ),
            ),
          ]),
          const SizedBox(height: 24),

          // Phiên đăng nhập
          _sectionTitle(colors, l10n!.settingsSessions),
          const SizedBox(height: 10),
          _card(colors, [
            _actionRow(
              colors,
              icon: Icons.devices_rounded,
              title: l10n!.settingsCurrentDevice,
              subtitle: l10n!.settingsActive,
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n!.settingsOnline,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: colors.success,
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 24),

          // Quyền riêng tư
          const _StrangerMessagesSettingsCard(),
          const SizedBox(height: 24),

          // Thông báo Câu lạc bộ
          const _ClubNotificationSettingsCard(),
          const SizedBox(height: 24),

          // Báo cáo của tôi
          _sectionTitle(colors, l10n!.settingsCommunitySafety),
          const SizedBox(height: 10),
          _card(colors, [
            _actionRow(
              colors,
              icon: Icons.flag_outlined,
              title: l10n!.settingsMyReports,
              subtitle: l10n!.settingsMyReportsSubtitle,
              onTap: () => context.push('/profile/reports'),
            ),
          ]),
          const SizedBox(height: 24),

          // Vùng nguy hiểm
          _sectionTitle(colors, l10n!.settingsDangerZone),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(color: colors.error.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 18, color: colors.error),
                    const SizedBox(width: 8),
                    Text(
                      l10n!.settingsDeleteAccountTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: colors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n!.settingsDeleteAccountDescription,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmDeleteAccount(context, ref),
                    icon: const Icon(Icons.delete_forever_rounded, size: 18),
                    label: Text(
                      l10n!.settingsDeleteAccount,
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.error,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _StrangerMessagesSettingsCard extends ConsumerStatefulWidget {
  const _StrangerMessagesSettingsCard();

  @override
  ConsumerState<_StrangerMessagesSettingsCard> createState() =>
      _StrangerMessagesSettingsCardState();
}

class _StrangerMessagesSettingsCardState
    extends ConsumerState<_StrangerMessagesSettingsCard> {
  bool? _value;
  bool _isUpdating = false;

  Future<void> _update(bool value, bool previousValue) async {
    setState(() {
      _value = value;
      _isUpdating = true;
    });

    try {
      final updated = await ref.read(userRepositoryProvider).updateProfile({
        'allowStrangerMessages': value,
      });
      ref.invalidate(userProfileProvider);
      if (!mounted) return;
      setState(() {
        _value = updated.allowStrangerMessages ?? value;
        _isUpdating = false;
      });
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.settingsStrangerMessagesUpdated)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _value = previousValue;
        _isUpdating = false;
      });
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.settingsStrangerMessagesUpdateError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(userProfileProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(colors, l.settingsPrivacyTitle),
        const SizedBox(height: 10),
        _card(colors, [
          profileAsync.when(
            data: (profile) {
              final currentValue =
                  _value ?? profile.allowStrangerMessages ?? true;
              return SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(
                  Icons.mark_unread_chat_alt_outlined,
                  color: AppTheme.primary,
                ),
                title: Text(
                  l.settingsStrangerMessages,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '${currentValue ? l.settingsStrangerMessagesOn : l.settingsStrangerMessagesOff}\n${l.settingsStrangerMessagesDescription}',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: colors.textSecondary,
                  ),
                ),
                value: currentValue,
                onChanged: _isUpdating
                    ? null
                    : (value) => _update(value, currentValue),
                activeThumbColor: AppTheme.primary,
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l.settingsStrangerMessagesUpdateError,
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
          ),
        ]),
      ],
    );
  }
}

class _ClubNotificationSettingsCard extends ConsumerStatefulWidget {
  const _ClubNotificationSettingsCard();

  @override
  ConsumerState<_ClubNotificationSettingsCard> createState() =>
      _ClubNotificationSettingsCardState();
}

class _ClubNotificationSettingsCardState
    extends ConsumerState<_ClubNotificationSettingsCard> {
  List<ClubNotificationPrefModel>? _prefs;
  bool _isLoading = true;
  String? _updatingClubId;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    try {
      final list = await ref
          .read(communityRepositoryProvider)
          .getMyNotificationPreferences();
      if (mounted) {
        setState(() {
          _prefs = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _prefs = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updatePref(String communityId, String newPref) async {
    final l10n = AppLocalizations.of(context);
    final currentList = _prefs ?? [];
    final idx = currentList.indexWhere((c) => c.communityId == communityId);
    if (idx == -1) return;

    final oldPref = currentList[idx].notificationPreference;
    // Optimistic update
    setState(() {
      _updatingClubId = communityId;
      currentList[idx] = currentList[idx].copyWith(
        notificationPreference: newPref,
      );
    });

    try {
      await ref
          .read(communityRepositoryProvider)
          .updateNotificationPreference(communityId, newPref);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newPref == 'ALL'
                  ? (l10n!.settingsNotificationsAllUpdated)
                  : newPref == 'MENTIONS_ONLY'
                  ? (l10n!.settingsNotificationsMentionsUpdated)
                  : (l10n!.settingsNotificationsMutedUpdated),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          currentList[idx] = currentList[idx].copyWith(
            notificationPreference: oldPref,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n!.settingsNotificationsUpdateFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _updatingClubId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(colors, l10n!.settingsClubNotifications),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: colors.border),
          ),
          child: _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                )
              : (_prefs == null || _prefs!.isEmpty)
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.groups_outlined,
                        size: 36,
                        color: colors.textMuted,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n!.settingsNoClubsForNotifications,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n!.settingsClubNotificationsHint,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: _prefs!.length,
                  separatorBuilder: (_, index) => _divider(colors),
                  itemBuilder: (context, index) {
                    final club = _prefs![index];
                    final isUpdating = _updatingClubId == club.communityId;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(0xFFEFF6FF),
                                backgroundImage:
                                    club.logoUrl != null &&
                                        club.logoUrl!.isNotEmpty
                                    ? NetworkImage(club.logoUrl!)
                                    : null,
                                child:
                                    club.logoUrl == null ||
                                        club.logoUrl!.isEmpty
                                    ? Text(
                                        club.communityName.isNotEmpty
                                            ? club.communityName[0]
                                                  .toUpperCase()
                                            : 'C',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: Color(0xFF2563EB),
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            club.communityName,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: colors.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colors.bgDark,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            club.role,
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: colors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      club.notificationPreference == 'ALL'
                                          ? (l10n!
                                                .settingsClubNotificationAllSummary)
                                          : club.notificationPreference ==
                                                'MENTIONS_ONLY'
                                          ? (l10n!
                                                .settingsClubNotificationMentionsSummary)
                                          : (l10n!
                                                .settingsClubNotificationMutedSummary),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isUpdating)
                                const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // 3-Option Segmented Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildSegmentButton(
                                  title: l10n!.settingsNotificationAll,
                                  icon: Icons.notifications_active_outlined,
                                  isSelected:
                                      club.notificationPreference == 'ALL',
                                  activeColor: const Color(0xFF2563EB),
                                  colors: colors,
                                  onTap: isUpdating
                                      ? null
                                      : () => _updatePref(
                                          club.communityId,
                                          'ALL',
                                        ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _buildSegmentButton(
                                  title: l10n!.settingsNotificationMentions,
                                  icon: Icons.alternate_email_rounded,
                                  isSelected:
                                      club.notificationPreference ==
                                      'MENTIONS_ONLY',
                                  activeColor: const Color(0xFFD97706),
                                  colors: colors,
                                  onTap: isUpdating
                                      ? null
                                      : () => _updatePref(
                                          club.communityId,
                                          'MENTIONS_ONLY',
                                        ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _buildSegmentButton(
                                  title: l10n!.settingsNotificationMuted,
                                  icon: Icons.notifications_off_outlined,
                                  isSelected:
                                      club.notificationPreference == 'MUTED',
                                  activeColor: const Color(0xFFE11D48),
                                  colors: colors,
                                  onTap: isUpdating
                                      ? null
                                      : () => _updatePref(
                                          club.communityId,
                                          'MUTED',
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSegmentButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required AppColorsExtension colors,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.1)
              : colors.bgDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? activeColor.withValues(alpha: 0.5)
                : colors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? activeColor : colors.textMuted,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? activeColor : colors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  SHARED WIDGETS
// ═════════════════════════════════════════════════════════════════════════
Widget _card(AppColorsExtension colors, List<Widget> children) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: colors.bgCard,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      border: Border.all(color: colors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}

Widget _fieldLabel(AppColorsExtension colors, String text) {
  return Text(
    text,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: colors.textPrimary,
    ),
  );
}

Widget _sectionTitle(AppColorsExtension colors, String title) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: colors.textSecondary,
        letterSpacing: 0.3,
      ),
    ),
  );
}

Widget _dropdown(
  AppColorsExtension colors,
  String value,
  List<String> items,
  ValueChanged<String?>? onChange, {
  Map<String, String>? displayLabels,
}) {
  // Giá trị hiện tại nằm ngoài danh sách (dữ liệu cũ) — thêm để DropdownButton không crash.
  var effectiveItems = items;
  if (!items.contains(value)) effectiveItems = [...items, value];
  return Container(
    height: 48,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: colors.bgCard,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      border: Border.all(color: colors.border),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        icon: Icon(Icons.arrow_drop_down_rounded, color: colors.textMuted),
        style: TextStyle(fontSize: 14, color: colors.textPrimary),
        dropdownColor: colors.bgCard,
        items: effectiveItems
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(displayLabels?[e] ?? e),
              ),
            )
            .toList(),
        onChanged: onChange,
      ),
    ),
  );
}

Widget _divider(AppColorsExtension colors) {
  return Padding(
    padding: const EdgeInsets.only(left: 56),
    child: Divider(height: 1, color: colors.border.withValues(alpha: 0.5)),
  );
}

Widget _saveButton(
  BuildContext context,
  bool isLoading,
  Future<void> Function() onSave,
) {
  return SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton(
      onPressed: isLoading ? null : onSave,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.4),
        shadowColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
          : Text(
              AppLocalizations.of(context)?.settingsSaveButton ??
                  'Save changes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
    ),
  );
}

Widget _securityRow(
  BuildContext context,
  AppColorsExtension colors, {
  required IconData icon,
  required String title,
  required bool verified,
  String? fallbackText,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                fallbackText ??
                    (verified
                        ? (AppLocalizations.of(context)?.infoEmailVerified ??
                              'Verified')
                        : (AppLocalizations.of(context)?.infoEmailUnverified ??
                              'Unverified')),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: (verified ? colors.success : colors.warning).withValues(
              alpha: 0.12,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                verified
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                size: 13,
                color: verified ? colors.success : colors.warning,
              ),
              const SizedBox(width: 4),
              Text(
                verified
                    ? (AppLocalizations.of(context)?.infoEmailVerified ??
                          'Verified')
                    : (AppLocalizations.of(context)?.infoEmailUnverified ??
                          'Unverified'),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: verified ? colors.success : colors.warning,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _actionRow(
  AppColorsExtension colors, {
  required IconData icon,
  required String title,
  required String subtitle,
  VoidCallback? onTap,
  Widget? trailing,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
              ],
            ),
          ),
          if (trailing != null)
            trailing
          else if (onTap != null)
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: colors.textMuted,
            ),
        ],
      ),
    ),
  );
}

Widget _buildErrorState(
  BuildContext context,
  AppColorsExtension colors,
  String message,
  VoidCallback onRetry,
) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 48, color: colors.textMuted),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onRetry,
            child: Text(AppLocalizations.of(context)?.infoRetry ?? 'Retry'),
          ),
        ],
      ),
    ),
  );
}
