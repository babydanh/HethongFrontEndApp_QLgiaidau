import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/community_social_models.dart';

/// Loại text pill hiển thị cạnh tên thành viên (P2C.4/P2C.5) — không emoji.
enum MemberTagChipKind {
  /// Tag BQT — trung tính (surface + border).
  bqt,

  /// Streak thắng liên tiếp — success.
  win,

  /// Streak thua liên tiếp — error.
  loss,

  /// ELO tăng trong tuần — warning.
  eloUp,
}

/// P2C.5 — Text pill dùng chung cho tag BQT và streak (màu từ AppTheme, radius 8).
class MemberTagChip extends StatelessWidget {
  final String label;
  final MemberTagChipKind kind;

  const MemberTagChip({
    super.key,
    required this.label,
    this.kind = MemberTagChipKind.bqt,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Color bg;
    final Color fg;
    final Color border;
    switch (kind) {
      case MemberTagChipKind.bqt:
        bg = colors.bgSurface;
        fg = colors.textSecondary;
        border = colors.border;
      case MemberTagChipKind.win:
        bg = colors.success.withValues(alpha: 0.12);
        fg = colors.success;
        border = colors.success.withValues(alpha: 0.35);
      case MemberTagChipKind.loss:
        bg = colors.error.withValues(alpha: 0.12);
        fg = colors.error;
        border = colors.error.withValues(alpha: 0.35);
      case MemberTagChipKind.eloUp:
        bg = colors.warning.withValues(alpha: 0.12);
        fg = colors.warning;
        border = colors.warning.withValues(alpha: 0.35);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
          height: 1.3,
        ),
      ),
    );
  }
}

/// P2C.5 — Ánh xạ streak model (P2C.3) sang chip hiển thị.
/// Backend luôn gửi `label` khi có streak (P2C.3); thiếu label → không hiển thị
/// (tránh hardcode chuỗi fallback — mọi chuỗi từ AppConstants/l10n).
class StreakChip extends StatelessWidget {
  final String? type; // 'WIN' | 'LOSS' | 'ELO_UP'
  final int count;
  final String? label;

  const StreakChip({super.key, this.type, this.count = 0, this.label});

  @override
  Widget build(BuildContext context) {
    final text = label;
    if (text == null || text.isEmpty || count <= 0) {
      return const SizedBox.shrink();
    }
    final MemberTagChipKind kind = switch (type) {
      'WIN' => MemberTagChipKind.win,
      'LOSS' => MemberTagChipKind.loss,
      'ELO_UP' => MemberTagChipKind.eloUp,
      _ => MemberTagChipKind.bqt,
    };
    return MemberTagChip(label: text, kind: kind);
  }
}

/// Giải mã màu hex "#RRGGBB" từ tag preset; sai định dạng → null (fallback xám).
Color? presetHexToColor(String? hex) {
  if (hex == null) return null;
  final clean = hex.replaceFirst('#', '');
  if (clean.length != 6) return null;
  final value = int.tryParse('FF$clean', radix: 16);
  return value == null ? null : Color(value);
}

/// Style hiển thị tag preset — đồng bộ web:
/// - solid: nền màu đặc (bài viết, chat, profile)
/// - tint: nền màu 15% + chữ màu (danh sách thành viên)
enum PresetTagChipStyle { solid, tint }

/// Chip tag thành viên với màu từ tag preset của CLB (khớp tên không phân biệt
/// hoa/thường như web). Không có preset tương ứng → chip xám trung tính.
class PresetTagChip extends StatelessWidget {
  final String label;
  final Color? color;
  final PresetTagChipStyle style;

  /// Chấm màu nhỏ phía trước chữ (section "Danh hiệu CLB" ở profile).
  final bool showDot;

  const PresetTagChip({
    super.key,
    required this.label,
    this.color,
    this.style = PresetTagChipStyle.solid,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Color bg;
    final Color fg;
    final Color border;

    if (color == null) {
      // Fallback xám — same web (#f1f5f9 / #cbd5e1 / #1e293b).
      bg = colors.bgSurface;
      fg = colors.textSecondary;
      border = colors.border;
    } else {
      switch (style) {
        case PresetTagChipStyle.solid:
          bg = color!;
          fg = const Color(0xFF0F172A);
          border = color!.withValues(alpha: 0.6);
        case PresetTagChipStyle.tint:
          bg = color!.withValues(alpha: 0.15);
          fg = _readableOnTint(color!);
          border = color!.withValues(alpha: 0.4);
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fg.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  /// Chữ màu preset trên nền tint — dùng màu đậm hơn chút cho dễ đọc ở dark mode.
  Color _readableOnTint(Color base) => base;
}

/// Tìm màu preset theo tên tag (không phân biệt hoa/thường) — dùng chung
/// cho mọi nơi hiển thị tag.
Color? resolvePresetColor(List<CommunityTagPreset> presets, String tag) {
  for (final preset in presets) {
    if (preset.name.toLowerCase() == tag.toLowerCase()) {
      return presetHexToColor(preset.color);
    }
  }
  return null;
}
