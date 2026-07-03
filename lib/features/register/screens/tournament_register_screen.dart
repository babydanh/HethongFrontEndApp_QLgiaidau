import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:intl/intl.dart';

final _divisionsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, tournamentId) async {
  try {
    final dio = ref.read(dioClientProvider).dio;
    final response = await dio.get('/tournaments/$tournamentId/divisions');
    if (response.statusCode == 200) {
      return ((response.data['data'] ?? []) as List).cast<Map<String, dynamic>>();
    }
    return [];
  } catch (_) {
    return [];
  }
});

class TournamentRegisterScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  final String? inviteCode;
  const TournamentRegisterScreen({super.key, required this.tournamentId, this.inviteCode});

  @override
  ConsumerState<TournamentRegisterScreen> createState() => _TournamentRegisterScreenState();
}

class _TournamentRegisterScreenState extends ConsumerState<TournamentRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  String? _selectedDiv;
  bool _submitting = false;
  bool _success = false;

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final dio = ref.read(dioClientProvider).dio;
      final res = await dio.post('/tournaments/${widget.tournamentId}/register', data: {
        'teamName': _nameCtrl.text.trim(),
        if (_selectedDiv != null) 'divisionId': _selectedDiv,
        if (widget.inviteCode != null) 'inviteCode': widget.inviteCode,
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() => _success = true);
        final d = res.data['data'];
        final pid = d?['id'] ?? '';
        final fee = (d?['entryFee'] ?? 0).toDouble();
        if (fee > 0 && mounted) {
          context.push('/payment/checkout', extra: {'tournamentId': widget.tournamentId, 'participantId': pid, 'amount': fee});
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally { if (mounted) setState(() => _submitting = false); }
  }

  @override
  Widget build(BuildContext context) {
    final tAsync = ref.watch(tournamentProvider(widget.tournamentId));
    final divAsync = ref.watch(_divisionsProvider(widget.tournamentId));
    final isAuth = ref.watch(authProvider).isAuthenticated;

    if (_success) return _buildSuccess();
    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(title: const Text('Đăng ký'), centerTitle: true),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: tAsync.when(
          data: (t) {
            if (t == null) return const Center(child: Text('Không tìm thấy giải'));
            if (!isAuth) return _buildLoginPrompt(t);
            return _buildForm(t, divAsync);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Lỗi: $e')),
        ),
      ),
    );
  }

  Widget _buildSuccess() => Scaffold(
    backgroundColor: context.colors.bgDark,
    body: Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(color: context.colors.success.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(Icons.check_circle_rounded, size: 52, color: context.colors.success),
        ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
        const SizedBox(height: 24),
        const Text('Đăng ký thành công!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 32),
        ElevatedButton(onPressed: () => context.go('/intro/${widget.tournamentId}'), child: const Text('Xem chi tiết')),
      ]),
    )),
  );

  Widget _buildHeader(Tournament t) => Container(
    width: double.infinity, padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)]), borderRadius: BorderRadius.circular(20)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 24)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.name, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800), maxLines: 2),
          const SizedBox(height: 4),
          Text('Tối đa: ${t.maxTeams} đội', style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ])),
      ]),
      if (t.entryFee != null && t.entryFee! > 0) ...[
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: context.colors.warning.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
          child: Text('Phí: ${NumberFormat('#,###', 'vi_VN').format(t.entryFee!.ceil())}đ',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))),
      ],
    ]),
  ).animate().fadeIn(duration: 300.ms);

  Widget _buildLoginPrompt(Tournament t) => Column(children: [
    _buildHeader(t), const SizedBox(height: 24),
    Container(padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: context.colors.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.colors.border)),
      child: Column(children: [
        Icon(Icons.login_rounded, size: 48, color: context.colors.textMuted),
        const SizedBox(height: 12),
        const Text('Vui lòng đăng nhập để tham gia', textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton.icon(onPressed: () => context.push('/login'), icon: const Icon(Icons.login), label: const Text('Đăng nhập')),
      ]),
    ),
  ]);

  Widget _buildForm(Tournament t, AsyncValue<List<Map<String, dynamic>>> divAsync) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _buildHeader(t), const SizedBox(height: 24),
    Container(padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: context.colors.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.colors.border)),
      child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('THÔNG TIN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameCtrl,
          style: TextStyle(color: context.colors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Tên đội / VĐV', hintText: 'Nhập tên đội',
            prefixIcon: Icon(Icons.group_rounded, color: context.colors.textMuted),
            filled: true, fillColor: context.colors.bgDark,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (v) => (v == null || v.trim().length < 3) ? 'Tối thiểu 3 ký tự' : null,
        ),
        const SizedBox(height: 16),
        divAsync.when(data: (divs) {
          if (divs.isEmpty) return const SizedBox.shrink();
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('NỘI DUNG', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
            const SizedBox(height: 12),
            ...divs.map((d) {
              final id = d['id'] ?? ''; final name = d['name'] ?? '';
              final sel = _selectedDiv == id;
              return Padding(padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(onTap: () => setState(() => _selectedDiv = id),
                  child: Container(padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: context.colors.bgDark, borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: sel ? AppTheme.primary : context.colors.border, width: sel ? 2 : 1)),
                    child: Row(children: [
                      Expanded(child: Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.textPrimary))),
                      Container(width: 20, height: 20,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: sel ? AppTheme.primary : context.colors.border, width: 2)),
                        child: sel ? Center(child: Container(width: 10, height: 10, decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle))) : null),
                    ]),
                  ),
                ),
              );
            }).toList(),
          ]);
        }, loading: () => const SizedBox(height: 24, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
          error: (_, __) => const SizedBox.shrink()),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 50,
          child: ElevatedButton.icon(
            onPressed: _submitting ? null : _register,
            icon: _submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_circle_outline_rounded),
            label: Text(_submitting ? 'Đang xử lý...' : 'Xác nhận đăng ký'),
            style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          ),
        ),
      ])),
    ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
  ]);
}
