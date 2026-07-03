import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/app_text_field.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';

/// Màn hình Cài đặt — 3 tab: Hồ sơ, Ngân hàng, Bảo mật.
///
/// Mỗi tab là một form độc lập, gọi API thật:
/// - Hồ sơ: PATCH /users/profile
/// - Ngân hàng: PATCH /users/profile (bankName, bankAccountNumber, bankAccountName)
/// - Bảo mật: điều hướng sang /profile/change-password + xem phiên đăng nhập
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

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: colors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Cài đặt',
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

// ═════════════════════════════════════════════════════════════════════════
//  TAB 1: HỒ SƠ — PATCH /users/profile
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

  String _gender = 'Nam';
  String _province = '';
  bool _isLoading = false;
  bool _initialized = false;

  final _genders = ['Nam', 'Nữ', 'Khác'];
  final _provinces = [
    'Hà Nội', 'TP. Hồ Chí Minh', 'Đà Nẵng', 'Hải Phòng', 'Cần Thơ',
    'An Giang', 'Bình Dương', 'Đồng Nai', 'Khánh Hòa', 'Lâm Đồng',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    _log.info('Bắt đầu cập nhật hồ sơ');

    try {
      final repo = ref.read(userRepositoryProvider);
      await repo.updateProfile({
        'fullName': _nameCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'gender': _gender,
        'provinceCode': _province,
      });

      _log.success('Cập nhật hồ sơ thành công');
      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã lưu thay đổi'),
            backgroundColor: context.colors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, stack) {
      _log.error('Lỗi cập nhật hồ sơ', e, stack);
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
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (!_initialized) {
          _nameCtrl.text = profile.fullName ?? '';
          _phoneCtrl.text = profile.phoneNumber ?? '';
          _addressCtrl.text = profile.address ?? '';
          _bioCtrl.text = profile.bio ?? '';
          _gender = profile.gender ?? 'Nam';
          _province = profile.provinceCode ?? 'Hà Nội';
          _initialized = true;
        }
        return _buildForm(colors, profile.avatarUrl, profile.email);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _buildErrorState(colors, 'Không thể tải hồ sơ', () => ref.invalidate(userProfileProvider)),
    );
  }

  Widget _buildForm(AppColorsExtension colors, String? avatarUrl, String? email) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _card(colors, [
              _fieldLabel(colors, 'Họ và tên'),
              const SizedBox(height: 6),
              AppTextFormField(
                controller: _nameCtrl,
                hint: 'Nhập họ tên',
                prefixIcon: Icons.person_outline,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ tên' : null,
              ),
              const SizedBox(height: 16),
              _fieldLabel(colors, 'Email'),
              const SizedBox(height: 6),
              AppTextFormField(
                initialValue: email ?? '',
                hint: 'email@domain.com',
                prefixIcon: Icons.email_outlined,
                enabled: false,
              ),
              const SizedBox(height: 16),
              _fieldLabel(colors, 'Số điện thoại'),
              const SizedBox(height: 6),
              AppTextFormField(
                controller: _phoneCtrl,
                hint: 'Nhập số điện thoại',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
              ),
              const SizedBox(height: 16),
              _fieldLabel(colors, 'Giới tính'),
              const SizedBox(height: 6),
              _dropdown(colors, _gender, _genders, (v) {
                if (v != null) setState(() => _gender = v);
              }),
              const SizedBox(height: 16),
              _fieldLabel(colors, 'Địa chỉ'),
              const SizedBox(height: 6),
              AppTextFormField(
                controller: _addressCtrl,
                hint: 'Nhập địa chỉ',
                prefixIcon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 16),
              _fieldLabel(colors, 'Tỉnh / Thành phố'),
              const SizedBox(height: 6),
              _dropdown(colors, _province, _provinces, (v) {
                if (v != null) setState(() => _province = v);
              }),
              const SizedBox(height: 16),
              _fieldLabel(colors, 'Tiểu sử'),
              const SizedBox(height: 6),
              AppTextFormField(
                controller: _bioCtrl,
                hint: 'Giới thiệu bản thân...',
                maxLines: 3,
                prefixIcon: Icons.edit_note_rounded,
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
  final _bankNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();

  bool _isLoading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _bankNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _accountNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    _log.info('Bắt đầu lưu thông tin ngân hàng');

    try {
      final repo = ref.read(userRepositoryProvider);
      await repo.updateProfile({
        'bankName': _bankNameCtrl.text.trim(),
        'bankAccountNumber': _accountNumberCtrl.text.trim(),
        'bankAccountName': _accountNameCtrl.text.trim(),
      });

      _log.success('Lưu thông tin ngân hàng thành công');
      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã lưu thông tin ngân hàng'),
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
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (!_initialized) {
          _bankNameCtrl.text = profile.bankName ?? '';
          _accountNumberCtrl.text = profile.bankAccountNumber ?? '';
          _accountNameCtrl.text = profile.bankAccountName ?? '';
          _initialized = true;
        }
        return _buildForm(colors);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _buildErrorState(colors, 'Không thể tải thông tin ngân hàng',
          () => ref.invalidate(userProfileProvider)),
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
            // Info banner
            _infoBanner(colors),
            const SizedBox(height: 20),
            _card(colors, [
              _fieldLabel(colors, 'Tên ngân hàng'),
              const SizedBox(height: 6),
              AppTextFormField(
                controller: _bankNameCtrl,
                hint: 'VD: Vietcombank, Techcombank...',
                prefixIcon: Icons.account_balance_rounded,
              ),
              const SizedBox(height: 16),
              _fieldLabel(colors, 'Số tài khoản'),
              const SizedBox(height: 6),
              AppTextFormField(
                controller: _accountNumberCtrl,
                hint: 'Nhập số tài khoản',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.numbers_rounded,
              ),
              const SizedBox(height: 16),
              _fieldLabel(colors, 'Tên chủ tài khoản'),
              const SizedBox(height: 6),
              AppTextFormField(
                controller: _accountNameCtrl,
                hint: 'Nhập tên chủ tài khoản',
                prefixIcon: Icons.person_rounded,
                textCapitalization: TextCapitalization.words,
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
          Icon(Icons.lock_rounded, size: 18, color: AppTheme.primary.withValues(alpha: 0.8)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Thông tin ngân hàng dùng để nhận tiền thưởng giải đấu. '
              'Dữ liệu được bảo mật và không hiển thị công khai.',
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
//  TAB 3: BẢO MẬT — đổi mật khẩu + trạng thái xác thực
// ═════════════════════════════════════════════════════════════════════════
class _SecurityTab extends ConsumerWidget {
  const _SecurityTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final profileAsync = ref.watch(userProfileProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trạng thái xác thực
          _sectionTitle(colors, 'Trạng thái xác thực'),
          const SizedBox(height: 10),
          _card(colors, [
            ...profileAsync.when(
              data: (profile) => [
                _securityRow(
                  colors,
                  icon: Icons.email_outlined,
                  title: 'Email',
                  verified: profile.isEmailVerified == true,
                  fallbackText: profile.email,
                ),
                _divider(colors),
                _securityRow(
                  colors,
                  icon: Icons.phone_android_rounded,
                  title: 'Số điện thoại',
                  verified: profile.isPhoneVerified == true,
                  fallbackText: profile.phoneNumber,
                ),
              ],
              loading: () => [const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )],
              error: (_, _) => [Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Không thể tải trạng thái', style: TextStyle(color: colors.textSecondary)),
              )],
            ),
          ]),
          const SizedBox(height: 24),

          // Đổi mật khẩu
          _sectionTitle(colors, 'Mật khẩu'),
          const SizedBox(height: 10),
          _card(colors, [
            _actionRow(
              colors,
              icon: Icons.lock_outline_rounded,
              title: 'Đổi mật khẩu',
              subtitle: 'Cập nhật mật khẩu đăng nhập',
              onTap: () => context.push('/profile/change-password'),
            ),
            _divider(colors),
            _actionRow(
              colors,
              icon: Icons.security_rounded,
              title: 'Mật khẩu mạnh',
              subtitle: 'Tối thiểu 6 ký tự, nên có chữ hoa và số',
              trailing: Icon(Icons.check_circle_rounded, color: colors.success, size: 20),
            ),
          ]),
          const SizedBox(height: 24),

          // Phiên đăng nhập
          _sectionTitle(colors, 'Phiên đăng nhập'),
          const SizedBox(height: 10),
          _card(colors, [
            _actionRow(
              colors,
              icon: Icons.devices_rounded,
              title: 'Thiết bị hiện tại',
              subtitle: 'Đang hoạt động',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Online',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: colors.success),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 32),
        ],
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
  ValueChanged<String?> onChange,
) {
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
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
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

Widget _saveButton(BuildContext context, bool isLoading, Future<void> Function() onSave) {
  return SizedBox(
    width: double.infinity,
    height: 52,
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
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
        onPressed: isLoading ? null : onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : const Text(
                'Lưu thay đổi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
              ),
      ),
    ),
  );
}

Widget _securityRow(
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
              Text(title, style: TextStyle(fontSize: 11, color: colors.textMuted, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(
                fallbackText ?? (verified ? 'Đã xác thực' : 'Chưa xác thực'),
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
            color: (verified ? colors.success : colors.warning).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                verified ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                size: 13,
                color: verified ? colors.success : colors.warning,
              ),
              const SizedBox(width: 4),
              Text(
                verified ? 'Đã xác thực' : 'Chưa xác thực',
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
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: colors.textMuted)),
              ],
            ),
          ),
          if (trailing != null) trailing
          else if (onTap != null)
            Icon(Icons.chevron_right_rounded, size: 20, color: colors.textMuted),
        ],
      ),
    ),
  );
}

Widget _buildErrorState(AppColorsExtension colors, String message, VoidCallback onRetry) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 48, color: colors.textMuted),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary)),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    ),
  );
}
