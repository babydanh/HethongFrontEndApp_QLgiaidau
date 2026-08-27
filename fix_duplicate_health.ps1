$ErrorActionPreference = 'Stop'
$path = 'D:\Duancanhan\Project_QuanLyGiaiDau\HethongFrontEndApp_QLgiaidau\lib\features\match\notifiers\score_panel_notifier.dart'
$text = [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8)
$old = @'
      if (isOurEcho) {
        _footballSyncHealthy = true;
        _footballSyncHealthy = true;
        _pendingScoreSignature = null;
'@
$new = @'
      if (isOurEcho) {
        _footballSyncHealthy = true;
        _pendingScoreSignature = null;
'@
if (-not $text.Contains($old)) { throw 'Missing duplicate health block' }
$text = $text.Replace($old, $new)
[IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false))
Write-Output 'duplicate health fixed'
