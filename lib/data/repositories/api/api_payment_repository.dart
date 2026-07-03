import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/data/models/payment_model.dart';

class PaymentRepository {
  static const _log = AppLogger('PaymentRepo');
  final DioClient _dioClient;

  PaymentRepository(this._dioClient);

  Future<List<PaymentModel>> getMyPayments() async {
    try {
      final response = await _dioClient.dio.get('/payments/me');
      if (response.statusCode == 200) {
        final List<dynamic> list = response.data['data'] ?? [];
        return list.map((json) => PaymentModel.fromJson(json)).toList();
      }
      return [];
    } catch (e, stack) {
      _log.error('Error fetching payments', e, stack);
      return [];
    }
  }

  Future<PaymentModel?> getPaymentById(String id) async {
    try {
      final response = await _dioClient.dio.get('/payments/$id');
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null) return PaymentModel.fromJson(data);
      }
      return null;
    } catch (e, stack) {
      _log.error('Error fetching payment $id', e, stack);
      return null;
    }
  }

  Future<Map<String, dynamic>?> createPaymentLink(CreatePaymentDto dto) async {
    try {
      final response = await _dioClient.dio.post('/payments/create-link', data: dto.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['data'];
      }
      return null;
    } catch (e, stack) {
      _log.error('Error creating payment link', e, stack);
      return null;
    }
  }

  Future<bool> mockVerify(String paymentId) async {
    try {
      final response = await _dioClient.dio.post('/payments/mock-verify', data: {
        'paymentId': paymentId,
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e, stack) {
      _log.error('Error verifying payment', e, stack);
      return false;
    }
  }
}
