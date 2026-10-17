/// Đọc trường tuỳ chọn của response tạo sơ đồ (`autoPaired`, `unpairedNames`).
/// Server cũ có thể không trả trường nào: khi đó kết quả rỗng, không lỗi.

Map<dynamic, dynamic>? _bodyOf(Object? raw) {
  if (raw is! Map) return null;
  final data = raw['data'];
  return data is Map ? data : raw;
}

/// Tên người lẻ còn lại sau khi tạo sơ đồ.
List<String> bracketUnpairedNames(Object? raw) {
  final value = _bodyOf(raw)?['unpairedNames'];
  return value is List ? value.map((e) => e.toString()).toList() : const [];
}

/// Mỗi cặp server tự ghép thành một nhãn "A & B".
List<String> bracketAutoPairedLabels(Object? raw) {
  final value = _bodyOf(raw)?['autoPaired'];
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (item is Map && item['memberNames'] is List)
        (item['memberNames'] as List).map((e) => e.toString()).join(' & '),
  ];
}
