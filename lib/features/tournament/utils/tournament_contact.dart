/// What the Overview tab may show as the organiser's contact.
class TournamentContact {
  const TournamentContact({
    required this.organizerName,
    required this.phone,
    required this.email,
    required this.hiddenFromViewers,
  });

  /// Only filled in MANUAL display mode.
  final String organizerName;
  final String phone;
  final String email;

  /// True when a manager sees contact details that viewers cannot.
  final bool hiddenFromViewers;
}

String _text(Object? value) => value is String ? value.trim() : '';

/// Decides which contact block to draw from `Tournament.contactInfo`.
///
/// MANUAL: typed in to be public, so always shown as name + phone.
/// PROFILE (or no mode): taken from the personal profile, so shown to viewers
/// only when `hidden` is exactly `false`; a manager always sees it, flagged
/// when viewers cannot. A missing flag means hidden, like `showFounder`.
/// Returns null when there is nothing to draw.
TournamentContact? visibleContact(
  Map<String, dynamic>? info, {
  required bool isManager,
}) {
  if (info == null) return null;
  final manual = _text(info['displayMode']).toUpperCase() == 'MANUAL';
  final phone = _text(info['phone']);
  if (manual) {
    final name = _text(info['organizerName']);
    if (name.isEmpty && phone.isEmpty) return null;
    return TournamentContact(
      organizerName: name,
      phone: phone,
      email: '',
      hiddenFromViewers: false,
    );
  }
  final hidden = info['hidden'] != false;
  if (hidden && !isManager) return null;
  final email = _text(info['email']);
  if (phone.isEmpty && email.isEmpty) return null;
  return TournamentContact(
    organizerName: '',
    phone: phone,
    email: email,
    hiddenFromViewers: hidden,
  );
}
