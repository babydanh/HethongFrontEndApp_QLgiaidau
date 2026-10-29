import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _load(String name) =>
    jsonDecode(File('lib/l10n/$name').readAsStringSync())
        as Map<String, dynamic>;

Set<String> _placeholders(String text) =>
    RegExp(r'\{(\w+)\}').allMatches(text).map((m) => m.group(1)!).toSet();

void main() {
  final vi = _load('app_vi.arb');
  final en = _load('app_en.arb');
  final duprKeys = vi.keys
      .where((k) => !k.startsWith('@') && k.contains('Dupr'))
      .toList();

  test('DUPR keys exist (editor and register groups)', () {
    expect(duprKeys, containsAll(<String>[
      'divisionEditorDuprLimit',
      'divisionEditorDuprFrom',
      'divisionEditorDuprTo',
      'divisionEditorDuprUnlimited',
      'divisionEditorDuprInclusiveHint',
      'divisionEditorAccDupr',
      'divisionEditorAccDuprNone',
      'registerDuprRange',
      'registerDuprChecking',
      'registerDuprMatches',
      'registerDuprBelowMin',
      'registerDuprAboveMax',
      'registerDuprMissing',
      'registerDuprInputLabel',
      'registerDuprSave',
      'registerDuprSaved',
      'registerDuprSaveFailed',
      'registerDuprSelfDeclaredNote',
    ]));
  });

  test('every DUPR key is in both arb files with matching placeholders', () {
    for (final key in duprKeys) {
      expect(en.containsKey(key), isTrue, reason: '$key missing in app_en.arb');
      expect(
        _placeholders(en[key] as String),
        _placeholders(vi[key] as String),
        reason: 'placeholders differ for $key',
      );
    }
    final enOnly = en.keys.where(
      (k) => !k.startsWith('@') && k.contains('Dupr') && !vi.containsKey(k),
    );
    expect(enOnly, isEmpty);
  });
}
