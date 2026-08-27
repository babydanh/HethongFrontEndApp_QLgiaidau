$ErrorActionPreference = 'Stop'
$path = 'D:\Duancanhan\Project_QuanLyGiaiDau\HethongFrontEndApp_QLgiaidau\lib\features\match\widgets\football_score_panel.dart'
$text = [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8)
$old = @'
    final phases = score.phase == 'COMPLETED'
        ? const ['COMPLETED']
        : footballEditablePhases;
'@
$new = @'
    final phases = score.phase == 'COMPLETED'
        ? const ['COMPLETED']
        : footballEditablePhases;
    final isLocked = state.isSubmitting || score.phase == 'COMPLETED';
'@
if (-not $text.Contains($old)) { throw 'Missing phases anchor' }
$text = $text.Replace($old, $new)
$text = $text.Replace('disabled: state.isSubmitting,', 'disabled: isLocked,')
$text = $text.Replace('onPressed: state.isSubmitting', 'onPressed: isLocked')
$text = $text.Replace('onChanged: state.isSubmitting || score.phase == ''COMPLETED''', 'onChanged: isLocked')
[IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false))
Write-Output 'terminal controls patched'
