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
  bool _loading = true;
  Map<String, dynamic>? _tournament;

  @override
  void initState() {
    super.initState();
    _fetchTournament();
  }

  Future<void> _fetchTournament() async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      final res = await dio.get('/tournaments/join/${widget.inviteCode}');
      if (res.statusCode == 200 && mounted) {
        final data = res.data['data'] as Map<String, dynamic>?;
        setState(() => _tournament = data);
        // Redirect to real registration flow with gates (profile, gender, ELO)
        if (data != null && data['id'] != null && mounted) {
          final tournamentId = data['id'].toString();
          context.go('/register/$tournamentId?invite=${widget.inviteCode}');
          return;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() { super.dispose(); }

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
                ],
              ]),
            ),
    );
  }
}
