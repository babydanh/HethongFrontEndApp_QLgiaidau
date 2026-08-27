$ErrorActionPreference = 'Stop'
$repo = 'D:\Duancanhan\Project_QuanLyGiaiDau\HethongFrontEndApp_QLgiaidau'
Set-Location $repo

function Replace-Once([string]$path, [string]$old, [string]$new, [string]$label) {
  $text = [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8)
  if (-not $text.Contains($old)) { throw "Missing anchor: $label" }
  $text = $text.Replace($old, $new)
  [IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false))
}

$panel = Join-Path $repo 'lib\features\match\widgets\football_score_panel.dart'
Replace-Once $panel @'
    final phases = <String>[
      'FIRST_HALF',
      'HALFTIME',
      'SECOND_HALF',
      'STOPPAGE_TIME',
      'FULL_TIME',
      'EXTRA_TIME_FIRST_HALF',
      'EXTRA_TIME_BREAK',
      'EXTRA_TIME_SECOND_HALF',
      'PENALTY_SHOOTOUT',
      'COMPLETED',
    ];
'@ @'
    final phases = score.phase == 'COMPLETED'
        ? const ['COMPLETED']
        : footballEditablePhases;
'@ 'phase choices'

Replace-Once $panel @'
                      onChanged: state.isSubmitting
                          ? null
'@ @'
                      onChanged: state.isSubmitting || score.phase == 'COMPLETED'
                          ? null
'@ 'phase disabled terminal'

Replace-Once $panel @'
                      decoration: InputDecoration(
              labelText: l10n.footballScore_minute,
              isDense: true,
            ),
            onSubmitted: (value) =>
                widget.onMinuteSubmitted(int.tryParse(value) ?? widget.minute),
'@ @'
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
'@ 'minute input'

Replace-Once $panel @'
            decoration: InputDecoration(
              labelText: l10n.footballScore_addedMinute,
              isDense: true,
            ),
            onSubmitted: (value) => widget.onAddedMinuteSubmitted(
              int.tryParse(value) ?? widget.addedMinute,
            ),
'@ @'
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
'@ 'added minute input'

$notifier = Join-Path $repo 'lib\features\match\notifiers\score_panel_notifier.dart'
Replace-Once $notifier @'
  bool _footballSyncInFlight = false;
  String? _pendingScoreSignature;
'@ @'
  bool _footballSyncInFlight = false;
  bool _footballSyncHealthy = true;
  String? _pendingScoreSignature;
'@ 'sync health field'

Replace-Once $notifier @'
      if (isOurEcho) {
        _pendingScoreSignature = null;
        _pendingBaseRevision = null;
'@ @'
      if (isOurEcho) {
        _footballSyncHealthy = true;
        _pendingScoreSignature = null;
        _pendingBaseRevision = null;
'@ 'sync echo health'

Replace-Once $notifier @'
        _pendingScoreSignature = null;
        _pendingBaseRevision = null;
      }
'@ @'
        _footballSyncHealthy = true;
        _pendingScoreSignature = null;
        _pendingBaseRevision = null;
      }
'@ 'newer snapshot health'

Replace-Once $notifier @'
  void _scheduleFootballSync(FootballLiveState value) {
    _markLocalScorePending();
'@ @'
  void _scheduleFootballSync(FootballLiveState value) {
    _footballSyncHealthy = true;
    _markLocalScorePending();
'@ 'schedule health reset'

Replace-Once $notifier @'
  Future<void> _flushFootballSync() async {
    if (_footballSyncInFlight) return;
    final value = _pendingFootballSync;
    if (value == null) return;
'@ @'
  Future<bool> _flushFootballSync() async {
    if (_footballSyncInFlight) return true;
    final value = _pendingFootballSync;
    if (value == null) return _footballSyncHealthy;
'@ 'flush return type'

Replace-Once $notifier @'
    if (match == null) {
      _footballSyncInFlight = false;
      return;
    }
'@ @'
    if (match == null) {
      _footballSyncInFlight = false;
      _footballSyncHealthy = false;
      return false;
    }
'@ 'flush missing match'

Replace-Once $notifier @'
    } catch (error, stack) {
      _log.error('Football live score sync failed', error, stack);
      state = state.copyWith(errorMessage: _l10n.scorePanel_footballSyncError);
    } finally {
      _footballSyncInFlight = false;
      if (_pendingFootballSync != null) {
        unawaited(_flushFootballSync());
      }
    }
  }

  Future<void> _flushPendingFootballSync() async {
'@ @'
    } catch (error, stack) {
      _log.error('Football live score sync failed', error, stack);
      _footballSyncHealthy = false;
      state = state.copyWith(errorMessage: _l10n.scorePanel_footballSyncError);
    } finally {
      _footballSyncInFlight = false;
      if (_pendingFootballSync != null) {
        unawaited(_flushFootballSync());
      }
    }
    return _footballSyncHealthy;
  }

  Future<bool> _flushPendingFootballSync() async {
'@ 'flush failure state'

Replace-Once $notifier @'
    if (_pendingFootballSync != null) {
      await _flushFootballSync();
    }
  }

  bool canCompleteAs(int winnerTeam) {
'@ @'
    if (_pendingFootballSync != null) {
      await _flushFootballSync();
    }
    return _footballSyncHealthy;
  }

  bool canCompleteAs(int winnerTeam) {
'@ 'flush aggregate result'

Replace-Once $notifier @'
        await _flushPendingFootballSync();
        final football = state.football!;
'@ @'
        final flushed = await _flushPendingFootballSync();
        if (!flushed) {
          state = state.copyWith(
            isSubmitting: false,
            errorMessage: _l10n.scorePanel_footballSyncError,
          );
          return;
        }
        final football = state.football!;
'@ 'completion abort on flush failure'

Write-Output 'review round two patch applied'
