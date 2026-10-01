part of '../screens/club_detail_screen.dart';

extension _ClubDetailMemberProfile on _ClubDetailScreenState {
  /// "Trận đấu" filter inside the profile preview keeps its club context: it
  /// searches this club's matches instead of dropping the member onto a
  /// generic search. Shared by every profile entry point on the club screen
  /// so the shared widget owns the preview and we only own the destination.
  void _filterClubMatches(String query) {
    final clubName =
        ref.read(communityDetailProvider(widget.clubId)).value?.name ?? '';
    context.push(
      '/club/${widget.clubId}/search?name=${Uri.encodeComponent(clubName)}&q=${Uri.encodeComponent(query)}&type=MATCHES',
    );
  }
}
