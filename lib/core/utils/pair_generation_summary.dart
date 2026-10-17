// Đọc response ghép ngẫu nhiên `POST /tournaments/lite/:id/pairs/generate`.
// Server trả `paired` (mỗi cặp có `memberNames`), `unpairedParticipantIds`
// và `unpairedNames`. Thiếu trường thì coi là rỗng, không báo lỗi.

Map<dynamic, dynamic>? _pairBodyOf(Object? raw) {
  if (raw is! Map) return null;
  final data = raw['data'];
  return data is Map ? data : raw;
}

/// Đổi id người lẻ thành tên; id không tra được thì giữ `#id` để không mất người.
List<String> unpairedDisplayNames(
  List<String> ids,
  Map<String, String> namesById,
) {
  return [
    for (final id in ids)
      if ((namesById[id] ?? '').trim().isNotEmpty)
        namesById[id]!.trim()
      else
        '#$id',
  ];
}

/// Mỗi cặp server ghép thành một nhãn "A & B".
List<String> pairGeneratedLabels(Object? raw) {
  final value = _pairBodyOf(raw)?['paired'];
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (item is Map && item['memberNames'] is List)
        (item['memberNames'] as List)
            .map((e) => e.toString().trim())
            .where((name) => name.isNotEmpty)
            .join(' & '),
  ].where((label) => label.isNotEmpty).toList();
}

/// Tên người lẻ: ưu tiên `unpairedNames` của server; thiếu hoặc rỗng thì đổi
/// `unpairedParticipantIds` qua [namesById].
List<String> pairUnpairedNames(Object? raw, Map<String, String> namesById) {
  final body = _pairBodyOf(raw);
  final serverNames = body?['unpairedNames'];
  if (serverNames is List) {
    final names = [
      for (final name in serverNames)
        if (name != null && name.toString().trim().isNotEmpty)
          name.toString().trim(),
    ];
    if (names.isNotEmpty) return names;
  }
  final ids = body?['unpairedParticipantIds'];
  final idList = ids is List
      ? ids.map((e) => e.toString()).toList()
      : const <String>[];
  return unpairedDisplayNames(idList, namesById);
}
