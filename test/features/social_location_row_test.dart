import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/social_place.dart';
import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/social_location_row.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpRow(
    WidgetTester tester, {
    SocialPlace? place,
    Locale locale = const Locale('en'),
    VoidCallback? onTap,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 280,
            child: SocialLocationRow(place: place, onTap: onTap ?? () {}),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'shows one actionable localized placeholder with no coordinates',
    (tester) async {
      var taps = 0;
      await pumpRow(tester, onTap: () => taps++);
      expect(find.text('Select location'), findsOneWidget);
      await tester.tap(find.byType(SocialLocationRow));
      expect(taps, 1);
      await pumpRow(tester, locale: const Locale('vi'));
      expect(find.text('Chọn địa điểm'), findsOneWidget);
    },
  );

  testWidgets(
    'shows a saved name and long address without overflow or coordinates',
    (tester) async {
      await pumpRow(
        tester,
        place: const SocialPlace(
          name: 'Nhà thi đấu Phú Thọ',
          formattedAddress:
              '1 Lữ Gia, Quận 11, Thành phố Hồ Chí Minh, Việt Nam, một địa chỉ rất dài',
          latitude: 10.762,
          longitude: 106.657,
        ),
      );
      expect(find.text('Nhà thi đấu Phú Thọ'), findsOneWidget);
      expect(find.textContaining('1 Lữ Gia'), findsOneWidget);
      expect(find.textContaining('10.762'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
