import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/pickleball_court_3d_animated.dart';
import 'package:app_quanly_giaidau/core/widgets/pickleball_rally_animation.dart';
import 'package:app_quanly_giaidau/core/widgets/sporto_loading_widget.dart';
import 'package:app_quanly_giaidau/core/widgets/app_icons.dart';

/// Màn hình Trình diễn và Thử nghiệm các Hoạt họa Loading Thể Thao SportO:
/// Cho phép người dùng trực tiếp xem và chọn mẫu loading ưng ý nhất.
class LoadingShowcaseScreen extends StatefulWidget {
  const LoadingShowcaseScreen({super.key});

  @override
  State<LoadingShowcaseScreen> createState() => _LoadingShowcaseScreenState();
}

class _LoadingShowcaseScreenState extends State<LoadingShowcaseScreen> {
  int _selectedTab = 0; // 0: Rally, 1: Court 3D, 2: Orbit, 3: Bounce
  static SportoLoadingVariant activeAppVariant = SportoLoadingVariant.rally;

  final List<
    ({
      String id,
      String title,
      String subtitle,
      String badge,
      String description,
      SportoLoadingVariant variant,
    })
  >
  _models = [
    (
      id: 'rally',
      title: 'Pickleball Rally Pro',
      subtitle: 'Trận Đấu Vợt Đập Bóng Qua Lưới',
      badge: 'KHUYÊN DÙNG ⭐',
      description:
          '2 cây vợt chuẩn carbon (Team Xanh & Cam) vung đập đối kháng qua lưới. Quả bóng bay theo đường cong parabol tự nhiên với vệt sáng năng lượng và tia lửa khi chạm vợt.',
      variant: SportoLoadingVariant.rally,
    ),
    (
      id: 'court3d',
      title: 'Sân Đấu 3D Isometric',
      subtitle: 'Bóng Nảy To Ra Nhỏ Lại Trên Sân 3D',
      badge: 'CÔNG NGHỆ 3D',
      description:
          'Khối sân 3D Isometric vẽ 100% bằng code vector, mặt sân men bóng sang trọng. Bóng nảy vút lên gần người xem (To ra 1.75x) rồi rơi xuống đập sân tạo sóng xung kích Neon.',
      variant: SportoLoadingVariant.court3d,
    ),
    (
      id: 'orbit',
      title: 'SportO Kinetic Orbit',
      subtitle: 'Phong Cách Nike & ESPN Tối Giản',
      badge: 'HIỆN ĐẠI',
      description:
          'Vòng xoay quỹ đạo năng lượng kép bao bọc Logo SportO chính thức nhịp thở hô hấp. Tinh tế, nhẹ nhàng và chuẩn nhận diện thương hiệu.',
      variant: SportoLoadingVariant.orbit,
    ),
    (
      id: 'bounce',
      title: 'Smash & Bounce Extreme',
      subtitle: 'Quả Bóng Neon Đàn Hồi Cực Đỉnh',
      badge: 'ĐÀN HỒI',
      description:
          'Bóng Pickleball nảy tưng bừng với hiệu ứng bẹp dãn đàn hồi Squash & Stretch chuẩn 12 nguyên lý hoạt hình Disney, sóng chấn động lan tỏa dưới sàn.',
      variant: SportoLoadingVariant.bounce,
    ),
  ];

  void _applyModel(SportoLoadingVariant variant) {
    HapticFeedback.mediumImpact();
    setState(() {
      activeAppVariant = variant;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(AppIcons.checkCircle, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Đã áp dụng "${_models[_selectedTab].title}" làm Loading của ứng dụng!',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _models[_selectedTab];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(AppIcons.chevronLeft, color: Color(0xFF0F172A)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text(
          'Màn Trình Diễn Loading Thể Thao',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ─── THANH CHỌN MẪU (TABS) ───
            Container(
              height: 48,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: List.generate(_models.length, (index) {
                  final isSelected = _selectedTab == index;
                  final item = _models[index];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedTab = index);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          item.id.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected
                                ? AppTheme.primary
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // ─── KHU VỰC PREVIEW ANIMATION TOÀN MÀN HÌNH ───
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Badge nhãn
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        current.badge,
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      current.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      current.subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),

                    const SizedBox(height: 8),
                    Center(
                      child: switch (_selectedTab) {
                        0 => const PickleballRallyAnimation(
                          width: 270,
                          height: 140,
                          message: 'Đang tải giải đấu sôi động...',
                        ),
                        1 => const Pickleball3DCourtAnimation(
                          size: 190,
                          message: 'Đang khởi tạo sân thi đấu...',
                        ),
                        2 => const SportoLoadingWidget(
                          size: 120,
                          variant: SportoLoadingVariant.orbit,
                          message: 'Đang kết nối hệ thống SportO...',
                        ),
                        3 => const SportoLoadingWidget(
                          size: 120,
                          variant: SportoLoadingVariant.bounce,
                          message: 'Đang chuẩn bị giao bóng...',
                        ),
                        _ => const SizedBox.shrink(),
                      },
                    ),

                    const Spacer(),

                    // Mô tả chi tiết
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            AppIcons.info,
                            size: 18,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              current.description,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF475569),
                                height: 1.35,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── NÚT HÀNH ĐỘNG ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _applyModel(current.variant),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(AppIcons.checkCircle, size: 20),
                  label: Text(
                    'Áp Dụng "${current.title}" Cho App',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
