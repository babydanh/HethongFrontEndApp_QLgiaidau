import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';

class JoinInviteScreen extends ConsumerStatefulWidget {
  final String inviteCode;
  const JoinInviteScreen({super.key, required this.inviteCode});

  @override
  ConsumerState<JoinInviteScreen> createState() => _JoinInviteScreenState();
}

class _JoinInviteScreenState extends ConsumerState<JoinInviteScreen> {
  final _nameCtrl = TextEditingController();
  bool _submitting = false;
  bool _loading = true;
  Map<String, dynamic>? _tournament;

  @override
  void initState() {
    super.initState();
    _fetchTournament();
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _fetchTournament() async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      final res = await dio.get('/tournaments/join/${widget.inviteCode}');
      if (res.statusCode == 200 && mounted) {
        setState(() => _tournament = res.data['data']);
      }
    } catch (_) {} finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _join() async {
    if (_nameCtrl.text.trim().length < 3) return;
    setState(() => _submitting = true);
    try {
      final dio = ref.read(dioClientProvider).dio;
      final res = await dio.post('/tournaments/join/${widget.inviteCode}', data: {
        'teamName': _nameCtrl.text.trim(),
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tham gia thành công!')));
        if (mounted) context.go('/home');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally { if (mounted) setState(() => _submitting = false); }
  }

  @override
  Widget build(BuildContext context) {
    final isAuth = ref.watch(authProvider).isAuthenticated;

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(title: const Text('Tham gia giải đấu'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                Container(width: 72, height: 72, decoration: BoxDecoration(color: context.colors.info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.key_rounded, size: 36, color: Colors.blue)),
                const SizedBox(height: 20),
                const Text('Mã mời hợp lệ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Mã: ${widget.inviteCode}', style: TextStyle(color: context.colors.info, fontWeight: FontWeight.w700)),
                if (_tournament != null) ...[
                  const SizedBox(height: 4),
                  Text(_tournament!['name'] ?? '', style: TextStyle(color: context.colors.textSecondary, fontSize: 14)),
                ],
                const SizedBox(height: 32),
                if (!isAuth) ...[
                  ElevatedButton.icon(onPressed: () => context.push('/login'), icon: const Icon(Icons.login), label: const Text('Đăng nhập để tiếp tục')),
                ] else ...[
                  TextField(
                    controller: _nameCtrl,
                    style: TextStyle(color: context.colors.textPrimary),
                    decoration: InputDecoration(labelText: 'Tên đội / VĐV',
                      prefixIcon: Icon(Icons.group_rounded, color: context.colors.textMuted),
                      filled: true, fillColor: context.colors.bgDark, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(
                    onPressed: _submitting ? null : _join,
                    icon: _submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_circle_outline_rounded),
                    label: Text(_submitting ? 'Đang xử lý...' : 'Xác nhận tham gia'),
                    style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  )),
                ],
              ]),
            ),
    );
  }
}
