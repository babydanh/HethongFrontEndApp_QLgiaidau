import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/widgets/app_icons.dart';

class PenaltyOption {
  final String id;
  final String name;
  final Color color;
  final IconData icon;

  const PenaltyOption({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
  });
}

abstract class IPenaltyStrategy {
  List<PenaltyOption> getOptions();
  String getRulesDescription();
}

class BadmintonPenaltyStrategy implements IPenaltyStrategy {
  @override
  List<PenaltyOption> getOptions() => const [
    PenaltyOption(
      id: 'WARNING',
      name: 'Nhắc nhở',
      color: Colors.amber,
      icon: AppIcons.warning,
    ),
    PenaltyOption(
      id: 'SERVICE_FAULT',
      name: 'Lỗi giao cầu',
      color: Colors.orange,
      icon: AppIcons.trophy,
    ),
    PenaltyOption(
      id: 'MISCONDUCT',
      name: 'Hành vi không đúng mực',
      color: Colors.deepOrange,
      icon: AppIcons.shield,
    ),
    PenaltyOption(
      id: 'YELLOW_CARD',
      name: 'Thẻ vàng',
      color: Colors.amber,
      icon: AppIcons.sparkles,
    ),
    PenaltyOption(
      id: 'RED_CARD',
      name: 'Thẻ đỏ',
      color: Colors.red,
      icon: AppIcons.sparkles,
    ),
  ];

  @override
  String getRulesDescription() =>
      'Cảnh báo, lỗi kỹ thuật và thẻ được ghi theo quyết định của trọng tài/BTC.';
}

class TennisPenaltyStrategy implements IPenaltyStrategy {
  @override
  List<PenaltyOption> getOptions() => const [
    PenaltyOption(
      id: 'WARNING',
      name: 'Nhắc nhở',
      color: Colors.amber,
      icon: AppIcons.warning,
    ),
    PenaltyOption(
      id: 'CODE_VIOLATION',
      name: 'Vi phạm tác phong',
      color: Colors.orange,
      icon: AppIcons.shield,
    ),
    PenaltyOption(
      id: 'POINT_PENALTY',
      name: 'Phạt 1 điểm',
      color: Colors.deepOrange,
      icon: AppIcons.cancel,
    ),
    PenaltyOption(
      id: 'GAME_PENALTY',
      name: 'Phạt 1 game',
      color: Colors.red,
      icon: AppIcons.cancel,
    ),
  ];

  @override
  String getRulesDescription() =>
      'Tennis không dùng thẻ màu riêng; có cảnh báo, vi phạm tác phong, phạt điểm và phạt game.';
}

class PickleballPenaltyStrategy implements IPenaltyStrategy {
  @override
  List<PenaltyOption> getOptions() => const [
    PenaltyOption(
      id: 'WARNING',
      name: 'Cảnh cáo',
      color: Colors.amber,
      icon: AppIcons.warning,
    ),
    PenaltyOption(
      id: 'SERVICE_FAULT',
      name: 'Lỗi giao bóng',
      color: Colors.orange,
      icon: AppIcons.trophy,
    ),
    PenaltyOption(
      id: 'TECHNICAL_FAULT',
      name: 'Lỗi kỹ thuật',
      color: Colors.red,
      icon: AppIcons.shield,
    ),
    PenaltyOption(
      id: 'UNSPORTSMANLIKE',
      name: 'Thi đấu thiếu fair-play',
      color: Colors.deepOrange,
      icon: AppIcons.sportBadminton,
    ),
  ];

  @override
  String getRulesDescription() =>
      'Lỗi kỹ thuật được ghi nhận riêng; không tự động cộng điểm khi chưa có quyết định xử điểm.';
}

class TableTennisPenaltyStrategy implements IPenaltyStrategy {
  @override
  List<PenaltyOption> getOptions() => const [
    PenaltyOption(
      id: 'WARNING',
      name: 'Nhắc nhở',
      color: Colors.amber,
      icon: AppIcons.warning,
    ),
    PenaltyOption(
      id: 'SERVICE_FAULT',
      name: 'Lỗi giao bóng',
      color: Colors.orange,
      icon: AppIcons.trophy,
    ),
    PenaltyOption(
      id: 'MISCONDUCT',
      name: 'Hành vi không đúng mực',
      color: Colors.deepOrange,
      icon: AppIcons.shield,
    ),
    PenaltyOption(
      id: 'YELLOW_CARD',
      name: 'Thẻ vàng',
      color: Colors.amber,
      icon: AppIcons.sparkles,
    ),
    PenaltyOption(
      id: 'RED_CARD',
      name: 'Thẻ đỏ',
      color: Colors.red,
      icon: AppIcons.sparkles,
    ),
  ];

  @override
  String getRulesDescription() =>
      'Cảnh báo, lỗi kỹ thuật và thẻ được ghi theo preset bóng bàn của hệ thống.';
}

class DefaultPenaltyStrategy implements IPenaltyStrategy {
  @override
  List<PenaltyOption> getOptions() => const [
    PenaltyOption(
      id: 'WARNING',
      name: 'Nhắc nhở',
      color: Colors.amber,
      icon: AppIcons.warning,
    ),
    PenaltyOption(
      id: 'FOUL',
      name: 'Lỗi / Truất quyền',
      color: Colors.red,
      icon: AppIcons.shield,
    ),
  ];

  @override
  String getRulesDescription() =>
      'Áp dụng theo quy định cụ thể của giải đấu và ban tổ chức.';
}

class PenaltyStrategyFactory {
  static IPenaltyStrategy getStrategy(String sportType) {
    switch (sportType) {
      case AppConstants.sportBadminton:
        return BadmintonPenaltyStrategy();
      case AppConstants.sportTennis:
        return TennisPenaltyStrategy();
      case AppConstants.sportTableTennis:
        return TableTennisPenaltyStrategy();
      case AppConstants.sportPickleball:
        return PickleballPenaltyStrategy();
      default:
        return DefaultPenaltyStrategy();
    }
  }
}
