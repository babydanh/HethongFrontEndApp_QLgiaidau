class PaymentModel {
  final String id;
  final String tournamentId;
  final String participantId;
  final double amount;
  final String status; // PENDING, COMPLETED, FAILED, REFUNDED
  final String gateway; // VNPAY, MOMO, TRANSFER, PAYOS
  final String? transactionReference;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? tournamentName;
  final String? teamName;

  const PaymentModel({
    required this.id,
    required this.tournamentId,
    required this.participantId,
    required this.amount,
    required this.status,
    required this.gateway,
    this.transactionReference,
    required this.createdAt,
    this.completedAt,
    this.tournamentName,
    this.teamName,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] ?? '',
      tournamentId: json['tournamentId'] ?? '',
      participantId: json['participantId'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      status: json['status'] ?? 'PENDING',
      gateway: json['paymentGateway'] ?? json['gateway'] ?? 'VNPAY',
      transactionReference: json['transactionReference'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      tournamentName: json['tournament'] is Map
          ? (json['tournament'] as Map)['name']?.toString()
          : json['tournamentName']?.toString(),
      teamName: json['participant'] is Map
          ? (json['participant'] as Map)['teamName']?.toString()
          : json['teamName']?.toString(),
    );
  }

  bool get isCompleted => status == 'COMPLETED';
  bool get isPending => status == 'PENDING';
  bool get isFailed => status == 'FAILED';
  bool get isRefunded => status == 'REFUNDED';

  String get statusLabel {
    switch (status) {
      case 'COMPLETED':
        return 'Hoàn thành';
      case 'PENDING':
        return 'Chờ thanh toán';
      case 'FAILED':
        return 'Thất bại';
      case 'REFUNDED':
        return 'Đã hoàn tiền';
      default:
        return status;
    }
  }

  String get gatewayLabel {
    switch (gateway) {
      case 'VNPAY':
        return 'VNPAY';
      case 'MOMO':
        return 'MoMo';
      case 'TRANSFER':
        return 'Chuyển khoản';
      case 'PAYOS':
        return 'PAYOS';
      default:
        return gateway;
    }
  }
}

class CreatePaymentDto {
  final String tournamentId;
  final String participantId;
  final double amount;
  final String paymentGateway;

  const CreatePaymentDto({
    required this.tournamentId,
    required this.participantId,
    required this.amount,
    required this.paymentGateway,
  });

  Map<String, dynamic> toJson() => {
    'tournamentId': tournamentId,
    'participantId': participantId,
    'amount': amount,
    'paymentGateway': paymentGateway,
  };
}
