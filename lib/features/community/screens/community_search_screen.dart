import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/community_search_models.dart';
import 'package:app_quanly_giaidau/features/community/providers/community_search_provider.dart';
import 'package:app_quanly_giaidau/features/profile/widgets/user_profile_bottom_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CommunitySearchScreen extends ConsumerStatefulWidget {
  final String communityId;
  final String communityName;
  final String? initialQuery;

  const CommunitySearchScreen({
    super.key,
    required this.communityId,
    required this.communityName,
    this.initialQuery,
  });

  @override
  ConsumerState<CommunitySearchScreen> createState() =>
      _CommunitySearchScreenState();
}

class _CommunitySearchScreenState extends ConsumerState<CommunitySearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _activeQuery = '';
  CommunitySearchType _type = CommunitySearchType.all;

  @override
  void initState() {
    super.initState();
    final query = widget.initialQuery?.trim() ?? '';
    if (query.isNotEmpty) {
      _controller.text = query;
      _activeQuery = query.length >= 2 ? query : '';
    }
  }

  @override
  void didUpdateWidget(covariant CommunitySearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != oldWidget.initialQuery) {
      final query = widget.initialQuery?.trim() ?? '';
      _controller.text = query;
      setState(() => _activeQuery = query.length >= 2 ? query : '');
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      setState(() => _activeQuery = '');
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _activeQuery = query);
    });
  }

  void _selectType(CommunitySearchType type) {
    setState(() => _type = type);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final request = _activeQuery.length >= 2
        ? CommunitySearchRequest(
            communityId: widget.communityId,
            query: _activeQuery,
            type: _type,
          )
        : null;
    final resultAsync = request == null
        ? null
        : ref.watch(communitySearchProvider(request));

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: colors.bgCard,
        titleSpacing: 0,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: _onQueryChanged,
          onSubmitted: (value) {
            final query = value.trim();
            if (query.length >= 2) setState(() => _activeQuery = query);
          },
          style: TextStyle(color: colors.textPrimary, fontSize: 16),
          decoration: InputDecoration(
            hintText: l10n.communitySearchHint,
            hintStyle: TextStyle(color: colors.textMuted, fontSize: 15),
            border: InputBorder.none,
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (_, value, _) => value.text.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).deleteButtonTooltip,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _activeQuery = '');
                      },
                    ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildTypeChips(l10n, colors),
          Expanded(child: _buildResults(resultAsync, l10n, colors)),
        ],
      ),
    );
  }

  Widget _buildTypeChips(AppLocalizations l10n, AppColorsExtension colors) {
    final items = <(CommunitySearchType, String)>[
      (CommunitySearchType.all, l10n.communitySearchAll),
      (CommunitySearchType.posts, l10n.communitySearchPosts),
      (CommunitySearchType.members, l10n.communitySearchMembers),
      (CommunitySearchType.matches, l10n.communitySearchMatches),
      (CommunitySearchType.tournaments, l10n.communitySearchTournaments),
    ];
    return Container(
      color: colors.bgCard,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(item.$2),
                  selected: _type == item.$1,
                  onSelected: (_) => _selectType(item.$1),
                  selectedColor: AppTheme.primary.withValues(alpha: 0.14),
                  side: BorderSide(
                    color: _type == item.$1 ? AppTheme.primary : colors.border,
                  ),
                  labelStyle: TextStyle(
                    color: _type == item.$1
                        ? AppTheme.primary
                        : colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(
    AsyncValue<CommunitySearchResults>? resultAsync,
    AppLocalizations l10n,
    AppColorsExtension colors,
  ) {
    if (_activeQuery.length < 2 || resultAsync == null) {
      return Center(
        child: Text(
          l10n.communitySearchIdle,
          style: TextStyle(color: colors.textMuted),
        ),
      );
    }
    return resultAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
      error: (_, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, color: colors.textMuted, size: 42),
            const SizedBox(height: 10),
            Text(
              l10n.communitySearchError,
              style: TextStyle(color: colors.textSecondary),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(
                communitySearchProvider(
                  CommunitySearchRequest(
                    communityId: widget.communityId,
                    query: _activeQuery,
                    type: _type,
                  ),
                ),
              ),
              child: Text(l10n.communitySearchRetry),
            ),
          ],
        ),
      ),
      data: (results) => _buildResultList(results, l10n, colors),
    );
  }

  Widget _buildResultList(
    CommunitySearchResults results,
    AppLocalizations l10n,
    AppColorsExtension colors,
  ) {
    final sections = <Widget>[];
    if (_type == CommunitySearchType.all ||
        _type == CommunitySearchType.posts) {
      sections.add(_buildPostSection(results.posts, l10n, colors));
    }
    if (_type == CommunitySearchType.all ||
        _type == CommunitySearchType.members) {
      sections.add(_buildMemberSection(results.members, l10n, colors));
    }
    if (_type == CommunitySearchType.all ||
        _type == CommunitySearchType.matches) {
      sections.add(_buildMatchSection(results.matches, l10n, colors));
    }
    if (_type == CommunitySearchType.all ||
        _type == CommunitySearchType.tournaments) {
      sections.add(_buildTournamentSection(results.tournaments, l10n, colors));
    }
    final hasResults =
        results.posts.isNotEmpty ||
        results.members.isNotEmpty ||
        results.matches.isNotEmpty ||
        results.tournaments.isNotEmpty;
    if (!hasResults) {
      return Center(
        child: Text(
          l10n.communitySearchEmpty,
          style: TextStyle(color: colors.textMuted),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: sections,
    );
  }

  Widget _section(
    String title,
    int count,
    List<Widget> children,
    AppColorsExtension colors,
  ) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: colors.bgCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Text(
              '$title ($count)',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPostSection(
    List posts,
    AppLocalizations l10n,
    AppColorsExtension colors,
  ) => _section(
    l10n.communitySearchPosts,
    posts.length,
    posts
        .map<Widget>(
          (post) => ListTile(
            leading: CircleAvatar(
              backgroundImage: post.authorAvatarUrl?.trim().isNotEmpty == true
                  ? NetworkImage(post.authorAvatarUrl!.trim())
                  : null,
              child: post.authorAvatarUrl?.trim().isNotEmpty == true
                  ? null
                  : Text(
                      post.authorName.isEmpty
                          ? '?'
                          : post.authorName[0].toUpperCase(),
                    ),
            ),
            title: Text(
              post.authorName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              post.text.isEmpty ? l10n.communitySearchPosts : post.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => context.push(
              '/communities/${widget.communityId}/social?name=${Uri.encodeComponent(widget.communityName)}',
            ),
          ),
        )
        .toList(),
    colors,
  );

  Widget _buildMemberSection(
    List members,
    AppLocalizations l10n,
    AppColorsExtension colors,
  ) => _section(
    l10n.communitySearchMembers,
    members.length,
    members
        .map<Widget>(
          (member) => ListTile(
            leading: CircleAvatar(
              backgroundImage: member.userAvatarUrl?.trim().isNotEmpty == true
                  ? NetworkImage(member.userAvatarUrl!.trim())
                  : null,
              child: member.userAvatarUrl?.trim().isNotEmpty == true
                  ? null
                  : Text(
                      (member.userFullName?.trim().isNotEmpty == true
                              ? member.userFullName!.trim()[0]
                              : '?')
                          .toUpperCase(),
                    ),
            ),
            title: Text(
              member.userFullName?.trim().isNotEmpty == true
                  ? member.userFullName!.trim()
                  : l10n.communitySearchMembers,
            ),
            subtitle: Text(member.role),
            onTap: member.userId.isEmpty
                ? null
                : () => UserProfileBottomSheet.show(
                    context,
                    userId: member.userId,
                    communityId: widget.communityId,
                    initialFullName: member.userFullName,
                    initialAvatarUrl: member.userAvatarUrl,
                  ),
          ),
        )
        .toList(),
    colors,
  );

  Widget _buildMatchSection(
    List<CommunitySearchMatchModel> matches,
    AppLocalizations l10n,
    AppColorsExtension colors,
  ) => _section(
    l10n.communitySearchMatches,
    matches.length,
    matches
        .map<Widget>(
          (match) => ListTile(
            leading: const Icon(
              Icons.sports_tennis_outlined,
              color: AppTheme.primary,
            ),
            title: Text(
              match.title.isEmpty
                  ? (match.tournamentName ?? l10n.communitySearchMatches)
                  : match.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text('${match.tournamentName ?? ''} · ${match.status}'),
            onTap: () {
              if (match.tournamentId?.isNotEmpty == true) {
                context.push(
                  '/tournament/${match.tournamentId}/match/${match.id}',
                );
              } else {
                context.push('/club/${widget.communityId}/match-sessions');
              }
            },
          ),
        )
        .toList(),
    colors,
  );

  Widget _buildTournamentSection(
    List tournaments,
    AppLocalizations l10n,
    AppColorsExtension colors,
  ) => _section(
    l10n.communitySearchTournaments,
    tournaments.length,
    tournaments
        .map<Widget>(
          (tournament) => ListTile(
            leading: const Icon(
              Icons.emoji_events_outlined,
              color: AppTheme.primary,
            ),
            title: Text(
              tournament.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(tournament.status),
            onTap: () => context.push('/intro/${tournament.id}'),
          ),
        )
        .toList(),
    colors,
  );
}
