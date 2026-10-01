import 'package:flutter/material.dart';

/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
///  RESPONSIVE ARCHITECTURE — Dùng chung cho toàn bộ app
///
///  🎯 Mục tiêu: Mọi màn hình đều responsive, không lỗi trên
///     mọi thiết bị (iPhone SE → iPad Pro 12.9")
///
///  📐 Nguyên tắc:
///    1. Grid → dùng [gridDelegate] (maxCrossAxisExtent)
///    2. Layout → dùng [AppResponsiveBuilder] + quyết định sidebar
///    3. Width → dùng % (clamp), không pixel cứng
///    4. Chiều cao banner → [AppResponsive.bannerHeight] (% CHIỀU CAO
///       viewport, khác nhau dọc/ngang), không pixel cứng; chữ banner →
///       [AppResponsive.bannerFontSize] để tỉ lệ chữ/banner không đổi giữa
///       mọi màn hình.
///    5. Font → Theme.of(context).textTheme
///
///  🚫 Desktop: app chỉ chạy mobile + tablet.
///     Desktop/web đã có frontend-web_qlgiaidau (Next.js) lo.
///
///  📱 Breakpoints:
///    < 600   → mobile  (iPhone SE, Galaxy, iPhone Pro Max)
///    600-839 → tablet nhỏ (Fold unfolded, iPad Mini)
///    ≥ 840   → tablet  (iPad Air, iPad Pro 11", 12.9")
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Danh sách các kích thước màn hình cho app (mobile + tablet).
enum ScreenSize {
  /// Màn hình điện thoại (< 600px)
  mobile,

  /// Tablet nhỏ / Foldable mở ra (600px - 839px)
  smallTablet,

  /// Tablet lớn (≥ 840px)
  tablet,
}

/// ─── Helper lấy ScreenSize từ width ───
ScreenSize getScreenSize(double width) {
  if (width < 600) return ScreenSize.mobile;
  if (width < 840) return ScreenSize.smallTablet;
  return ScreenSize.tablet;
}

/// ─── Breakpoints cho app (chỉ mobile + tablet) ───
class AppBreakpoints {
  /// Dưới ngưỡng này là mobile (< 600px)
  static const double mobileMax = 600;

  /// Trên ngưỡng này là tablet (≥ 840px)
  static const double tabletMin = 840;
}

/// ─── Các hằng số responsive dùng chung ───
class AppResponsive {
  // ── Grid ──
  /// Tự động tính số cột dựa trên kích thước màn hình.
  /// Dùng [maxCrossAxisExtent] thay vì [crossAxisCount].
  ///
  /// ```dart
  /// // ✅ Chuẩn — 1 dòng chạy mọi thiết bị
  /// GridView.builder(
  ///   gridDelegate: AppResponsive.gridDelegate(),
  ///   itemCount: teams.length,
  ///   itemBuilder: (_, i) => TournamentTeamCard(team: teams[i]),
  /// )
  /// ```
  static SliverGridDelegate gridDelegate({
    double maxExtent = 180,
    double ratio = 0.85,
    double spacing = 12,
  }) {
    return SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: maxExtent,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      childAspectRatio: ratio,
    );
  }

  // ── Padding ──
  /// Padding lề màn hình theo kích thước.
  /// Mobile: 12 | Tablet nhỏ: 16 | Tablet: 20
  static EdgeInsets padding(double width) {
    if (width >= AppBreakpoints.tabletMin) return const EdgeInsets.all(20);
    if (width >= AppBreakpoints.mobileMax) return const EdgeInsets.all(16);
    return const EdgeInsets.all(12);
  }

  // ── Sidebar ──
  /// Chiều rộng sidebar = 28% màn hình, giới hạn 220-360.
  static double sidebarWidth(double parentWidth,
      {double min = 220, double max = 360}) {
    return (parentWidth * 0.28).clamp(min, max);
  }

  /// Có nên hiển thị sidebar master-detail không?
  /// Chỉ hiển thị khi màn hình >= 840px (tablet to).
  static bool shouldShowSidebar(double width) =>
      width >= AppBreakpoints.tabletMin;

  // ── Font ──
  /// Kích thước chữ tiêu đề.
  /// Tablet: 24 | Mobile: 20
  static double titleFontSize(double width) =>
      width >= AppBreakpoints.tabletMin ? 24 : 20;

  /// Kích thước chữ nội dung.
  /// Tablet: 15 | Mobile: 14
  static double bodyFontSize(double width) =>
      width >= AppBreakpoints.tabletMin ? 15 : 14;

  // ── Card ──
  /// maxExtent cho grid card, tự động scale.
  static double cardExtent(double width) {
    if (width >= AppBreakpoints.tabletMin) return 200;
    if (width >= AppBreakpoints.mobileMax) return 180;
    return 160;
  }

  /// Tỉ lệ aspectRatio cho card (rộng/cao).
  static double cardRatio(double width) =>
      width >= AppBreakpoints.tabletMin ? 0.9 : 0.85;

  // ── Banner ──
  /// Tỉ lệ chiều cao banner / chiều cao viewport khi màn hình DỌC.
  ///
  /// Đây là hướng chiếm đa số (điện thoại, iPad cầm tay). Ở dọc, bề ngang mới
  /// là giới hạn chứ không phải bề dọc: 0.20 rút banner còn ~169px trên iPhone
  /// 14 (844px cao) — thấp hơn hẳn bản `AspectRatio(16/9)` cũ (~219px), nên
  /// giải nổi bật bị "bẹp". 0.30 → 253px: cao hơn bản cũ nhưng vẫn chỉ chiếm
  /// ~1/3 màn hình, phần danh sách bên dưới còn chỗ để thở.
  static const double bannerPortraitViewportRatio = 0.30;

  /// Tỉ lệ khi màn hình NẰM NGANG (rộng hơn cao) — laptop, tablet ngang.
  ///
  /// Ngang thì bề dọc mới là giới hạn. Giữ nguyên 0.20 vì đây chính là tỉ lệ
  /// đã chặn được `AspectRatio(16/9)`: bản cũ cho ra 750px = 97.7% chiều cao
  /// viewport ở 1366×768, tức banner gần như chiếm trọn màn hình.
  static const double bannerLandscapeViewportRatio = 0.20;

  /// Biên dưới: viewport quá thấp (điện thoại nằm ngang 390px cao → 20% là
  /// 78px) thì banner nhỏ hơn cả ô tiêu đề overlay nằm trên nó.
  ///
  /// Biên cũ `min: 200` đã bị bỏ có chủ ý: 768 × 0.20 = 154 < 200 sẽ bị đẩy
  /// ngược lên 200 = 26% màn hình — tức "huge" trên laptop 14".
  static const double bannerMinHeight = 140;

  /// Biên trên: CHỈ chặn viewport cao bất thường (>~1067px, ví dụ cửa sổ
  /// desktop 2160px), nơi 0.30 đã là 648px — nuốt gần hết màn hình.
  ///
  /// 320px giữ nguyên tỉ lệ 0.30 cho mọi thiết bị thật (iPhone SE → iPad Pro
  /// 12.9"), nên "banner chiếm cùng một tỉ lệ màn hình" vẫn đúng.
  static const double bannerMaxHeight = 320;

  /// Tỉ lệ cỡ chữ tiêu đề overlay / chiều cao banner
  /// (17px trên banner 185px cũ).
  static const double bannerTitleRatio = 0.092;

  /// Tỉ lệ cỡ chữ tiêu đề trong khối header / chiều cao banner
  /// (18px trên banner 185px, 24px trên cover 240px).
  static const double bannerHeadlineRatio = 0.10;

  /// Tỉ lệ cỡ chữ phụ trên banner / chiều cao banner
  /// (10px trên banner 185px cũ).
  static const double bannerCaptionRatio = 0.054;

  /// Chiều cao banner = tỉ lệ theo hướng màn hình × chiều cao viewport,
  /// giới hạn [bannerMinHeight]–[bannerMaxHeight].
  ///
  /// - [viewportWidth] — quyết định nhánh dọc/ngang. Bỏ trống thì coi như DỌC
  ///   vì đó là hướng phổ biến của app; call site quên truyền chỉ lệch ở
  ///   chế độ ngang, không vỡ layout.
  ///
  /// ⚠️ Mọi thứ bám theo chiều cao này, kể cả chữ: [bannerFontSize] nhân
  /// thẳng [bannerHeight] với [bannerTitleRatio]/[bannerHeadlineRatio]/
  /// [bannerCaptionRatio]. TUYỆT ĐỐI không lấy chiều cao banner từ nguồn khác
  /// (một nhánh riêng theo hướng chẳng hạn) — banner sẽ cao lên trong khi
  /// chữ giữ nguyên cỡ cũ, và không có dòng cảnh báo nào báo lỗi.
  ///
  /// ```dart
  /// final size = MediaQuery.sizeOf(context);
  /// SizedBox(
  ///   height: AppResponsive.bannerHeight(size.height, viewportWidth: size.width),
  ///   width: double.infinity,
  ///   child: Image.network(url, fit: BoxFit.cover),
  /// )
  /// ```
  static double bannerHeight(
    double viewportHeight, {
    double? viewportWidth,
    double min = bannerMinHeight,
    double max = bannerMaxHeight,
  }) {
    final isLandscape = viewportWidth != null && viewportWidth > viewportHeight;
    final ratio =
        isLandscape ? bannerLandscapeViewportRatio : bannerPortraitViewportRatio;
    return (viewportHeight * ratio).clamp(min, max);
  }

  /// Cỡ chữ trong banner — scale TUYẾN TÍNH theo [bannerHeight].
  ///
  /// Vì [bannerHeight] đã clamp trước, quan hệ
  /// `bannerFontSize(vh) / bannerHeight(vh) == ratio` đúng tuyệt đối ở
  /// MỌI kích thước viewport: banner cao gấp đôi thì chữ to gấp đôi. Đây là
  /// điều kiện để tỉ lệ chữ/banner không đổi giữa 14" và 16", và cả giữa
  /// chế độ dọc với chế độ ngang. Vì vậy [viewportWidth] phải truyền giống
  /// hệt giá trị mà call site dùng cho [bannerHeight].
  ///
  /// - [bannerTitleRatio] — tiêu đề overlay nằm TRÊN ảnh banner.
  /// - [bannerHeadlineRatio] — tiêu đề trong khối header cạnh/dưới banner.
  static double bannerFontSize(
    double viewportHeight, {
    double? viewportWidth,
    double ratio = bannerTitleRatio,
  }) {
    return bannerHeight(viewportHeight, viewportWidth: viewportWidth) * ratio;
  }

  // ── Spacing ──
  /// Khoảng cách giữa các section.
  static double sectionSpacing(double width) =>
      width >= AppBreakpoints.tabletMin ? 32 : 24;

  /// Khoảng cách giữa các item trong cùng 1 section.
  static double itemSpacing(double width) =>
      width >= AppBreakpoints.tabletMin ? 16 : 12;
}

/// ─── Kiểm tra kích thước màn hình (dùng trong build) ───
extension ScreenSizeCheck on BuildContext {
  /// Màn hình hiện tại có phải là mobile không?
  bool get isMobile =>
      MediaQuery.sizeOf(this).width < AppBreakpoints.mobileMax;

  /// Màn hình hiện tại có phải là tablet nhỏ không?
  bool get isSmallTablet {
    final w = MediaQuery.sizeOf(this).width;
    return w >= AppBreakpoints.mobileMax && w < AppBreakpoints.tabletMin;
  }

  /// Màn hình hiện tại có phải là tablet không?
  bool get isTablet =>
      MediaQuery.sizeOf(this).width >= AppBreakpoints.tabletMin;

  /// Trả về [ScreenSize] tương ứng.
  ScreenSize get screenSize =>
      getScreenSize(MediaQuery.sizeOf(this).width);
}

/// ─── Widget Builder chứa sẵn ScreenSize ───
///
/// Sử dụng cho các màn hình cần phân biệt layout rõ rệt.
///
/// ```dart
/// AppResponsiveBuilder(builder: (context, size, constraints) {
///   if (size == ScreenSize.mobile || size == ScreenSize.smallTablet) {
///     return _buildMobileLayout(constraints);
///   }
///   return _buildTabletLayout(constraints);
/// })
/// ```
class AppResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenSize size, BoxConstraints constraints) builder;

  const AppResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = getScreenSize(constraints.maxWidth);
      return builder(context, size, constraints);
    });
  }
}

/// ─── Responsive Row (tự động xuống dòng) ───
///
/// Khi màn hình hẹp, các item tự động xuống hàng thay vì tràn.
/// Dùng cho info strip, action buttons, filter chips.
///
/// ```dart
/// ResponsiveWrap(
///   spacing: 8, runSpacing: 6,
///   children: [chip1, chip2, chip3, chip4],
/// )
/// ```
class ResponsiveWrap extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final WrapAlignment alignment;

  const ResponsiveWrap({
    super.key,
    required this.children,
    this.spacing = 8,
    this.runSpacing = 6,
    this.alignment = WrapAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      alignment: alignment,
      children: children,
    );
  }
}

/// ─── Responsive Grid (tự động số cột) ───
///
/// ```dart
/// ResponsiveGrid(
///   maxExtent: 180,
///   ratio: 0.85,
///   itemCount: teams.length,
///   itemBuilder: (_, i) => TournamentTeamCard(team: teams[i]),
/// )
/// ```
class ResponsiveGrid extends StatelessWidget {
  final double maxExtent;
  final double ratio;
  final double spacing;
  final int itemCount;
  final NullableIndexedWidgetBuilder itemBuilder;

  const ResponsiveGrid({
    super.key,
    this.maxExtent = 180,
    this.ratio = 0.85,
    this.spacing = 12,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxExtent,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: ratio,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
    );
  }
}
