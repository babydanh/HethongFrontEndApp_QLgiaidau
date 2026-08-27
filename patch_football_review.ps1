$ErrorActionPreference = 'Stop'
$repo = 'D:\Duancanhan\Project_QuanLyGiaiDau\HethongFrontEndApp_QLgiaidau'
Set-Location $repo
$path = Join-Path $repo 'lib\features\match\notifiers\score_panel_notifier.dart'
$text = [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8)

$old = @'
        : '${value.football!.team1Goals}:${value.football!.team2Goals}:${value.football!.phase}:${value.football!.minute}:${value.football!.addedMinute}:${value.football!.shootoutTeam1Goals}:${value.football!.shootoutTeam2Goals}:${value.football!.events.length}';
'@
$new = @'
        : '${value.football!.team1Goals}:${value.football!.team2Goals}:${value.football!.phase}:${value.football!.minute}:${value.football!.addedMinute}:${value.football!.shootoutTeam1Goals}:${value.football!.shootoutTeam2Goals}:${value.football!.events.map((event) => '${event.type}:${event.isTeam1 ? 1 : 2}:${event.minute}:${event.addedMinute}').join('|')}';
'@
if (-not $text.Contains($old)) { throw 'Missing signature anchor' }
$text = $text.Replace($old, $new)

$old = @'
  void footballAddGoal(bool isTeam1) {
    final current = state.football ?? const FootballLiveState();
    final next = current.copyWith(
      team1Goals: isTeam1 ? current.team1Goals + 1 : current.team1Goals,
      team2Goals: isTeam1 ? current.team2Goals : current.team2Goals + 1,
    );
'@
$new = @'
  void footballAddGoal(bool isTeam1) {
    final current = state.football ?? const FootballLiveState();
    final next = current.copyWith(
      team1Goals: isTeam1 ? current.team1Goals + 1 : current.team1Goals,
      team2Goals: isTeam1 ? current.team2Goals : current.team2Goals + 1,
      events: [
        ...current.events,
        FootballEvent(
          type: 'GOAL',
          isTeam1: isTeam1,
          minute: current.minute,
          addedMinute: current.addedMinute,
        ),
      ],
    );
'@
if (-not $text.Contains($old)) { throw 'Missing add goal anchor' }
$text = $text.Replace($old, $new)

$old = @'
  void footballRemoveGoal(bool isTeam1) {
    final current = state.football ?? const FootballLiveState();
    final next = current.copyWith(
      team1Goals: isTeam1
          ? (current.team1Goals > 0 ? current.team1Goals - 1 : 0)
          : current.team1Goals,
      team2Goals: isTeam1
          ? current.team2Goals
          : (current.team2Goals > 0 ? current.team2Goals - 1 : 0),
    );
'@
$new = @'
  void footballRemoveGoal(bool isTeam1) {
    final current = state.football ?? const FootballLiveState();
    final events = [...current.events];
    for (var index = events.length - 1; index >= 0; index--) {
      final event = events[index];
      if (event.type == 'GOAL' && event.isTeam1 == isTeam1) {
        events.removeAt(index);
        break;
      }
    }
    final next = current.copyWith(
      team1Goals: isTeam1
          ? (current.team1Goals > 0 ? current.team1Goals - 1 : 0)
          : current.team1Goals,
      team2Goals: isTeam1
          ? current.team2Goals
          : (current.team2Goals > 0 ? current.team2Goals - 1 : 0),
      events: events,
'@
if (-not $text.Contains($old)) { throw 'Missing remove goal anchor' }
$text = $text.Replace($old, $new)

[IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false))
Write-Output "patched $path"
