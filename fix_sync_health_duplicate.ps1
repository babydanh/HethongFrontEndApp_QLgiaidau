$ErrorActionPreference = 'Stop'
$path = 'D:\Duancanhan\Project_QuanLyGiaiDau\HethongFrontEndApp_QLgiaidau\lib\features\match\notifiers\score_panel_notifier.dart'
$text = [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8)
$old = @'
      if (isOurEcho) {
        _footballSyncHealthy = true;
        _footballSyncHealthy = true;
        _pendingScoreSignature = null;
        _pendingBaseRevision = null;
      } else {
'@
$new = @'
      if (isOurEcho) {
        _footballSyncHealthy = true;
        _pendingScoreSignature = null;
        _pendingBaseRevision = null;
      } else {
'@
if (-not $text.Contains($old)) { throw 'Missing duplicate health block' }
$text = $text.Replace($old, $new)
$old = @'
        if (baseRevision != null &&
            remoteRevision != null &&
            remoteRevision <= baseRevision) {
          return;
        }
        _pendingScoreSignature = null;
'@
$new = @'
        if (baseRevision != null &&
            remoteRevision != null &&
            remoteRevision <= baseRevision) {
          return;
        }
        _footballSyncHealthy = true;
        _pendingScoreSignature = null;
'@
if (-not $text.Contains($old)) { throw 'Missing authoritative snapshot block' }
$text = $text.Replace($old, $new)
[IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false))
Write-Output 'sync health duplicate fixed'
