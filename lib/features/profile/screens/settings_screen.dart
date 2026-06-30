import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/app_text_field.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  static const _log = AppLogger('SettingsScreen');
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
    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(
        backgroundColor: context.colors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Cài đặt',
          style: TextStyle(
            color: context.colors.textPrimary,
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
          unselectedLabelColor: context.colors.textSecondary,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Hồ sơ'),
            Tab(text: 'Ngân hàng'),
            Tab(text: 'Bảo mật'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ProfileTab(),
          _BankTab(),
          _SecurityTab(),
        ],
      ),
    );
  }
}

// ─── PROFILE TAB ───

class _ProfileTab extends ConsumerStatefulWidget {
  const _ProfileTab();

  @override
  ConsumerState<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<_ProfileTab> {
  static const _log = AppLogger('ProfileTab');
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  String _gender = '';
  String _province = '';
  bool _isLoading = false;

  final _genders = ['Nam', 'Nữ', 'Khác'];
  final _provinces = ['Hà Nội', 'TP. Hồ Chí Minh', 'Đà Nẵng', 'Hải Phòng', 'Cần Thơ',
    'An Giang', 'Bình Dương', 'Đồng Nai', 'Khánh Hòa', 'Lâm Đồng', 'Nghệ An', 'Quảng Ninh', 'Thừa Thiên Huế'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (_nameCtrl.text.isEmpty && profile.fullName != null) {
          _nameCtrl.text = profile.fullName ?? '';
          _phoneCtrl.text = profile.phoneNumber ?? '';
          _addressCtrl.text = profile.address ?? '';
          _bioCtrl.text = profile.bio ?? '';
          _gender = profile.gender ?? 'Nam';
          _province = profile.provinceCode ?? 'Hà Nội';
        }

        return _buildForm(profile.avatarUrl, profile.email);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: context.colors.textMuted),
            const SizedBox(height: 12),
            Text('Không thể tải thông tin', style: TextStyle(color: context.colors.textSecondary)),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => ref.invalidate(userProfileProvider), child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(String? avatarUrl, String? email) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Avatar
            GestureDetector(
              onTap: () => _log.info('Upload avatar - will implement with file_picker'),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl) as ImageProvider
                        : null,
                    child: (avatarUrl == null || avatarUrl.isEmpty)
                        ? Icon(Icons.person_rounded, size: 46, color: AppTheme.primary)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.colors.bgCard, width: 2.5),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 15, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.colors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Họ và tên'),
                  const SizedBox(height: 6),
                  AppTextFormField(
                    controller: _nameCtrl,
                    hint: 'Nhập họ tên',
                    prefixIcon: Icons.person_outline,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ tên' : null,
                  ),
                  const SizedBox(height: 16),

                  _fieldLabel('Email'),
                  const SizedBox(height: 6),
                  TextFormField(
                    initialValue: email ?? '',
                    readOnly: true,
                    style: TextStyle(color: context.colors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'email@domain.com',
                      filled: true,
                      fillColor: context.colors.bgSurface,
                      prefixIcon: Icon(Icons.email_outlined, color: context.colors.textMuted),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.colors.border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _fieldLabel('Số điện thoại'),
                  const SizedBox(height: 6),
                  AppTextFormField(
                    controller: _phoneCtrl,
                    hint: 'Nhập số điện thoại',
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                  ),
                  const SizedBox(height: 16),

                  _fieldLabel('Giới tính'),
                  const SizedBox(height: 6),
                  _buildDropdown(_gender, _genders, (v) {
                    if (v != null) setState(() => _gender = v);
                  }),
                  const SizedBox(height: 16),

                  _fieldLabel('Địa chỉ'),
                  const SizedBox(height: 6),
                  AppTextFormField(
                    controller: _addressCtrl,
                    hint: 'Nhập địa chỉ',
                    prefixIcon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 16),

                  _fieldLabel('Tỉnh / Thành phố'),
                  const SizedBox(height: 6),
                  _buildDropdown(_province, _provinces, (v) {
                    if (v != null) setState(() => _province = v);
                  }),
                  const SizedBox(height: 16),

                  _fieldLabel('Giới thiệu'),
                  const SizedBox(height: 6),
                  AppTextFormField(
                    controller: _bioCtrl,
                    hint: 'Giới thiệu về bạn...',
                    prefixIcon: Icons.notes_rounded,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : const Text('Lưu thay đổi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(userRepositoryProvider);
      await repo.updateProfile({
        'fullName': _nameCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim(),
        'gender': _gender,
        'address': _addressCtrl.text.trim(),
        'provinceCode': _province,
        'bio': _bioCtrl.text.trim(),
      });
      ref.invalidate(userProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Cập nhật hồ sơ thành công'),
            backgroundColor: context.colors.success, behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'),
            backgroundColor: context.colors.error, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildDropdown(String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down_rounded, color: context.colors.textMuted),
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.colors.textPrimary),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.colors.textPrimary));
  }
}

// ─── BANK TAB ───

class _BankTab extends ConsumerStatefulWidget {
  const _BankTab();

  @override
  ConsumerState<_BankTab> createState() => _BankTabState();
}

class _BankTabState extends ConsumerState<_BankTab> {
  static const _log = AppLogger('BankTab');
  final _formKey = GlobalKey<FormState>();
  final _bankNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _bankNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _accountNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (_bankNameCtrl.text.isEmpty && profile.bankName != null) {
          _bankNameCtrl.text = profile.bankName ?? '';
          _accountNumberCtrl.text = profile.bankAccountNumber ?? '';
          _accountNameCtrl.text = profile.bankAccountName ?? '';
        }
        return _buildForm();
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: Text('Không thể tải', style: TextStyle(color: context.colors.textSecondary))),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 20, color: AppTheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Thông tin ngân hàng được sử dụng cho việc hoàn tiền khi bạn rút khỏi giải đấu có thu phí.',
                      style: TextStyle(fontSize: 13, color: AppTheme.primary.withValues(alpha: 0.8), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.colors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Tên ngân hàng'),
                  const SizedBox(height: 6),
                  AppTextFormField(
                    controller: _bankNameCtrl,
                    hint: 'VD: Vietcombank, Techcombank...',
                    prefixIcon: Icons.account_balance_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên ngân hàng' : null,
                  ),
                  const SizedBox(height: 16),

                  _fieldLabel('Số tài khoản'),
                  const SizedBox(height: 6),
                  AppTextFormField(
                    controller: _accountNumberCtrl,
                    hint: 'Nhập số tài khoản',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.pin_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập số tài khoản' : null,
                  ),
                  const SizedBox(height: 16),

                  _fieldLabel('Chủ tài khoản'),
                  const SizedBox(height: 6),
                  AppTextFormField(
                    controller: _accountNameCtrl,
                    hint: 'Nhập tên chủ tài khoản (VIẾT HOA)',
                    prefixIcon: Icons.person_outline,
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên chủ tài khoản' : null,
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _saveBank,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : const Text('Lưu thông tin ngân hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _saveBank() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(userRepositoryProvider);
      await repo.updateProfile({
        'bankName': _bankNameCtrl.text.trim(),
        'bankAccountNumber': _accountNumberCtrl.text.trim(),
        'bankAccountName': _accountNameCtrl.text.trim().toUpperCase(),
      });
      ref.invalidate(userProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Cập nhật thông tin ngân hàng thành công'),
            backgroundColor: context.colors.success, behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'),
            backgroundColor: context.colors.error, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _fieldLabel(String text) {
    return Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.colors.textPrimary));
  }
}

// ─── SECURITY TAB ───

class _SecurityTab extends ConsumerStatefulWidget {
  const _SecurityTab();

  @override
  ConsumerState<_SecurityTab> createState() => _SecurityTabState();
}

class _SecurityTabState extends ConsumerState<_SecurityTab> {
  static const _log = AppLogger('SecurityTab');
  final _formKey = GlobalKey<FormState>();
  final _oldPwdCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPwdCtrl.dispose();
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.colors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Mật khẩu hiện tại'),
                  const SizedBox(height: 6),
                  _buildPasswordField(_oldPwdCtrl, _obscureOld, () {
                    setState(() => _obscureOld = !_obscureOld);
                  }, 'Nhập mật khẩu hiện tại'),
                  const SizedBox(height: 20),

                  _fieldLabel('Mật khẩu mới'),
                  const SizedBox(height: 6),
                  _buildPasswordField(_newPwdCtrl, _obscureNew, () {
                    setState(() => _obscureNew = !_obscureNew);
                  }, 'Nhập mật khẩu mới'),
                  const SizedBox(height: 10),
                  _passwordRequirement('Có ít nhất 6 ký tự', _newPwdCtrl.text.length >= 6),
                  const SizedBox(height: 4),
                  _passwordRequirement('Có ít nhất 1 chữ hoa', RegExp(r'[A-Z]').hasMatch(_newPwdCtrl.text)),
                  const SizedBox(height: 4),
                  _passwordRequirement('Có ít nhất 1 chữ số', RegExp(r'[0-9]').hasMatch(_newPwdCtrl.text)),
                  const SizedBox(height: 20),

                  _fieldLabel('Xác nhận mật khẩu mới'),
                  const SizedBox(height: 6),
                  _buildPasswordField(_confirmPwdCtrl, _obscureConfirm, () {
                    setState(() => _obscureConfirm = !_obscureConfirm);
                  }, 'Nhập lại mật khẩu mới'),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _changePassword,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : const Text('Đổi mật khẩu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Help card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.colors.info.withValues(alpha: 0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: context.colors.info),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Mật khẩu phải có ít nhất 6 ký tự, bao gồm chữ hoa và chữ số để bảo mật tài khoản.',
                      style: TextStyle(fontSize: 12, color: context.colors.info.withValues(alpha: 0.8), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController ctrl, bool obscure, VoidCallback toggle, String hint) {
    return AppTextFormField(
      controller: ctrl,
      hint: hint,
      obscureText: obscure,
      prefixIcon: Icons.lock_outline,
      suffixIcon: obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      onSuffixIconPressed: toggle,
      onChanged: (_) => setState(() {}),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
        if (ctrl == _confirmPwdCtrl && v != _newPwdCtrl.text) return 'Mật khẩu xác nhận không khớp';
        return null;
      },
    );
  }

  Widget _passwordRequirement(String text, bool met) {
    return Row(
      children: [
        Icon(met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 16, color: met ? context.colors.success : context.colors.textMuted),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
            color: met ? context.colors.success : context.colors.textSecondary)),
      ],
    );
  }

  Future<void> _changePassword() async {
    if (_newPwdCtrl.text != _confirmPwdCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Mật khẩu xác nhận không khớp'),
            backgroundColor: context.colors.error, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(userRepositoryProvider);
      await repo.changePassword(_oldPwdCtrl.text, _newPwdCtrl.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Đổi mật khẩu thành công'),
            backgroundColor: context.colors.success, behavior: SnackBarBehavior.floating),
      );
      _oldPwdCtrl.clear();
      _newPwdCtrl.clear();
      _confirmPwdCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'),
            backgroundColor: context.colors.error, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _fieldLabel(String text) {
    return Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.colors.textPrimary));
  }
}
