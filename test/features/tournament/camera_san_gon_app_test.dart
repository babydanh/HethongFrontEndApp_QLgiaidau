import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/data/models/match_recording_catalog_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/court_camera_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/facebook_camera_live_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_recording_catalog_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_camera_section.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/schedule_court_label.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_editor_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_list_section.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/court_count_stepper.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/court_camera_provider.dart';
import 'package:app_quanly_giaidau/providers/match_recording_catalog_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// TC-CAMTAB-APP-01..05: Camera tab keeps "+" without courts, camera block on
/// top, "Sân N" label. TC-COURT-LABEL-APP-01: courtDisplayName.
/// TC-COURT-STEP-APP-01..03: CourtCountStepper.
class _Venues implements TournamentManagementRepository {
  _Venues(this.courts, {this.gate});

  final List<Map<String, dynamic>> courts;

  /// When set, getVenues waits for it: the "still loading" state.
  final Completer<void>? gate;

  @override
  Future<List<Map<String, dynamic>>> getVenues(String id) async {
    await gate?.future;
    return [
      {'name': 'Nhà thi đấu', 'courts': courts},
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Cameras implements ICourtCameraRepository {
  @override
  Future<List<TournamentCameraModel>> listCameras(String tournamentId) async =>
      const [
        TournamentCameraModel(
          id: 'cam-1',
          name: 'Camera 1',
          mode: 'PULL',
          status: 'IDLE',
          courtId: 'court-1',
          playbackUrl: 'https://p.example/1.m3u8',
        ),
      ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Live implements IFacebookCameraLiveRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Catalog implements IMatchRecordingCatalogRepository {
  @override
  Future<List<MatchLivestreamSummary>> listTournamentMatchLivestreams(
    String tournamentId,
  ) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _courtOne = {'id': 'court-1', 'name': 'Sân 1'};

Widget _app(Widget home, {List<Override> overrides = const []}) => ProviderScope(
  overrides: overrides,
  child: MaterialApp(
    theme: AppTheme.lightTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('vi'),
    home: Scaffold(body: home),
  ),
);

Future<void> _pumpTab(
  WidgetTester tester,
  _Venues venues, {
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    _app(
      const TournamentManagementCameraSection(tournamentId: 't1'),
      overrides: [
        tournamentManagementRepositoryProvider.overrideWithValue(venues),
        courtCameraRepositoryProvider.overrideWithValue(_Cameras()),
        matchRecordingCatalogRepositoryProvider.overrideWithValue(_Catalog()),
        facebookCameraLiveRepositoryProvider.overrideWithValue(_Live()),
        managedMatchesWithDivisionProvider.overrideWith(
          (ref, args) => Stream.value(const <MatchModel>[]),
        ),
      ],
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

IconButton _plus(WidgetTester tester) => tester.widget<IconButton>(
  find.byWidgetPredicate(
    (widget) => widget is IconButton && widget.tooltip == 'Tạo camera',
  ),
);

Future<List<int>> _pumpStepper(
  WidgetTester tester, {
  int initialValue = 1,
}) async {
  final values = <int>[];
  await tester.pumpWidget(
    _app(
      Center(
        child: CourtCountStepper(
          fieldKey: const ValueKey('count'),
          initialValue: initialValue,
          onChanged: values.add,
        ),
      ),
    ),
  );
  return values;
}

String _countText(WidgetTester tester) =>
    tester.widget<TextField>(find.byKey(const ValueKey('count'))).controller!.text;

void main() {
  group('courtDisplayName', () {
    test('TC-COURT-LABEL-APP-01 digits-only names get the Sân prefix', () {
      expect(courtDisplayName('3'), 'Sân 3');
      expect(courtDisplayName(' 12 '), 'Sân 12');
      expect(courtDisplayName('Sân 3'), 'Sân 3');
      expect(courtDisplayName('Court A'), 'Court A');
      expect(courtDisplayName('3A'), '3A');
      expect(courtDisplayName(''), '');
    });
  });

  testWidgets('TC-CAMTAB-APP-01 no court: + stays, tap says add a court first '
      'and opens no form', (tester) async {
    await _pumpTab(tester, _Venues(const []));

    expect(find.byTooltip('Tạo camera'), findsOneWidget);
    await tester.tap(find.byTooltip('Tạo camera'));
    await tester.pumpAndSettle();

    expect(find.text('Thêm sân trước khi tạo camera'), findsOneWidget);
    expect(find.byType(CameraEditorSheet), findsNothing);
  });

  testWidgets('TC-CAMTAB-APP-02 with a court: + opens the form named Cam N+1', (
    tester,
  ) async {
    await _pumpTab(tester, _Venues(const [_courtOne]));

    await tester.tap(find.byTooltip('Tạo camera'));
    await tester.pumpAndSettle();

    expect(find.byType(CameraEditorSheet), findsOneWidget);
    final name = tester.widget<TextField>(
      find.byKey(const ValueKey('camera-editor-name')),
    );
    // One camera exists, so the next one is "Cam 2".
    expect(name.controller!.text, 'Cam 2');
  });

  testWidgets('TC-CAMTAB-APP-03 + is disabled while the courts load', (
    tester,
  ) async {
    final gate = Completer<void>();
    await _pumpTab(tester, _Venues(const [_courtOne], gate: gate), settle: false);

    expect(find.byTooltip('Tạo camera'), findsOneWidget);
    expect(_plus(tester).onPressed, isNull);

    gate.complete();
    await tester.pumpAndSettle();
    expect(_plus(tester).onPressed, isNotNull);
  });

  testWidgets('TC-CAMTAB-APP-04 the camera block sits above the court cards', (
    tester,
  ) async {
    await _pumpTab(tester, _Venues(const [_courtOne]));

    final cameras = tester.getTopLeft(find.byType(CameraListSection)).dy;
    final court = tester
        .getTopLeft(find.byKey(const ValueKey('camera-court-tile-court-1')))
        .dy;
    expect(cameras, lessThan(court));
  });

  testWidgets('TC-CAMTAB-APP-05 a digits-only court name reads Sân N', (
    tester,
  ) async {
    await _pumpTab(
      tester,
      _Venues(const [
        {'id': 'court-1', 'name': '3'},
      ]),
    );

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('camera-court-tile-court-1')),
        matching: find.text('Sân 3'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('TC-COURT-STEP-APP-01 starts at 1, minus is off, plus adds one', (
    tester,
  ) async {
    final values = await _pumpStepper(tester);

    expect(_countText(tester), '1');
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('court-count-minus')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const ValueKey('court-count-plus')));
    await tester.pump();
    expect(_countText(tester), '2');
    expect(values, [2]);

    await tester.tap(find.byKey(const ValueKey('court-count-minus')));
    await tester.pump();
    expect(_countText(tester), '1');
    expect(values, [2, 1]);
  });

  testWidgets('TC-COURT-STEP-APP-02 a typed number is kept; above 50 snaps to '
      '50; empty counts as 1', (tester) async {
    final values = await _pumpStepper(tester);

    await tester.enterText(find.byKey(const ValueKey('count')), '12');
    await tester.pump();
    expect(values.last, 12);
    expect(_countText(tester), '12');

    await tester.enterText(find.byKey(const ValueKey('count')), '99');
    await tester.pump();
    expect(values.last, 50);
    expect(_countText(tester), '50');
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('court-count-plus')))
          .onPressed,
      isNull,
    );

    await tester.enterText(find.byKey(const ValueKey('count')), '');
    await tester.pump();
    expect(values.last, 1);
  });

  testWidgets('TC-COURT-STEP-APP-03 leaving the field rewrites a blank or 0 to '
      '1', (tester) async {
    await _pumpStepper(tester, initialValue: 4);

    await tester.enterText(find.byKey(const ValueKey('count')), '0');
    await tester.pump();
    expect(_countText(tester), '0');

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(_countText(tester), '1');
  });
}
