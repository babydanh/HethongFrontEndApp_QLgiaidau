import 'package:app_quanly_giaidau/domain/entities/swiss.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TC-FEAT-SWISS-ENTITY-01: giá trị API', () {
    test('ánh xạ đủ tiebreak hai chiều và bỏ qua giá trị lạ', () {
      const expected = {
        SwissTiebreak.buchholz: 'BUCHHOLZ',
        SwissTiebreak.buchholzCut1: 'BUCHHOLZ_CUT1',
        SwissTiebreak.sonnebornBerger: 'SONNEBORN_BERGER',
        SwissTiebreak.pointDiff: 'POINT_DIFF',
        SwissTiebreak.wins: 'WINS',
        SwissTiebreak.headToHead: 'HEAD_TO_HEAD',
        SwissTiebreak.seed: 'SEED',
      };

      for (final entry in expected.entries) {
        expect(entry.key.apiValue, entry.value);
        expect(SwissTiebreak.fromApi(entry.value), entry.key);
      }
      expect(SwissTiebreak.fromApi('UNKNOWN'), isNull);
    });
  });

  group('TC-FEAT-SWISS-ENTITY-02: cấu hình', () {
    test('tính số vòng mặc định theo lũy thừa hai gần nhất', () {
      expect(SwissConfig.defaultTotalRounds(0), 1);
      expect(SwissConfig.defaultTotalRounds(1), 1);
      expect(SwissConfig.defaultTotalRounds(2), 1);
      expect(SwissConfig.defaultTotalRounds(3), 2);
      expect(SwissConfig.defaultTotalRounds(9), 4);
    });

    test('đọc và ghi đúng cấu hình API', () {
      final config = SwissConfig.fromJson({
        'totalRounds': 5,
        'tiebreakOrder': ['BUCHHOLZ', 'POINT_DIFF', 'SEED'],
        'firstRoundPairing': 'RANDOM',
      });

      expect(config.totalRounds, 5);
      expect(config.tiebreakOrder, [
        SwissTiebreak.buchholz,
        SwissTiebreak.pointDiff,
        SwissTiebreak.seed,
      ]);
      expect(config.firstRoundPairing, 'RANDOM');
      expect(config.toJson(), {
        'totalRounds': 5,
        'tiebreakOrder': ['BUCHHOLZ', 'POINT_DIFF', 'SEED'],
        'firstRoundPairing': 'RANDOM',
      });
    });

    test('thiếu cấu hình dùng mặc định an toàn', () {
      final config = SwissConfig.fromJson(const {});

      expect(config.totalRounds, 1);
      expect(config.tiebreakOrder, [
        SwissTiebreak.buchholz,
        SwissTiebreak.pointDiff,
        SwissTiebreak.headToHead,
        SwissTiebreak.seed,
      ]);
      expect(config.firstRoundPairing, 'SEED');
    });
  });

  group('TC-FEAT-SWISS-ENTITY-03: phản hồi API', () {
    test('đọc preview, cảnh báo, người tham gia và stage', () {
      final preview = SwissPreview.fromJson({
        'roundNumber': 3,
        'totalRounds': 5,
        'pairs': [
          {'board': 1, 'participant1Id': 'p1', 'participant2Id': 'p2'},
        ],
        'byeParticipantId': 'p3',
        'sitOutParticipantIds': ['p4'],
        'participants': [
          {
            'id': 'p1',
            'teamName': 'Đội 1',
            'logoUrl': null,
            'seed': 2,
            'totalPoints': 4.5,
            'buchholz': 8,
            'hadBye': false,
          },
        ],
        'warnings': [
          {
            'type': 'SCORE_GAP',
            'participantIds': ['p1', 'p2'],
            'gap': 2,
          },
        ],
      });
      final stage = SwissStageInfo.fromJson({
        'id': 'stage-1',
        'type': 'SWISS',
        'roundConfig': {
          'swiss': {
            'totalRounds': 5,
            'tiebreakOrder': ['BUCHHOLZ'],
            'firstRoundPairing': 'SEED',
          },
        },
      });

      expect(preview.roundNumber, 3);
      expect(preview.totalRounds, 5);
      expect(preview.pairs.single.board, 1);
      expect(preview.pairs.single.participant1Id, 'p1');
      expect(preview.pairs.single.participant2Id, 'p2');
      expect(preview.byeParticipantId, 'p3');
      expect(preview.sitOutParticipantIds, ['p4']);
      expect(preview.participants.single.seed, 2);
      expect(preview.participants.single.totalPoints, 4.5);
      expect(preview.participants.single.buchholz, 8);
      expect(preview.warnings.single.type, 'SCORE_GAP');
      expect(preview.warnings.single.participantIds, ['p1', 'p2']);
      expect(preview.warnings.single.gap, 2);
      expect(stage.stageId, 'stage-1');
      expect(stage.config.tiebreakOrder, [SwissTiebreak.buchholz]);
    });
    test('đọc kết quả validate và tạo vòng theo hợp đồng API', () {
      final validation = SwissValidateResult.fromJson({
        'valid': false,
        'errors': [
          {
            'code': 'MISSING_PARTICIPANT',
            'participantIds': ['p1'],
          },
        ],
        'warnings': [
          {
            'type': 'REMATCH',
            'participantIds': ['p2', 'p3'],
            'round': 2,
          },
        ],
      });
      final result = SwissNextRoundResult.fromJson({
        'roundNumber': 4,
        'matchIds': ['match-1', 'match-2'],
      });

      expect(validation.valid, isFalse);
      expect(validation.errors.single.participantIds, ['p1']);
      expect(validation.warnings.single.round, 2);
      expect(result.roundNumber, 4);
      expect(result.matchIds, ['match-1', 'match-2']);
    });

    test(
      'tuần tự hóa yêu cầu vòng đúng tên trường và chỉ xác nhận khi được bật',
      () {
        final request = SwissRoundDraftRequest(
          divisionId: 'division-1',
          stageId: 'stage-1',
          pairs: [(participant1Id: 'p1', participant2Id: 'p2')],
          byeParticipantId: null,
          sitOutParticipantIds: ['p3'],
        );

        expect(request.toJson(), {
          'divisionId': 'division-1',
          'stageId': 'stage-1',
          'pairs': [
            {'participant1Id': 'p1', 'participant2Id': 'p2'},
          ],
          'byeParticipantId': null,
          'sitOutParticipantIds': ['p3'],
        });
        expect(
          request.toJson(confirmWarnings: true)['confirmWarnings'],
          isTrue,
        );
      },
    );

    test('đọc yêu cầu ghép cặp từ các trường API', () {
      final request = SwissRoundDraftRequest.fromJson({
        'divisionId': 'division-2',
        'stageId': 'stage-2',
        'pairs': [
          {'participant1Id': 'p4', 'participant2Id': 'p5'},
        ],
        'byeParticipantId': 'p6',
        'sitOutParticipantIds': ['p7'],
      });

      expect(request.divisionId, 'division-2');
      expect(request.stageId, 'stage-2');
      expect(request.pairs, [(participant1Id: 'p4', participant2Id: 'p5')]);
      expect(request.byeParticipantId, 'p6');
      expect(request.sitOutParticipantIds, ['p7']);
    });

    test('đọc lỗi Swiss có mã, trạng thái và cảnh báo', () {
      final warning = SwissWarning.fromJson({
        'type': 'REMATCH',
        'participantIds': ['p1', 'p2'],
        'round': 1,
      });
      final error = SwissError.fromJson({
        'code': 'MISSING_PARTICIPANT',
        'participantIds': ['p3'],
      });
      final exception = SwissApiException.fromJson({
        'statusCode': 409,
        'message': 'Warnings need confirmation',
        'data': {
          'code': 'SWISS_WARNINGS_UNCONFIRMED',
          'warnings': [
            {
              'type': 'REMATCH',
              'participantIds': ['p1', 'p2'],
              'round': 1,
            },
          ],
        },
      });

      expect(warning.round, 1);
      expect(error.code, 'MISSING_PARTICIPANT');
      expect(exception.status, 409);
      expect(exception.code, 'SWISS_WARNINGS_UNCONFIRMED');
      expect(exception.message, 'Warnings need confirmation');
      expect(exception.warnings.single.type, 'REMATCH');
    });
  });

  group(
    'SwissStageInfo giữ roundConfig thô và biết có totalRounds hay không',
    () {
      SwissStageInfo stage(Map<String, dynamic> roundConfig) =>
          SwissStageInfo.fromJson({
            'id': 's1',
            'type': 'SWISS',
            'roundConfig': roundConfig,
          });

      test('giữ nguyên khóa ngoài swiss và khóa lạ trong swiss', () {
        final info = stage({
          'other': {'a': 1},
          'swiss': {'totalRounds': 4, 'future': true},
        });

        expect(info.rawRoundConfig['other'], {'a': 1});
        expect(info.hasTotalRounds, isTrue);
        expect(info.totalRounds, 4);
      });

      test(
        'thiếu swiss.totalRounds thì totalRounds là null (không đoán 1)',
        () {
          final info = stage({
            'swiss': {
              'tiebreakOrder': ['BUCHHOLZ'],
            },
          });

          expect(info.hasTotalRounds, isFalse);
          expect(info.totalRounds, isNull);
        },
      );
    },
  );

  group('planSwissSave', () {
    const swiss = SwissConfig(
      totalRounds: 4,
      tiebreakOrder: [SwissTiebreak.buchholz],
      firstRoundPairing: 'RANDOM',
    );
    const base = {'matchType': 'SINGLES', 'bracketType': 'SWISS'};

    test('đã có stage: chỉ PATCH stage, giữ khóa khác của roundConfig', () {
      final stage = SwissStageInfo.fromJson({
        'id': 's1',
        'roundConfig': {
          'other': {'a': 1},
          'swiss': {'totalRounds': 3, 'future': true},
        },
      });

      final plan = planSwissSave(
        basePayload: base,
        divisionRoundConfig: null,
        swiss: swiss,
        stage: stage,
      );

      expect(plan.divisionPayload, isNull);
      expect(plan.stageRoundConfig!['other'], {'a': 1});
      expect(plan.stageRoundConfig!['swiss'], {
        'future': true,
        'totalRounds': 4,
        'tiebreakOrder': ['BUCHHOLZ'],
        'firstRoundPairing': 'RANDOM',
      });
    });

    test('chưa có stage: ghi roundConfig.swiss vào cấu hình nội dung', () {
      final plan = planSwissSave(
        basePayload: base,
        divisionRoundConfig: {
          'groupsConfig': {'numGroups': 2},
        },
        swiss: swiss,
        stage: null,
      );

      expect(plan.stageRoundConfig, isNull);
      expect(plan.divisionPayload!['isConfigOverride'], isTrue);
      final roundConfig =
          plan.divisionPayload!['roundConfig'] as Map<String, dynamic>;
      expect(roundConfig['groupsConfig'], {'numGroups': 2});
      expect((roundConfig['swiss'] as Map)['totalRounds'], 4);
      expect(plan.divisionPayload!['matchType'], 'SINGLES');
    });

    test('không phải Swiss: chỉ cấu hình nội dung cũ', () {
      final plan = planSwissSave(
        basePayload: base,
        divisionRoundConfig: null,
        swiss: null,
        stage: null,
      );

      expect(plan.divisionPayload, base);
      expect(plan.stageRoundConfig, isNull);
    });

    test('omitTotalRounds bỏ totalRounds khỏi payload', () {
      final plan = planSwissSave(
        basePayload: base,
        divisionRoundConfig: null,
        swiss: swiss,
        stage: null,
        omitTotalRounds: true,
      );

      final roundConfig =
          plan.divisionPayload!['roundConfig'] as Map<String, dynamic>;
      expect((roundConfig['swiss'] as Map).containsKey('totalRounds'), isFalse);
      expect((roundConfig['swiss'] as Map)['firstRoundPairing'], 'RANDOM');
    });
  });

  group('SwissApiException đọc details', () {
    test('details.errors và details.warnings', () {
      final exception = SwissApiException.fromJson({
        'statusCode': 400,
        'code': 'SWISS_INVALID_PAIRING',
        'message': 'bad',
        'details': {
          'errors': [
            {
              'code': 'MISSING_PARTICIPANT',
              'participantIds': ['p1'],
            },
          ],
          'warnings': [
            {
              'type': 'REMATCH',
              'participantIds': ['p1', 'p2'],
              'round': 1,
            },
          ],
        },
      });

      expect(exception.code, 'SWISS_INVALID_PAIRING');
      expect(exception.errors.single.code, 'MISSING_PARTICIPANT');
      expect(exception.errors.single.participantIds, ['p1']);
      expect(exception.warnings.single.type, 'REMATCH');
    });
  });

  group('số đội và cấu hình mặc định của nội dung', () {
    test('số đội lấy từ _count.participants, không có thì 0', () {
      expect(
        swissDivisionTeamCount({
          '_count': {'participants': 12},
          'maxParticipants': 64,
        }),
        12,
      );
      expect(swissDivisionTeamCount({'maxParticipants': 64}), 0);
      expect(swissDivisionTeamCount({'participantCount': 9}), 0);
    });

    test(
      'thiếu cấu hình thì dùng mặc định theo số đội, không thấp hơn đã ghép',
      () {
        final config = swissConfigOrDefault(null, 8, 0);
        expect(config.totalRounds, 3);
        expect(config.tiebreakOrder, SwissConfig.defaultTiebreakOrder);
        expect(config.firstRoundPairing, 'SEED');
        expect(swissConfigOrDefault(null, 8, 5).totalRounds, 5);
        expect(
          swissConfigOrDefault(
            {'totalRounds': 4, 'firstRoundPairing': 'RANDOM'},
            8,
            0,
          ).totalRounds,
          4,
        );
      },
    );
  });
}
