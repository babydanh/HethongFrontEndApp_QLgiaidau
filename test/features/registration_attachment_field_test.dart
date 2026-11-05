import 'dart:async';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/repositories/registration_attachment_repository.dart';
import 'package:app_quanly_giaidau/features/register/widgets/registration_attachment_field.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/registration_attachment_provider.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements IRegistrationAttachmentRepository {
  final calls = <({String tournamentId, String fieldId, String fileName})>[];
  Completer<Map<String, dynamic>>? gate;
  Object? error;

  @override
  Future<Map<String, dynamic>> upload({
    required String tournamentId,
    required String fieldId,
    required List<int> bytes,
    required String fileName,
  }) {
    calls.add((
      tournamentId: tournamentId,
      fieldId: fieldId,
      fileName: fileName,
    ));
    final error = this.error;
    if (error != null) return Future.error(error);
    return gate?.future ??
        Future.value({
          'url': 'https://res.test/$fileName',
          'publicId': 'p',
          'originalName': fileName,
          'size': bytes.length,
          'mimeType': 'application/pdf',
        });
  }
}

PlatformFile _file(String name, int size) => PlatformFile(
  name: name,
  size: size,
  // ignore: deprecated_member_use
  bytes: Uint8List(size > 1024 ? 1024 : size),
);

const _baseField = <String, dynamic>{
  'id': 'f1',
  'label': 'Doc',
  'type': 'FILE',
  'required': true,
};

class _Harness {
  _Harness(this.repo, this.pick, {this.field = _baseField});

  final _FakeRepo repo;
  final Future<PlatformFile?> Function() pick;
  final Map<String, dynamic> field;
  final changes = <Map<String, dynamic>?>[];
  final busy = <bool>[];

  Widget build() => ProviderScope(
    overrides: [
      registrationAttachmentRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => RegistrationAttachmentField(
            tournamentId: 'tour-1',
            field: field,
            value: changes.isEmpty ? null : changes.last,
            onChanged: (value) => setState(() => changes.add(value)),
            onUploadingChanged: busy.add,
            pickFile: pick,
          ),
        ),
      ),
    ),
  );
}

Future<void> _tapChoose(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('regAttachmentChoose')));
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  // TC-REGATTACH-02
  testWidgets('a file over 10 MB is blocked before any upload', (tester) async {
    final repo = _FakeRepo();
    final h = _Harness(repo, () async => _file('big.pdf', 11 * 1024 * 1024));
    await tester.pumpWidget(h.build());

    await _tapChoose(tester);

    expect(find.textContaining('larger than 10 MB'), findsOneWidget);
    expect(repo.calls, isEmpty);
    expect(h.changes, isEmpty);
  });

  // TC-REGATTACH-02b
  testWidgets('the per-field limit below 10 MB is honoured', (tester) async {
    final repo = _FakeRepo();
    final h = _Harness(
      repo,
      () async => _file('mid.pdf', 3 * 1024 * 1024),
      field: {..._baseField, 'maxFileSizeMb': 2},
    );
    await tester.pumpWidget(h.build());

    await _tapChoose(tester);

    expect(find.textContaining('larger than 2 MB'), findsOneWidget);
    expect(repo.calls, isEmpty);
  });

  // TC-REGATTACH-03
  testWidgets('shows progress while uploading, then the name and size', (
    tester,
  ) async {
    final repo = _FakeRepo()..gate = Completer();
    final h = _Harness(repo, () async => _file('rule.pdf', 2048));
    await tester.pumpWidget(h.build());

    await _tapChoose(tester);

    expect(h.busy, [true]);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('rule.pdf'), findsOneWidget);
    // Re-tapping while a file is in flight must not start a second upload.
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('regAttachmentChoose')))
          .onPressed,
      isNull,
    );

    repo.gate!.complete({
      'url': 'https://res.test/rule.pdf',
      'publicId': 'p',
      'originalName': 'rule.pdf',
      'size': 2048,
      'mimeType': 'application/pdf',
    });
    await tester.pump(const Duration(milliseconds: 50));

    expect(h.busy, [true, false]);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('rule.pdf'), findsOneWidget);
    expect(find.textContaining('2.0 KB'), findsOneWidget);
    expect(repo.calls.single, (
      tournamentId: 'tour-1',
      fieldId: 'f1',
      fileName: 'rule.pdf',
    ));
    expect(h.changes.single?['url'], 'https://res.test/rule.pdf');
  });

  // TC-REGATTACH-04
  testWidgets('a timeout shows a network message and keeps no file', (
    tester,
  ) async {
    final repo = _FakeRepo()
      ..error = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.sendTimeout,
      );
    final h = _Harness(repo, () async => _file('a.pdf', 100));
    await tester.pumpWidget(h.build());

    await _tapChoose(tester);

    expect(find.textContaining('Network problem'), findsOneWidget);
    expect(h.busy, [true, false]);
    expect(h.changes, isEmpty);
  });

  // TC-REGATTACH-05
  testWidgets('a 413 from the server shows the too-large message', (
    tester,
  ) async {
    final req = RequestOptions(path: '/x');
    final repo = _FakeRepo()
      ..error = DioException(
        requestOptions: req,
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: req, statusCode: 413),
      );
    final h = _Harness(repo, () async => _file('a.pdf', 100));
    await tester.pumpWidget(h.build());

    await _tapChoose(tester);

    expect(find.textContaining('larger than 10 MB'), findsOneWidget);
    expect(h.changes, isEmpty);
  });

  // TC-REGATTACH-06
  testWidgets('a 400 shows the server reason (e.g. type not accepted)', (
    tester,
  ) async {
    final req = RequestOptions(path: '/x');
    final repo = _FakeRepo()
      ..error = DioException(
        requestOptions: req,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: req,
          statusCode: 400,
          data: {'message': 'File type not accepted'},
        ),
      );
    final h = _Harness(repo, () async => _file('a.exe', 100));
    await tester.pumpWidget(h.build());

    await _tapChoose(tester);

    expect(find.text('File type not accepted'), findsOneWidget);
  });

  // TC-REGATTACH-07
  testWidgets('the remove button clears the uploaded file', (tester) async {
    final repo = _FakeRepo();
    final h = _Harness(repo, () async => _file('a.pdf', 100));
    await tester.pumpWidget(h.build());
    await _tapChoose(tester);
    expect(find.text('a.pdf'), findsOneWidget);

    await tester.tap(find.byKey(const Key('regAttachmentRemove')));
    await tester.pump(const Duration(milliseconds: 50));

    expect(h.changes.last, isNull);
    expect(find.text('a.pdf'), findsNothing);
  });

  // TC-REGATTACH-08
  testWidgets('cancelling the picker does nothing', (tester) async {
    final repo = _FakeRepo();
    final h = _Harness(repo, () async => null);
    await tester.pumpWidget(h.build());

    await _tapChoose(tester);

    expect(repo.calls, isEmpty);
    expect(h.busy, isEmpty);
    expect(h.changes, isEmpty);
  });

  // TC-REGATTACH-09
  testWidgets('an upload finishing after dispose is dropped quietly', (
    tester,
  ) async {
    final repo = _FakeRepo()..gate = Completer();
    final h = _Harness(repo, () async => _file('a.pdf', 100));
    await tester.pumpWidget(h.build());
    await _tapChoose(tester);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    repo.gate!.complete({'url': 'u'});
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
    expect(h.changes, isEmpty);
  });
}
