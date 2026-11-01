import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/social/screens/social_list_view.dart';
import 'package:app_quanly_giaidau/features/social/widgets/social_session_card_skeleton.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/social_provider.dart';
import 'package:app_quanly_giaidau/providers/user_location_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _QuietLocation extends UserLocationNotifier {
  @override
  UserLocationState build() =>
      const UserLocationState(status: UserLocationStatus.denied);
}

Widget _app() => ProviderScope(
  overrides: [
    userLocationProvider.overrideWith(_QuietLocation.new),
    filteredSocialSessionsProvider.overrideWithValue(const AsyncLoading()),
  ],
  child: MaterialApp(
    theme: AppTheme.lightTheme,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const Scaffold(body: SocialListView()),
  ),
);

void main() {
  testWidgets('social list shows session skeletons while sessions load', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(SocialSessionCardSkeleton), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
