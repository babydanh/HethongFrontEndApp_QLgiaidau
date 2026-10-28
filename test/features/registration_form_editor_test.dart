import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/registration_form_editor.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records the PATCH payloads sent by the editor (fake data only).
class _Repo
    implements TournamentManagementRepository, TournamentSettingsRepository {
  final saved = <Map<String, dynamic>>[];

  @override
  Future<void> updateTournament(String id, Map<String, dynamic> payload) async {
    saved.add(Map<String, dynamic>.of(payload));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _field(
  String id,
  String label, {
  String type = 'TEXT',
  List<String>? options,
  bool required = false,
}) => {
  'id': id,
  'label': label,
  'type': type,
  'required': required,
  'options': ?options,
};

Tournament _tournament({
  List<Map<String, dynamic>> fields = const [],
  String status = 'REGISTRATION_OPEN',
}) => Tournament.fromJson({
  'name': 'Giải thử',
  'sport': 'pickleball',
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': status,
  'maxTeams': 16,
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
  'divisions': [
    {'id': 'div-a', 'name': 'Đôi nam', 'matchType': 'DOUBLES'},
  ],
  'tournamentConfig': {
    'location': {'city': 'Hà Nội'},
    'registrationForm': {
      'version': 1,
      'status': 'PUBLISHED',
      'divisionIds': ['div-a'],
      'fields': fields,
    },
  },
}, 'tournament-1');

Widget _app(
  _Repo repo,
  Tournament tournament, {
  Set<String> answered = const {},
}) => ProviderScope(
  overrides: [tournamentManagementRepositoryProvider.overrideWithValue(repo)],
  child: MaterialApp(
    theme: AppTheme.darkTheme,
    locale: const Locale('vi'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: RegistrationFormEditorScreen(
      tournament: tournament,
      answeredFieldIds: answered,
    ),
  ),
);

void _tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('model', () {
    test(
      'readRegistrationFormFields đọc câu hỏi và bỏ mục thiếu id/label/type',
      () {
        final fields = readRegistrationFormFields({
          'registrationForm': {
            'fields': [
              _field('a', 'Size áo', type: 'SELECT', options: ['S', 'M']),
              {'id': 'b', 'type': 'TEXT'},
              'rác',
            ],
          },
        });
        expect(fields.map((f) => f['id']), ['a']);
        expect(readRegistrationFormFields({}), isEmpty);
      },
    );

    test('validateRegistrationFields: thiếu tên, chọn thiếu lựa chọn', () {
      expect(
        validateRegistrationFields([_field('a', '  ')])?.code,
        'missingLabel',
      );
      final choice = validateRegistrationFields([
        _field('a', 'Size', type: 'SELECT', options: ['S', ' S ']),
      ]);
      expect(choice?.code, 'choiceOptions');
      expect(choice?.label, 'Size');
      expect(
        validateRegistrationFields([
          _field('a', 'Size', type: 'MULTI_SELECT', options: ['S', 'M']),
          _field('b', 'Ghi chú'),
        ]),
        isNull,
      );
    });

    test('buildRegistrationFormConfig giữ khoá khác và chuẩn hoá câu hỏi', () {
      final config = buildRegistrationFormConfig(
        tournamentConfig: {
          'location': {'city': 'Hà Nội'},
          'registrationForm': {
            'status': 'DRAFT',
            'divisionIds': <String>[],
            'extra': 1,
          },
        },
        fields: [
          _field(
            'a',
            '  Size  ',
            type: 'SELECT',
            options: ['S', ' S ', '', 'M'],
          ),
          _field('b', 'Ghi chú', options: ['rác']),
        ],
        allDivisionIds: const ['div-a', 'div-b'],
      );
      expect(config['location'], {'city': 'Hà Nội'});
      final form = config['registrationForm'] as Map<String, dynamic>;
      expect(form['status'], 'PUBLISHED');
      expect(form['version'], 1);
      expect(form['extra'], 1);
      expect(form['divisionIds'], ['div-a', 'div-b']);
      final fields = form['fields'] as List;
      expect((fields[0] as Map)['label'], 'Size');
      expect((fields[0] as Map)['options'], ['S', 'M']);
      expect((fields[1] as Map).containsKey('options'), isFalse);
    });
  });

  testWidgets('Họ tên và Số điện thoại cố định, không có thao tác xoá', (
    tester,
  ) async {
    _tallView(tester);
    await tester.pumpWidget(_app(_Repo(), _tournament()));

    expect(find.text('Họ và tên'), findsOneWidget);
    expect(find.text('Số điện thoại'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('registration-form-system-name')),
      findsOneWidget,
    );
    expect(find.byType(Dismissible), findsNothing);
  });

  testWidgets(
    'kéo đổi thứ tự rồi Lưu: payload theo thứ tự mới, giữ khoá khác',
    (tester) async {
      _tallView(tester);
      final repo = _Repo();
      await tester.pumpWidget(
        _app(
          repo,
          _tournament(fields: [_field('a', 'Size áo'), _field('b', 'Ghi chú')]),
        ),
      );

      // Drag in small steps so the reorderable list tracks the pointer.
      final gesture = await tester.startGesture(
        tester.getCenter(
          find.byKey(const ValueKey('registration-field-handle-b')),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      for (var i = 0; i < 12; i++) {
        await gesture.moveBy(const Offset(0, -10));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await gesture.up();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('registration-form-save')));
      await tester.pumpAndSettle();

      final config = repo.saved.single['tournamentConfig'] as Map;
      expect(config['location'], {'city': 'Hà Nội'});
      final fields = (config['registrationForm'] as Map)['fields'] as List;
      expect(fields.map((f) => (f as Map)['id']), ['b', 'a']);
    },
  );

  testWidgets(
    'vuốt xoá có xác nhận; câu hỏi đã có trả lời cảnh báo mất dữ liệu',
    (tester) async {
      _tallView(tester);
      await tester.pumpWidget(
        _app(
          _Repo(),
          _tournament(fields: [_field('a', 'Size áo'), _field('b', 'Ghi chú')]),
          answered: {'a'},
        ),
      );

      // Câu đã có người trả lời: hộp xác nhận nêu rõ câu trả lời sẽ mất.
      await tester.drag(
        find.byKey(const ValueKey('registration-field-a')),
        const Offset(-600, 0),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('sẽ mất'), findsOneWidget);
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('registration-field-a')),
        findsOneWidget,
      );

      // Câu chưa có trả lời: hỏi xác nhận thường, xác nhận thì mất khỏi danh sách.
      await tester.drag(
        find.byKey(const ValueKey('registration-field-b')),
        const Offset(-600, 0),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('sẽ mất'), findsNothing);
      await tester.tap(
        find.byKey(const ValueKey('registration-delete-confirm')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('registration-field-b')), findsNothing);
    },
  );

  testWidgets('Chọn một thiếu lựa chọn: không gửi, báo lỗi nêu tên câu hỏi', (
    tester,
  ) async {
    _tallView(tester);
    final repo = _Repo();
    await tester.pumpWidget(
      _app(
        repo,
        _tournament(
          fields: [
            _field('a', 'Size áo', type: 'SELECT', options: ['S']),
          ],
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('registration-form-save')));
    await tester.pumpAndSettle();

    expect(repo.saved, isEmpty);
    expect(find.textContaining('Size áo'), findsWidgets);
    expect(find.textContaining('ít nhất 2 lựa chọn'), findsOneWidget);
  });

  testWidgets('thêm câu hỏi Chọn một qua chip loại, nhập lựa chọn rồi Lưu', (
    tester,
  ) async {
    _tallView(tester);
    final repo = _Repo();
    await tester.pumpWidget(_app(repo, _tournament()));

    // The chip only picks the type; the add button then opens the editor.
    await tester.tap(find.byKey(const ValueKey('registration-add-SELECT')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('registration-add-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('registration-editor-label')),
      'Trình độ',
    );
    await tester.enterText(
      find.byKey(const ValueKey('registration-editor-options')),
      'Mới\nTrung bình\nKhá',
    );
    await tester.tap(find.byKey(const ValueKey('registration-editor-done')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('registration-form-save')));
    await tester.pumpAndSettle();

    final config = repo.saved.single['tournamentConfig'] as Map;
    final fields = (config['registrationForm'] as Map)['fields'] as List;
    final added = fields.single as Map;
    expect(added['label'], 'Trình độ');
    expect(added['type'], 'SELECT');
    expect(added['options'], ['Mới', 'Trung bình', 'Khá']);
    expect(added['id'], startsWith('custom_'));
  });

  testWidgets('bấm đúp Lưu chỉ gửi một lần', (tester) async {
    _tallView(tester);
    final repo = _Repo();
    await tester.pumpWidget(_app(repo, _tournament()));

    final save = find.byKey(const ValueKey('registration-form-save'));
    await tester.tap(save);
    await tester.tap(save, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(repo.saved.length, 1);
  });

  testWidgets('đăng ký đã đóng: form khoá, không cho Lưu', (tester) async {
    _tallView(tester);
    final repo = _Repo();
    await tester.pumpWidget(
      _app(repo, _tournament(status: 'REGISTRATION_CLOSED')),
    );

    expect(find.textContaining('Form đã khoá'), findsOneWidget);
    final save = tester.widget<TextButton>(
      find.byKey(const ValueKey('registration-form-save')),
    );
    expect(save.onPressed, isNull);
  });
}
