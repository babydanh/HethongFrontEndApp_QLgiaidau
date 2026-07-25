import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';

class LiteJoinScreen extends ConsumerStatefulWidget {
  final String inviteCode;
  const LiteJoinScreen({super.key, required this.inviteCode});

  @override
  ConsumerState<LiteJoinScreen> createState() => _LiteJoinScreenState();
}

class _LiteJoinScreenState extends ConsumerState<LiteJoinScreen> {
  bool _loading = true;
  bool _joining = false;
  bool _requestingClub = false;
  Map<String, dynamic>? _status;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      final res = await dio.get('/tournaments/lite/join/${widget.inviteCode}');
      if (mounted) {
        final data = res.data as Map<String, dynamic>?;
        setState(() {
          _status = data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleJoin() async {
    setState(() => _joining = true);
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.post('/tournaments/lite/join/${widget.inviteCode}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tham gia thành công!')),
        );
        final tournamentId = _status?['tournament']?['id']?.toString();
        if (tournamentId != null && tournamentId.isNotEmpty) {
          context.go('/tournament/$tournamentId');
        }
      }
    } catch (e) {
      if (mounted) {
        final msg = e is Exception ? e.toString().replaceAll('Exception: ', '') : 'Có lỗi xảy ra';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _handleRequestClub() async {
    final communityId = _status?['communityId']?.toString();
    if (communityId == null || communityId.isEmpty) return;
    setState(() => _requestingClub = true);
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.post('/communities/$communityId/join');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi yêu cầu vào CLB!')),
        );
        _fetchStatus();
      }
    } catch (e) {
      if (mounted) {
        final msg = e is Exception ? e.toString().replaceAll('Exception: ', '') : 'Có lỗi xảy ra';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } finally {
      if (mounted) setState(() => _requestingClub = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuth = ref.watch(authProvider).isAuthenticated;

    // Not authenticated → redirect login
    if (!isAuth && !_loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.push('/login?redirect=${Uri.encodeComponent('/lite-join/${widget.inviteCode}')}');
      });
      return Scaffold(
        backgroundColor: context.colors.bgDark,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final tournament = _status?['tournament'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(title: const Text('Tham gia giải'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : tournament == null
              ? const Center(child: Text('Không tìm thấy giải đấu'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Tournament info
                      Icon(Icons.emoji_events, size: 48, color: context.colors.info),
                      const SizedBox(height: 16),
                      Text(
                        tournament['name'] ?? '',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                      if (tournament['category'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          tournament['category'],
                          style: TextStyle(color: context.colors.textSecondary, fontSize: 14),
                        ),
                      ],
                      const SizedBox(height: 32),

                      // Case: Already joined
                      if (_status?['alreadyJoined'] == true) ...[
                        const Icon(Icons.check_circle, size: 40, color: Colors.green),
                        const SizedBox(height: 12),
                        const Text('Bạn đã tham gia giải này'),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              final id = tournament['id']?.toString() ?? '';
                              if (id.isNotEmpty) context.go('/tournament/$id');
                            },
                            child: const Text('Xem giải đấu'),
                          ),
                        ),
                      ],

                      // Case: Registration closed
                      if (_status?['registrationClosed'] == true) ...[
                        const Icon(Icons.warning_amber_rounded, size: 40, color: Colors.amber),
                        const SizedBox(height: 12),
                        const Text('Giải đã đóng đăng ký'),
                      ],

                      // Case: Tournament full
                      if (_status?['tournamentFull'] == true) ...[
                        const Icon(Icons.warning_amber_rounded, size: 40, color: Colors.amber),
                        const SizedBox(height: 12),
                        const Text('Giải đã đủ số lượng'),
                      ],

                      // Case: Requires club join - OPEN
                      if (_status?['requiresClubJoin'] == true && _status?['clubPolicy'] == 'OPEN') ...[
                        const Icon(Icons.people, size: 40, color: Colors.blue),
                        const SizedBox(height: 12),
                        Text.rich(
                          TextSpan(
                            text: 'Bạn chưa là thành viên CLB ',
                            children: [
                              TextSpan(
                                text: _status?['communityName'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _requestingClub ? null : _handleRequestClub,
                            child: Text(_requestingClub ? 'Đang gửi...' : 'Vào CLB & Tham gia'),
                          ),
                        ),
                      ],

                      // Case: Requires club join - APPROVAL
                      if (_status?['requiresClubJoin'] == true && _status?['clubPolicy'] == 'APPROVAL') ...[
                        const Icon(Icons.shield, size: 40, color: Colors.amber),
                        const SizedBox(height: 12),
                        Text.rich(
                          TextSpan(
                            text: 'CLB ',
                            children: [
                              TextSpan(
                                text: _status?['communityName'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const TextSpan(text: ' cần duyệt thành viên'),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _requestingClub ? null : _handleRequestClub,
                            child: Text(_requestingClub ? 'Đang gửi...' : 'Xin vào CLB'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bạn cần được duyệt trước khi tham gia giải',
                          style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
                        ),
                      ],

                      // Case: Requires club join - INVITE_ONLY
                      if (_status?['requiresClubJoin'] == true && _status?['clubPolicy'] == 'INVITE_ONLY') ...[
                        const Icon(Icons.shield, size: 40, color: Colors.amber),
                        const SizedBox(height: 12),
                        Text.rich(
                          TextSpan(
                            text: 'CLB ',
                            children: [
                              TextSpan(
                                text: _status?['communityName'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const TextSpan(text: ' chỉ dành cho thành viên được mời'),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      // Case: Club join pending
                      if (_status?['clubJoinPending'] == true) ...[
                        const Icon(Icons.warning_amber_rounded, size: 40, color: Colors.amber),
                        const SizedBox(height: 12),
                        const Text('Yêu cầu vào CLB đang chờ duyệt'),
                      ],

                      // Case: Can join
                      if (_status?['canJoin'] == true) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.colors.info.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.colors.info.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tên thi đấu',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.info,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tên tài khoản của bạn',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tên sẽ được lấy từ hồ sơ cá nhân',
                                style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _joining ? null : _handleJoin,
                            child: Text(_joining ? 'Đang tham gia...' : 'Tham gia'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}
