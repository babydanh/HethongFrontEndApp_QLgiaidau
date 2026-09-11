part of '../screens/club_detail_screen.dart';

extension _ClubDetailMemberProfile on _ClubDetailScreenState {
  void _showMemberProfile(String userId, String? fullName, String? avatarUrl) {
    UserProfileBottomSheet.show(
      context,
      userId: userId,
      communityId: widget.clubId,
      initialFullName: fullName,
      initialAvatarUrl: avatarUrl,
      onFilterMatches: (query) {
        final clubName =
            ref.read(communityDetailProvider(widget.clubId)).value?.name ?? '';
        context.push(
          '/club/${widget.clubId}/search?name=${Uri.encodeComponent(clubName)}&q=${Uri.encodeComponent(query)}',
        );
      },
    );
  }
}
