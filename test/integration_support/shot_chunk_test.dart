import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/support/shot.dart';

void main() {
  test('chunkBase64 round-trips and respects the chunk size', () {
    final bytes = List<int>.generate(5000, (i) => i % 256);
    final chunks = chunkBase64(bytes, size: 800);

    expect(chunks.every((c) => c.length <= 800), isTrue);
    expect(chunks.length, greaterThan(1));
    expect(base64Decode(chunks.join()), bytes);
  });

  test('chunkBase64 returns no chunks for empty input', () {
    expect(chunkBase64(const []), isEmpty);
  });

  test('chunkBase64 keeps chunks aligned to 4 characters', () {
    final chunks = chunkBase64(List<int>.filled(300, 7), size: 10);

    expect(chunks.take(chunks.length - 1).every((c) => c.length == 8), isTrue);
    expect(base64Decode(chunks.join()), List<int>.filled(300, 7));
  });
}
