// import 'dart:convert';
// import 'dart:typed_data';
//
// import 'package:app_quanly_giaidau/core/services/app_logger.dart';
// import 'package:app_quanly_giaidau/core/services/dio_client.dart';
// import 'package:app_quanly_giaidau/core/services/token_manager.dart';
// import 'package:dio/dio.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class _NoTokenManager extends TokenManager {
//   @override
//   Future<String?> getAccessToken() async => null;
// }
//
// class _RecordingLogger extends AppLogger {
//   _RecordingLogger() : super('DioClientTest');
//
//   final messages = <String>[];
//
//   @override
//   void debug(String message) => messages.add(message);
// }
//
// class _StaticResponseAdapter implements HttpClientAdapter {
//   _StaticResponseAdapter({required this.statusCode, required this.data});
//
//   final int statusCode;
//   final Map<String, dynamic> data;
//
//   @override
//   Future<ResponseBody> fetch(
//     RequestOptions options,
//     Stream<Uint8List>? requestStream,
//     Future<void>? cancelFuture,
//   ) async => ResponseBody.fromString(
//     jsonEncode(data),
//     statusCode,
//     headers: {
//       Headers.contentTypeHeader: [Headers.jsonContentType],
//     },
//   );
//
//   @override
//   void close({bool force = false}) {}
// }
//
// void main() {
//   TestWidgetsFlutterBinding.ensureInitialized();
//
//   setUpAll(() {
//     dotenv.loadFromString(envString: 'API_BASE_URL=https://api.example.test');
//   });
//
//   setUp(() {
//     SharedPreferences.setMockInitialValues({});
//   });
//
//   test('debug network logs omit payout request and response data', () async {
//     final logger = _RecordingLogger();
//     final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
//       ..httpClientAdapter = _StaticResponseAdapter(
//         statusCode: 201,
//         data: {
//           'data': {
//             'bankAccountNumber': 'sensitive-account-number',
//             'bankAccountName': 'Sensitive Account Name',
//           },
//         },
//       );
//     final client = DioClient(
//       tokenManager: _NoTokenManager(),
//       dio: dio,
//       logger: logger,
//     );
//
//     await client.dio.post(
//       '/payments/payout',
//       data: {
//         'tournamentId': 'tournament-1',
//         'bankName': 'Example Bank',
//         'bankAccountNumber': 'sensitive-account-number',
//         'bankAccountName': 'Sensitive Account Name',
//         'amountRequested': 25000,
//       },
//     );
//
//     final output = logger.messages.join('\n');
//     expect(output, isNot(contains('Example Bank')));
//     expect(output, isNot(contains('sensitive-account-number')));
//     expect(output, isNot(contains('Sensitive Account Name')));
//     expect(output, contains('[REQUEST] POST /payments/payout'));
//     expect(output, contains('[RESPONSE] 201 /payments/payout'));
//   });
//
//   test('debug network logs omit sensitive error response data', () async {
//     final logger = _RecordingLogger();
//     final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
//       ..httpClientAdapter = _StaticResponseAdapter(
//         statusCode: 400,
//         data: {
//           'bankAccountNumber': 'sensitive-account-number',
//           'bankAccountName': 'Sensitive Account Name',
//         },
//       );
//     final client = DioClient(
//       tokenManager: _NoTokenManager(),
//       dio: dio,
//       logger: logger,
//     );
//
//     await expectLater(
//       client.dio.post(
//         '/payments/payout',
//         data: {'bankAccountNumber': 'sensitive-account-number'},
//       ),
//       throwsA(isA<DioException>()),
//     );
//
//     final output = logger.messages.join('\n');
//     expect(output, isNot(contains('sensitive-account-number')));
//     expect(output, isNot(contains('Sensitive Account Name')));
//     expect(output, contains('[ERROR] 400 /payments/payout'));
//   });
// }
