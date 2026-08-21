from pathlib import Path

root = Path(__file__).resolve().parent

existing_vi = [
  ('bracketDiagramRoundRobinTitle', 'Bảng chéo vòng tròn'),
  ('bracketDiagramDoubleEliminationTitle', 'Sơ đồ nhánh thắng / thua'),
  ('bracketDiagramGroupKnockoutTitle', 'Sơ đồ vòng loại'),
  ('bracketDiagramDefaultTitle', 'Sơ đồ thi đấu'),
  ('crossTableEmpty', 'Chưa có dữ liệu đội thi đấu'),
  ('crossTableError', 'Lỗi: {error}'),
  ('crossTableDefaultGroup', 'Bảng A'),
  ('crossTableLegTitle', '{title} - Vòng {leg}'),
  ('crossTablePreviousLeg', 'Vòng trước'),
  ('crossTableNextLeg', 'Vòng tiếp theo'),
  ('crossTableLegIndicator', 'Vòng {current} / {max}'),
  ('crossTableTeamCount', '{count} đội'),
]
existing_en = [
  ('bracketDiagramRoundRobinTitle', 'Round-robin table'),
  ('bracketDiagramDoubleEliminationTitle', 'Winners / losers bracket'),
  ('bracketDiagramGroupKnockoutTitle', 'Qualification bracket'),
  ('bracketDiagramDefaultTitle', 'Competition bracket'),
  ('crossTableEmpty', 'No team data yet'),
  ('crossTableError', 'Error: {error}'),
  ('crossTableDefaultGroup', 'Group A'),
  ('crossTableLegTitle', '{title} - Round {leg}'),
  ('crossTablePreviousLeg', 'Previous round'),
  ('crossTableNextLeg', 'Next round'),
  ('crossTableLegIndicator', 'Round {current} / {max}'),
  ('crossTableTeamCount', '{count} teams'),
]
extra_vi = [
  ('bracketDiagramGroupStageTitle', 'Sơ đồ vòng loại'),
  ('bracketDiagramBack', 'Quay lại'),
  ('bracketCrossTableRoundProgress', 'Vòng {current} / {max}'),
  ('bracketCrossTablePreviousRound', 'Vòng trước'),
  ('bracketCrossTableNextRound', 'Vòng tiếp theo'),
  ('qrScannerInvalidCode', 'Mã QR không hợp lệ'),
  ('qrScannerTitle', 'Quét mã QR'),
  ('qrScannerVerifying', 'Đang xác thực...'),
  ('officialScoreScoringTab', 'Tính điểm'),
  ('officialScorePenaltyTab', 'Phạm lỗi'),
  ('doubleElimUpperGrandFinal', 'CK NHÁNH THẮNG'),
  ('doubleElimUpperSemifinal', 'BK NHÁNH THẮNG'),
  ('doubleElimLowerGrandFinal', 'CK NHÁNH THUA'),
  ('doubleElimLowerSemifinal', 'BK NHÁNH THUA'),
  ('liveMatchRemainingLabel', 'Còn lại'),
  ('teamScoreEditForbidden', 'Lỗi: Bạn không có quyền sửa điểm.'),
  ('chatDetailRevokedMessage', 'Tin nhắn đã bị thu hồi'),
]
extra_en = [
  ('bracketDiagramGroupStageTitle', 'Qualification bracket'),
  ('bracketDiagramBack', 'Back'),
  ('bracketCrossTableRoundProgress', 'Round {current} / {max}'),
  ('bracketCrossTablePreviousRound', 'Previous round'),
  ('bracketCrossTableNextRound', 'Next round'),
  ('qrScannerInvalidCode', 'Invalid QR code'),
  ('qrScannerTitle', 'Scan QR code'),
  ('qrScannerVerifying', 'Verifying...'),
  ('officialScoreScoringTab', 'Scoring'),
  ('officialScorePenaltyTab', 'Penalties'),
  ('doubleElimUpperGrandFinal', 'WINNERS BRACKET FINAL'),
  ('doubleElimUpperSemifinal', 'WINNERS BRACKET SEMIFINAL'),
  ('doubleElimLowerGrandFinal', 'LOSERS BRACKET FINAL'),
  ('doubleElimLowerSemifinal', 'LOSERS BRACKET SEMIFINAL'),
  ('liveMatchRemainingLabel', 'Remaining'),
  ('teamScoreEditForbidden', 'Error: You do not have permission to edit the score.'),
  ('chatDetailRevokedMessage', 'This message was revoked'),
]
metadata = {
  'crossTableError': ['error'],
  'crossTableLegTitle': ['title', 'leg'],
  'crossTableLegIndicator': ['current', 'max'],
  'crossTableTeamCount': ['count'],
  'bracketCrossTableRoundProgress': ['current', 'max'],
}

def esc(value):
    return value.replace('\\', '\\\\').replace('"', '\\"')

def block(entries):
    lines = [f'  "{k}": "{esc(v)}",' for k, v in entries]
    for key, names in metadata.items():
        if any(k == key for k, _ in entries):
            lines.append(f'  "@{key}": {{')
            lines.append('    "placeholders": {')
            for i, name in enumerate(names):
                comma = ',' if i < len(names) - 1 else ''
                lines.append(f'      "{name}": {{{{}}}}{comma}')
            lines.append('    }')
            lines.append('  },')
    # Remove comma from final metadata line before closing JSON.
    lines[-1] = lines[-1].rstrip(',')
    return '\n'.join(lines)

def repair(path, existing, extra):
    text = path.read_text(encoding='utf-8')
    marker = '  "bracketDiagramRoundRobinTitle":'
    start = text.rfind(marker)
    if start < 0:
        raise RuntimeError(f'Marker not found in {path}')
    prefix = text[:start].rstrip()
    if prefix.endswith(','):
        prefix = prefix[:-1].rstrip()
    content = prefix + ',\n' + block(existing + extra) + '\n}\n'
    path.write_text(content, encoding='utf-8')
    print(f'Repaired {path.name}')

repair(root / 'lib/l10n/app_vi.arb', existing_vi, extra_vi)
repair(root / 'lib/l10n/app_en.arb', existing_en, extra_en)
