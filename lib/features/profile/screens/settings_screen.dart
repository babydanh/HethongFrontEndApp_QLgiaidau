import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_quanly_giaidau/core/widgets/image_crop_dialog.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/domain/entities/region.dart';
import 'package:app_quanly_giaidau/data/models/club_notification_pref_model.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/features/profile/utils/edit_profile_payload.dart';
import 'package:app_quanly_giaidau/features/profile/utils/email_verification_flow.dart';
import 'package:app_quanly_giaidau/features/profile/utils/phone_verification_flow.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit_extras.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/features/profile/widgets/organizer_verification_sheet.dart';
import 'package:app_quanly_giaidau/core/utils/vietnam_address_parser.dart';
import 'package:app_quanly_giaidau/core/extensions/string_extensions.dart';

/// Màn Chỉnh sửa hồ sơ (`/profile/edit`) — 4 tab: Hồ sơ, Ngân hàng, Tổ chức,
/// Bảo mật. Dựng bằng bộ Lavish (LavishScaffold, LavishTextField, ...).
///
/// - Hồ sơ: upload avatar + ảnh bìa, ngày sinh, giới tính (khóa + yêu cầu đổi),
///   khu vực tranh tài (tỉnh/thành từ API); xác minh email + SĐT ở cuối form
/// - Ngân hàng: chọn ví điện tử/ngân hàng, tên chủ TK tự viết hoa không dấu
/// - Tổ chức: trạng thái vai trò Ban Tổ Chức, mở luồng đăng ký
/// - Bảo mật: đổi mật khẩu, phiên đăng nhập, quyền riêng tư, thông báo CLB,
///   xóa tài khoản
/// Ngôn ngữ nằm ở trang Cài đặt, không ở đây.
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
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = LavishColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return LavishScaffold(
      title: l10n.settingsEditProfile,
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/profile');
        }
      },
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: c.soft(LavishTone.neutral),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: LavishColors.accent,
                  borderRadius: BorderRadius.circular(11),
                ),
                splashBorderRadius: BorderRadius.circular(11),
                labelColor: Colors.white,
                unselectedLabelColor: c.muted,
                labelPadding: EdgeInsets.zero,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
                tabs: [
                  Tab(height: 42, text: l10n.settingsProfileTab),
                  Tab(height: 42, text: l10n.settingsBankTab),
                  Tab(height: 42, text: l10n.accountSettingsOrganizerTab),
                  Tab(height: 42, text: l10n.settingsSecurityTab),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _ProfileTab(),
                _BankTab(),
                _OrganizerTab(),
                _SecurityTab(),
              ],
            ),
          ),
        ],
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

class _ProfileTabState extends ConsumerState<_ProfileTab>
    with AutomaticKeepAliveClientMixin {
  static const _log = AppLogger('Settings.Profile');
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  String? _nameError;
  String? _phoneError;
  String? _addressError;
  String? _bioError;
  String? _saveError;

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

  static const _genderUnset = '__unset__';
  static const _genders = [
    _genderUnset,
    genderLabelMale,
    genderLabelFemale,
    genderLabelOther,
  ];

  @override
  bool get wantKeepAlive => true;

  List<Region> _provinces = _fallbackProvinces;
  String _gender = _genderUnset;
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
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    final l10n = AppLocalizations.of(context)!;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext)!;
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
                title: Text(l10n.profileTakePhoto),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: AppTheme.primary,
                ),
                title: Text(l10n.profileChooseFromGallery),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
    if (source == null || !mounted) return;
    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (file == null) return;
    final originalBytes = await file.readAsBytes();
    if (!mounted) return;
    final croppedBytes = await ImageCropDialog.show(
      context,
      bytes: originalBytes,
      title: l10n.profileChangeAvatar,
    );
    if (croppedBytes == null || !mounted) return;
    setState(() => _isUploadingAvatar = true);
    try {
      await ref
          .read(userRepositoryProvider)
          .uploadAvatar(croppedBytes, 'profile_avatar.png');
      ref.invalidate(userProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.profileAvatarUpdated),
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
    final l10n = AppLocalizations.of(context)!;
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    if (bytes.length > 5 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsImageSizeLimit),
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
            content: Text(l10n.profileCoverUpdated),
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
      helpText: AppLocalizations.of(context)!.infoDob,
    );
    if (picked != null && mounted) setState(() => _dob = picked);
  }

  Future<void> _showGenderChangeRequestDialog() async {
    final l10n = AppLocalizations.of(context)!;
    var requestedGender = _gender.isNotEmpty && _gender != _genderUnset
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
                  SnackBar(content: Text(l10n.settingsRequestSent)),
                );
              } catch (e) {
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(
                      ErrorParser.parse(e, l10n.settingsRequestFailed, l10n),
                    ),
                  ),
                );
              } finally {
                if (ctx.mounted) setState(() => isSubmitting = false);
              }
            }

            return AlertDialog(
              backgroundColor: context.colors.bgCard,
              title: Text(l10n.settingsGenderChangeTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.settingsGenderLockedMessage,
                    style: const TextStyle(fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: requestedGender,
                    decoration: InputDecoration(
                      labelText: l10n.settingsDesiredGender,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'Nam',
                        child: Text(l10n.settingsGenderMale),
                      ),
                      DropdownMenuItem(
                        value: 'Nữ',
                        child: Text(l10n.settingsGenderFemale),
                      ),
                      DropdownMenuItem(
                        value: 'Khác',
                        child: Text(l10n.settingsGenderOther),
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
                  child: Text(l10n.commonCancel),
                ),
                FilledButton(
                  onPressed: isSubmitting ? null : submit,
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.settingsSendRequest),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _validate(AppLocalizations l10n) {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    String? nameError;
    if (name.isEmpty) {
      nameError = l10n.settingsFullNameRequired;
    } else if (name.length < 2) {
      nameError = l10n.settingsFullNameMin;
    } else if (name.length > 100) {
      nameError = l10n.settingsFullNameMax;
    }
    final phoneError = phone.isNotEmpty && !isValidVnPhone(phone)
        ? l10n.settingsPhoneInvalid
        : null;
    final addressError = _addressCtrl.text.length > 255
        ? l10n.settingsAddressMax
        : null;
    final bioError = _bioCtrl.text.length > 500 ? l10n.settingsBioMax : null;
    setState(() {
      _nameError = nameError;
      _phoneError = phoneError;
      _addressError = addressError;
      _bioError = bioError;
    });
    return nameError == null &&
        phoneError == null &&
        addressError == null &&
        bioError == null;
  }

  Future<void> _save(bool genderLocked) async {
    final l10n = AppLocalizations.of(context)!;
    if (!_validate(l10n)) return;

    setState(() {
      _isLoading = true;
      _saveError = null;
    });
    _log.info('Bắt đầu cập nhật hồ sơ');

    try {
      final payload = buildEditProfilePayload(
        fullName: _nameCtrl.text,
        phone: _phoneCtrl.text,
        dateOfBirth: _dob,
        // Giới tính bị khóa sau khi hoàn thành giải — không gửi để tránh ghi đè.
        gender: _gender == _genderUnset ? null : _gender,
        genderLocked: genderLocked,
        address: _addressCtrl.text,
        provinceCode: _provinceCode,
        bio: _bioCtrl.text,
      );

      await ref.read(userRepositoryProvider).updateProfile(payload);

      _log.success('Cập nhật hồ sơ thành công');
      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsSaveChanges),
            backgroundColor: context.colors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, stack) {
      _log.error('Lỗi cập nhật hồ sơ', e, stack);
      if (mounted) setState(() => _saveError = ErrorParser.parse(e, '', l10n));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ErrorParser.parse(e, '', AppLocalizations.of(context))),
        backgroundColor: context.colors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (!_initialized) {
          _nameCtrl.text = profile.fullName ?? '';
          _emailCtrl.text = profile.email ?? '';
          _phoneCtrl.text = profile.phoneNumber ?? '';
          _addressCtrl.text = profile.address ?? '';
          _bioCtrl.text = profile.bio ?? '';
          // Backend trả MALE/FEMALE/OTHER; đưa về nhãn của màn.
          _gender = normalizeGenderLabel(profile.gender) ?? _genderUnset;
          _provinceCode = profile.provinceCode ?? '';
          _dob = DateTime.tryParse(profile.dateOfBirth ?? '');
          _initialized = true;
        }
        final genderLocked = profile.isGenderLocked == true;
        return _buildForm(
          profile.avatarUrl,
          profile.coverUrl,
          profile.email,
          profile.fullName,
          genderLocked,
        );
      },
      loading: () => const SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: LavishRowSkeleton(count: 7),
      ),
      error: (e, _) => LavishErrorState(
        message: AppLocalizations.of(context)!.settingsProfileLoadError,
        onRetry: () => ref.invalidate(userProfileProvider),
      ),
    );
  }

  Widget _buildForm(
    String? avatarUrl,
    String? coverUrl,
    String? email,
    String? fullName,
    bool genderLocked,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final c = LavishColors.of(context);
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCoverAndAvatar(c, avatarUrl, coverUrl, email, fullName),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LavishTextField(
                        label: l10n.fullNameLabel,
                        controller: _nameCtrl,
                        errorText: _nameError,
                        onChanged: (_) => setState(() => _nameError = null),
                      ),
                      const SizedBox(height: 12),
                      LavishTextField(
                        label: l10n.emailLabel,
                        controller: _emailCtrl,
                        enabled: false,
                      ),
                      const SizedBox(height: 12),
                      LavishTextField(
                        label: l10n.infoPhone,
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        errorText: _phoneError,
                        onChanged: (_) => setState(() => _phoneError = null),
                      ),
                      const SizedBox(height: 12),
                      _dobField(c),
                      const SizedBox(height: 12),
                      _genderField(c, genderLocked),
                      const SizedBox(height: 12),
                      _provinceField(c),
                      const SizedBox(height: 12),
                      LavishTextField(
                        label: l10n.settingsDetailedAddress,
                        controller: _addressCtrl,
                        errorText: _addressError,
                        onChanged: (_) => setState(() => _addressError = null),
                      ),
                      if (_autoDetectedProvinceName != null &&
                          _provinceCode.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: LavishPill(
                            l10n.settingsAutoDetected(
                              _autoDetectedProvinceName!,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      LavishTextField(
                        label: l10n.settingsBio,
                        controller: _bioCtrl,
                        maxLines: 3,
                        errorText: _bioError,
                        onChanged: (_) => setState(() => _bioError = null),
                      ),
                    ],
                  ),
                ),
                const _VerificationSection(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        LavishStickyBar(
          label: l10n.settingsSaveButton,
          busy: _isLoading,
          error: _saveError,
          onPressed: () => _save(genderLocked),
        ),
      ],
    );
  }

  /// Bìa thấp (96) + avatar 72 gối lên mép dưới bìa; tên/email nằm dưới bìa.
  Widget _buildCoverAndAvatar(
    LavishColors c,
    String? avatarUrl,
    String? coverUrl,
    String? email,
    String? fullName,
  ) {
    final l10n = AppLocalizations.of(context)!;
    const coverHeight = 96.0;
    const avatarRadius = 36.0;
    const avatarRing = 3.0;
    const avatarBox = (avatarRadius + avatarRing) * 2;
    const overlap = 32.0;
    return SizedBox(
      height: coverHeight + avatarBox - overlap + 8,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: coverHeight,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    LavishColors.accent,
                    LavishColors.accent.withValues(alpha: 0.55),
                  ],
                ),
              ),
              child: coverUrl == null
                  ? null
                  : Image.network(
                      coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
            ),
          ),
          Positioned(
            right: 6,
            top: 6,
            child: IconButton(
              tooltip: l10n.settingsChangeCover,
              onPressed: _isUploadingCover ? null : _pickAndUploadCover,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white,
                minimumSize: const Size(48, 48),
              ),
              icon: _isUploadingCover
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.photo_camera_rounded, size: 20),
            ),
          ),
          Positioned(
            left: 14,
            top: coverHeight - overlap,
            child: Tooltip(
              message: l10n.settingsTapToChangeAvatar,
              child: GestureDetector(
                onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.surface,
                      ),
                      padding: const EdgeInsets.all(avatarRing),
                      child: CircleAvatar(
                        radius: avatarRadius,
                        backgroundColor: c.soft(LavishTone.accent),
                        backgroundImage: avatarUrl == null
                            ? null
                            : NetworkImage(avatarUrl),
                        child: _isUploadingAvatar
                            ? const SizedBox.square(
                                dimension: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              )
                            : avatarUrl == null
                            ? Text(
                                firstInitial(fullName),
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: LavishColors.accent,
                                ),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: LavishColors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.surface, width: 2),
                        ),
                        child: const Icon(
                          Icons.photo_camera_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 14 + avatarBox + 12,
            right: 14,
            top: coverHeight + 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: c.text,
                  ),
                ),
                Text(
                  email ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: c.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dobField(LavishColors c) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: _pickDob,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        isEmpty: false,
        decoration: _fieldDecoration(c, l10n.infoDob).copyWith(
          suffixIcon: Icon(Icons.calendar_month_rounded, color: c.muted),
        ),
        child: Text(
          _dob == null
              ? l10n.settingsChooseDateOfBirth
              : l10n.settingsDobDisplay(
                  _dob!.day.toString().padLeft(2, '0'),
                  _dob!.month.toString().padLeft(2, '0'),
                  _dob!.year.toString(),
                ),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _dob == null ? c.faint : c.text,
          ),
        ),
      ),
    );
  }

  Widget _genderField(LavishColors c, bool locked) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _dropdown(
          c,
          l10n.infoGender,
          _gender,
          _genders,
          locked ? null : (v) => setState(() => _gender = v ?? _genderUnset),
          displayLabels: {
            _genderUnset: l10n.settingsGenderNotSelected,
            genderLabelMale: l10n.settingsGenderMale,
            genderLabelFemale: l10n.settingsGenderFemale,
            genderLabelOther: l10n.settingsGenderOther,
          },
        ),
        if (locked)
          LavishRow(
            leading: const LavishIconBox(
              tone: LavishTone.warn,
              child: Icon(Icons.lock_outline_rounded),
            ),
            title: l10n.settingsGenderLocked,
            trailing: [
              LavishButton(
                label: l10n.settingsRequestGenderChange,
                kind: LavishButtonKind.outline,
                dense: true,
                onPressed: _showGenderChangeRequestDialog,
              ),
            ],
          ),
      ],
    );
  }

  Widget _provinceField(LavishColors c) {
    final l10n = AppLocalizations.of(context)!;
    // Mã tỉnh đã lưu không có trong danh sách (VD: API thiếu) — vẫn hiển thị để không mất dữ liệu.
    final codes = _provinces.map((province) => province.code).toSet();
    final items = [..._provinces];
    final currentName = _provinces
        .where((province) => province.code == _provinceCode)
        .firstOrNull
        ?.name;
    return _dropdown(
      c,
      l10n.settingsCompetitionRegion,
      currentName ?? l10n.settingsNoTierSRegion,
      [l10n.settingsNoTierSRegion, ...items.map((province) => province.name)],
      (v) {
        if (v == null) return;
        setState(() {
          _provinceCode = v == l10n.settingsNoTierSRegion
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

class _BankTabState extends ConsumerState<_BankTab>
    with AutomaticKeepAliveClientMixin {
  static const _log = AppLogger('Settings.Bank');
  final _accountNumberCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();

  // Stable internal sentinel; the visible label comes from l10n.settingsNoBank.
  static const _noBank = '';
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
  String? _saveError;
  bool _isLoading = false;
  bool _initialized = false;

  @override
  bool get wantKeepAlive => true;

  bool get _isWallet => _wallets.contains(_bankName);

  @override
  void dispose() {
    _accountNumberCtrl.dispose();
    _accountNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isLoading = true;
      _saveError = null;
    });
    _log.info('Bắt đầu lưu thông tin ngân hàng');

    try {
      final repo = ref.read(userRepositoryProvider);
      await repo.updateProfile({
        'bankName': _bankName == _noBank ? '' : _bankName,
        'bankAccountNumber': _accountNumberCtrl.text.trim(),
        'bankAccountName': normalizeBankAccountName(
          _accountNameCtrl.text.trim(),
        ),
      });

      _log.success('Lưu thông tin ngân hàng thành công');
      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsRefundSaved),
            backgroundColor: context.colors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, stack) {
      _log.error('Lỗi lưu thông tin ngân hàng', e, stack);
      if (mounted) setState(() => _saveError = ErrorParser.parse(e, '', l10n));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
        return _buildForm();
      },
      loading: () => const SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: LavishRowSkeleton(count: 4),
      ),
      error: (e, _) => LavishErrorState(
        message: AppLocalizations.of(context)!.settingsBankLoadError,
        onRetry: () => ref.invalidate(userProfileProvider),
      ),
    );
  }

  Widget _buildForm() {
    final l10n = AppLocalizations.of(context)!;
    final c = LavishColors.of(context);
    final noBank = l10n.settingsNoBank;
    String walletPrefix(String wallet) => l10n.settingsWalletPrefix(wallet);
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

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LavishRow(
                  leading: const LavishIconBox(child: Icon(Icons.lock_rounded)),
                  title: l10n.settingsRefundInfo,
                  subtitleMaxLines: 1,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _dropdown(
                        c,
                        l10n.settingsPayoutMethod,
                        currentLabel,
                        bankOptions,
                        (v) {
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
                        },
                      ),
                      const SizedBox(height: 12),
                      LavishTextField(
                        label: _isWallet
                            ? l10n.settingsWalletPhone
                            : l10n.settingsAccountNumber,
                        controller: _accountNumberCtrl,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      LavishTextField(
                        label: l10n.settingsAccountHolder,
                        controller: _accountNameCtrl,
                        onChanged: (value) {
                          final normalized = normalizeBankAccountName(value);
                          if (normalized != value) {
                            final selection = _accountNameCtrl.selection;
                            _accountNameCtrl.value = TextEditingValue(
                              text: normalized,
                              selection: selection,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        LavishStickyBar(
          label: l10n.settingsSaveButton,
          busy: _isLoading,
          error: _saveError,
          onPressed: _save,
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  TAB 3: TỔ CHỨC — trạng thái vai trò Ban Tổ Chức + mở đơn đăng ký
// ═════════════════════════════════════════════════════════════════════════
class _OrganizerTab extends ConsumerWidget {
  const _OrganizerTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(userProfileProvider);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LavishGroupHeader(l10n.accountSettingsOrganizerRoleTitle),
          profileAsync.when(
            data: (profile) {
              final isOrganizer = profile.hasRole('ORGANIZER');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LavishRow(
                    leading: LavishIconBox(
                      tone: isOrganizer ? LavishTone.ok : LavishTone.accent,
                      child: Icon(
                        isOrganizer
                            ? Icons.verified_rounded
                            : Icons.how_to_reg_outlined,
                      ),
                    ),
                    title: isOrganizer
                        ? l10n.accountSettingsOrganizerVerified
                        : l10n.accountSettingsOrganizerNotRegistered,
                    subtitle: isOrganizer
                        ? l10n.accountSettingsOrganizerVerifiedDescription
                        : l10n.accountSettingsOrganizerDescription,
                    subtitleMaxLines: 3,
                  ),
                  if (!isOrganizer)
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: LavishButton(
                        label: l10n.accountSettingsOrganizerOpenApplication,
                        icon: const Icon(Icons.how_to_reg_rounded, size: 18),
                        onPressed: () =>
                            OrganizerVerificationSheet.show(context),
                      ),
                    ),
                ],
              );
            },
            loading: () => const LavishRowSkeleton(count: 1),
            error: (_, _) => LavishErrorState(
              message: l10n.settingsStatusLoadError,
              onRetry: () => ref.invalidate(userProfileProvider),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  XÁC MINH EMAIL / SĐT — hiển thị cuối form tab HỒ SƠ
// ═════════════════════════════════════════════════════════════════════════
class _VerificationSection extends ConsumerWidget {
  const _VerificationSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(userProfileProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LavishGroupHeader(l10n.settingsVerificationStatus),
        ...profileAsync.when(
          data: (profile) => [
            _verifyRow(
              context,
              icon: Icons.email_outlined,
              title: l10n.emailLabel,
              verified: profile.isEmailVerified == true,
              value: profile.email,
            ),
            _verifyRow(
              context,
              icon: Icons.phone_android_rounded,
              title: l10n.infoPhone,
              verified: profile.isPhoneVerified == true,
              value: profile.phoneNumber ?? l10n.settingsPhoneNotUpdated,
            ),
            if (profile.isEmailVerified != true)
              _actionRow(
                context,
                icon: Icons.mark_email_unread_rounded,
                title: l10n.settingsVerifyEmail,
                subtitle: l10n.settingsVerifyEmailSubtitle,
                onTap: () => startEmailVerificationFlow(
                  context,
                  ref,
                  profile.email ?? '',
                ),
              ),
            if (profile.isPhoneVerified != true)
              _actionRow(
                context,
                icon: Icons.sms_rounded,
                title: l10n.settingsVerifyPhone,
                subtitle: l10n.settingsVerifyPhoneSubtitle,
                onTap: () => startPhoneVerificationFlow(
                  context,
                  ref,
                  profile.phoneNumber ?? '',
                ),
              ),
          ],
          loading: () => [const LavishRowSkeleton(count: 2)],
          error: (_, _) => [
            LavishErrorState(
              message: l10n.settingsStatusLoadError,
              onRetry: () => ref.invalidate(userProfileProvider),
            ),
          ],
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  TAB 4: BẢO MẬT — đổi mật khẩu, phiên đăng nhập, quyền riêng tư, xóa tài khoản
// ═════════════════════════════════════════════════════════════════════════
class _SecurityTab extends ConsumerWidget {
  const _SecurityTab();

  static const _log = AppLogger('Settings.Security');

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Lấy sẵn mọi thứ cần dùng sau await: widget có thể đã bị gỡ khi xong.
    final repo = ref.read(userRepositoryProvider);
    final auth = ref.read(authProvider.notifier);
    final container = ProviderScope.containerOf(context);
    final router = GoRouter.of(context);

    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DeleteAccountDialog(onDelete: repo.deleteAccount),
    );
    if (deleted != true) return;

    // Tài khoản đã xóa trên Backend: luôn kết thúc phiên cục bộ và về /home,
    // dù signOut có lỗi.
    try {
      await auth.signOut();
    } catch (e, stack) {
      _log.error('signOut sau khi xóa tài khoản lỗi', e, stack);
    } finally {
      container.invalidate(userProfileProvider);
      router.go('/home');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LavishGroupHeader(l10n.settingsPasswordSection),
          _actionRow(
            context,
            icon: Icons.lock_outline_rounded,
            title: l10n.settingsChangePassword,
            subtitle: l10n.settingsChangePasswordSubtitle,
            onTap: () => context.push('/profile/change-password'),
          ),
          const _StrangerMessagesSettingsCard(),
          const _ClubNotificationSettingsCard(),
          LavishGroupHeader(l10n.settingsDangerZone),
          LavishRow(
            leading: const LavishIconBox(
              tone: LavishTone.bad,
              child: Icon(Icons.shield_outlined),
            ),
            title: l10n.settingsDeleteAccountTitle,
            subtitle: l10n.settingsDeleteAccountDescription,
            subtitleMaxLines: 4,
            titleColor: LavishColors.bad,
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: LavishButton(
              label: l10n.settingsDeleteAccount,
              kind: LavishButtonKind.danger,
              icon: const Icon(Icons.delete_forever_rounded, size: 18),
              onPressed: () => _confirmDeleteAccount(context, ref),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Hộp thoại xác nhận xóa tài khoản. Sở hữu [TextEditingController] để dispose
/// đúng lúc (sau khi route đóng xong), trả `true` khi xóa thành công.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.onDelete});

  final Future<void> Function(String password) onDelete;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  static const _log = AppLogger('Settings.DeleteAccount');
  final _passwordCtrl = TextEditingController();
  bool _isDeleting = false;
  String? _error;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _delete(AppLocalizations l10n) async {
    final password = _passwordCtrl.text;
    if (password.isEmpty) {
      setState(() => _error = l10n.settingsPasswordRequired);
      return;
    }
    setState(() {
      _isDeleting = true;
      _error = null;
    });
    try {
      await widget.onDelete(password);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e, stack) {
      _log.error('Xóa tài khoản lỗi', e, stack);
      // Hiện lỗi thật (sai mật khẩu, mất mạng...) ngay trong hộp thoại.
      if (mounted) {
        setState(() {
          _error = ErrorParser.parse(e, '', l10n);
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: colors.bgCard,
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: colors.error),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.settingsConfirmDeleteTitle)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.settingsDeleteIrreversible,
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          LavishTextField(
            label: l10n.settingsConfirmPassword,
            controller: _passwordCtrl,
            enabled: !_isDeleting,
            obscure: true,
            errorText: _error,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        LavishButton(
          label: l10n.settingsConfirmDelete,
          kind: LavishButtonKind.danger,
          busy: _isDeleting,
          onPressed: () => _delete(l10n),
        ),
      ],
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _value = previousValue;
        _isUpdating = false;
      });
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ErrorParser.parse(e, l.settingsStrangerMessagesUpdateError, l),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(userProfileProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LavishGroupHeader(l.settingsPrivacyTitle),
        profileAsync.when(
          data: (profile) {
            final currentValue =
                _value ?? profile.allowStrangerMessages ?? false;
            return LavishRow(
              leading: const LavishIconBox(
                child: Icon(Icons.mark_unread_chat_alt_outlined),
              ),
              title: l.settingsStrangerMessages,
              subtitle: currentValue
                  ? l.settingsStrangerMessagesOn
                  : l.settingsStrangerMessagesOff,
              onTap: _isUpdating
                  ? null
                  : () => _update(!currentValue, currentValue),
              trailing: [
                LavishSwitch(
                  value: currentValue,
                  onChanged: _isUpdating
                      ? null
                      : (value) => _update(value, currentValue),
                ),
              ],
            );
          },
          loading: () => const LavishRowSkeleton(count: 1),
          error: (_, _) => LavishErrorState(
            onRetry: () => ref.invalidate(userProfileProvider),
          ),
        ),
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
  bool _loadFailed = false;
  static const _log = AppLogger('Settings.ClubNotifications');
  final Set<String> _updatingClubIds = {};

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });
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
    } catch (e, stack) {
      _log.error('Lỗi tải thông báo CLB', e, stack);
      // Lỗi tải khác "không có CLB": hiện lỗi + thử lại thay vì danh sách rỗng.
      if (mounted) {
        setState(() {
          _loadFailed = true;
          _isLoading = false;
        });
      }
    }
  }

  String? _prefOf(String communityId) => _prefs
      ?.where((c) => c.communityId == communityId)
      .firstOrNull
      ?.notificationPreference;

  List<ClubNotificationPrefModel> _withPref(String communityId, String pref) =>
      [
        for (final c in _prefs ?? const <ClubNotificationPrefModel>[])
          c.communityId == communityId
              ? c.copyWith(notificationPreference: pref)
              : c,
      ];

  Future<void> _updatePref(String communityId, String newPref) async {
    final l10n = AppLocalizations.of(context)!;
    final oldPref = _prefOf(communityId);
    if (oldPref == null || _updatingClubIds.contains(communityId)) return;

    // Optimistic update: gán list mới, không sửa tại chỗ.
    setState(() {
      _updatingClubIds.add(communityId);
      _prefs = _withPref(communityId, newPref);
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
                  ? (l10n.settingsNotificationsAllUpdated)
                  : newPref == 'MENTIONS_ONLY'
                  ? (l10n.settingsNotificationsMentionsUpdated)
                  : (l10n.settingsNotificationsMutedUpdated),
            ),
          ),
        );
      }
    } catch (e, stack) {
      _log.error('Lỗi cập nhật thông báo CLB $communityId', e, stack);
      if (mounted) {
        setState(() => _prefs = _withPref(communityId, oldPref));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsNotificationsUpdateFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _updatingClubIds.remove(communityId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = LavishColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final prefs = _prefs ?? const <ClubNotificationPrefModel>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LavishGroupHeader(l10n.settingsClubNotifications),
        if (_isLoading)
          const LavishRowSkeleton(count: 2)
        else if (_loadFailed)
          LavishErrorState(onRetry: _loadPrefs)
        else if (prefs.isEmpty)
          LavishEmptyState(
            icon: Icons.groups_outlined,
            title: l10n.settingsNoClubsForNotifications,
          )
        else
          for (final club in prefs) _clubTile(c, l10n, club),
      ],
    );
  }

  Widget _clubTile(
    LavishColors c,
    AppLocalizations l10n,
    ClubNotificationPrefModel club,
  ) {
    final isUpdating = _updatingClubIds.contains(club.communityId);
    final hasLogo = club.logoUrl != null && club.logoUrl!.isNotEmpty;
    final summary = club.notificationPreference == 'ALL'
        ? l10n.settingsClubNotificationAllSummary
        : club.notificationPreference == 'MENTIONS_ONLY'
        ? l10n.settingsClubNotificationMentionsSummary
        : l10n.settingsClubNotificationMutedSummary;
    Widget chip(String title, String value) => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: LavishChipButton(
          label: title,
          selected: club.notificationPreference == value,
          onPressed: isUpdating
              ? null
              : () => _updatePref(club.communityId, value),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LavishRow(
          leading: CircleAvatar(
            radius: 17,
            backgroundColor: c.soft(LavishTone.accent),
            backgroundImage: hasLogo ? NetworkImage(club.logoUrl!) : null,
            child: hasLogo
                ? null
                : Text(
                    firstInitial(club.communityName, fallback: 'C'),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: LavishColors.accent,
                    ),
                  ),
          ),
          title: club.communityName,
          subtitle: summary,
          trailing: [
            if (isUpdating)
              const SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            LavishPill(
              club.role.toRoleDisplayName(l10n),
              tone: LavishTone.neutral,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(11, 6, 11, 8),
          child: Row(
            children: [
              chip(l10n.settingsNotificationAll, 'ALL'),
              chip(l10n.settingsNotificationMentions, 'MENTIONS_ONLY'),
              chip(l10n.settingsNotificationMuted, 'MUTED'),
            ],
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  SHARED WIDGETS
// ═════════════════════════════════════════════════════════════════════════
/// Viền/nhãn giống [LavishTextField] cho ô chọn (dropdown, ngày sinh).
InputDecoration _fieldDecoration(LavishColors c, String label) {
  OutlineInputBorder border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color, width: 1.5),
  );
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(fontSize: 13, color: c.muted),
    border: border(c.chipLine),
    enabledBorder: border(c.chipLine),
    disabledBorder: border(c.chipLine),
    focusedBorder: border(LavishColors.accent),
  );
}

Widget _dropdown(
  LavishColors c,
  String label,
  String value,
  List<String> items,
  ValueChanged<String?>? onChange, {
  Map<String, String>? displayLabels,
}) {
  // DropdownButton cần đúng một mục cho mỗi giá trị: bỏ mục trùng (API trả hai
  // tỉnh cùng tên) và thêm giá trị hiện tại nếu nằm ngoài danh sách (dữ liệu cũ).
  final effectiveItems = {...items, value}.toList();
  return InputDecorator(
    isEmpty: false,
    decoration: _fieldDecoration(c, label),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        isDense: true,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: c.muted),
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: c.text,
        ),
        dropdownColor: c.surface,
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

Widget _verifyRow(
  BuildContext context, {
  required IconData icon,
  required String title,
  required bool verified,
  String? value,
}) {
  final l10n = AppLocalizations.of(context)!;
  return LavishRow(
    leading: LavishIconBox(child: Icon(icon)),
    title: title,
    subtitle: value,
    subtitleMaxLines: 1,
    trailing: [
      LavishPill(
        verified ? l10n.infoEmailVerified : l10n.infoEmailUnverified,
        tone: verified ? LavishTone.ok : LavishTone.warn,
      ),
    ],
  );
}

Widget _actionRow(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  VoidCallback? onTap,
  Widget? trailing,
}) {
  final c = LavishColors.of(context);
  return LavishRow(
    leading: LavishIconBox(child: Icon(icon)),
    title: title,
    subtitle: subtitle,
    onTap: onTap,
    trailing: [
      ?trailing,
      if (trailing == null && onTap != null)
        Icon(Icons.chevron_right_rounded, size: 20, color: c.faint),
    ],
  );
}
