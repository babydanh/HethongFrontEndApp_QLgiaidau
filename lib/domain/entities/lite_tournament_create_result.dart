class LiteTournamentCreateResult {
  const LiteTournamentCreateResult({
    required this.id,
    required this.name,
    required this.status,
    this.inviteCode,
    this.joinUrl,
    this.qrPayload,
  });

  final String id;
  final String name;
  final String status;
  final String? inviteCode;
  final String? joinUrl;
  final String? qrPayload;

  factory LiteTournamentCreateResult.fromJson(Map<String, dynamic> json) {
    return LiteTournamentCreateResult(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      inviteCode: json['inviteCode']?.toString(),
      joinUrl: json['joinUrl']?.toString(),
      qrPayload: json['qrPayload']?.toString(),
    );
  }

  @override
  String toString() => 'LiteTournamentCreateResult(id: $id, name: $name, status: $status)';
}
