import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/participant_detail_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock repository quản lý giải: ghi lại từng lời gọi API của sheet.
class _RecordingManagementRepository implements TournamentManagementRepository {
  final notes = <(String participantId, String note)>[];
  final entries = <(String participantId, Map<String, dynamic> payload)>[];
  final seeds = <Map<String, dynamic>>[];
  final statusUpdates = <(String participantId, String status)>[];
  final rosterLocks = <(String participantId, bool lock)>[];
  final mockDeletes = <String>[];
  int refreshes = 0;

  @override
  Future<void> updateParticipantNote(
    String id,
    String participantId,
    String note,
  ) async {
    notes.add((participantId, note));
  }

  @override
  Future<void> updateOrganizerEntry(
    String id,
    String participantId,
    Map<String, dynamic> payload,
  ) async {
    entries.add((participantId, payload));
  }

  @override
  Future<void> updateTournamentSeeds(
    String id,
    List<Map<String, dynamic>> seeds,
  ) async {
    this.seeds.addAll(seeds);
  }

  @override
  Future<void> updateParticipantStatus(
    String id,
    String participantId,
    String status,
  ) async {
    statusUpdates.add((participantId, status));
  }

  @override
  Future<void> lockParticipantRoster(String id, String participantId) async {
    rosterLocks.add((participantId, true));
  }

  @override
  Future<void> unlockParticipantRoster(String id, String participantId) async {
    rosterLocks.add((participantId, false));
  }

  @override
  Future<void> deleteMockParticipant(String id, String participantId) async {
    mockDeletes.add(participantId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Trang chủ có nút mở sheet: sheet chạy trong modal route thật nên đóng được
/// bằng maybePop (pump trực tiếp vào home thì route gốc không pop được).
Widget _app(_RecordingManagementRepository repo) => ProviderScope(
  overrides: [tournamentManagementRepositoryProvider.overrideWithValue(repo)],
  child: MaterialApp(
    theme: AppTheme.darkTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('vi'),
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            key: const ValueKey('open-sheet'),
            onPressed: () => ParticipantDetailSheet.show(
              context,
              tournamentId: 't1',
              participant: _participant,
              tournamentStatus: 'IN_PROGRESS',
              divisionName: 'Đôi Nam Nữ',
              pairFormat: true,
              onRefresh: () async {
                repo.refreshes += 1;
              },
            ),
            child: const Text('Mở sheet'),
          ),
        ),
      ),
    ),
  ),
);

/// Hồ sơ cặp chờ duyệt, đủ ghi chú + câu trả lời form + tệp đính kèm.
const _participant = OrganizerOpsParticipant(
  id: 'p-1',
  teamName: 'An – Bình',
  teamStatus: 'PENDING_APPROVAL',
  isPaid: false,
  entryFee: 150000,
  customResponses: {
    'notes': 'Ghi chú cũ',
    'shirt_size': 'L',
    'agree': true,
    'attachment': {
      'url': 'https://cdn.example.com/giay-xac-nhan.pdf',
      'originalName': 'giay-xac-nhan.pdf',
    },
  },
  members: [
    OrganizerOpsMember(userId: 'u-an', fullName: 'An', email: 'an@x.com'),
    OrganizerOpsMember(userId: 'u-binh', fullName: 'Bình'),
  ],
);

void main() {
  testWidgets('TC-WP-03-02: lưu ghi chú gửi PATCH note, sheet vẫn mở', (
    tester,
  ) async {
    final repo = _RecordingManagementRepository();
    await tester.pumpWidget(_app(repo));
    await tester.tap(find.byKey(const ValueKey('open-sheet')));
    await tester.pumpAndSettle();

    // Ghi chú cũ được nạp sẵn vào ô nhập.
    expect(find.byType(ParticipantDetailSheet), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('participant-detail-note')),
        matching: find.text('Ghi chú cũ'),
      ),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('participant-detail-note')),
      'Ghi chú mới của BTC',
    );
    await tester.tap(
      find.byKey(const ValueKey('participant-detail-note-save')),
    );
    await tester.pumpAndSettle();

    expect(repo.notes, hasLength(1));
    expect(repo.notes.first.$1, 'p-1');
    expect(repo.notes.first.$2, 'Ghi chú mới của BTC');
    // Danh sách phía sau được làm mới qua onRefresh.
    expect(repo.refreshes, 1);
    // Spec: sheet vẫn mở sau khi lưu ghi chú.
    expect(find.byType(ParticipantDetailSheet), findsOneWidget);
  });

  testWidgets('TC-WP-03-02: hiện trạng thái, thanh toán và câu trả lời form', (
    tester,
  ) async {
    final repo = _RecordingManagementRepository();
    await tester.pumpWidget(_app(repo));
    await tester.tap(find.byKey(const ValueKey('open-sheet')));
    await tester.pumpAndSettle();

    final sheet = find.byType(ParticipantDetailSheet);
    // Trạng thái chờ duyệt + chưa thanh toán + badge cặp + hạng mục.
    expect(
      find.descendant(of: sheet, matching: find.text('Chờ duyệt')),
      findsOneWidget,
    );
    expect(find.text('Chưa thanh toán'), findsOneWidget);
    expect(find.text('Cặp · Đôi Nam Nữ'), findsOneWidget);
    // Lệ phí hiển thị trên dòng thanh toán (150000 -> 150,000₫).
    expect(find.textContaining('150'), findsOneWidget);
    // Câu trả lời form: key humanize, bool dịch Có, tệp đính kèm hiện tên file.
    expect(find.text('Shirt size'), findsOneWidget);
    expect(find.text('L'), findsOneWidget);
    expect(find.text('Agree'), findsOneWidget);
    expect(find.text('Có'), findsOneWidget);
    expect(find.text('giay-xac-nhan.pdf'), findsOneWidget);
    // Ghi chú (notes) và key hệ thống không lặp lại thành câu trả lời.
    expect(find.text('Notes'), findsNothing);
    expect(repo.notes, isEmpty);
  });

  testWidgets('TC-WP-03-02: duyệt gửi COMPLETE rồi đóng sheet', (tester) async {
    final repo = _RecordingManagementRepository();
    await tester.pumpWidget(_app(repo));
    await tester.tap(find.byKey(const ValueKey('open-sheet')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('participant-detail-approve')));
    await tester.pumpAndSettle();

    expect(repo.statusUpdates, hasLength(1));
    expect(repo.statusUpdates.first, ('p-1', 'COMPLETE'));
    expect(repo.refreshes, 1);
    expect(find.byType(ParticipantDetailSheet), findsNothing);
  });

  testWidgets('TC-WP-03-02: hồ sơ VĐV ảo có nút xoá, phải confirm', (
    tester,
  ) async {
    final repo = _RecordingManagementRepository();
    final mock = OrganizerOpsParticipant(
      id: 'p-mock',
      teamName: 'VĐV ảo A',
      teamStatus: 'COMPLETE',
      isPaid: true,
      members: [
        const OrganizerOpsMember(
          userId: 'mock-1',
          fullName: 'VĐV ảo',
          isMock: true,
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tournamentManagementRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => ParticipantDetailSheet.show(
                    context,
                    tournamentId: 't1',
                    participant: mock,
                    tournamentStatus: 'IN_PROGRESS',
                    onRefresh: () async {
                      repo.refreshes += 1;
                    },
                  ),
                  child: const Text('Mở sheet'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mở sheet'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('participant-detail-delete-mock')),
    );
    await tester.pumpAndSettle();
    // Chưa confirm thì chưa gọi API.
    expect(repo.mockDeletes, isEmpty);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Xoá VĐV ảo'),
      ),
    );
    await tester.pumpAndSettle();

    expect(repo.mockDeletes, ['p-mock']);
    expect(repo.refreshes, 1);
    // Xoá xong đóng sheet như Web.
    expect(find.byType(ParticipantDetailSheet), findsNothing);
  });

  testWidgets('TC-WP-03-02: đội bóng khoá roster qua POST lock-roster', (
    tester,
  ) async {
    final repo = _RecordingManagementRepository();
    final football = OrganizerOpsParticipant(
      id: 'p-fb',
      teamName: 'FC Một',
      teamStatus: 'COMPLETE',
      isPaid: true,
      footballTeamId: 'ft-1',
      members: [const OrganizerOpsMember(userId: 'u-hung', fullName: 'Hùng')],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tournamentManagementRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => ParticipantDetailSheet.show(
                    context,
                    tournamentId: 't1',
                    participant: football,
                    tournamentStatus: 'IN_PROGRESS',
                  ),
                  child: const Text('Mở sheet'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mở sheet'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('participant-detail-roster-lock')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('participant-detail-roster-lock')),
    );
    await tester.pumpAndSettle();

    expect(repo.rosterLocks, hasLength(1));
    expect(repo.rosterLocks.first, ('p-fb', true));
  });

  testWidgets('TC-WP-03-02: gán seed nhanh gửi PATCH /tournaments/:id/seeds', (
    tester,
  ) async {
    final repo = _RecordingManagementRepository();
    await tester.pumpWidget(_app(repo));
    await tester.tap(find.byKey(const ValueKey('open-sheet')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('participant-detail-seed')),
      '3',
    );
    // Mục seed nằm cuối thân cuộn của sheet: phải cuộn tới nút trước khi bấm.
    await tester.ensureVisible(
      find.byKey(const ValueKey('participant-detail-seed-save')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('participant-detail-seed-save')),
    );
    await tester.pumpAndSettle();

    expect(repo.seeds, [
      {'participantId': 'p-1', 'seed': 3},
    ]);

    // Seed không hợp lệ: báo lỗi tại chỗ, không gửi API.
    await tester.enterText(
      find.byKey(const ValueKey('participant-detail-seed')),
      'abc',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('participant-detail-seed-save')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('participant-detail-seed-save')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Seed phải là số nguyên từ 1 trở lên.'), findsOneWidget);
    expect(repo.seeds, hasLength(1));
  });

  testWidgets('TC-WP-03-02: sửa liên hệ khách gửi PATCH entry đúng payload', (
    tester,
  ) async {
    final repo = _RecordingManagementRepository();
    final guests = OrganizerOpsParticipant(
      id: 'p-guest',
      teamName: 'Hồ Sơ Khách',
      teamStatus: 'COMPLETE',
      isPaid: true,
      canOrganizerEdit: true,
      customResponses: {'player1Email': 'a@x.com'},
      members: const [],
      players: [
        const ParticipantPlayer(slot: 1, fullName: 'Khách A', isGuest: true),
        const ParticipantPlayer(slot: 2, fullName: 'Khách B', isGuest: true),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tournamentManagementRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => ParticipantDetailSheet.show(
                    context,
                    tournamentId: 't1',
                    participant: guests,
                    tournamentStatus: 'IN_PROGRESS',
                  ),
                  child: const Text('Mở sheet'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mở sheet'));
    await tester.pumpAndSettle();

    // Cặp tài khoản thật không có khách nên không hiện nút sửa; hồ sơ khách thì có.
    await tester.tap(find.byKey(const ValueKey('participant-contact-edit')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('participant-contact-name-1')),
      'Khách A sửa',
    );
    await tester.enterText(
      find.byKey(const ValueKey('participant-contact-phone-1')),
      '0901123456',
    );
    // Nút Lưu nằm dưới khối ô nhập dài: cuộn tới trước khi bấm.
    await tester.ensureVisible(
      find.byKey(const ValueKey('participant-contact-save')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('participant-contact-save')));
    await tester.pumpAndSettle();

    expect(repo.entries, hasLength(1));
    expect(repo.entries.first.$1, 'p-guest');
    final members = repo.entries.first.$2['members'] as List;
    expect(members, hasLength(1));
    expect(members.first['slot'], 1);
    expect(members.first['name'], 'Khách A sửa');
    expect(members.first['email'], 'a@x.com');
    expect(members.first['phone'], '0901123456');
    // expectedKey theo đúng định dạng server kiểm (`guest: tên|email`).
    expect(members.first['expectedKey'], 'guest:Khách A|a@x.com');
    // Khách B không sửa thì không gửi dòng đó.
    expect(members.any((member) => member['slot'] == 2), isFalse);
  });

  testWidgets('TC-WP-03-02: tên khách rỗng chặn lưu, không gửi API', (
    tester,
  ) async {
    final repo = _RecordingManagementRepository();
    final guests = OrganizerOpsParticipant(
      id: 'p-guest',
      teamName: 'Hồ Sơ Khách',
      teamStatus: 'COMPLETE',
      isPaid: true,
      canOrganizerEdit: true,
      members: const [],
      players: [
        const ParticipantPlayer(slot: 1, fullName: 'Khách A', isGuest: true),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tournamentManagementRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => ParticipantDetailSheet.show(
                    context,
                    tournamentId: 't1',
                    participant: guests,
                    tournamentStatus: 'IN_PROGRESS',
                  ),
                  child: const Text('Mở sheet'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mở sheet'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('participant-contact-edit')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('participant-contact-name-1')),
      ' ',
    );
    await tester.tap(find.byKey(const ValueKey('participant-contact-save')));
    await tester.pumpAndSettle();

    expect(find.text('Nhập tên'), findsOneWidget);
    expect(repo.entries, isEmpty);
  });
}
