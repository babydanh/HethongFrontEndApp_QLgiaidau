$ErrorActionPreference = 'Stop'
$path = 'D:\Duancanhan\Project_QuanLyGiaiDau\HethongFrontEndApp_QLgiaidau\lib\features\match\notifiers\score_panel_notifier.dart'
function Replace-Once([string]$old, [string]$new, [string]$label) {
  $script:text = [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8)
  if (-not $script:text.Contains($old)) { throw "Missing anchor: $label" }
  $script:text = $script:text.Replace($old, $new)
  [IO.File]::WriteAllText($path, $script:text, [Text.UTF8Encoding]::new($false))
}
Replace-Once @'
  bool _footballSyncInFlight = false;
  String? _pendingScoreSignature;
'@ @'
  bool _footballSyncInFlight = false;
  bool _footballSyncHealthy = true;
  String? _pendingScoreSignature;
'@ 'sync health field'
Replace-Once @'
      if (isOurEcho) {
        _pendingScoreSignature = null;
        _pendingBaseRevision = null;
'@ @'
      if (isOurEcho) {
        _footballSyncHealthy = true;
        _pendingScoreSignature = null;
        _pendingBaseRevision = null;
'@ 'sync echo health'
Replace-Once @'
        _pendingScoreSignature = null;
        _pendingBaseRevision = null;
      }
'@ @'
        _footballSyncHealthy = true;
        _pendingScoreSignature = null;
        _pendingBaseRevision = null;
      }
'@ 'newer snapshot health'
Replace-Once @'
  void _scheduleFootballSync(FootballLiveState value) {
    _markLocalScorePending();
'@ @'
  void _scheduleFootballSync(FootballLiveState value) {
    _footballSyncHealthy = true;
    _markLocalScorePending();
'@ 'schedule health reset'
Replace-Once @'
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
Replace-Once @'
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
Replace-Once @'
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
Replace-Once @'
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
Replace-Once @'
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
Write-Output 'notifier sync patch applied'
