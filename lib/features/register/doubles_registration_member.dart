class DoublesRegistrationMember {
  const DoublesRegistrationMember({required this.fullName, required this.role});

  final String fullName;
  final String role;

  factory DoublesRegistrationMember.fromJson(Map<dynamic, dynamic> json) {
    return DoublesRegistrationMember(
      fullName: json['fullName']?.toString().trim() ?? '',
      role: json['role']?.toString().trim().toUpperCase() ?? '',
    );
  }

  static List<DoublesRegistrationMember> fromParticipantJson(Object? value) {
    if (value is! Map) return const [];

    final members = value['members'];
    final teamMembers = value['teamMembers'];
    final raw = members is List && members.isNotEmpty ? members : teamMembers;
    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map(DoublesRegistrationMember.fromJson)
        .where((member) => member.fullName.isNotEmpty)
        .toList(growable: false);
  }
}
