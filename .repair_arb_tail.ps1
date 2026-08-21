$root = 'D:\Duancanhan\Project_QuanLyGiaiDau\HethongFrontEndApp_QLgiaidau\lib\l10n'
$tails = @{
  'app_vi.arb' = @'
  "@crossTableTeamCount": {
    "placeholders": {
      "count": {}
    }
  },
  "bracketDiagramGroupStageTitle": "Sơ đồ vòng loại",
  "bracketDiagramBack": "Quay lại",
  "bracketCrossTableRoundProgress": "Vòng {current} / {max}",
  "bracketCrossTablePreviousRound": "Vòng trước",
  "bracketCrossTableNextRound": "Vòng tiếp theo",
  "bracketCrossTableTeamCount": "{count} đội",
  "qrScannerInvalidCode": "Mã QR không hợp lệ",
  "qrScannerTitle": "Quét mã QR",
  "qrScannerVerifying": "Đang xác thực...",
  "officialScoreScoringTab": "Tính điểm",
  "officialScorePenaltyTab": "Phạm lỗi",
  "doubleElimUpperGrandFinal": "CK NHÁNH THẮNG",
  "doubleElimUpperSemifinal": "BK NHÁNH THẮNG",
  "doubleElimLowerGrandFinal": "CK NHÁNH THUA",
  "doubleElimLowerSemifinal": "BK NHÁNH THUA",
  "liveMatchRemainingLabel": "Còn lại",
  "teamScoreEditForbidden": "Lỗi: Bạn không có quyền sửa điểm.",
  "chatDetailRevokedMessage": "Tin nhắn đã bị thu hồi",
  "singleElimUpdateError": "Không thể cập nhật vị trí: {error}",
  "@bracketCrossTableRoundProgress": {
    "placeholders": {
      "current": {},
      "max": {}
    }
  },
  "@bracketCrossTableTeamCount": {
    "placeholders": {
      "count": {}
    }
  }
}
'@
  'app_en.arb' = @'
  "@crossTableTeamCount": {
    "placeholders": {
      "count": {}
    }
  },
  "bracketDiagramGroupStageTitle": "Qualification bracket",
  "bracketDiagramBack": "Back",
  "bracketCrossTableRoundProgress": "Round {current} / {max}",
  "bracketCrossTablePreviousRound": "Previous round",
  "bracketCrossTableNextRound": "Next round",
  "bracketCrossTableTeamCount": "{count} teams",
  "qrScannerInvalidCode": "Invalid QR code",
  "qrScannerTitle": "Scan QR code",
  "qrScannerVerifying": "Verifying...",
  "officialScoreScoringTab": "Scoring",
  "officialScorePenaltyTab": "Penalties",
  "doubleElimUpperGrandFinal": "WINNERS BRACKET FINAL",
  "doubleElimUpperSemifinal": "WINNERS BRACKET SEMIFINAL",
  "doubleElimLowerGrandFinal": "LOSERS BRACKET FINAL",
  "doubleElimLowerSemifinal": "LOSERS BRACKET SEMIFINAL",
  "liveMatchRemainingLabel": "Remaining",
  "teamScoreEditForbidden": "Error: You do not have permission to edit the score.",
  "chatDetailRevokedMessage": "This message was revoked",
  "singleElimUpdateError": "Unable to update the position: {error}",
  "@bracketCrossTableRoundProgress": {
    "placeholders": {
      "current": {},
      "max": {}
    }
  },
  "@bracketCrossTableTeamCount": {
    "placeholders": {
      "count": {}
    }
  }
}
'@
}
foreach ($file in $tails.Keys) {
  $path = Join-Path $root $file
  $text = [System.IO.File]::ReadAllText($path)
  $marker = '  "@crossTableTeamCount": {'
  $index = $text.IndexOf($marker)
  if ($index -lt 0) { throw "Marker not found in $file" }
  $prefix = $text.Substring(0, $index)
  $newText = $prefix + $tails[$file].TrimEnd() + "`r`n"
  [System.IO.File]::WriteAllText($path, $newText, [System.Text.UTF8Encoding]::new($false))
}
Write-Output 'ARB tails repaired.'
