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

class _SettingsScreenState extends ConsumerState<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  @override void initState() { super.initState(); _tabController = TabController(length: 3, vsync: this); }
  @override void dispose() { _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: context.colors.bgDark,
    appBar: AppBar(backgroundColor: context.colors.bgDark, elevation: 0,
      leading: IconButton(icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary), onPressed: () => context.pop()),
      title: Text('Cài đặt', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.w900, fontSize: 20)), centerTitle: true,
      bottom: TabBar(controller: _tabController, indicatorColor: AppTheme.primary, indicatorWeight: 3,
        labelColor: AppTheme.primary, unselectedLabelColor: context.colors.textSecondary,
        tabs: const [Tab(text: 'Hồ sơ'), Tab(text: 'Ngân hàng'), Tab(text: 'Bảo mật')])),
    body: TabBarView(controller: _tabController, children: const [_ProfileTab(), _BankTab(), _SecurityTab()]));
}

class _ProfileTab extends ConsumerStatefulWidget {
  const _ProfileTab(); @override ConsumerState<_ProfileTab> createState() => _ProfileTabState();
}
class _ProfileTabState extends ConsumerState<_ProfileTab> {
  final _formKey = GlobalKey<FormState>(); final _nameCtrl = TextEditingController(); final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController(); final _bioCtrl = TextEditingController();
  String _gender = ''; String _province = ''; bool _isLoading = false;
  final _genders = ['Nam', 'Nữ', 'Khác'];
  final _provinces = ['Hà Nội', 'TP. Hồ Chí Minh', 'Đà Nẵng', 'Hải Phòng', 'Cần Thơ', 'An Giang', 'Bình Dương', 'Đồng Nai', 'Khánh Hòa', 'Lâm Đồng'];

  @override void dispose() { _nameCtrl.dispose(); _phoneCtrl.dispose(); _addressCtrl.dispose(); _bioCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(userProfileProvider);
    return p.when(data: (profile) {
      if (_nameCtrl.text.isEmpty && profile.fullName != null) {
        _nameCtrl.text = profile.fullName ?? ''; _phoneCtrl.text = profile.phoneNumber ?? '';
        _addressCtrl.text = profile.address ?? ''; _bioCtrl.text = profile.bio ?? '';
        _gender = profile.gender ?? 'Nam'; _province = profile.provinceCode ?? 'Hà Nội';
      }
      return _buildForm(profile.avatarUrl, profile.email);
    }, loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.cloud_off_rounded, size: 48, color: context.colors.textMuted), const SizedBox(height: 12),
        Text('Không thể tải', style: TextStyle(color: context.colors.textSecondary)),
        const SizedBox(height: 16), FilledButton(onPressed: () => ref.invalidate(userProfileProvider), child: const Text('Thử lại'))])));
  }

  Widget _buildForm(String? avatarUrl, String? email) => SingleChildScrollView(padding: const EdgeInsets.all(20), child: Form(key: _formKey, child: Column(children: [
    Stack(children: [
      CircleAvatar(radius: 46, backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
        backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) as ImageProvider : null,
        child: (avatarUrl == null || avatarUrl.isEmpty) ? Icon(Icons.person_rounded, size: 46, color: AppTheme.primary) : null),
      Positioned(bottom: 0, right: 0, child: Container(width: 30, height: 30, decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle, border: Border.all(color: context.colors.bgCard, width: 2.5)),
        child: const Icon(Icons.camera_alt_rounded, size: 15, color: Colors.white))),
    ]),
    const SizedBox(height: 24),
    _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _field('Họ và tên'), const SizedBox(height: 6), AppTextFormField(controller: _nameCtrl, hint: 'Nhập họ tên', prefixIcon: Icons.person_outline, validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ tên' : null),
      const SizedBox(height: 16), _field('Email'), const SizedBox(height: 6),
      TextFormField(initialValue: email ?? '', readOnly: true, style: TextStyle(color: context.colors.textPrimary),
        decoration: InputDecoration(hintText: 'email@domain.com', filled: true, fillColor: context.colors.bgSurface,
          prefixIcon: Icon(Icons.email_outlined, color: context.colors.textMuted),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.border)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
      const SizedBox(height: 16), _field('Số điện thoại'), const SizedBox(height: 6),
      AppTextFormField(controller: _phoneCtrl, hint: 'Nhập số điện thoại', keyboardType: TextInputType.phone, prefixIcon: Icons.phone_outlined),
      const SizedBox(height: 16), _field('Giới tính'), const SizedBox(height: 6), _dropdown(_gender, _genders, (v) { if (v != null) setState(() => _gender = v); }),
      const SizedBox(height: 16), _field('Địa chỉ'), const SizedBox(height: 6),
      AppTextFormField(controller: _addressCtrl, hint: 'Nhập địa chỉ', prefixIcon: Icons.location_on_outlined),
      const SizedBox(height: 16), _field('Tỉnh / Thành phố'), const SizedBox(height: 6), _dropdown(_province, _provinces, (v) { if (v != null) setState(() => _province = v); }),
      const SizedBox(height: 24),
      SizedBox(width: double.infinity, height: 50, child: FilledButton(onPressed: _isLoading ? null : () {}, style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        child: _isLoading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : const Text('Lưu thay đổi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
    ])),
  ])));

  Widget _card(Widget child) => Container(padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: context.colors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.colors.border)), child: child);
  Widget _field(String t) => Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.colors.textPrimary));
  Widget _dropdown(String v, List<String> items, ValueChanged<String?> onChange) => Container(height: 48, padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(color: context.colors.bgSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.colors.border)),
    child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: v, isExpanded: true, icon: Icon(Icons.arrow_drop_down_rounded, color: context.colors.textMuted),
      style: TextStyle(fontSize: 14, color: context.colors.textPrimary), items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: onChange)));
}

class _BankTab extends ConsumerWidget {
  const _BankTab(); @override Widget build(BuildContext context, WidgetRef ref) => Center(child: Text('Ngân hàng', style: TextStyle(color: context.colors.textSecondary)));
}
class _SecurityTab extends ConsumerWidget {
  const _SecurityTab(); @override Widget build(BuildContext context, WidgetRef ref) => Center(child: Text('Bảo mật', style: TextStyle(color: context.colors.textSecondary)));
}
