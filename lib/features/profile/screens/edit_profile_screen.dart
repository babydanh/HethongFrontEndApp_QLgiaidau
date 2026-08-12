import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/app_text_field.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/features/profile/utils/email_verification_flow.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';

class Province {
  final String code;
  final String name;

  Province({required this.code, required this.name});

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  static const _log = AppLogger('EditProfileScreen');
  AppLocalizations get l10n => AppLocalizations.of(context)!;

  late TabController _tabController;

  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _bioController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountNumberController = TextEditingController();
  final _bankAccountNameController = TextEditingController();
  final _deletePasswordController = TextEditingController();

  DateTime _selectedDate = DateTime(1995, 5, 15);
  String _selectedGender = 'Nam';
  
  List<Province> _provinces = [];
  Province? _selectedProvince;
  String? _initialProvinceCode;
  bool _loadingProvinces = true;
  bool _isLoading = false;
  bool _isInitialized = false;

  // OTP verification states
  bool _isEmailVerified = false;
  bool _isPhoneVerified = false;
  bool _emailChanged = false;
  bool _phoneChanged = false;
  String? _originalEmail;
  String? _originalPhone;

  final List<String> _genders = ['Nam', 'Nữ', 'Khác'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() => _fetchProvinces());
  }

  Future<void> _fetchProvinces() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/regions/provinces');
      final List<dynamic> data = response.data['data'] ?? response.data;
      final loaded = data.map((json) => Province.fromJson(json)).toList();
      
      loaded.sort((a, b) => a.name.compareTo(b.name));

      setState(() {
        _provinces = loaded;
        _loadingProvinces = false;
        
        if (_initialProvinceCode != null) {
          _selectedProvince = _provinces.firstWhere(
            (p) => p.code == _initialProvinceCode,
            orElse: () => _provinces.firstWhere(
              (p) => p.name.contains('Hà Nội') || p.code == '01',
              orElse: () => _provinces.first,
            ),
          );
        } else {
          _selectedProvince = _provinces.firstWhere(
            (p) => p.name.contains('Hà Nội') || p.code == '01',
            orElse: () => _provinces.first,
          );
        }
      });
    } catch (e) {
      setState(() {
        _provinces = [
          Province(code: '01', name: 'Hà Nội'),
          Province(code: '79', name: 'TP. Hồ Chí Minh'),
          Province(code: '48', name: 'Đà Nẵng'),
          Province(code: '31', name: 'Hải Phòng'),
          Province(code: '92', name: 'Cần Thơ'),
        ];
        _loadingProvinces = false;
        _selectedProvince = _provinces.first;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    _bankNameController.dispose();
    _bankAccountNumberController.dispose();
    _bankAccountNameController.dispose();
    _deletePasswordController.dispose();
    super.dispose();
  }

  void _initFields(UserProfile profile) {
    if (_isInitialized) return;
    _fullNameController.text = profile.fullName ?? '';
    _emailController.text = profile.email ?? '';
    _phoneController.text = profile.phoneNumber ?? '';
    _addressController.text = profile.address ?? '';
    _bankNameController.text = profile.bankName ?? '';
    _bankAccountNumberController.text = profile.bankAccountNumber ?? '';
    _bankAccountNameController.text = profile.bankAccountName ?? '';

    _originalEmail = profile.email;
    _originalPhone = profile.phoneNumber;
    _isEmailVerified = profile.isEmailVerified ?? false;
    _isPhoneVerified = profile.isPhoneVerified ?? false;

    if (profile.dateOfBirth != null && profile.dateOfBirth!.isNotEmpty) {
      final parsed = DateTime.tryParse(profile.dateOfBirth!);
      if (parsed != null) {
        _selectedDate = parsed;
      }
    }

    if (profile.gender != null && _genders.contains(profile.gender)) {
      _selectedGender = profile.gender!;
    }

    if (profile.provinceCode != null && profile.provinceCode!.isNotEmpty) {
      _initialProvinceCode = profile.provinceCode;
      if (_provinces.isNotEmpty) {
        _selectedProvince = _provinces.firstWhere(
          (p) => p.code == _initialProvinceCode,
          orElse: () => _selectedProvince ?? _provinces.first,
        );
      }
    }

    _bioController.text = profile.bio ?? '';

    _isInitialized = true;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2979FF),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final colors = context.colors;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: colors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.edit_avatar_title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF2979FF)),
                title: Text(l10n.edit_take_photo, style: TextStyle(color: colors.textPrimary)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF2979FF)),
                title: Text(l10n.edit_choose_from_library, style: TextStyle(color: colors.textPrimary)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (pickedFile == null) return;

      setState(() => _isLoading = true);
      final bytes = await pickedFile.readAsBytes();
      final fileName = pickedFile.name;

      final repo = ref.read(userRepositoryProvider);
      await repo.uploadAvatar(bytes, fileName);
      
      ref.invalidate(userProfileProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.edit_avatar_upload_success),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      final message = e.code == 'camera_access_denied'
          ? 'Bạn chưa cấp quyền camera cho Sporto.'
          : e.code == 'photo_access_denied'
              ? 'Bạn chưa cấp quyền thư viện ảnh cho Sporto.'
              : 'Không thể mở camera hoặc thư viện ảnh.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.edit_avatar_upload_error(e.toString())),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── OTP VERIFICATION ─────────────────────────────────────────────

  Future<void> _verifyEmailWithOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.edit_email_required), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.edit_email_invalid), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    if (email == _originalEmail && _isEmailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.edit_email_verified_already), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    await startEmailVerificationFlow(context, ref, email);
    if (!mounted) return;
    
    setState(() {
      _isEmailVerified = true;
      _emailChanged = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.edit_email_verify_success),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _verifyPhoneWithOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.edit_phone_required), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final cleanedPhone = phone.replaceAll(RegExp(r'[\s\-\.]'), '');
    if (!RegExp(r'^(?:\+84|0)[3|5|7|8|9]\d{8}$').hasMatch(cleanedPhone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.edit_phone_invalid), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    if (phone == _originalPhone && _isPhoneVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.edit_phone_verified_already), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    // Request OTP for phone
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/auth/verify-phone/request', data: {'phoneNumber': cleanedPhone});
    } catch (e) {
      _log.error('Không thể gửi mã OTP đến SĐT', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.edit_otp_send_error(e.toString())), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    if (!mounted) return;

    // Show OTP input dialog
    final tokenCtrl = TextEditingController();
    var isSubmitting = false;
    final messenger = ScaffoldMessenger.of(context);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            Future<void> submitToken() async {
              final token = tokenCtrl.text.trim();
              if (token.isEmpty) {
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.edit_otp_enter_code)),
                );
                return;
              }

              setDialogState(() => isSubmitting = true);

              try {
                final dio = ref.read(dioProvider);
                await dio.post('/auth/verify-phone/confirm', data: {
                  'token': token,
                  'phoneNumber': cleanedPhone,
                });
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                
                if (mounted) {
                  setState(() {
                    _isPhoneVerified = true;
                    _phoneChanged = true;
                  });
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(l10n.edit_phone_verify_success),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (!ctx.mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.edit_phone_verify_failed(e.toString()))),
                );
              } finally {
                if (ctx.mounted) setDialogState(() => isSubmitting = false);
              }
            }

            return AlertDialog(
              backgroundColor: context.colors.bgCard,
              title: Text(l10n.edit_phone_verify_title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mã OTP đã được gửi đến $cleanedPhone. Nhập mã để hoàn tất.',
                    style: TextStyle(color: context.colors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: tokenCtrl,
                    enabled: !isSubmitting,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.edit_otp_label,
                      hintText: l10n.edit_otp_hint,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
                  child: Text(l10n.matchesCancel),
                ),
                FilledButton(
                  onPressed: isSubmitting ? null : submitToken,
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.edit_verify),
                ),
              ],
            );
          },
        );
      },
    );

    tokenCtrl.dispose();
  }

  // ─── DELETE ACCOUNT ──────────────────────────────────────────────

  Future<void> _confirmDeleteAccount() async {
    final colors = context.colors;
    final passwordCtrl = TextEditingController();
    var isSubmitting = false;
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            Future<void> submitDelete() async {
              final password = passwordCtrl.text;
              if (password.isEmpty) {
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.edit_password_required)),
                );
                return;
              }

              setDialogState(() => isSubmitting = true);

              try {
                final dio = ref.read(dioProvider);
                await dio.delete('/users/profile', data: {'password': password});
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop(true);
              } catch (e) {
                if (!ctx.mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(l10n.edit_delete_account_error(e.toString().replaceAll("Exception: ", ""))),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                if (ctx.mounted) setDialogState(() => isSubmitting = false);
              }
            }

            return AlertDialog(
              backgroundColor: colors.bgCard,
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: colors.error),
                  const SizedBox(width: 8),
                  Text(l10n.edit_delete_account_title),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.edit_delete_account_confirm,
                    style: TextStyle(color: colors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordCtrl,
                    enabled: !isSubmitting,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: l10n.edit_current_password,
                      hintText: l10n.edit_password_confirm_hint,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(false),
                  child: Text(l10n.matchesCancel),
                ),
                FilledButton(
                  onPressed: isSubmitting ? null : submitDelete,
                  style: FilledButton.styleFrom(backgroundColor: colors.error),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(l10n.edit_delete_account, style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );

    passwordCtrl.dispose();

    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).signOut(reason: 'Tài khoản đã được xoá');
      if (!mounted) return;
      context.go('/login');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.edit_account_deleted),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ─── SAVE ─────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(userRepositoryProvider);
      
      final formattedDate =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

      final body = <String, dynamic>{
        'fullName': _fullNameController.text.trim(),
        'dateOfBirth': formattedDate,
        'gender': _selectedGender,
      };

      final phoneVal = _phoneController.text.trim();
      if (phoneVal.isNotEmpty) body['phoneNumber'] = phoneVal;

      final addressVal = _addressController.text.trim();
      if (addressVal.isNotEmpty) body['address'] = addressVal;

      if (_selectedProvince?.code != null && _selectedProvince!.code.isNotEmpty) {
        body['provinceCode'] = _selectedProvince!.code;
      }

      final bioVal = _bioController.text.trim();
      if (bioVal.isNotEmpty) body['bio'] = bioVal;

      // Only send email if changed and verified
      if (_emailChanged && _isEmailVerified) {
        body['email'] = _emailController.text.trim();
      }

      // Send bank fields
      final bankName = _bankNameController.text.trim();
      final bankAccountNumber = _bankAccountNumberController.text.trim();
      final bankAccountName = _bankAccountNameController.text.trim();
      if (bankName.isNotEmpty) body['bankName'] = bankName;
      if (bankAccountNumber.isNotEmpty) body['bankAccountNumber'] = bankAccountNumber;
      if (bankAccountName.isNotEmpty) body['bankAccountName'] = bankAccountName;

      await repo.updateProfile(body);

      ref.invalidate(userProfileProvider);

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.edit_update_success),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
      context.go('/profile');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final errorMsg = ErrorParser.parse(e, 'Lỗi cập nhật hồ sơ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
    }
  }

  // ─── BUILD ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: colors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => context.go('/profile'),
        ),
        title: Text(
          'Chỉnh sửa hồ sơ',
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
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: const [
            Tab(text: 'Hồ sơ'),
            Tab(text: 'Ngân hàng'),
            Tab(text: 'Bảo mật'),
          ],
        ),
      ),
      body: profileAsync.when(
        data: (profile) {
          _initFields(profile);
          return TabBarView(
            controller: _tabController,
            children: [
              _buildProfileTab(colors, profile),
              _buildBankTab(colors),
              _buildSecurityTab(colors, profile),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Lỗi tải hồ sơ: $e',
            style: TextStyle(color: colors.error),
          ),
        ),
      ),
      bottomNavigationBar: profileAsync.maybeWhen(
        data: (_) => Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: colors.bgCard,
            border: Border(top: BorderSide(color: colors.border)),
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Lưu thay đổi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ),
        orElse: () => null,
      ),
    );
  }

  // ─── TAB 1: HỒ SƠ CÁ NHÂN ─────────────────────────────────────────
  Widget _buildProfileTab(AppColorsExtension colors, UserProfile profile) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 32),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildAvatarPicker(profile),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel(text: 'Họ và tên', colors: colors),
                  const SizedBox(height: 6),
                  AppTextFormField(
                    controller: _fullNameController,
                    hint: 'Nhập họ và tên của bạn',
                    prefixIcon: Icons.person_outline,
                    validator: (val) =>
                        (val == null || val.trim().isEmpty) ? 'Vui lòng nhập họ và tên' : null,
                  ),
                  const SizedBox(height: 18),
                  _FieldLabel(text: 'Email', colors: colors),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextFormField(
                          controller: _emailController,
                          hint: 'example@domain.com',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                          validator: (val) {
                            if (val != null && val.trim().isNotEmpty) {
                              final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                              if (!emailRegex.hasMatch(val.trim())) {
                                return 'Email không hợp lệ';
                              }
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() => _emailChanged = true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildVerifyButton(
                        isVerified: _isEmailVerified,
                        onVerify: _verifyEmailWithOtp,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _FieldLabel(text: 'Số điện thoại', colors: colors),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextFormField(
                          controller: _phoneController,
                          hint: '0987654321',
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icons.phone_outlined,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Vui lòng nhập số điện thoại';
                            }
                            final phone = val.trim().replaceAll(RegExp(r'[\s\-\.]'), '');
                            if (!RegExp(r'^(?:\+84|0)[3|5|7|8|9]\d{8}$').hasMatch(phone)) {
                              return 'Số điện thoại không hợp lệ';
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() => _phoneChanged = true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildVerifyButton(
                        isVerified: _isPhoneVerified,
                        onVerify: _verifyPhoneWithOtp,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _FieldLabel(text: 'Ngày sinh', colors: colors),
                  const SizedBox(height: 6),
                  _buildDatePicker(),
                  const SizedBox(height: 18),
                  _FieldLabel(text: 'Giới tính', colors: colors),
                  const SizedBox(height: 6),
                  _buildGenderDropdown(),
                  const SizedBox(height: 18),
                  _FieldLabel(text: 'Địa chỉ', colors: colors),
                  const SizedBox(height: 6),
                  AppTextFormField(
                    controller: _addressController,
                    hint: 'Nhập địa chỉ',
                    prefixIcon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 18),
                  _FieldLabel(text: 'Tỉnh / Thành phố', colors: colors),
                  const SizedBox(height: 6),
                  _buildProvinceDropdown(),
                  const SizedBox(height: 18),
                  _FieldLabel(text: 'Giới thiệu (bio)', colors: colors),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _bioController,
                    maxLines: 3,
                    maxLength: 200,
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Giới thiệu ngắn về bản thân...',
                      hintStyle: TextStyle(color: colors.textMuted, fontSize: 12),
                      filled: true,
                      fillColor: colors.bgSurface,
                      prefixIcon: Icon(Icons.info_outline_rounded, color: colors.textMuted, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colors.border.withValues(alpha: 0.5)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ─── TAB 2: NGÂN HÀNG ─────────────────────────────────────────────
  Widget _buildBankTab(AppColorsExtension colors) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance_outlined, size: 20, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Tài khoản ngân hàng nhận thưởng',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Dùng để ban tổ chức chuyển khoản giải thưởng từ các giải đấu.',
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
                const SizedBox(height: 20),
                _FieldLabel(text: 'Tên ngân hàng', colors: colors),
                const SizedBox(height: 6),
                AppTextFormField(
                  controller: _bankNameController,
                  hint: 'VD: Vietcombank, Techcombank...',
                  prefixIcon: Icons.business_outlined,
                ),
                const SizedBox(height: 18),
                _FieldLabel(text: 'Số tài khoản', colors: colors),
                const SizedBox(height: 6),
                AppTextFormField(
                  controller: _bankAccountNumberController,
                  hint: 'Nhập số tài khoản',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.pin_outlined,
                ),
                const SizedBox(height: 18),
                _FieldLabel(text: 'Chủ tài khoản', colors: colors),
                const SizedBox(height: 6),
                AppTextFormField(
                  controller: _bankAccountNameController,
                  hint: 'Nhập tên chủ tài khoản (Viết hoa không dấu)',
                  prefixIcon: Icons.person_outline,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSaveButton(colors),
        ],
      ),
    );
  }

  // ─── TAB 3: BẢO MẬT & TÀI KHOẢN ──────────────────────────────────
  Widget _buildSecurityTab(AppColorsExtension colors, UserProfile profile) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          // Đổi mật khẩu card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.security_rounded, size: 20, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Bảo mật tài khoản',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.lock_reset_rounded, color: AppTheme.primary),
                  ),
                  title: Text('Đổi mật khẩu', style: TextStyle(fontWeight: FontWeight.w700, color: colors.textPrimary)),
                  subtitle: Text('Cập nhật mật khẩu đăng nhập của bạn', style: TextStyle(fontSize: 12, color: colors.textMuted)),
                  trailing: Icon(Icons.chevron_right_rounded, color: colors.textMuted),
                  onTap: () => context.push('/profile/change-password'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Delete account card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.error.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 20, color: colors.error),
                    const SizedBox(width: 8),
                    Text(
                      'Xoá tài khoản',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: colors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Xoá vĩnh viễn tài khoản và dữ liệu cá nhân của bạn.',
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _confirmDeleteAccount,
                    icon: const Icon(Icons.delete_forever_rounded, size: 18),
                    label: const Text('Xoá tài khoản'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.error,
                      side: BorderSide(color: colors.error.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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

  Widget _buildSaveButton(AppColorsExtension colors) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      height: 52,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: context.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text(
                  'Lưu thay đổi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildVerifyButton({required bool isVerified, required VoidCallback onVerify}) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isVerified ? const Color(0xFF10B981) : context.colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isVerified ? const Color(0xFF10B981) : context.colors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onVerify,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              isVerified ? Icons.verified_rounded : Icons.verified_outlined,
              size: 20,
              color: isVerified ? Colors.white : context.colors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPicker(UserProfile profile) {
    final avatarUrl = profile.avatarUrl;
    return GestureDetector(
      onTap: _pickAndUploadAvatar,
      child: Stack(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF2979FF), Color(0xFF448AFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2979FF).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colors.bgSurface,
                ),
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.person_rounded,
                            size: 50,
                            color: context.colors.textMuted,
                          ),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                          },
                        ),
                      )
                    : Icon(
                        Icons.person_rounded,
                        size: 50,
                        color: context.colors.textMuted,
                      ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2979FF),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2979FF).withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    final formattedDate =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: context.colors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(Icons.cake_outlined, size: 20, color: context.colors.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: context.colors.textPrimary,
                ),
              ),
            ),
            Icon(Icons.calendar_today_rounded, size: 18, color: context.colors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border.withValues(alpha: 0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedGender,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down_rounded, color: context.colors.textMuted),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: context.colors.textPrimary,
          ),
          dropdownColor: context.colors.bgSurface,
          items: _genders.map((g) {
            return DropdownMenuItem(value: g, child: Text(g));
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedGender = val);
          },
        ),
      ),
    );
  }

  Widget _buildProvinceDropdown() {
    if (_loadingProvinces) {
      return Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: context.colors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.border.withValues(alpha: 0.5)),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border.withValues(alpha: 0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Province>(
          value: _selectedProvince,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down_rounded, color: context.colors.textMuted),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: context.colors.textPrimary,
          ),
          dropdownColor: context.colors.bgSurface,
          items: _provinces.map((p) {
            return DropdownMenuItem<Province>(value: p, child: Text(p.name));
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedProvince = val);
          },
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final AppColorsExtension colors;

  const _FieldLabel({required this.text, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: colors.textSecondary,
      ),
    );
  }
}
