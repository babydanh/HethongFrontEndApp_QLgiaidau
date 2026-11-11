/// What the organizer may do with a referee (mirrors Web `PermissionsTab`):
/// withdraw a pending invite, add a declined one again, remove an added one.
enum RefereeAction { none, revoke, resend, remove }

/// One display row of the permissions list, staff and referees unified.
class PermissionRow {
  const PermissionRow({
    required this.name,
    required this.email,
    required this.userId,
    required this.role,
    this.status,
    this.refereeId,
    this.action = RefereeAction.none,
  });

  final String name;
  final String email;
  final String userId;

  /// `CO_ORGANIZER`, `SPECTATOR` or `REFEREE`.
  final String role;

  /// Backend invite status, referees only: `INVITED | ACCEPTED | DECLINED`.
  final String? status;
  final String? refereeId;
  final RefereeAction action;
}

/// Merges staff and referee payloads into rows. Pure, so it is testable
/// without widgets; unknown referee statuses offer no action.
List<PermissionRow> buildPermissionRows(
  List<Map<String, dynamic>> staff,
  List<Map<String, dynamic>> referees,
) => [
  for (final member in staff)
    PermissionRow(
      name: _name(member),
      email: _text(member['email']),
      userId: _userId(member, const ['userId', 'user_id', 'id']),
      role: _text(member['role']).toUpperCase(),
    ),
  for (final referee in referees)
    PermissionRow(
      name: _name(referee),
      email: _text(referee['email']),
      // A referee invite is keyed by its record id, so no `id` fallback here.
      userId: _userId(referee, const ['userId', 'user_id']),
      role: 'REFEREE',
      status: _text(referee['status']).toUpperCase(),
      refereeId: _text(referee['id'] ?? referee['refereeId']),
      action: _actionFor(_text(referee['status'])),
    ),
];

RefereeAction _actionFor(String status) => switch (status.toUpperCase()) {
  'INVITED' => RefereeAction.revoke,
  'DECLINED' => RefereeAction.resend,
  'ACCEPTED' => RefereeAction.remove,
  _ => RefereeAction.none,
};

String _text(Object? value) => value?.toString().trim() ?? '';

String _name(Map<String, dynamic> person) {
  final nested = person['user'];
  final nestedName = nested is Map
      ? nested['fullName'] ?? nested['name']
      : null;
  return _text(person['fullName'] ?? person['name'] ?? nestedName);
}

String _userId(Map<String, dynamic> person, List<String> keys) {
  for (final key in keys) {
    final value = _text(person[key]);
    if (value.isNotEmpty) return value;
  }
  final nested = person['user'];
  if (nested is Map) return _userId(Map<String, dynamic>.from(nested), keys);
  return '';
}
