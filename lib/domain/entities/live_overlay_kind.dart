/// Hai overlay trực tiếp. Server ép loại trừ: chỉ một overlay hiện tại một lúc.
enum LiveOverlayKind { h2h, bracket }

extension LiveOverlayKindWire on LiveOverlayKind {
  /// Giá trị `kind` gửi lên PATCH overlay-visibility.
  String get wireValue => switch (this) {
    LiveOverlayKind.h2h => 'H2H',
    LiveOverlayKind.bracket => 'BRACKET',
  };
}
