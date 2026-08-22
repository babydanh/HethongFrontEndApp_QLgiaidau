import 'dart:ui';

import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

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
  final String? divisionId;

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
    this.divisionId,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    final pMap = json['payment'] is Map<String, dynamic>
        ? json['payment'] as Map<String, dynamic>
        : (json['payment'] is Map
              ? Map<String, dynamic>.from(json['payment'] as Map)
              : json);

    final rawAmount = pMap['amount'] ?? json['amount'];
    final parsedAmount = double.tryParse(rawAmount?.toString() ?? '0') ?? 0;

    return PaymentModel(
      id: (pMap['id'] ?? json['id'])?.toString() ?? '',
      tournamentId:
          (pMap['tournamentId'] ?? json['tournamentId'])?.toString() ?? '',
      participantId:
          (pMap['participantId'] ?? json['participantId'])?.toString() ?? '',
      amount: parsedAmount,
      status: (pMap['status'] ?? json['status'])?.toString() ?? 'PENDING',
      gateway:
          (pMap['paymentGateway'] ??
                  pMap['gateway'] ??
                  json['paymentGateway'] ??
                  json['gateway'])
              ?.toString() ??
          'PAYOS',
      transactionReference:
          (pMap['transactionReference'] ?? json['transactionReference'])
              ?.toString(),
      createdAt: pMap['createdAt'] != null
          ? DateTime.parse(pMap['createdAt'])
          : (json['createdAt'] != null
                ? DateTime.parse(json['createdAt'])
                : DateTime.now()),
      completedAt: pMap['paidAt'] != null
          ? DateTime.parse(pMap['paidAt'])
          : (pMap['completedAt'] != null
                ? DateTime.parse(pMap['completedAt'])
                : (json['completedAt'] != null
                      ? DateTime.parse(json['completedAt'])
                      : null)),
      tournamentName: json['tournament'] is Map
          ? (json['tournament'] as Map)['name']?.toString()
          : (pMap['tournament'] is Map
                ? (pMap['tournament'] as Map)['name']?.toString()
                : json['tournamentName']?.toString()),
      teamName: json['participant'] is Map
          ? (json['participant'] as Map)['teamName']?.toString()
          : (pMap['participant'] is Map
                ? (pMap['participant'] as Map)['teamName']?.toString()
                : json['teamName']?.toString()),
      divisionId:
          (pMap['divisionId'] ??
                  pMap['tournamentDivisionId'] ??
                  json['divisionId'] ??
                  json['tournamentDivisionId'])
              ?.toString(),
    );
  }

  bool get isCompleted => status == 'COMPLETED';
  bool get isPending => status == 'PENDING';
  bool get isFailed => status == 'FAILED';
  bool get isRefunded => status == 'REFUNDED';
  bool get isTerminalFailure =>
      status == 'FAILED' ||
      status == 'CANCELLED' ||
      status == 'EXPIRED' ||
      status == 'REFUNDED';
  bool get isRetryable =>
      status == 'PENDING' ||
      status == 'FAILED' ||
      status == 'CANCELLED' ||
      status == 'EXPIRED';

  String get statusLabel =>
      localizedStatusLabel(lookupAppLocalizations(PlatformDispatcher.instance.locale));

  String localizedStatusLabel(AppLocalizations l10n) {
    switch (status) {
      case 'COMPLETED':
        return l10n.paymentStatusCompleted;
      case 'PENDING':
        return l10n.paymentStatusPending;
      case 'FAILED':
        return l10n.paymentStatusFailed;
      case 'REFUNDED':
        return l10n.paymentStatusRefunded;
      case 'CANCELLED':
        return l10n.paymentStatusCancelled;
      case 'EXPIRED':
        return l10n.paymentStatusExpired;
      default:
        return status;
    }
  }

  String get gatewayLabel =>
      localizedGatewayLabel(lookupAppLocalizations(PlatformDispatcher.instance.locale));

  String localizedGatewayLabel(AppLocalizations l10n) {
    switch (gateway) {
      case 'VNPAY':
        return 'VNPAY';
      case 'MOMO':
        return 'MoMo';
      case 'TRANSFER':
        return l10n.paymentGatewayTransfer;
      case 'PAYOS':
        return 'PAYOS';
      default:
        return gateway;
    }
  }
}

class CreatePaymentDto {
  final String tournamentId;
  final String? participantId;
  final String? purpose;
  final String? divisionId;
  final double? amount;

  const CreatePaymentDto({
    required this.tournamentId,
    this.participantId,
    this.purpose = 'REGISTRATION_FEE',
    this.divisionId,
    this.amount,
  });

  Map<String, dynamic> toJson() => {
    'tournamentId': tournamentId,
    'purpose': purpose ?? 'REGISTRATION_FEE',
    if (isValidUuid(participantId)) 'participantId': participantId!.trim(),
    if (isValidUuid(divisionId)) 'divisionId': divisionId!.trim(),
    if (amount != null && amount! > 0) 'amount': amount,
  };
}

final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
);

bool isValidUuid(String? value) {
  final normalized = value?.trim();
  return normalized != null && _uuidPattern.hasMatch(normalized);
}
