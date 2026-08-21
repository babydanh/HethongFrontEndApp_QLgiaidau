$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root
$files = Get-ChildItem -Path (Join-Path $root 'lib') -Recurse -Include *.dart -File
$linePattern = '[\u00C0-\u1EF9]'
$matches = Select-String -Path $files.FullName -Pattern $linePattern -Encoding UTF8
$filtered = $matches | Where-Object { $_.Line -notmatch '^\s*//' -and $_.Line -notmatch '^\s*import ' }
$filtered | ForEach-Object {
  $relative = $_.Path.Substring($root.Length + 1)
  $relative + ':' + $_.LineNumber + ': ' + $_.Line.Trim()
} | Set-Content -Encoding UTF8 (Join-Path $root '.l10n-hardcoded-scan.txt')
Write-Output ('STRING_LITERAL_MATCHES=' + @($filtered).Count)
Get-Content (Join-Path $root '.l10n-hardcoded-scan.txt') -TotalCount 200
