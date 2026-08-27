$ErrorActionPreference = 'Stop'
$path = 'D:\Duancanhan\Project_QuanLyGiaiDau\HethongFrontEndApp_QLgiaidau\lib\features\match\widgets\football_score_panel.dart'
$text = [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8)
$old = @'
            decoration: InputDecoration(
              labelText: l10n.footballScore_minute,
              isDense: true,
            ),
            onSubmitted: (value) =>
                widget.onMinuteSubmitted(int.tryParse(value) ?? widget.minute),
'@
$new = @'
            decoration: InputDecoration(
              labelText: l10n.footballScore_minute,
              isDense: true,
            ),
            readOnly: widget.disabled,
            onChanged: (value) {
              final parsed = int.tryParse(value);
              if (parsed != null) widget.onMinuteSubmitted(parsed);
            },
            onSubmitted: (value) =>
                widget.onMinuteSubmitted(int.tryParse(value) ?? widget.minute),
'@
if (-not $text.Contains($old)) { throw 'Missing minute field anchor' }
$text = $text.Replace($old, $new)
$old = @'
            decoration: InputDecoration(
              labelText: l10n.footballScore_addedMinute,
              isDense: true,
            ),
            onSubmitted: (value) => widget.onAddedMinuteSubmitted(
              int.tryParse(value) ?? widget.addedMinute,
            ),
'@
$new = @'
            decoration: InputDecoration(
              labelText: l10n.footballScore_addedMinute,
              isDense: true,
            ),
            readOnly: widget.disabled,
            onChanged: (value) {
              final parsed = int.tryParse(value);
              if (parsed != null) widget.onAddedMinuteSubmitted(parsed);
            },
            onSubmitted: (value) => widget.onAddedMinuteSubmitted(
              int.tryParse(value) ?? widget.addedMinute,
            ),
'@
if (-not $text.Contains($old)) { throw 'Missing added minute field anchor' }
$text = $text.Replace($old, $new)
[IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false))
Write-Output 'time fields patched'
