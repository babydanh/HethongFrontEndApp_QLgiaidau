import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/social/screens/create_social_screen.dart';
import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/social_location_row.dart';
import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/social_setting_tile.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

const _locationError = "Vui lòng chọn địa điểm hoặc 'Quyết định sau'.";

Widget _app(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('TC-SOCIAL-FORM-01 location row shows its error text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        SocialLocationRow(
          place: null,
          onTap: () {},
          errorText: _locationError,
        ),
      ),
    );
    expect(find.text(_locationError), findsOneWidget);
  });

  testWidgets('TC-SOCIAL-FORM-02 setting tile shows its error text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        SocialSettingTile(
          icon: Icons.calendar_month_outlined,
          label: 'Ngày giờ',
          onTap: () {},
          errorText: 'Chọn giờ trong tương lai',
        ),
      ),
    );
    expect(find.text('Chọn giờ trong tương lai'), findsOneWidget);
  });

  testWidgets('TC-SOCIAL-FORM-03 tiles show no error text by default', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            SocialLocationRow(place: null, onTap: () {}),
            SocialSettingTile(icon: Icons.lock, label: 'X', onTap: () {}),
          ],
        ),
      ),
    );
    expect(find.text(_locationError), findsNothing);
  });

  testWidgets(
    'TC-SOCIAL-FORM-04 submit with no location marks the location row red',
    (tester) async {
      await tester.pumpWidget(
        _app(
          const CreateSocialScreen(clubId: 'club-1', clubName: 'CLB'),
          overrides: [
            categoriesProvider.overrideWith(
              (ref) async => [
                CategoryModel(
                  id: 'sport-1',
                  name: 'Pickleball',
                  slug: 'pickleball',
                  description: '',
                  isActive: true,
                ),
              ],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final rowError = find.descendant(
        of: find.byType(SocialLocationRow),
        matching: find.text(_locationError),
      );
      expect(rowError, findsNothing);

      await tester.tap(find.text('Tạo buổi giao lưu').last);
      await tester.pumpAndSettle();

      expect(rowError, findsOneWidget);
    },
  );
}
