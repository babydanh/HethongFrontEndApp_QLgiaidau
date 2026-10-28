import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:integration_test/integration_test.dart';

/// Splits [bytes] into base64 chunks of at most [size] characters each.
/// [size] is rounded down to a multiple of 4 so every chunk is valid base64.
List<String> chunkBase64(List<int> bytes, {int size = 800}) {
  final encoded = base64Encode(bytes);
  final step = size - size % 4;
  return [
    for (var i = 0; i < encoded.length; i += step)
      encoded.substring(
        i,
        i + step > encoded.length ? encoded.length : i + step,
      ),
  ];
}

/// Takes a screenshot and prints it to the log as base64 chunks, because the
/// cloud runner keeps only the test log. Call `convertFlutterSurfaceToImage`
/// once after `pumpWidget` and pump a frame before calling this.
///
/// Log format (one chunk per line):
///   [[SHOT-BEGIN name bytes]]
///   [[SHOT name i]] base64
///   [[SHOT-END name]]
Future<void> shot(
  IntegrationTestWidgetsFlutterBinding binding,
  String name,
) async {
  final bytes = await binding.takeScreenshot(name);
  debugPrint('[[SHOT-BEGIN $name ${bytes.length}]]');
  final chunks = chunkBase64(bytes);
  for (var i = 0; i < chunks.length; i++) {
    debugPrint('[[SHOT $name $i]] ${chunks[i]}');
  }
  debugPrint('[[SHOT-END $name]]');
}
