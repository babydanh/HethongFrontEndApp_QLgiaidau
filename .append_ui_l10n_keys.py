from pathlib import Path

root = Path(__file__).resolve().parent
vi = {
  'bracketDiagramRoundRobinTitle': 'Bảng chéo vòng tròn',
  'bracketDiagramDoubleEliminationTitle': 'Sơ đồ nhánh thắng / thua',
  'bracketDiagramGroupStageTitle': 'Sơ đồ vòng loại',
  'bracketDiagramDefaultTitle': 'Sơ đồ thi đấu',
  'bracketDiagramBack': 'Quay lại',
  'bracketCrossTableRoundProgress': 'Vòng {current} / {max}',
  'bracketCrossTablePreviousRound': 'Vòng trước',
  'bracketCrossTableNextRound': 'Vòng tiếp theo',
  'bracketCrossTableTeamCount': '{count} đội',
  'qrScannerInvalidCode': 'Mã QR không hợp lệ',
  'qrScannerTitle': 'Quét mã QR',
  'qrScannerVerifying': 'Đang xác thực...',
  'officialScoreScoringTab': 'Tính điểm',
  'officialScorePenaltyTab': 'Phạm lỗi',
  'doubleElimUpperGrandFinal': 'CK NHÁNH THẮNG',
  'doubleElimUpperSemifinal': 'BK NHÁNH THẮNG',
  'doubleElimLowerGrandFinal': 'CK NHÁNH THUA',
  'doubleElimLowerSemifinal': 'BK NHÁNH THUA',
  'liveMatchRemainingLabel': 'Còn lại',
  'teamScoreEditForbidden': 'Lỗi: Bạn không có quyền sửa điểm.',
  'chatDetailRevokedMessage': 'Tin nhắn đã bị thu hồi',
}
en = {
  'bracketDiagramRoundRobinTitle': 'Round-robin table',
  'bracketDiagramDoubleEliminationTitle': 'Winners / losers bracket',
  'bracketDiagramGroupStageTitle': 'Qualification bracket',
  'bracketDiagramDefaultTitle': 'Competition bracket',
  'bracketDiagramBack': 'Back',
  'bracketCrossTableRoundProgress': 'Round {current} / {max}',
  'bracketCrossTablePreviousRound': 'Previous round',
  'bracketCrossTableNextRound': 'Next round',
  'bracketCrossTableTeamCount': '{count} teams',
  'qrScannerInvalidCode': 'Invalid QR code',
  'qrScannerTitle': 'Scan QR code',
  'qrScannerVerifying': 'Verifying...',
  'officialScoreScoringTab': 'Scoring',
  'officialScorePenaltyTab': 'Penalties',
  'doubleElimUpperGrandFinal': 'WINNERS BRACKET FINAL',
  'doubleElimUpperSemifinal': 'WINNERS BRACKET SEMIFINAL',
  'doubleElimLowerGrandFinal': 'LOSERS BRACKET FINAL',
  'doubleElimLowerSemifinal': 'LOSERS BRACKET SEMIFINAL',
  'liveMatchRemainingLabel': 'Remaining',
  'teamScoreEditForbidden': 'Error: You do not have permission to edit the score.',
  'chatDetailRevokedMessage': 'This message was revoked',
}
placeholders = {
  'bracketCrossTableRoundProgress': ['current', 'max'],
  'bracketCrossTableTeamCount': ['count'],
}

def append_keys(path, values):
    text = path.read_text(encoding='utf-8')
    missing = [k for k in values if f'"{k}"' not in text]
    if not missing:
        print(f'{path.name}: no missing keys')
        return
    lines = []
    for key in missing:
        value = values[key].replace('\\', '\\\\').replace('"', '\\"')
        lines.append(f'  "{key}": "{value}",')
    for key in missing:
        if key in placeholders:
            lines.append(f'  "@{key}": {{')
            lines.append('    "placeholders": {')
            names = placeholders[key]
            for i, name in enumerate(names):
                comma = ',' if i < len(names) - 1 else ''
                lines.append(f'      "{name}": {{{{}}}}{comma}')
            lines.append('    }')
            lines.append('  },')
    insertion = '\n' + '\n'.join(lines)
    pos = text.rfind('\n}')
    if pos < 0:
        raise RuntimeError(f'No final JSON brace in {path}')
    updated = text[:pos] + insertion + text[pos:]
    path.write_text(updated, encoding='utf-8')
    print(f'{path.name}: appended {len(missing)} keys')

append_keys(root / 'lib/l10n/app_vi.arb', vi)
append_keys(root / 'lib/l10n/app_en.arb', en)
