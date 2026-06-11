class SavedTournament {
  final String id;
  final String role;
  final String tokenCode;

  SavedTournament({
    required this.id,
    required this.role,
    required this.tokenCode,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'tokenCode': tokenCode,
      };

  factory SavedTournament.fromJson(Map<String, dynamic> json) => SavedTournament(
        id: json['id'] as String,
        role: json['role'] as String,
        tokenCode: json['tokenCode'] as String,
      );
}
