import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/core/widgets/match_card/match_card_live.dart';
import 'package:app_quanly_giaidau/core/widgets/match_card/match_card_compact.dart';

class LiveMatchScreen extends ConsumerWidget {
  final String tournamentId;
  const LiveMatchScreen({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesProvider(tournamentId));
    final tournamentAsync = ref.watch(tournamentProvider(tournamentId));

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(
        backgroundColor: context.colors.bgDark,
        title: tournamentAsync.when(
          data: (t) => Text(t?.name ?? 'Giải đấu'),
          loading: () => const Text('Đang tải...'),
          error: (error, stack) => const Text('Giải đấu'),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout_rounded, color: context.colors.textSecondary),
            onPressed: () {
              ref.read(authProvider.notifier).signOut();
              context.go('/home');
            },
          ),
        ],
      ),
      body: matchesAsync.when(
        data: (matches) {
          if (matches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports_score, size: 64,
                      color: context.colors.textMuted.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text('Chưa có trận đấu',
                      style: TextStyle(fontSize: 16, color: context.colors.textSecondary)),
                  const SizedBox(height: 8),
                  Text('Chờ ban tổ chức bốc thăm',
                      style: TextStyle(fontSize: 13, color: context.colors.textMuted)),
                ],
              ),
            );
          }

          final liveMatches =
              matches.where((m) => m.status == AppConstants.matchLive).toList();
          final completedMatches = matches
              .where((m) => m.status == AppConstants.matchCompleted)
              .toList();
          final upcomingMatches = matches
              .where((m) => m.status == AppConstants.matchScheduled)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ─── Live Matches ───
              if (liveMatches.isNotEmpty) ...[
                _buildSectionHeader('🔴 Đang thi đấu', context.colors.error),
                const SizedBox(height: 8),
                ...liveMatches.map((m) => MatchCardLive(match: m)),
                const SizedBox(height: 24),
              ],

              // ─── Upcoming ───
              if (upcomingMatches.isNotEmpty) ...[
                _buildSectionHeader('📅 Sắp diễn ra', context.colors.info),
                const SizedBox(height: 8),
                ...upcomingMatches.map((m) => MatchCardCompact(match: m, isCompleted: false)),
                const SizedBox(height: 24),
              ],

              // ─── Completed ───
              if (completedMatches.isNotEmpty) ...[
                _buildSectionHeader('✅ Đã kết thúc', context.colors.success),
                const SizedBox(height: 8),
                ...completedMatches.map((m) => MatchCardCompact(match: m, isCompleted: true)),
              ],
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}
