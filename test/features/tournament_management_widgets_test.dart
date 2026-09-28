import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('403 management errors show a forbidden state without retry', (
    tester,
  ) async {
    var retried = false;
    final requestOptions = RequestOptions(path: '/management');
    final error = DioException(
      requestOptions: requestOptions,
      response: Response<dynamic>(
        requestOptions: requestOptions,
        statusCode: 403,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: TournamentManagementError(
            error: error,
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(
      find.text(
        'You do not have permission to access this management section.',
      ),
      findsOneWidget,
    );
    expect(find.byType(OutlinedButton), findsNothing);
    expect(retried, isFalse);
  });
}
