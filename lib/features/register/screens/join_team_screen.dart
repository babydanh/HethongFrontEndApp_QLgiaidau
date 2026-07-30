import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';

class JoinTeamScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  final String participantId;
  final String token;
  const JoinTeamScreen({
    super.key,
    required this.tournamentId,
    required this.participantId,
    required this.token,
  });

  @override
  ConsumerState<JoinTeamScreen> createState() => _JoinTeamScreenState();
}

class _JoinTeamScreenState extends ConsumerState<JoinTeamScreen> {
  bool _submitting = false;
  bool _success = false;

  Future<void> _join() async {
    setState(() => _submitting = true);
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.post(
        '/tournaments/${widget.tournamentId}/join-team',
        data: {
          'participantId': widget.participantId,
          'teamInviteToken': widget.token,
        },
      );
      setState(() => _success = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorParser.parse(e, AppLocalizations.of(context)!.joinTeamError)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAuthenticated = ref.watch(authProvider).isAuthenticated;
    if (!isAuthenticated) {
      final redirect = Uri(
        path: '/join-team',
        queryParameters: {
          'tournamentId': widget.tournamentId,
          'pid': widget.participantId,
          'token': widget.token,
        },
      ).toString();
      return Scaffold(
        backgroundColor: context.colors.bgDark,
        appBar: AppBar(title: Text(l10n.joinTeamTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton.icon(
              onPressed: () => context.push(
                '/login?redirect=${Uri.encodeComponent(redirect)}',
              ),
              icon: const Icon(Icons.login_rounded),
              label: Text(l10n.joinTeamLogin),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(title: Text(l10n.joinTeamTitle), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _success
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 72,
                      color: context.colors.success,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.joinTeamSuccess,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () =>
                          context.go('/intro/${widget.tournamentId}'),
                      child: Text(l10n.joinTeamViewTournament),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: context.colors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.group_add_rounded,
                        size: 36,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.joinTeamInvitation,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.joinTeamDesc,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _submitting ? null : _join,
                        icon: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline_rounded),
                        label: Text(
                          _submitting ? l10n.joinTeamProcessing : l10n.joinTeamConfirm,
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
