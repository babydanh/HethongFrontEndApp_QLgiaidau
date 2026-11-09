import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/features/social/logic/social_add_people.dart';
import 'package:app_quanly_giaidau/features/social/widgets/social_avatar.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/providers/social_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thêm người vào buổi, cùng logic với "Thêm VĐV" của Web (AddAthleteModal):
/// tab "Tìm người chơi" (ô tìm trống = người quen gồm bạn bè + thành viên CLB,
/// từ 3 ký tự = tìm toàn hệ thống), tab "Người ngoài" (khách không tài khoản).
/// Endpoint: POST /social-sessions/:id/participants (userId | guestName) và
/// /participants/batch.
class SocialAddParticipantSheet extends ConsumerStatefulWidget {
  const SocialAddParticipantSheet({super.key, required this.session});

  final SocialSessionModel session;

  static Future<void> show(BuildContext context, SocialSessionModel session) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SocialAddParticipantSheet(session: session),
    );
  }

  @override
  ConsumerState<SocialAddParticipantSheet> createState() =>
      _SocialAddParticipantSheetState();
}

class _SocialAddParticipantSheetState
    extends ConsumerState<SocialAddParticipantSheet> {
  final _searchController = TextEditingController();
  final _guestController = TextEditingController();
  final Map<String, SocialPerson> _selected = {};
  Timer? _debounce;
  List<SocialPerson> _results = const [];
  bool _searching = false;
  bool _submitting = false;
  bool _guestTab = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _guestController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (!isSearchableSocialTerm(value)) {
      setState(() {
        _results = const [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final term = value.trim();
      final found = await ref.read(userRepositoryProvider).searchUsers(term);
      if (!mounted || _searchController.text.trim() != term) return;
      setState(() {
        _results = [
          for (final u in found)
            SocialPerson(
              userId: u.id,
              fullName: u.fullName,
              avatarUrl: u.avatarUrl,
              sources: const {SocialPersonSource.system},
            ),
        ];
        _searching = false;
      });
    });
  }

  void _toast(String message, {bool error = false}) {
    final colors = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? colors.error : colors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _run(Future<String> Function() action) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final navigator = Navigator.of(context);
    try {
      final message = await action();
      if (!mounted) return;
      navigator.pop();
      _toast(message);
    } catch (error) {
      if (mounted) _toast(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _addSelected() => _run(() async {
    final res = await ref
        .read(socialSessionDetailProvider(widget.session.id).notifier)
        .addParticipantsBatch(userIds: _selected.keys.toList());
    final skipped = res.skipped.length;
    return skipped > 0
        ? 'Đã thêm ${res.added.length} người (bỏ qua $skipped người đã tham gia).'
        : 'Đã thêm ${res.added.length} người vào buổi.';
  });

  Future<void> _addGuest() {
    final name = _guestController.text.trim();
    return _run(() async {
      await ref
          .read(socialSessionDetailProvider(widget.session.id).notifier)
          .addGuestParticipant(guestName: name);
      return 'Đã thêm $name vào buổi.';
    });
  }

  List<SocialPerson> _acquaintances() {
    final friends =
        ref.watch(userFriendsProvider).asData?.value ?? const <FriendshipItem>[];
    final communityId = widget.session.communityId?.trim() ?? '';
    final members = communityId.isEmpty
        ? const []
        : (ref.watch(communityMembersProvider(communityId)).asData?.value ??
              const []);
    return mergeSocialPeople([
      (
        source: SocialPersonSource.friend,
        items: [
          for (final f in friends)
            if (f.status == 'ACCEPTED')
              SocialPerson(
                userId: f.friendId,
                fullName: f.friendName ?? '',
                avatarUrl: f.friendAvatar,
                sources: const {},
              ),
        ],
      ),
      (
        source: SocialPersonSource.club,
        items: [
          for (final m in members)
            if (m.status.toUpperCase() == 'JOINED')
              SocialPerson(
                userId: m.userId,
                fullName: m.userFullName ?? '',
                avatarUrl: m.userAvatarUrl,
                sources: const {},
              ),
        ],
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final height = MediaQuery.sizeOf(context).height * 0.85;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Thêm người tham gia',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: false, label: Text('Tìm người chơi')),
                  ButtonSegment(value: true, label: Text('Người ngoài')),
                ],
                selected: {_guestTab},
                onSelectionChanged: (v) => setState(() => _guestTab = v.first),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _guestTab ? _guestForm(colors) : _searchTab(colors)),
          ],
        ),
      ),
    );
  }

  Widget _searchTab(AppColorsExtension colors) {
    final term = _searchController.text.trim();
    final searching = term.isNotEmpty;
    final searchable = isSearchableSocialTerm(term);
    final joined = joinedUserIds(widget.session);
    final list = searching ? _results : _acquaintances();
    final loadingAcq = !searching &&
        (ref.watch(userFriendsProvider).isLoading);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Tìm theo tên hoặc email',
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              searching ? 'Tài khoản trong hệ thống' : 'Người quen',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: colors.textSecondary,
              ),
            ),
          ),
        ),
        Expanded(
          child: () {
            if (_searching || loadingAcq) {
              return const Center(child: CircularProgressIndicator());
            }
            if (searching && !searchable) {
              return _hint(colors, 'Nhập ít nhất 3 ký tự để tìm trên toàn hệ thống.');
            }
            if (list.isEmpty) {
              return _hint(
                colors,
                searching
                    ? 'Không tìm thấy tài khoản nào.'
                    : 'Chưa có người quen. Hãy tìm theo tên hoặc thêm người ngoài.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: list.length,
              separatorBuilder: (_, index) =>
                  Divider(height: 1, color: colors.border),
              itemBuilder: (_, i) => _personTile(colors, list[i], joined),
            );
          }(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _selected.isEmpty || _submitting ? null : _addSelected,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _selected.isEmpty
                          ? 'Thêm vào buổi'
                          : 'Thêm vào buổi (${_selected.length})',
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _personTile(
    AppColorsExtension colors,
    SocialPerson person,
    Set<String> joined,
  ) {
    final already = joined.contains(person.userId);
    final picked = _selected.containsKey(person.userId);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      enabled: !already,
      leading: SocialAvatar(name: person.fullName, imageUrl: person.avatarUrl),
      title: Text(
        person.fullName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
      ),
      subtitle: Text(
        already
            ? 'Đã tham gia'
            : [
                if (person.sources.contains(SocialPersonSource.friend))
                  'Bạn bè',
                if (person.sources.contains(SocialPersonSource.club)) 'CLB',
              ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: already
          ? Icon(Icons.check_circle_rounded, color: colors.success)
          : Checkbox(
              value: picked,
              onChanged: (_) => _toggle(person),
            ),
      onTap: already ? null : () => _toggle(person),
    );
  }

  void _toggle(SocialPerson person) => setState(() {
    if (_selected.remove(person.userId) == null) {
      _selected[person.userId] = person;
    }
  });

  Widget _hint(AppColorsExtension colors, String text) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: colors.textSecondary),
      ),
    ),
  );

  Widget _guestForm(AppColorsExtension colors) {
    final hasName = _guestController.text.trim().isNotEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Người chưa có tài khoản. Chỉ giữ chỗ trong buổi bằng tên.',
            style: TextStyle(color: colors.textSecondary, fontSize: 13.5),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _guestController,
            maxLength: 100,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Tên người chơi',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: hasName && !_submitting ? _addGuest : null,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Thêm người ngoài'),
            ),
          ),
        ],
      ),
    );
  }
}
