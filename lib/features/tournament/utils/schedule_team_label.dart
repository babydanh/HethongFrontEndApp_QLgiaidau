/// Tên đội rút gọn cho thẻ trận trong lưới lịch, cùng quy tắc lịch web
/// (`formatCompetitorDisplay` ở PublicCourtScheduleBoard): mỗi VĐV giữ 2 từ
/// cuối, cặp đôi nối bằng " / ".
///
/// [members] (roster) được ưu tiên; không có thì tách [fullName] theo "/", "&"
/// hoặc " - " như web.
String scheduleShortTeamName(
  String fullName, {
  List<String> members = const [],
}) {
  final players = members.where((m) => m.trim().isNotEmpty).length >= 2
      ? members.where((m) => m.trim().isNotEmpty).toList()
      : _splitPlayers(fullName);
  return players.map(_shortTwoWords).join(' / ');
}

final RegExp _pairSeparator = RegExp(r'[/&]');
final RegExp _whitespace = RegExp(r'\s+');

/// Tiền tố tên thử nghiệm/nhóm mà web bỏ khi hiện lịch.
final RegExp _namePrefix = RegExp(
  r'^(QA\s*|Cặp\s*|Đôi\s*|VĐV\s*|Đội\s*)',
  caseSensitive: false,
);

List<String> _splitPlayers(String fullName) {
  final full = fullName.trim();
  if (full.isEmpty) return const [''];
  final parts = full.contains(_pairSeparator)
      ? full.split(_pairSeparator)
      : full.contains(' - ')
      ? full.split(' - ')
      : [full];
  final players = parts.map((p) => p.trim()).where((p) => p.isNotEmpty);
  return players.isEmpty ? [full] : players.toList();
}

String _shortTwoWords(String name) {
  final cleaned = name.trim().replaceFirst(_namePrefix, '').trim();
  final words = cleaned.split(_whitespace).where((w) => w.isNotEmpty).toList();
  if (words.length <= 2) return cleaned;
  return words.sublist(words.length - 2).join(' ');
}
