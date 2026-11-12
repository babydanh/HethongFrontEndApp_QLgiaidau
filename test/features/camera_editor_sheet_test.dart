import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/features/tournament/models/court_match_drag.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_editor_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// TC-WP-05-01 (task 5.1): camera editor sheet — validation, double-tap guard,
/// verbatim server error, edit = court only.
/// TC-CAM-AQP-APP-01..03: AQP-only add form and its "?" help.
const _courts = [
  TournamentCourtRef(id: 'court-1', name: 'Court 1', venueName: 'Hall'),
  TournamentCourtRef(id: 'court-2', name: 'Court 2', venueName: 'Hall'),
];

final _name = find.byKey(const ValueKey('camera-editor-name'));
final _help = find.byKey(const ValueKey('camera-help-button'));
final _helpPanel = find.byKey(const ValueKey('camera-help-panel'));
final _submit = find.byKey(const ValueKey('camera-editor-submit'));
final _court = find.byKey(const ValueKey('camera-editor-court'));

Future<List<bool?>> _open(
  WidgetTester tester,
  CameraEditorSubmit onSubmit, {
  TournamentCameraModel? camera,
}) async {
  final popped = <bool?>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async => popped.add(
                await CameraEditorSheet.show(
                  context,
                  courts: _courts,
                  camera: camera,
                  onSubmit: onSubmit,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return popped;
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(CameraEditorSheet)))!;

Future<void> _pickCourt(WidgetTester tester, String name) async {
  await tester.tap(_court);
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a camera on a court missing from the list still opens the sheet', (
    tester,
  ) async {
    await _open(
      tester,
      (value) async {},
      camera: const TournamentCameraModel(
        id: 'cam-1',
        name: 'Gone court cam',
        mode: 'PUSH',
        status: 'IDLE',
        courtId: 'court-archived',
      ),
    );

    expect(tester.takeException(), isNull);
    expect(_court, findsOneWidget);
    expect(find.text(_l10n(tester).tournamentCameraCourtNone), findsWidgets);
  });

  testWidgets('a name shorter than two characters is refused and nothing is sent', (
    tester,
  ) async {
    var calls = 0;
    await _open(tester, (value) async => calls++);

    await tester.enterText(_name, ' a ');
    await tester.tap(_submit);
    await tester.pumpAndSettle();

    expect(calls, 0);
    expect(find.text(_l10n(tester).tournamentCameraNameInvalid(2, 255)), findsOneWidget);
  });

  testWidgets('a PUSH camera is submitted with a trimmed name and the chosen court', (
    tester,
  ) async {
    final values = <CameraEditorValue>[];
    final popped = await _open(tester, (value) async => values.add(value));

    await tester.enterText(_name, '  Court 1 phone  ');
    await _pickCourt(tester, 'Court 2');
    await tester.tap(_submit);
    await tester.pumpAndSettle();

    final value = values.single;
    expect(value.name, 'Court 1 phone');
    expect(value.mode, 'PUSH');
    expect(value.courtId, 'court-2');
    expect(popped, [true]);
  });

  testWidgets('TC-CAM-AQP-APP-01 the add form has no PUSH/PULL choice or URL field', (
    tester,
  ) async {
    await _open(tester, (value) async {});

    expect(_name, findsOneWidget);
    expect(find.text('PUSH'), findsNothing);
    expect(find.text('PULL'), findsNothing);
    expect(find.byType(SegmentedButton<String>), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('TC-CAM-AQP-APP-02 the ? opens and closes the animated help', (
    tester,
  ) async {
    await _open(tester, (value) async {});

    expect(_help, findsOneWidget);
    expect(_helpPanel, findsNothing);

    await tester.tap(_help);
    await tester.pump(const Duration(milliseconds: 400));
    expect(_helpPanel, findsOneWidget);
    final l10n = _l10n(tester);
    expect(find.text(l10n.tournamentCameraHelpStep1), findsOneWidget);
    expect(find.text(l10n.tournamentCameraHelpStep3), findsOneWidget);
    // The form must still be usable while the help is open.
    expect(_name, findsOneWidget);

    await tester.tap(_help);
    await tester.pump(const Duration(milliseconds: 400));
    expect(_helpPanel, findsNothing);
    expect(_name, findsOneWidget);
  });

  testWidgets('TC-CAM-AQP-APP-02b the open help fits a 320dp phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _open(tester, (value) async {});

    await tester.tap(_help);
    await tester.pump(const Duration(milliseconds: 400));

    expect(_helpPanel, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TC-CAM-AQP-APP-03 reduced motion keeps the help still', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await _open(tester, (value) async {});

    await tester.tap(_help);
    // pumpAndSettle only returns when no animation keeps scheduling frames.
    await tester.pumpAndSettle();
    expect(_helpPanel, findsOneWidget);
  });

  testWidgets('a second tap while saving does not submit twice', (tester) async {
    final pending = Completer<void>();
    var calls = 0;
    final popped = await _open(tester, (value) {
      calls++;
      return pending.future;
    });

    await tester.enterText(_name, 'Court 1 phone');
    await tester.tap(_submit);
    await tester.pump();
    await tester.tap(_submit, warnIfMissed: false);
    await tester.pump();

    expect(calls, 1);
    pending.complete();
    await tester.pumpAndSettle();
    expect(popped, [true]);
  });

  testWidgets('a server refusal is shown verbatim and the sheet stays open', (
    tester,
  ) async {
    final options = RequestOptions(path: '/x');
    final popped = await _open(
      tester,
      (value) async => throw DioException(
        requestOptions: options,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: 409,
          data: {'message': 'Court already has a PULL camera'},
        ),
      ),
    );

    await tester.enterText(_name, 'Court 1 phone');
    await tester.tap(_submit);
    await tester.pumpAndSettle();

    expect(find.text('Court already has a PULL camera'), findsOneWidget);
    expect(popped, isEmpty);
    expect(tester.widget<FilledButton>(_submit).onPressed, isNotNull);
  });

  testWidgets('editing an existing camera only changes its court', (tester) async {
    final values = <CameraEditorValue>[];
    const camera = TournamentCameraModel(
      id: 'cam-1',
      name: 'Court 1 phone',
      mode: 'PUSH',
      status: 'IDLE',
      courtId: 'court-1',
    );
    await _open(tester, (value) async => values.add(value), camera: camera);

    expect(_name, findsNothing);
    expect(find.text('Court 1 phone'), findsOneWidget);
    await _pickCourt(tester, 'Court 2');
    await tester.tap(_submit);
    await tester.pumpAndSettle();

    expect(values.single.courtId, 'court-2');
  });
}
