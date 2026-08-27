$ErrorActionPreference = 'Stop'
$root = 'D:\Duancanhan\Project_QuanLyGiaiDau\HethongFrontEndApp_QLgiaidau'
function Replace-Once([string]$path, [string]$old, [string]$new, [string]$label) {
  $text = [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8).Replace("`r`n", "`n")
  if (-not $text.Contains($old)) { throw "Missing anchor: $label" }
  $text = $text.Replace($old, $new)
  [IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false))
}
$state = Join-Path $root 'lib\features\match\notifiers\score_panel_state.dart'
Replace-Once $state @'
  final bool isSubmitting;
  final String? errorMessage;
'@ @'
  final bool isSubmitting;
  final bool isServerTerminal;
  final String? errorMessage;
'@ 'state field'
Replace-Once $state @'
    this.isSubmitting = false,
    this.errorMessage,
'@ @'
    this.isSubmitting = false,
    this.isServerTerminal = false,
    this.errorMessage,
'@ 'state constructor'
Replace-Once $state @'
    bool? isSubmitting,
    String? errorMessage,
'@ @'
    bool? isSubmitting,
    bool? isServerTerminal,
    String? errorMessage,
'@ 'state copyWith argument'
Replace-Once $state @'
    isSubmitting: isSubmitting ?? this.isSubmitting,
    errorMessage: errorMessage,
'@ @'
    isSubmitting: isSubmitting ?? this.isSubmitting,
    isServerTerminal: isServerTerminal ?? this.isServerTerminal,
    errorMessage: errorMessage,
'@ 'state copyWith value'
$notifier = Join-Path $root 'lib\features\match\notifiers\score_panel_notifier.dart'
Replace-Once $notifier @'
  static bool _isLiteMatch(MatchModel? match) {
    final mode = match?.tournamentConfig?['mode']?.toString().toUpperCase();
    return mode == 'LITE';
  }
'@ @'
  static bool _isLiteMatch(MatchModel? match) {
    final mode = match?.tournamentConfig?['mode']?.toString().toUpperCase();
    return mode == 'LITE';
  }

  static bool _isServerTerminal(MatchModel match) {
    final status = match.status.trim().toLowerCase();
    return status == 'completed' ||
        status == 'walkover' ||
        match.completedAt != null;
  }
'@ 'terminal helper'
Replace-Once $notifier @'
      return current.copyWith(config: config, isLite: _isLiteMatch(match));
'@ @'
      return current.copyWith(
        config: config,
        isLite: _isLiteMatch(match),
        isServerTerminal: _isServerTerminal(match),
      );
'@ 'terminal hydrate no details'
Replace-Once $notifier @'
      isLite: _isLiteMatch(match),
      finishedSets: finishedSets,
'@ @'
      isLite: _isLiteMatch(match),
      isServerTerminal: _isServerTerminal(match),
      finishedSets: finishedSets,
'@ 'terminal hydrate details'
$panel = Join-Path $root 'lib\features\match\widgets\football_score_panel.dart'
Replace-Once $panel @'
    final isLocked = state.isSubmitting || score.phase == 'COMPLETED';
'@ @'
    final isLocked =
        state.isSubmitting || state.isServerTerminal || score.phase == 'COMPLETED';
'@ 'terminal lock condition'
Write-Output 'server terminal state patch applied'
