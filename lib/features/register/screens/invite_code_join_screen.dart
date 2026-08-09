import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';

/// Màn hình trung gian: resolve mã mời (code) → chuyển đúng luồng tham gia.
/// - Giải Lite → `/lite-join/{code}`
/// - Giải đầy đủ → `/register/{id}?invite={code}`
/// Tương đương web `/tournaments/join/{inviteCode}`.
class InviteCodeJoinScreen extends ConsumerStatefulWidget {
  final String inviteCode;

  const InviteCodeJoinScreen({super.key, required this.inviteCode});

  @override
  ConsumerState<InviteCodeJoinScreen> createState() =>
      _InviteCodeJoinScreenState();
}

class _InviteCodeJoinScreenState extends ConsumerState<InviteCodeJoinScreen> {
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final repo = ref.read(tournamentRepositoryProvider);
    final Tournament? t = await repo.getByInviteCode(
      widget.inviteCode.trim(),
    );
    if (!mounted) return;
    if (t == null) {
      setState(() => _failed = true);
      return;
    }
    final code = widget.inviteCode.trim();
    final route = t.isLite
        ? '/lite-join/$code'
        : '/register/${t.id}?invite=$code';
    context.pushReplacement(route);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(title: Text(l10n.registerTitle), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _failed
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 56,
                      color: context.colors.textMuted,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.registerTournamentNotFound,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: Text(l10n.matchBack),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      l10n.registerInviteValidating,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
