import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Bộ icon thể thức thi đấu vẽ chuẩn 1:1 theo SVG của hệ thống Web:
/// 1. Single Elimination (Loại trực tiếp): Nhánh đấu đơn gộp vào nhánh chung kết
/// 2. Round Robin (Vòng tròn tính điểm): Vòng tròn 2 mũi tên xoay tròn (RotateCw)
/// 3. Group Stage + Knockout (Vòng bảng + loại trực tiếp): 2 bảng ô vuông nối nhánh ra bán kết/chung kết
/// 4. Double Elimination (Nhánh thắng/thua): Nhánh đấu kép 2 tầng trên và dưới
class BracketFormatIcons {
  static const String singleEliminationSvg = '''
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M3 5h4v6H3" />
  <path d="M3 19h4v-6H3" />
  <path d="M7 8h6v8H7" />
  <path d="M13 12h8" />
</svg>
''';

  static const String roundRobinSvg = '''
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M21 12a9 9 0 0 0-9-9 9.75 9.75 0 0 0-6.74 2.74L3 8" />
  <path d="M3 3v5h5" />
  <path d="M3 12a9 9 0 0 0 9 9 9.75 9.75 0 0 0 6.74-2.74L21 16" />
  <path d="M16 21h5v-5" />
</svg>
''';

  static const String groupStageKnockoutSvg = '''
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <rect x="3" y="4" width="6" height="6" rx="1.5" />
  <rect x="3" y="14" width="6" height="6" rx="1.5" />
  <path d="M9 7h4v4h4" />
  <path d="M9 17h4v-4" />
  <path d="M17 11h4" />
</svg>
''';

  static const String doubleEliminationSvg = '''
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M3 4h4v3H3" />
  <path d="M7 5.5h5v2.5" />
  <path d="M3 11h4v3H3" />
  <path d="M7 12.5h5v-2" />
  <path d="M12 9h4v3h-4" />
  <path d="M16 10.5h5" />
  <path d="M3 18h4v2H3" />
  <path d="M7 19h9v-7" />
</svg>
''';

  static Widget getIcon(
    String? bracketType, {
    double size = 18,
    Color color = Colors.black,
    String? fallbackBracketType,
  }) {
    final raw = (bracketType != null && bracketType.trim().isNotEmpty)
        ? bracketType
        : (fallbackBracketType ?? '');
    final type = raw.toUpperCase();

    String rawSvg;
    if (type.contains('ROUND_ROBIN') || type.contains('ROBIN') || type.contains('VÒNG TRÒN')) {
      rawSvg = roundRobinSvg;
    } else if (type.contains('GROUP_STAGE') || type.contains('GROUP') || type.contains('BẢNG')) {
      rawSvg = groupStageKnockoutSvg;
    } else if (type.contains('DOUBLE_ELIMINATION') ||
        type.contains('DOUBLE_ELIM') ||
        type.contains('NHÁNH KÉP') ||
        type.contains('THẮNG/THUA') ||
        type.contains('THẮNG THUA')) {
      rawSvg = doubleEliminationSvg;
    } else {
      rawSvg = singleEliminationSvg;
    }

    return SvgPicture.string(
      rawSvg,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  /// Lấy tên định dạng thể thức chuẩn hóa đa ngôn ngữ (VI / EN)
  static String getFormatLabel(
    BuildContext context,
    String? bracketType, [
    String? fallbackBracketType,
  ]) {
    final l10n = AppLocalizations.of(context);
    final raw = (bracketType != null && bracketType.trim().isNotEmpty)
        ? bracketType
        : (fallbackBracketType ?? '');
    final type = raw.toUpperCase();

    if (type.contains('ROUND_ROBIN') ||
        type.contains('ROBIN') ||
        type.contains('VÒNG TRÒN')) {
      return l10n?.roundRobin ?? 'Vòng tròn';
    }
    if (type.contains('GROUP_STAGE') ||
        type.contains('GROUP') ||
        type.contains('BẢNG')) {
      return l10n?.createClubTournament_bracketGroupStageKnockout ??
          'Vòng bảng + Loại trực tiếp';
    }
    if (type.contains('DOUBLE_ELIMINATION') ||
        type.contains('DOUBLE_ELIM') ||
        type.contains('NHÁNH KÉP') ||
        type.contains('THẮNG/THUA') ||
        type.contains('THẮNG THUA')) {
      return l10n?.eliminationDouble ?? 'Nhánh thắng/thua';
    }
    if (type.contains('SINGLE_ELIMINATION') ||
        type.contains('SINGLE') ||
        type.contains('LOẠI TRỰC TIẾP')) {
      return l10n?.eliminationSingle ?? 'Loại trực tiếp';
    }
    return raw.isNotEmpty ? raw : (l10n?.eliminationSingle ?? 'Loại trực tiếp');
  }
}
