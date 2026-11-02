/// What the Overview tab may show as the organiser's contact.
class TournamentContact {
  const TournamentContact({
    required this.organizerName,
    required this.phone,
    required this.email,
    required this.hiddenFromViewers,
    this.links = const {},
  });

  /// Only filled in MANUAL display mode.
  final String organizerName;
  final String phone;
  final String email;

  /// True when a manager sees contact details that viewers cannot.
  final bool hiddenFromViewers;

  /// Extra channels (Facebook, Zalo, custom...) by label; always public.
  final Map<String, String> links;
}

String _text(Object? value) => value is String ? value.trim() : '';

const _contactMetadataKeys = {'displaymode', 'organizername', 'hidden'};

/// Keys of `contactInfo` that are settings, not contact channels (same set as
/// the Web form).
bool isContactMetadataKey(String key) =>
    _contactMetadataKeys.contains(key.toLowerCase());

/// Contact channels beyond phone and email (Facebook, Zalo, custom...), keyed
/// by their label, in saved order.
Map<String, String> contactLinks(Map<String, dynamic>? info) => {
  for (final entry in (info ?? const <String, dynamic>{}).entries)
    if (entry.key != 'phone' &&
        entry.key != 'email' &&
        !isContactMetadataKey(entry.key) &&
        _text(entry.value).isNotEmpty)
      entry.key: _text(entry.value),
};

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
  final links = contactLinks(info);
  final phone = _text(info['phone']);
  if (manual) {
    final name = _text(info['organizerName']);
    if (name.isEmpty && phone.isEmpty && links.isEmpty) return null;
    return TournamentContact(
      organizerName: name,
      phone: phone,
      email: '',
      hiddenFromViewers: false,
      links: links,
    );
  }
  final hidden = info['hidden'] != false;
  final showProfile = !hidden || isManager;
  final email = _text(info['email']);
  final shownPhone = showProfile ? phone : '';
  final shownEmail = showProfile ? email : '';
  if (shownPhone.isEmpty && shownEmail.isEmpty && links.isEmpty) return null;
  return TournamentContact(
    organizerName: '',
    phone: shownPhone,
    email: shownEmail,
    hiddenFromViewers: hidden && (shownPhone.isNotEmpty || shownEmail.isNotEmpty),
    links: links,
  );
}
