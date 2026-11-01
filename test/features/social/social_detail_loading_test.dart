import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/skeleton/list_skeletons.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/features/social/screens/social_detail_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/social_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Never finishes loading, so the screen stays in its loading state.
class _HangingDetail extends SocialSessionDetailNotifier {
  _HangingDetail(super.sessionId);

  @override
  Future<SocialSessionModel> build() => Completer<SocialSessionModel>().future;
}

void main() {
  testWidgets('social detail shows a page skeleton while the session loads', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [socialSessionDetailProvider.overrideWith2(_HangingDetail.new)],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SocialDetailScreen(sessionId: 'session-1'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(DetailPageSkeleton), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
