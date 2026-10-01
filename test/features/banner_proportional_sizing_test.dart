import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/app_responsive.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/home/widgets/featured_tournament_banner_card.dart';
import 'package:app_quanly_giaidau/features/home/widgets/tournament_card_with_banner.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Banner trước đây cao cứng 185px nên chiếm 24.1% màn hình laptop 14"
/// (1366×768) nhưng chỉ 17.1% trên 16" (1920×1080). Bộ test này khoá lại
/// hợp đồng mới: banner = % CHIỀU CAO viewport, NHƯNG khác nhau theo hướng
/// màn hình — DỌC 30%, NGANG 20% — và chữ trong banner scale theo đúng chiều
/// cao đó nên tỉ lệ chữ/banner không đổi giữa hai máy lẫn giữa hai hướng.
const _laptop14 = Size(1366, 768);
const _laptop16 = Size(1920, 1080);
const _phonePortrait = Size(390, 844);
const _phoneLandscape = Size(844, 390);
const _tabletPortrait = Size(768, 1024);

void main() {
  group('AppResponsive.bannerHeight', () {
    test('màn hình nằm ngang vẫn chiếm đúng 20% chiều cao ở cả 14" và 16"', () {
      final h14 = AppResponsive.bannerHeight(
        _laptop14.height,
        viewportWidth: _laptop14.width,
      );
      final h16 = AppResponsive.bannerHeight(
        _laptop16.height,
        viewportWidth: _laptop16.width,
      );

      expect(h14 / _laptop14.height, closeTo(0.20, 1e-9));
      expect(h16 / _laptop16.height, closeTo(0.20, 1e-9));

      // Đây là điều cũ đã hỏng: 185px cho tỉ lệ 24.1% vs 17.1%.
      expect(h14, closeTo(153.6, 1e-9));
      expect(h16, 216.0);
      expect(
        h14 / _laptop14.height,
        closeTo(h16 / _laptop16.height, 1e-12),
      );
    });

    test('màn hình dọc cao hơn hẳn, và không thấp hơn bản AspectRatio(16/9) cũ', () {
      // 20% của 844 chỉ là 169px — THẤP HƠN bản 16/9 cũ (~219px), đó là lý do
      // banner bị bẹp. Dọc nay lấy 30% = 253px, cao hơn cả bản cũ.
      final phone = AppResponsive.bannerHeight(
        _phonePortrait.height,
        viewportWidth: _phonePortrait.width,
      );
      expect(phone, closeTo(253.2, 1e-9));
      expect(phone / _phonePortrait.height, closeTo(0.30, 1e-9));
      expect(phone, greaterThan(_phonePortrait.width * 9 / 16));

      // iPad dọc 1024px: 30% = 307px, vẫn nằm trong vùng không bị clamp.
      expect(
        AppResponsive.bannerHeight(
          _tabletPortrait.height,
          viewportWidth: _tabletPortrait.width,
        ),
        closeTo(307.2, 1e-9),
      );
    });

    test('cùng một máy, hai hướng thì hai chiều cao khác nhau', () {
      final portrait = AppResponsive.bannerHeight(
        _phonePortrait.height,
        viewportWidth: _phonePortrait.width,
      );
      final landscape = AppResponsive.bannerHeight(
        _phoneLandscape.height,
        viewportWidth: _phoneLandscape.width,
      );

      expect(portrait, closeTo(253.2, 1e-9));
      expect(landscape, AppResponsive.bannerMinHeight);
      expect(portrait, greaterThan(landscape));
    });

    test('bỏ trống viewportWidth thì coi như dọc, không vỡ layout', () {
      expect(
        AppResponsive.bannerHeight(_phonePortrait.height),
        AppResponsive.bannerHeight(
          _phonePortrait.height,
          viewportWidth: _phonePortrait.width,
        ),
      );
    });

    test('clamp giữ banner hợp lý trên viewport thấp và màn hình rất cao', () {
      // Điện thoại nằm ngang 390px cao: 20% là 78px, quá nhỏ → nâng lên 140.
      expect(
        AppResponsive.bannerHeight(
          _phoneLandscape.height,
          viewportWidth: _phoneLandscape.width,
        ),
        AppResponsive.bannerMinHeight,
      );
      // Màn hình 2160px cao: 30% là 648px, nuốt gần hết màn hình → hạ về 320.
      expect(AppResponsive.bannerHeight(2160), AppResponsive.bannerMaxHeight);
    });
  });

  group('AppResponsive.bannerFontSize', () {
    test('giữ nguyên tỉ lệ chữ/banner giữa 14" và 16"', () {
      for (final ratio in [
        AppResponsive.bannerTitleRatio,
        AppResponsive.bannerHeadlineRatio,
        AppResponsive.bannerCaptionRatio,
      ]) {
        final font14 = AppResponsive.bannerFontSize(
          _laptop14.height,
          viewportWidth: _laptop14.width,
          ratio: ratio,
        );
        final font16 = AppResponsive.bannerFontSize(
          _laptop16.height,
          viewportWidth: _laptop16.width,
          ratio: ratio,
        );

        expect(
          font14 /
              AppResponsive.bannerHeight(
                _laptop14.height,
                viewportWidth: _laptop14.width,
              ),
          closeTo(ratio, 1e-9),
        );
        expect(
          font16 /
              AppResponsive.bannerHeight(
                _laptop16.height,
                viewportWidth: _laptop16.width,
              ),
          closeTo(ratio, 1e-9),
        );
        // Trước đây 17px bất biến: 17/185 = 9.19% vs 17/240 = 7.08%.
        expect(font16, greaterThan(font14));
      }
    });

    test('cỡ chữ tiêu đề tăng tuyến tính theo chiều cao banner', () {
      expect(
        AppResponsive.bannerFontSize(
          _laptop14.height,
          viewportWidth: _laptop14.width,
        ),
        closeTo(14.1312, 1e-9),
      );
      expect(
        AppResponsive.bannerFontSize(
          _laptop16.height,
          viewportWidth: _laptop16.width,
        ),
        closeTo(19.872, 1e-9),
      );
    });

    test('banner dọc cao lên thì chữ cũng to lên đúng tỉ lệ', () {
      // Container và chữ phải cùng nhảy. Nếu chiều cao banner lấy từ một nhánh
      // riêng theo hướng trong khi chữ vẫn gọi bannerHeight cũ, ta sẽ có banner
      // cao mà chữ nhỏ — không lỗi biên dịch nào bắt được. Test này là chốt.
      final portrait = AppResponsive.bannerFontSize(
        _phonePortrait.height,
        viewportWidth: _phonePortrait.width,
      );
      final landscape = AppResponsive.bannerFontSize(
        _laptop14.height,
        viewportWidth: _laptop14.width,
      );

      expect(portrait, closeTo(23.2944, 1e-9));
      expect(portrait, greaterThan(landscape));
      expect(
        portrait /
            AppResponsive.bannerHeight(
              _phonePortrait.height,
              viewportWidth: _phonePortrait.width,
            ),
        closeTo(AppResponsive.bannerTitleRatio, 1e-12),
      );
    });
  });

  group('banner render ở kích thước thật', () {
    Future<void> pumpAt(WidgetTester tester, Size surface) async {
      tester.view.physicalSize = surface;
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: FeaturedTournamentBannerCard(
                tournament: _tournament,
                onTap: _noop,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('featured banner chiếm 20% chiều cao viewport ở 1366×768', (
      tester,
    ) async {
      await pumpAt(tester, _laptop14);

      final size = tester.getSize(find.byType(FeaturedTournamentBannerCard));
      expect(size.width, _laptop14.width);
      expect(size.height / _laptop14.height, closeTo(0.20, 1e-6));
      expect(size.height, closeTo(153.6, 1e-6));

      // Trước đây AspectRatio(16/9) cho ra 750px = 97.7% chiều cao viewport.
      expect(size.height, lessThan(_laptop14.height / 2));
    });

    testWidgets('featured banner chiếm 20% chiều cao viewport ở 1920×1080', (
      tester,
    ) async {
      await pumpAt(tester, _laptop16);

      final size = tester.getSize(find.byType(FeaturedTournamentBannerCard));
      expect(size.width, _laptop16.width);
      expect(size.height / _laptop16.height, closeTo(0.20, 1e-6));
      expect(size.height, closeTo(216.0, 1e-6));
    });

    testWidgets('featured banner dọc cao hơn hẳn: 30% chiều cao ở 390×844', (
      tester,
    ) async {
      await pumpAt(tester, _phonePortrait);

      final size = tester.getSize(find.byType(FeaturedTournamentBannerCard));
      expect(size.width, _phonePortrait.width);
      expect(size.height, closeTo(253.2, 1e-6));
      expect(size.height / _phonePortrait.height, closeTo(0.30, 1e-6));

      // Bản 20% cũ chỉ cho 168.8px — thấp hơn cả bản AspectRatio(16/9) cũ
      // (~219px) mà người dùng kêu "hồi trước cao thêm, giờ thấp lại".
      expect(size.height, greaterThan(_phonePortrait.width * 9 / 16));
    });

    testWidgets('chữ trên banner dọc to lên cùng banner, không giữ cỡ cũ', (
      tester,
    ) async {
      await pumpAt(tester, _phonePortrait);
      final portraitBox = tester.getSize(
        find.byType(FeaturedTournamentBannerCard),
      );
      final portraitFont = tester
          .widget<Text>(find.text(_tournament.name))
          .style!
          .fontSize!;

      await pumpAt(tester, _laptop14);
      final landscapeBox = tester.getSize(
        find.byType(FeaturedTournamentBannerCard),
      );
      final landscapeFont = tester
          .widget<Text>(find.text(_tournament.name))
          .style!
          .fontSize!;

      expect(portraitFont, greaterThan(landscapeFont));
      expect(portraitFont / portraitBox.height, closeTo(0.092, 1e-6));
      expect(landscapeFont / landscapeBox.height, closeTo(0.092, 1e-6));
    });

    testWidgets('chữ trên banner scale theo banner giữa 14" và 16"', (
      tester,
    ) async {
      await pumpAt(tester, _laptop14);
      final box14 = tester.getSize(find.byType(FeaturedTournamentBannerCard));
      final font14 = tester
          .widget<Text>(find.text(_tournament.name))
          .style!
          .fontSize!;

      await pumpAt(tester, _laptop16);
      final box16 = tester.getSize(find.byType(FeaturedTournamentBannerCard));
      final font16 = tester
          .widget<Text>(find.text(_tournament.name))
          .style!
          .fontSize!;

      expect(font16, greaterThan(font14));
      // Tỉ lệ chữ/banner phải BẰNG NHAU, không phải chỉ "cùng chiều hướng".
      expect(font14 / box14.height, closeTo(0.092, 1e-6));
      expect(font16 / box16.height, closeTo(0.092, 1e-6));
      expect(font14 / box14.height, equals(font16 / box16.height));
    });

    testWidgets('card danh sách giải ở home dùng cùng tỉ lệ 20%', (
      tester,
    ) async {
      for (final surface in [_laptop14, _laptop16]) {
        tester.view.physicalSize = surface;
        tester.view.devicePixelRatio = 1;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: TournamentCardWithBanner(
                    tournament: _tournament,
                    onTap: _noop,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final banner = tester.getSize(
          find.descendant(
            of: find.byType(TournamentCardWithBanner),
            matching: find.byType(SizedBox),
          ).first,
        );
        expect(
          banner.height / surface.height,
          closeTo(0.20, 1e-6),
          reason: 'banner height phải bám viewport tại $surface',
        );
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}

void _noop() {}

final _tournament = Tournament(
  id: 'synthetic-tournament',
  name: 'Synthetic tournament',
  sport: 'pickleball',
  format: 'single_elimination',
  bracketType: 'SINGLE_ELIMINATION',
  status: 'registration',
  adminToken: '',
  refereeToken: '',
  viewerToken: '',
  creatorId: 'synthetic-user',
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
  startDate: DateTime.utc(2026, 10, 1),
);
