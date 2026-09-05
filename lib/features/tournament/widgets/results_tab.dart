import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/tournament_result_provider.dart';

class ResultsTab extends ConsumerWidget {
  final String tournamentId;
  final String? selectedDivisionId;
  final String? selectedDivision;

  const ResultsTab({
    super.key,
    required this.tournamentId,
    this.selectedDivisionId,
    this.selectedDivision,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final resultAsync = ref.watch(tournamentResultProvider((
      tournamentId: tournamentId,
      divisionId: selectedDivisionId,
    )));

    return resultAsync.when(
      data: (data) {
        final rawAwards = data['awards'];
        if (rawAwards is! List || rawAwards.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events_outlined,
                    size: 40,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Chưa có kết quả chính thức',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kết quả sẽ được công bố khi các vòng chung kết hoàn tất',
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
              ],
            ),
          );
        }

        // Parse awards
        final awards = rawAwards
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        Map<String, dynamic>? gold;
        Map<String, dynamic>? silver;
        final List<Map<String, dynamic>> bronzes = [];
        final List<Map<String, dynamic>> others = [];

        for (final award in awards) {
          final rank = (award['rank'] as num?)?.toInt() ?? 0;
          if (rank == 1) {
            gold = award;
          } else if (rank == 2) {
            silver = award;
          } else if (rank == 3 || rank == 4) {
            bronzes.add(award);
          } else {
            others.add(award);
          }
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. PODIUM BỤC VINH DANH (3 CỘT VÀNG - BẠC - ĐỒNG) ──
              _buildPodiumView(context, gold, silver, bronzes),
              const SizedBox(height: 24),

              // ── 2. DANH SÁCH CHI TIẾT GIẢI THƯỞNG ──
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 10),
                child: Row(
                  children: [
                    Text(
                      'DANH SÁCH TRAO THƯỞNG',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: colors.textMuted,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: colors.bgSurface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colors.border.withValues(alpha: 0.6)),
                      ),
                      child: Text(
                        '${(gold != null ? 1 : 0) + (silver != null ? 1 : 0) + bronzes.length + others.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (gold != null) ...[
                _buildAwardCard(context, gold, 1, 'QUÁN QUÂN'),
                const SizedBox(height: 8),
              ],
              if (silver != null) ...[
                _buildAwardCard(context, silver, 2, 'Á QUÂN'),
                const SizedBox(height: 8),
              ],
              for (int i = 0; i < bronzes.length; i++) ...[
                _buildAwardCard(
                  context,
                  bronzes[i],
                  3,
                  bronzes.length > 1 ? 'ĐỒNG HẠNG 3' : 'HẠNG 3',
                ),
                const SizedBox(height: 8),
              ],
              for (final other in others) ...[
                _buildAwardCard(
                  context,
                  other,
                  (other['rank'] as num?)?.toInt() ?? 0,
                  'HẠNG ${(other['rank'] as num?)?.toInt() ?? 0}',
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events_outlined,
                size: 40,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa có kết quả chính thức',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Kết quả sẽ được công bố khi các vòng chung kết hoàn tất',
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodiumView(
    BuildContext context,
    Map<String, dynamic>? gold,
    Map<String, dynamic>? silver,
    List<Map<String, dynamic>> bronzes,
  ) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 0),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ── Bục 2: Á Quân (Bên Trái) ──
          Expanded(
            flex: 10,
            child: _buildPodiumColumn(
              context,
              award: silver,
              rank: 2,
              rankLabel: 'Á QUÂN',
              podiumHeight: 82,
              accentColor: const Color(0xFF64748B),
              podiumGradient: const LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xFFE2E8F0), Color(0xFFF1F5F9), Color(0xFFF8FAFC)],
              ),
              borderColor: const Color(0xFFCBD5E1),
              numberColor: const Color(0xFF475569),
            ),
          ),
          const SizedBox(width: 8),

          // ── Bục 1: Quán Quân (Ở Giữa - Cao nhất) ──
          Expanded(
            flex: 12,
            child: _buildPodiumColumn(
              context,
              award: gold,
              rank: 1,
              rankLabel: 'QUÁN QUÂN',
              podiumHeight: 114,
              accentColor: const Color(0xFFD97706),
              podiumGradient: const LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xFFFDE68A), Color(0xFFFEF3C7), Color(0xFFFFFBEB)],
              ),
              borderColor: const Color(0xFFF59E0B),
              numberColor: const Color(0xFFB45309),
              isGold: true,
            ),
          ),
          const SizedBox(width: 8),

          // ── Bục 3: Đồng Hạng 3 / Hạng 3 (Bên Phải) ──
          Expanded(
            flex: 10,
            child: _buildPodiumColumn(
              context,
              award: bronzes.isNotEmpty ? bronzes.first : null,
              extraAwards: bronzes.length > 1 ? bronzes.sublist(1) : const [],
              rank: 3,
              rankLabel: bronzes.length > 1 ? 'ĐỒNG HẠNG 3' : 'HẠNG 3',
              podiumHeight: 68,
              accentColor: const Color(0xFFEA580C),
              podiumGradient: const LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xFFFED7AA), Color(0xFFFFEDD5), Color(0xFFFFF7ED)],
              ),
              borderColor: const Color(0xFFFB923C),
              numberColor: const Color(0xFFC2410C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumColumn(
    BuildContext context, {
    required Map<String, dynamic>? award,
    List<Map<String, dynamic>> extraAwards = const [],
    required int rank,
    required String rankLabel,
    required double podiumHeight,
    required Color accentColor,
    required Gradient podiumGradient,
    required Color borderColor,
    required Color numberColor,
    bool isGold = false,
  }) {
    final colors = context.colors;
    final participant = award?['participant'] is Map
        ? Map<String, dynamic>.from(award!['participant'] as Map)
        : null;
    final teamName = participant?['teamName']?.toString() ?? 'Chưa xác định';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (participant != null) ...[
          // Crown icon for 1st place
          if (isGold)
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(bottom: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.star_rounded, color: Colors.white, size: 14),
            ),

          // Avatar display
          if (extraAwards.isNotEmpty)
            // Khi có đồng hạng (nhiều đội hạng 3): hiển thị 2 avatar cạnh nhau hoặc badge tie
            _buildTiePodiumAvatars(participant, extraAwards.first, accentColor)
          else
            _buildPodiumAvatar(participant, isGold ? 21 : 18, accentColor),
          const SizedBox(height: 6),

          // Tên đội / VĐV
          if (extraAwards.isNotEmpty) ...[
            // Đội 1
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                teamName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  height: 1.2,
                ),
              ),
            ),
            // Đội đồng hạng tiếp theo
            for (final extra in extraAwards) ...[
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  (extra['participant'] is Map
                          ? (extra['participant'] as Map)['teamName']
                          : null) ??
                      '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: colors.textSecondary,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                teamName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isGold ? 11.5 : 10.5,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  height: 1.2,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ] else ...[
          const SizedBox(height: 48),
        ],

        // Khối bục Podium
        Container(
          height: podiumHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: podiumGradient,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border.all(color: borderColor, width: isGold ? 1.5 : 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$rank',
                style: TextStyle(
                  fontSize: isGold ? 26 : 20,
                  fontWeight: FontWeight.w900,
                  color: numberColor,
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                child: Text(
                  rankLabel,
                  style: TextStyle(
                    fontSize: isGold ? 8.5 : 7.5,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTiePodiumAvatars(
    Map<String, dynamic> p1,
    Map<String, dynamic> p2Award,
    Color accentColor,
  ) {
    final p2 = p2Award['participant'] is Map
        ? Map<String, dynamic>.from(p2Award['participant'] as Map)
        : const <String, dynamic>{};

    return SizedBox(
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPodiumAvatar(p1, 15, accentColor),
          const SizedBox(width: 4),
          _buildPodiumAvatar(p2, 15, accentColor),
        ],
      ),
    );
  }

  Widget _buildPodiumAvatar(
    Map<String, dynamic> participant,
    double radius,
    Color ringColor,
  ) {
    final rawMembers = participant['members'];
    final members = rawMembers is List
        ? rawMembers
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList()
        : <Map<String, dynamic>>[];

    if (members.length >= 2) {
      return SizedBox(
        width: radius * 2 + 10,
        height: radius * 2,
        child: Stack(
          children: [
            Positioned(
              left: 10,
              child: _buildSingleAvatar(members[1], radius - 2, ringColor),
            ),
            Positioned(
              left: 0,
              child: _buildSingleAvatar(members[0], radius, ringColor),
            ),
          ],
        ),
      );
    }

    if (members.isNotEmpty) {
      return _buildSingleAvatar(members[0], radius, ringColor);
    }

    final name = participant['teamName']?.toString() ?? '?';
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ringColor.withValues(alpha: 0.12),
        border: Border.all(color: ringColor, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.w800,
          color: ringColor,
        ),
      ),
    );
  }

  Widget _buildSingleAvatar(
    Map<String, dynamic> member,
    double radius,
    Color ringColor,
  ) {
    final avatarUrl = member['avatarUrl']?.toString();
    final name = member['fullName']?.toString() ?? 'V';

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: 1.5),
        color: Colors.white,
      ),
      child: ClipOval(
        child: (avatarUrl != null && avatarUrl.isNotEmpty)
            ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _avatarFallback(name, ringColor),
              )
            : _avatarFallback(name, ringColor),
      ),
    );
  }

  Widget _avatarFallback(String name, Color color) {
    return Container(
      color: color.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildAwardCard(
    BuildContext context,
    Map<String, dynamic> award,
    int rank,
    String badgeTitle,
  ) {
    final colors = context.colors;
    final participant = award['participant'] is Map
        ? Map<String, dynamic>.from(award['participant'] as Map)
        : const <String, dynamic>{};
    final teamName = participant['teamName']?.toString() ?? 'Chưa xác định';

    final isGold = rank == 1;
    final isSilver = rank == 2;
    final isBronze = rank == 3 || rank == 4;

    final badgeColor = isGold
        ? const Color(0xFFF59E0B)
        : isSilver
            ? const Color(0xFF64748B)
            : isBronze
                ? const Color(0xFFEA580C)
                : const Color(0xFF64748B);

    final borderColor = isGold
        ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
        : isSilver
            ? const Color(0xFF94A3B8).withValues(alpha: 0.35)
            : isBronze
                ? const Color(0xFFEA580C).withValues(alpha: 0.35)
                : colors.border.withValues(alpha: 0.7);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: isGold ? 1.4 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Huy hiệu Rank Medal với màu nhận diện chuẩn thể thao
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: badgeColor.withValues(alpha: 0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Thông tin tên đội và danh hiệu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teamName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badgeTitle,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Avatar VĐV / Đội
          if (participant.isNotEmpty)
            _buildPodiumAvatar(participant, 17, badgeColor),
        ],
      ),
    );
  }
}
