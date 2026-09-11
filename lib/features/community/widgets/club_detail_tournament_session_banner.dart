part of '../screens/club_detail_screen.dart';

class _ClubSessionAthleticBanner extends StatelessWidget {
  final bool isDark;
  final bool isSessionClosed;
  final List<Color> bannerGradient;
  final String sportWatermarkText;
  final IconData sportIconData;
  final String sportName;
  final Color badgeBg;
  final Color badgeBorder;
  final Color badgeTextColor;
  final Color statusDotColor;
  final String statusText;

  const _ClubSessionAthleticBanner({
    required this.isDark,
    required this.isSessionClosed,
    required this.bannerGradient,
    required this.sportWatermarkText,
    required this.sportIconData,
    required this.sportName,
    required this.badgeBg,
    required this.badgeBorder,
    required this.badgeTextColor,
    required this.statusDotColor,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    return
    // ─── Athletic Sport Banner Cover ───
    SizedBox(
      height: 140,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Gradient nền thể thao rực rỡ
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isSessionClosed
                    ? [
                        const Color(0xFF64748B),
                        const Color(0xFF475569),
                        const Color(0xFF334155),
                      ]
                    : bannerGradient,
              ),
            ),
          ),

          // Ambient Glow Shapes
          Positioned(
            top: -24,
            right: -24,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -20,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),

          // Sport Court lines / Geometry overlay
          CustomPaint(size: Size.infinite, painter: _AthleticBannerPainter()),

          // Large Athletic Sport Watermark Text (Right)
          Positioned(
            right: 12,
            top: 24,
            bottom: 24,
            child: Align(
              alignment: Alignment.centerRight,
              child: Transform.rotate(
                angle: -0.06,
                child: Text(
                  sportWatermarkText,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -1,
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
              ),
            ),
          ),

          // Center SportO Vector Brandmark Logo
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  AppConstants.logoFullSvg,
                  width: 120,
                  fit: BoxFit.contain,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        sportName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: 0.88),
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                    Container(
                      width: 20,
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom Shadow Overlay for Badge & Label Readability
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 50,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.45),
                  ],
                ),
              ),
            ),
          ),

          // Top Badges (Status & Giao lưu CLB)
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Row(
              children: [
                // Status pill badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : badgeBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? badgeBorder.withValues(alpha: 0.4)
                          : badgeBorder,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusDotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: badgeTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                // Badge GIAO LƯU CLB
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Text(
                    'GIAO LƯU CLB',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom chip trên banner: Thể thao / Môn thi
          Positioned(
            left: 10,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(sportIconData, size: 11, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    sportName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
