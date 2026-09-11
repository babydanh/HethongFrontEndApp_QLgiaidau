part of '../screens/club_detail_screen.dart';

extension _ClubDetailPrivateView on _ClubDetailScreenState {
  Widget _buildPrivateLockView({
    required IconData icon,
    required String title,
    required String description,
    required Community club,
    required AppColorsExtension colors,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(icon, size: 38, color: const Color(0xFFD97706)),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        size: 14,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            if (!_isMember)
              Container(
                decoration: !_isPending
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF2563EB,
                            ).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      )
                    : null,
                child: FilledButton.icon(
                  onPressed: _isJoinLoading
                      ? null
                      : () => _handleJoinAction(club),
                  icon: Icon(_getJoinIcon(), size: 18),
                  label: Text(
                    _getJoinLabel(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _getJoinBgColor() ?? AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 13,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════
  //  TAB 3: THÀNH VIÊN
  // ════════════════════════════════════
}
