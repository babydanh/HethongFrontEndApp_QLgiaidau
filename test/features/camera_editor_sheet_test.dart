import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/features/tournament/models/court_match_drag.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_editor_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// TC-WP-05-01 (task 5.1): camera editor sheet — validation, PULL needs a
/// https URL, double-tap guard, verbatim server error, edit = court only.
const _courts = [
  TournamentCourtRef(id: 'court-1', name: 'Court 1', venueName: 'Hall'),
  TournamentCourtRef(id: 'court-2', name: 'Court 2', venueName: 'Hall'),
];

final _name = find.byKey(const ValueKey('camera-editor-name'));
final _url = find.byKey(const ValueKey('camera-editor-url'));
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
    expect(value.playbackUrl, isNull);
    expect(popped, [true]);
  });

  testWidgets('a PULL camera needs an https playback URL', (tester) async {
    final values = <CameraEditorValue>[];
    await _open(tester, (value) async => values.add(value));

    await tester.enterText(_name, 'Hall cam');
    await tester.tap(find.text('PULL'));
    await tester.pumpAndSettle();
    expect(_url, findsOneWidget);

    await tester.tap(_submit);
    await tester.pumpAndSettle();
    expect(values, isEmpty);
    expect(find.text(_l10n(tester).tournamentCameraUrlInvalid), findsOneWidget);

    await tester.enterText(_url, 'http://media.example.test/hall.m3u8');
    await tester.tap(_submit);
    await tester.pumpAndSettle();
    expect(values, isEmpty);

    await tester.enterText(_url, ' https://media.example.test/hall.m3u8 ');
    await tester.tap(_submit);
    await tester.pumpAndSettle();
    expect(values.single.mode, 'PULL');
    expect(values.single.playbackUrl, 'https://media.example.test/hall.m3u8');
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
    expect(_url, findsNothing);
    expect(find.text('Court 1 phone'), findsOneWidget);
    await _pickCourt(tester, 'Court 2');
    await tester.tap(_submit);
    await tester.pumpAndSettle();

    expect(values.single.courtId, 'court-2');
  });
}
