import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

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
        final raw = res.data;
        final payload = raw is Map && raw['data'] is Map ? raw['data'] : raw;
        final data = payload is Map ? Map<String, dynamic>.from(payload) : null;
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
    final l10n = AppLocalizations.of(context)!;
    setState(() => _joining = true);
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.post('/tournaments/lite/join/${widget.inviteCode}');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.lite_joinSuccess)));
        final tournamentId = _status?['tournament']?['id']?.toString();
        if (tournamentId != null && tournamentId.isNotEmpty) {
          context.go('/intro/$tournamentId');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorParser.parse(e, l10n.lite_joinError)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _handleRequestClub() async {
    final l10n = AppLocalizations.of(context)!;
    final communityId = _status?['communityId']?.toString();
    if (communityId == null || communityId.isEmpty) return;
    setState(() => _requestingClub = true);
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.post('/communities/$communityId/join');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.lite_clubRequestSuccess)),
        );
        _fetchStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ErrorParser.parse(e, l10n.lite_clubRequestError),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _requestingClub = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuth = ref.watch(authProvider).isAuthenticated;
    final l10n = AppLocalizations.of(context)!;

    // Not authenticated → redirect login
    if (!isAuth && !_loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.push(
          '/login?redirect=${Uri.encodeComponent('/lite-join/${widget.inviteCode}')}',
        );
      });
      return Scaffold(
        backgroundColor: context.colors.bgDark,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final tournament = _status?['tournament'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(title: Text(l10n.lite_joinButton), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : tournament == null
          ? Center(child: Text(l10n.tournamentNotFound))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Tournament info
                  Icon(
                    Icons.workspace_premium_outlined,
                    size: 48,
                    color: context.colors.info,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tournament['name'] ?? '',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (tournament['category'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      tournament['category'],
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Case: Already joined
                  if (_status?['alreadyJoined'] == true) ...[
                    Icon(
                      Icons.check_circle,
                      size: 40,
                      color: context.colors.success,
                    ),
                    const SizedBox(height: 12),
                    Text(l10n.lite_alreadyJoined),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final id = tournament['id']?.toString() ?? '';
                          if (id.isNotEmpty) context.go('/intro/$id');
                        },
                        child: Text(l10n.lite_viewTournament),
                      ),
                    ),
                  ],

                  // Case: Registration closed
                  if (_status?['registrationClosed'] == true) ...[
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 40,
                      color: context.colors.warning,
                    ),
                    const SizedBox(height: 12),
                    Text(l10n.lite_registrationClosed),
                  ],

                  if (_status?['registrationNotOpen'] == true) ...[
                    Icon(
                      Icons.schedule_rounded,
                      size: 40,
                      color: context.colors.warning,
                    ),
                    const SizedBox(height: 12),
                    Text(l10n.lite_registrationNotOpen),
                  ],

                  // Case: Tournament full
                  if (_status?['tournamentFull'] == true) ...[
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 40,
                      color: context.colors.warning,
                    ),
                    const SizedBox(height: 12),
                    Text(l10n.lite_tournamentFull),
                  ],

                  // Case: Requires club join - OPEN
                  if (_status?['requiresClubJoin'] == true &&
                      _status?['clubPolicy'] == 'OPEN') ...[
                    Icon(Icons.people, size: 40, color: context.colors.info),
                    const SizedBox(height: 12),
                    Text.rich(
                      TextSpan(
                        text: l10n.lite_requiresClubPrefix,
                        children: [
                          TextSpan(
                            text: _status?['communityName'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _requestingClub
                            ? null
                            : () async {
                                await _handleRequestClub();
                                _fetchStatus();
                              },
                        child: Text(
                          _requestingClub ? l10n.lite_sending : l10n.lite_joinClub,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.lite_clubHintAfterJoin,
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],

                  // Case: Requires club join - APPROVAL
                  if (_status?['requiresClubJoin'] == true &&
                      _status?['clubPolicy'] == 'APPROVAL') ...[
                    Icon(Icons.shield, size: 40, color: context.colors.warning),
                    const SizedBox(height: 12),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '${l10n.navClubs} '),
                          TextSpan(
                            text: _status?['communityName'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(text: l10n.lite_clubNeedsApprovalSuffix),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _requestingClub
                            ? null
                            : () async {
                                await _handleRequestClub();
                                _fetchStatus();
                              },
                        child: Text(
                          _requestingClub ? l10n.lite_sending : l10n.lite_requestClub,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.lite_clubApprovalHint,
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],

                  // Case: Requires club join - INVITE_ONLY
                  if (_status?['requiresClubJoin'] == true &&
                      _status?['clubPolicy'] == 'INVITE_ONLY') ...[
                    Icon(Icons.shield, size: 40, color: context.colors.warning),
                    const SizedBox(height: 12),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '${l10n.navClubs} '),
                          TextSpan(
                            text: _status?['communityName'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(text: l10n.lite_clubInviteOnlySuffix),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  // Case: Club join pending
                  if (_status?['clubJoinPending'] == true) ...[
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 40,
                      color: context.colors.warning,
                    ),
                    const SizedBox(height: 12),
                    Text(l10n.lite_clubPendingApproval),
                  ],

                  // Case: Can join
                  if (_status?['canJoin'] == true) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.colors.info.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: context.colors.info.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.registerPlayerName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.colors.info,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.lite_yourAccountName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: context.colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.lite_nameFromProfile,
                            style: TextStyle(
                              color: context.colors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _joining ? null : _handleJoin,
                        child: Text(
                          _joining ? l10n.lite_joining : l10n.lite_joinButton,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
