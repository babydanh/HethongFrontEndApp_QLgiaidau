import 'package:flutter/material.dart';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Quy chuẩn hiển thị đội/VĐV (hợp đồng `team-label-contract.md`, giống Web và
/// Backend). Đây là nguồn duy nhất cho nhãn đội/VĐV trong App: không tách
/// `teamName` theo ký tự phân cách, không tự ghép tên đội từ tên người.
///
/// - `TEAM`: hiện `teamName` khi sau khi chuẩn hoá không rỗng và không trùng
///   tên của bất kỳ VĐV nào.
/// - `PLAYERS`: hiện các VĐV trên một dòng (tối đa 2 avatar + tên nối " / "), không hiện tên đội.
/// - Tên đội không bao giờ viết tắt; tên VĐV viết tắt chỉ ở chỗ hẹp
///   ([ParticipantLabel.compact]).

/// Một VĐV của participant (đơn: 1, đôi: 2), theo thứ tự slot.
class ParticipantPlayer {
  final int slot;

  /// `null` với khách (không có tài khoản).
  final String? userId;
  final String fullName;
  final String? avatarUrl;
  final bool isGuest;

  const ParticipantPlayer({
    required this.slot,
    this.userId,
    required this.fullName,
    this.avatarUrl,
    this.isGuest = false,
  });

  factory ParticipantPlayer.fromJson(
    Map<dynamic, dynamic> json, {
    int slot = 0,
  }) {
    final user = json['user'] is Map ? json['user'] as Map : null;
    final userId =
        _nullableText(json['userId']) ??
        _nullableText(json['user_id']) ??
        _nullableText(user?['id']);
    return ParticipantPlayer(
      slot: slot,
      userId: userId,
      fullName: normalizeParticipantText(
        _nullableText(json['fullName']) ??
            _nullableText(json['full_name']) ??
            _nullableText(user?['fullName']) ??
            _nullableText(json['name']),
      ),
      avatarUrl:
          _nullableText(json['avatarUrl']) ??
          _nullableText(json['avatar_url']) ??
          _nullableText(user?['avatarUrl']) ??
          _nullableText(user?['avatar_url']),
      isGuest: json['isGuest'] == true || userId == null,
    );
  }
}

/// Kết quả quyết định hiển thị của một participant.
enum ParticipantDisplayMode { team, players }

class ParticipantDisplay {
  final ParticipantDisplayMode mode;

  /// Tên đội đã chuẩn hoá; chỉ có khi [mode] là [ParticipantDisplayMode.team].
  final String? teamName;

  /// VĐV đã lọc tên rỗng; dùng khi [mode] là [ParticipantDisplayMode.players].
  final List<ParticipantPlayer> players;

  const ParticipantDisplay._({
    required this.mode,
    this.teamName,
    this.players = const [],
  });

  bool get isTeam => mode == ParticipantDisplayMode.team;
}

/// Chuẩn hoá khoảng trắng: trim và gộp mọi khoảng trắng liên tiếp thành một.
String normalizeParticipantText(String? value) {
  if (value == null) return '';
  return value.trim().replaceAll(_whitespace, ' ');
}

final RegExp _whitespace = RegExp(r'\s+');

String? _nullableText(Object? value) {
  if (value == null) return null;
  final text = normalizeParticipantText(value.toString());
  return text.isEmpty ? null : text;
}

/// Dựng danh sách VĐV từ JSON participant.
///
/// Ưu tiên `players[]`. Nếu thiếu/rỗng (endpoint hoặc Backend cũ) thì dựng từ
/// `members[]` (hoặc `rosters[]`) + `guestNames[]` (khách, avatar null).
/// Không bao giờ dựng từ việc tách `teamName`.
List<ParticipantPlayer> toParticipantPlayers(Map<dynamic, dynamic> json) {
  final fromPlayers = json['players'];
  if (fromPlayers is List) {
    final players = <ParticipantPlayer>[];
    for (final entry in fromPlayers) {
      if (entry is! Map) continue;
      final player = ParticipantPlayer.fromJson(
        entry,
        slot: players.length + 1,
      );
      if (player.fullName.isEmpty) continue;
      players.add(player);
    }
    if (players.isNotEmpty) return _uniquePlayers(players);
  }

  final members = json['members'] ?? json['rosters'];
  final players = <ParticipantPlayer>[];
  if (members is List) {
    for (final entry in members) {
      if (entry is Map) {
        final player = ParticipantPlayer.fromJson(
          entry,
          slot: players.length + 1,
        );
        if (player.fullName.isEmpty) continue;
        players.add(player);
      } else {
        final name = _nullableText(entry);
        if (name == null) continue;
        players.add(
          ParticipantPlayer(
            slot: players.length + 1,
            fullName: name,
            isGuest: true,
          ),
        );
      }
    }
  }
  final guestNames = json['guestNames'];
  if (guestNames is List) {
    for (final entry in guestNames) {
      final name = _nullableText(entry);
      if (name == null) continue;
      players.add(
        ParticipantPlayer(
          slot: players.length + 1,
          fullName: name,
          isGuest: true,
        ),
      );
    }
  }
  return _uniquePlayers(players);
}

/// Drops repeated players (same userId, or same normalised name for guests)
/// keeping the first one, and renumbers slots from 1.
List<ParticipantPlayer> _uniquePlayers(List<ParticipantPlayer> players) {
  final seen = <String>{};
  final unique = <ParticipantPlayer>[];
  for (final p in players) {
    final key = p.userId != null
        ? 'u:${p.userId}'
        : 'n:${normalizeParticipantText(p.fullName).toLowerCase()}';
    if (!seen.add(key)) continue;
    unique.add(
      ParticipantPlayer(
        slot: unique.length + 1,
        userId: p.userId,
        fullName: p.fullName,
        avatarUrl: p.avatarUrl,
        isGuest: p.isGuest,
      ),
    );
  }
  return unique;
}

/// VĐV từ roster của match (`team1MemberInfos`/`team2MemberInfos`).
List<ParticipantPlayer> participantPlayersFromMemberInfos(
  List<MatchMemberInfo> infos,
) {
  final players = <ParticipantPlayer>[];
  for (final info in infos) {
    final name = normalizeParticipantText(info.fullName);
    if (name.isEmpty) continue;
    players.add(
      ParticipantPlayer(
        slot: players.length + 1,
        userId: info.userId,
        fullName: name,
        avatarUrl: info.avatarUrl,
        isGuest: info.userId == null,
      ),
    );
  }
  return _uniquePlayers(players);
}

/// VĐV khách từ tên thuần (`team1Members`/`guestNames` của match).
List<ParticipantPlayer> participantPlayersFromNames(Iterable<String> names) {
  final players = <ParticipantPlayer>[];
  for (final name in names) {
    final normalized = normalizeParticipantText(name);
    if (normalized.isEmpty) continue;
    players.add(
      ParticipantPlayer(
        slot: players.length + 1,
        fullName: normalized,
        isGuest: true,
      ),
    );
  }
  return _uniquePlayers(players);
}

/// Quyết định TEAM hay PLAYERS.
///
/// [teamOnly] = bóng đá: tên đội bóng là tên thật, luôn TEAM khi có tên.
ParticipantDisplay resolveParticipantDisplay({
  required String? teamName,
  required List<ParticipantPlayer> players,
  bool teamOnly = false,
}) {
  final name = normalizeParticipantText(teamName);
  final filtered = players
      .where((p) => normalizeParticipantText(p.fullName).isNotEmpty)
      .toList(growable: false);
  if (name.isNotEmpty) {
    final key = name.toLowerCase();
    final clashesWithPlayer = filtered.any(
      (p) => normalizeParticipantText(p.fullName).toLowerCase() == key,
    );
    // Backend may auto-fill teamName with the players' names joined by " / ".
    final joinedNames = filtered
        .map((p) => normalizeParticipantText(p.fullName))
        .join(' / ')
        .toLowerCase();
    final isJoinedNames = filtered.length > 1 && key == joinedNames;
    if (teamOnly || !(clashesWithPlayer || isJoinedNames)) {
      return ParticipantDisplay._(
        mode: ParticipantDisplayMode.team,
        teamName: name,
      );
    }
  }
  return ParticipantDisplay._(
    mode: ParticipantDisplayMode.players,
    players: filtered,
  );
}

/// Viết tắt tên người: mỗi chữ trước chữ cuối lấy chữ cái đầu + "." (in hoa),
/// chữ cuối giữ nguyên. Ví dụ `Nguyễn Thị Minh Khai` → `N. T. M. Khai`.
String abbreviateName(String fullName) {
  final words = normalizeParticipantText(
    fullName,
  ).split(' ').where((w) => w.isNotEmpty).toList(growable: false);
  if (words.isEmpty) return '';
  if (words.length == 1) return words.single;
  final initials = [
    for (final word in words.take(words.length - 1))
      '${String.fromCharCode(word.runes.first).toUpperCase()}.',
  ];
  return '${initials.join(' ')} ${words.last}';
}

/// Nhãn chuỗi (title, share, tìm kiếm, Excel). Không bao giờ gửi lên API.
/// PLAYERS nối tên VĐV bằng " / ". [abbreviated] = true khi chỗ hiển thị hẹp.
String participantLabel({
  required String? teamName,
  required List<ParticipantPlayer> players,
  bool teamOnly = false,
  bool abbreviated = false,
}) {
  final display = resolveParticipantDisplay(
    teamName: teamName,
    players: players,
    teamOnly: teamOnly,
  );
  if (display.isTeam) return display.teamName!;
  return display.players
      .map((p) => abbreviated ? abbreviateName(p.fullName) : p.fullName)
      .join(' / ');
}

/// Hiển thị đội/VĐV theo quy chuẩn chung.
///
/// [compact] (sơ đồ nhánh, thẻ trận, lịch sân, overlay): VĐV viết tắt, một
/// dòng gồm tối đa 2 avatar chồng nhau + tên nối " / ", tên đầy đủ hiện qua
/// Tooltip/nhấn giữ. Tên đội luôn đầy đủ, cắt "…" khi dài và hiện đầy đủ qua
/// Tooltip.
class ParticipantLabel extends StatelessWidget {
  final String? teamName;
  final List<ParticipantPlayer> players;
  final bool teamOnly;
  final bool compact;
  final TextStyle? style;
  final TextAlign textAlign;
  final CrossAxisAlignment crossAxisAlignment;

  const ParticipantLabel({
    super.key,
    required this.teamName,
    required this.players,
    this.teamOnly = false,
    this.compact = false,
    this.style,
    this.textAlign = TextAlign.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final display = resolveParticipantDisplay(
      teamName: teamName,
      players: players,
      teamOnly: teamOnly,
    );
    final baseStyle = style ?? DefaultTextStyle.of(context).style;

    if (display.isTeam) {
      final name = display.teamName!;
      return Tooltip(
        message: name,
        child: Text(
          name,
          style: baseStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
        ),
      );
    }

    if (display.players.isEmpty) {
      return Text(
        AppLocalizations.of(context)!.matchNotDetermined,
        style: baseStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: textAlign,
      );
    }

    final colors = context.colors;
    final avatarRadius = compact ? 7.0 : 11.0;
    final rowGap = compact ? 4.0 : 6.0;
    final shown = display.players.take(_maxAvatars).toList(growable: false);
    final overlap = avatarRadius * 1.3;
    final names = display.players
        .map((p) => compact ? abbreviateName(p.fullName) : p.fullName)
        .join(' / ');
    return Tooltip(
      message: display.players.map((p) => p.fullName).join(' / '),
      child: Row(
        // Fill the width only when the label is aligned to the end/centre.
        mainAxisSize: crossAxisAlignment == CrossAxisAlignment.start
            ? MainAxisSize.min
            : MainAxisSize.max,
        mainAxisAlignment: switch (crossAxisAlignment) {
          CrossAxisAlignment.end => MainAxisAlignment.end,
          CrossAxisAlignment.center => MainAxisAlignment.center,
          _ => MainAxisAlignment.start,
        },
        children: [
          ExcludeSemantics(
            child: SizedBox(
              width: avatarRadius * 2 + overlap * (shown.length - 1),
              height: avatarRadius * 2,
              child: Stack(
                children: [
                  for (var i = 0; i < shown.length; i++)
                    PositionedDirectional(
                      start: overlap * i,
                      child: _PlayerAvatar(
                        name: shown[i].fullName,
                        avatarUrl: shown[i].avatarUrl,
                        radius: avatarRadius,
                        backgroundColor: colors.bgSurface,
                        textStyle: baseStyle.copyWith(
                          fontSize: avatarRadius * 0.9,
                          color: colors.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(width: rowGap),
          Flexible(
            child: Text(
              names,
              style: baseStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: textAlign,
            ),
          ),
        ],
      ),
    );
  }
}

const int _maxAvatars = 2;

class _PlayerAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double radius;
  final Color backgroundColor;
  final TextStyle textStyle;

  const _PlayerAvatar({
    required this.name,
    required this.avatarUrl,
    required this.radius,
    required this.backgroundColor,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: url == null ? null : NetworkImage(url),
      onBackgroundImageError: url == null ? null : (_, _) {},
      child: url == null ? Text(_initials(name), style: textStyle) : null,
    );
  }
}

String _initials(String name) {
  final words = normalizeParticipantText(
    name,
  ).split(' ').where((w) => w.isNotEmpty).toList(growable: false);
  if (words.isEmpty) return '?';
  return String.fromCharCode(words.first.runes.first).toUpperCase();
}
