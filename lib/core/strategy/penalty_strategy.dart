import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';

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
  List<PenaltyOption> getOptions() => [
        const PenaltyOption(id: 'yellow_card', name: 'Thẻ Vàng (Cảnh cáo)', color: Colors.amber, icon: Icons.style),
        const PenaltyOption(id: 'red_card', name: 'Thẻ Đỏ (Phạt điểm)', color: Colors.red, icon: Icons.style),
        const PenaltyOption(id: 'black_card', name: 'Thẻ Đen (Truất quyền)', color: Colors.black, icon: Icons.style),
      ];

  @override
  String getRulesDescription() => 
      '1. Thẻ Vàng: Cảnh cáo cho lỗi hành vi lần đầu.\n'
      '2. Thẻ Đỏ: Phạt 1 điểm cho đối phương (nếu tái phạm).\n'
      '3. Thẻ Đen: Truất quyền thi đấu ngay lập tức (lỗi cực kỳ nghiêm trọng).';
}



class TennisPenaltyStrategy implements IPenaltyStrategy {
  @override
  List<PenaltyOption> getOptions() => [
        const PenaltyOption(id: 'warning', name: 'Cảnh cáo', color: Colors.amber, icon: Icons.warning_rounded),
        const PenaltyOption(id: 'point_penalty', name: 'Phạt điểm', color: Colors.orange, icon: Icons.remove_circle_outline),
        const PenaltyOption(id: 'game_penalty', name: 'Phạt Game/Match', color: Colors.red, icon: Icons.cancel_outlined),
      ];

  @override
  String getRulesDescription() => 
      '1. Cảnh cáo (Warning): Lần vi phạm đầu tiên.\n'
      '2. Phạt điểm (Point Penalty): Lần vi phạm thứ 2.\n'
      '3. Phạt Game/Truất quyền: Lần vi phạm thứ 3 trở đi.';
}

class PickleballPenaltyStrategy implements IPenaltyStrategy {
  @override
  List<PenaltyOption> getOptions() => [
        const PenaltyOption(id: 'tech_warning', name: 'Technical Warning', color: Colors.amber, icon: Icons.warning_rounded),
        const PenaltyOption(id: 'tech_foul', name: 'Technical Foul', color: Colors.red, icon: Icons.sports_score),
      ];

  @override
  String getRulesDescription() => 
      '1. Technical Warning: Cảnh cáo hành vi không chuẩn mực (không bị phạt điểm).\n'
      '2. Technical Foul: Lỗi kỹ thuật nghiêm trọng hoặc tái phạm (bị trừ điểm hoặc đối phương được cộng điểm).';
}

class DefaultPenaltyStrategy implements IPenaltyStrategy {
  @override
  List<PenaltyOption> getOptions() => [
        const PenaltyOption(id: 'warning', name: 'Cảnh cáo', color: Colors.amber, icon: Icons.warning_rounded),
        const PenaltyOption(id: 'foul', name: 'Lỗi / Truất quyền', color: Colors.red, icon: Icons.gavel),
      ];

  @override
  String getRulesDescription() => 'Tùy theo quy định cụ thể của giải đấu và ban tổ chức.';
}

class PenaltyStrategyFactory {
  static IPenaltyStrategy getStrategy(String sportType) {
    switch (sportType) {
      case AppConstants.sportBadminton:
        return BadmintonPenaltyStrategy();
      case AppConstants.sportTennis:
      case AppConstants.sportTableTennis:
        return TennisPenaltyStrategy();
      case AppConstants.sportPickleball:
        return PickleballPenaltyStrategy();
      default:
        return DefaultPenaltyStrategy();
    }
  }
}
