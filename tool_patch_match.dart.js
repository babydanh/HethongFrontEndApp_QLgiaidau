const fs = require('fs');
const path = 'lib/domain/entities/match.dart';
let src = fs.readFileSync(path, 'utf8');

// 1. Field declaration
const fieldOld = "  final int? timeLimitMinutes;\n  final DateTime updatedAt;\n  final String? refereeName;";
const fieldNew = "  final int? timeLimitMinutes;\n  final DateTime updatedAt;\n  /// Monotonic version from backend (optimistic lock + realtime ordering, NOTE-7).\n  final int? revision;\n  final String? refereeName;";
if (!src.includes('final int? revision;')) {
  if (!src.includes(fieldOld)) { console.error('FIELD ANCHOR NOT FOUND'); process.exit(1); }
  src = src.replace(fieldOld, fieldNew);
  console.log('field added');
} else { console.log('field exists'); }

// 2. Constructor param
const ctorOld = "    this.timeLimitMinutes,\n    required this.updatedAt,\n    this.refereeName,";
const ctorNew = "    this.timeLimitMinutes,\n    required this.updatedAt,\n    this.revision,\n    this.refereeName,";
if (!src.includes('this.revision,')) {
  if (!src.includes(ctorOld)) { console.error('CTOR ANCHOR NOT FOUND'); process.exit(1); }
  src = src.replace(ctorOld, ctorNew);
  console.log('ctor param added');
} else { console.log('ctor param exists'); }

// 3. copyWith signature
const cwSigOld = "    int? timeLimitMinutes,\n    DateTime? updatedAt,\n    String? refereeName,";
const cwSigNew = "    int? timeLimitMinutes,\n    DateTime? updatedAt,\n    int? revision,\n    String? refereeName,";
if (!src.includes('int? revision,\n    String? refereeName,')) {
  if (!src.includes(cwSigOld)) { console.error('CW SIG ANCHOR NOT FOUND'); process.exit(1); }
  src = src.replace(cwSigOld, cwSigNew);
  console.log('copyWith sig added');
} else { console.log('copyWith sig exists'); }

// 4. copyWith body
const cwBodyOld = "      timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,\n      updatedAt: updatedAt ?? this.updatedAt,\n      refereeName: refereeName ?? this.refereeName,";
const cwBodyNew = "      timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,\n      updatedAt: updatedAt ?? this.updatedAt,\n      revision: revision ?? this.revision,\n      refereeName: refereeName ?? this.refereeName,";
if (!src.includes('revision: revision ?? this.revision,')) {
  if (!src.includes(cwBodyOld)) { console.error('CW BODY ANCHOR NOT FOUND'); process.exit(1); }
  src = src.replace(cwBodyOld, cwBodyNew);
  console.log('copyWith body added');
} else { console.log('copyWith body exists'); }

// 5. toJson
const jsonOld = "      'timeLimitMinutes': timeLimitMinutes,\n      'updatedAt': updatedAt.toIso8601String(),";
const jsonNew = "      'timeLimitMinutes': timeLimitMinutes,\n      'updatedAt': updatedAt.toIso8601String(),\n      'revision': revision,";
if (!src.includes("'revision': revision,")) {
  if (!src.includes(jsonOld)) { console.error('JSON ANCHOR NOT FOUND'); process.exit(1); }
  src = src.replace(jsonOld, jsonNew);
  console.log('toJson added');
} else { console.log('toJson exists'); }

fs.writeFileSync(path, src);
console.log('DONE');
