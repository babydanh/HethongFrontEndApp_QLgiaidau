import 'package:app_quanly_giaidau/data/models/social_session_model.dart';

/// Display-only reference. Never sent to a participant/payment endpoint.
class SocialTicketSlot {
  const SocialTicketSlot(this.participant, this.ticketIndex);
  final SocialParticipantModel participant;
  final int ticketIndex;
  String get key => '${participant.id}:$ticketIndex';
}

List<SocialTicketSlot> projectSocialTickets(SocialSessionModel session) {
  final seen = <String>{};
  final joined = session.participants
      .where((p) => p.status.toUpperCase() == 'JOINED' && seen.add(p.id))
      .toList();
  final ordered = [
    ...joined.where((p) => p.isHost || p.userId == session.hostUserId),
    ...joined.where((p) => !p.isHost && p.userId != session.hostUserId),
  ];
  // These are the backend DTO limits. Reject corrupt counts, never fabricate
  // tickets or silently truncate confirmed participants to capacity.
  if (ordered.any(
    (p) => p.id.isEmpty || p.ticketCount < 1 || p.ticketCount > 64,
  )) {
    throw const FormatException('Invalid participant ticket count');
  }
  return [
    for (final participant in ordered)
      for (var index = 0; index < participant.ticketCount; index++)
        SocialTicketSlot(participant, index),
  ];
}
