import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/providers/ranking_provider.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';

// ═══════════════════════════════════════════════════════════
//  USER RANKING DETAIL SCREEN — Thông tin xếp hạng cá nhân
// ═══════════════════════════════════════════════════════════
class UserRankingDetailScreen extends ConsumerWidget {
  const UserRankingDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userId = authState.isAuthenticated ? 'self' : '';
    final rankingAsync = ref.watch(userRankingsSummaryProvider(userId));

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      body: rankingAsync.when(
        data: (rankings) {
          final ranking = rankings.isNotEmpty ? rankings.first : const PlayerRanking(
            id: '', userId: '', fullName: 'Người dùng', eloPoints: 0, tierName: '', rank: 0, matchesPlayed: 0, matchesWon: 0,
          );
          return _buildContent(context, ranking);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2979FF),
            strokeWidth: 2.5,
          ),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFFB0BEC5)),
                const SizedBox(height: 16),
                const Text(
                  'Không thể tải thông tin',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PlayerRanking ranking) {
    final winRate = ranking.winRate;
    final matchesLost = ranking.matchesLost;

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Back Button + Title ──
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF0F172A),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Thông tin xếp hạng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── User Info Card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A56DB), Color(0xFF0E3FAA), Color(0xFF071F6B)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A56DB).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(ranking.fullName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Name
                  Text(
                    ranking.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Tier badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔥 ', style: TextStyle(fontSize: 14)),
                        Text(
                          ranking.tierName,
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ELO Big Display
                  const Text(
                    'ELO RATING',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${ranking.eloPoints}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Text(
                      '↑ +34 tuần này',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Stats row
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItemWhite('${ranking.matchesPlayed}', 'Trận'),
                        _buildStatDivider(),
                        _buildStatItemWhite('${ranking.matchesWon}', 'Thắng'),
                        _buildStatDivider(),
                        _buildStatItemWhite('$matchesLost', 'Thua'),
                        _buildStatDivider(),
                        _buildStatItemWhite('${winRate.toStringAsFixed(0)}%', 'Win rate',
                            valueColor: const Color(0xFF4ADE80)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Recent Matches Section ──
            const Text(
              'Trận đấu gần đây',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),

            // Mock recent matches
            _buildRecentMatch(
              opponent: 'Trần Văn B',
              result: 'Thắng',
              score: '6-4, 6-3',
              isWin: true,
            ),
            _buildRecentMatch(
              opponent: 'Lê Thị C',
              result: 'Thua',
              score: '3-6, 4-6',
              isWin: false,
            ),
            _buildRecentMatch(
              opponent: 'Phạm Văn D',
              result: 'Thắng',
              score: '6-2, 7-5',
              isWin: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItemWhite(String value, String label, {Color? valueColor}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 32,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }

  Widget _buildRecentMatch({
    required String opponent,
    required String result,
    required String score,
    required bool isWin,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Result indicator
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isWin
                  ? const Color(0xFF10B981).withValues(alpha: 0.1)
                  : const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isWin ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: isWin ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Opponent info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'vs $opponent',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  score,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Result badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isWin
                  ? const Color(0xFF10B981).withValues(alpha: 0.1)
                  : const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              result,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isWin ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[parts.length - 2][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '??';
  }
}
