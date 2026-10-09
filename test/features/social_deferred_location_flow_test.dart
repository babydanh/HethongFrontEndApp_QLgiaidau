import 'package:app_quanly_giaidau/data/models/social_place.dart';
import 'package:app_quanly_giaidau/features/social/screens/create_social_screen.dart';
import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/social_location_flow.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('create button explains a missing location', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoriesProvider.overrideWith((ref) async => [
            CategoryModel(
              id: 'sport-1',
              name: 'Pickleball',
              slug: 'pickleball',
              description: '',
              isActive: true,
            ),
          ]),
        ],
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: CreateSocialScreen(clubId: 'club-1', clubName: 'CLB'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tạo buổi giao lưu').last);
    await tester.pump();
    expect(
      find.text("Vui lòng chọn địa điểm hoặc 'Quyết định sau'."),
      findsOneWidget,
    );
  });

  testWidgets('location picker offers Decide later', (tester) async {
    SocialPlace? result;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async =>
                    result = await SocialLocationFlow.show(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quyết định sau'));
    await tester.pumpAndSettle();
    expect(result?.isDeferred, isTrue);
    expect(result?.hasPin, isFalse);
  });
}
