import 'dart:async';

/// Tracks images uploaded during one form session that are not saved yet,
/// so the ones the user discards can be deleted from the server.
/// Only URLs passed to [track] are ever removed; removal errors are swallowed.
class PendingUploads {
  PendingUploads(this._remove);

  final Future<void> Function(String url) _remove;
  final Map<String, String> _bySlot = {};
  final Set<String> _removed = {};

  /// Records the temporary image of [slot]; a previous one in the slot is removed.
  void track(String slot, String url) {
    final previous = _bySlot[slot];
    _bySlot[slot] = url;
    if (previous != null && previous != url) unawaited(_delete(previous));
  }

  /// Removes the temporary image of [slot] (the user dropped it).
  void forget(String slot) {
    final url = _bySlot.remove(slot);
    if (url != null) unawaited(_delete(url));
  }

  /// Removes every tracked image not in [keep], then clears the tracking.
  Future<void> discardExcept(List<String> keep) async {
    final urls = _bySlot.values.where((url) => !keep.contains(url)).toList();
    _bySlot.clear();
    await Future.wait(urls.map(_delete));
  }

  Future<void> _delete(String url) async {
    if (!_removed.add(url)) return;
    try {
      await _remove(url);
    } catch (_) {
      // Best effort: a failed delete must never block the user.
    }
  }
}
