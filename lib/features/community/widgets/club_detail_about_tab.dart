part of '../screens/club_detail_screen.dart';

extension _ClubDetailAboutTab on _ClubDetailScreenState {
  Widget _buildAboutTab(Community club, AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    final String sportsDisplay = club.sports.isNotEmpty
        ? club.sports
              .map(l10n.sportDisplayName)
              .where((s) => s.isNotEmpty && s.toLowerCase() != 'thể thao')
              .join(', ')
        : l10n.createClubTournament_sportPickleball;
    final finalSportsText = sportsDisplay.isEmpty
        ? l10n.createClubTournament_sportPickleball
        : sportsDisplay;

    String createdDateText = '';
    if (club.createdAt.isNotEmpty) {
      final parsedDate = DateTime.tryParse(club.createdAt);
      if (parsedDate != null) {
        createdDateText =
            '${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}';
      }
    }

    final hasRules = club.rules != null && club.rules!.trim().isNotEmpty;
    final hasDesc =
        club.description != null && club.description!.trim().isNotEmpty;
    final hasSocial = club.socialLinks.entries.any(
      (e) => e.value.trim().isNotEmpty,
    );

    // Xử lý danh sách quy tắc (nếu có xuống dòng hoặc số thứ tự)
    final List<String> parsedRuleList = [];
    if (hasRules) {
      final rawLines = club.rules!
          .split(RegExp(r'\r?\n'))
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      parsedRuleList.addAll(rawLines);
    }

    final isOwnerOrAdmin =
        _myMembership?.role == 'OWNER' || _myMembership?.role == 'ADMIN';

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 14),
      children: [
        // ─── 1. GIỚI THIỆU (Facebook Style) ───
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Giới thiệu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              if (hasDesc) ...[
                Builder(
                  builder: (context) {
                    final descText = club.description!.trim();
                    final isLongDesc = descText.length > 140;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          descText,
                          maxLines: _isAboutDescExpanded || !isLongDesc
                              ? null
                              : 3,
                          overflow: _isAboutDescExpanded || !isLongDesc
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                        if (isLongDesc)
                          InkWell(
                            onTap: () {
                              _updateClubState(() {
                                _isAboutDescExpanded = !_isAboutDescExpanded;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                _isAboutDescExpanded
                                    ? 'Thu gọn'
                                    : '... Xem thêm',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
              ],
              // Thông tin cơ bản: Công khai / Riêng tư, Hiển thị, Lịch sử nhóm
              _buildFbMetaRow(
                icon: club.visibility.toUpperCase() == 'PRIVATE'
                    ? Icons.lock_outline_rounded
                    : Icons.public_rounded,
                title: club.visibility.toUpperCase() == 'PRIVATE'
                    ? l10n.club_aboutPrivacyPrivate
                    : l10n.club_aboutPrivacyPublic,
                subtitle: club.visibility.toUpperCase() == 'PRIVATE'
                    ? 'Chỉ thành viên mới nhìn thấy những người trong nhóm và những gì họ đăng.'
                    : 'Bất kỳ ai cũng có thể nhìn thấy mọi người trong nhóm và những gì họ đăng.',
                colors: colors,
              ),
              const SizedBox(height: 12),
              _buildFbMetaRow(
                icon: Icons.visibility_outlined,
                title: 'Hiển thị',
                subtitle: club.visibility.toUpperCase() == 'HIDDEN'
                    ? 'Nhóm bị ẩn, chỉ thành viên mới tìm thấy.'
                    : 'Ai cũng có thể tìm thấy nhóm này.',
                colors: colors,
              ),
              if (createdDateText.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildFbMetaRow(
                  icon: Icons.access_time_rounded,
                  title: 'Xem lịch sử nhóm',
                  subtitle: 'Ngày tạo nhóm: $createdDateText',
                  colors: colors,
                ),
              ],
              const SizedBox(height: 12),
              _buildFbMetaRow(
                icon: Icons.sports_tennis_rounded,
                title: l10n.club_sportLabel,
                subtitle: finalSportsText,
                colors: colors,
              ),
              if ((club.locationAddress ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildFbMetaRow(
                  icon: Icons.location_on_outlined,
                  title: l10n.club_location,
                  subtitle: club.locationAddress!,
                  colors: colors,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        _fbDivider(colors),
        const SizedBox(height: 18),

        // ─── 2. QUY TẮC NHÓM CỦA QUẢN TRỊ VIÊN ───
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Quy tắc nhóm của quản trị viên',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  if (isOwnerOrAdmin)
                    InkWell(
                      onTap: () => context.push('/club/${widget.clubId}/edit'),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit_note_rounded,
                              size: 16,
                              color: colors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.club_tabSettings,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              if (hasRules) ...[
                // Hiển thị danh sách quy tắc với định dạng số thứ tự 1, 2, 3...
                Builder(
                  builder: (context) {
                    final items = parsedRuleList;
                    final isLongList = items.length > 3;
                    final visibleCount = _isAboutRulesExpanded || !isLongList
                        ? items.length
                        : 3;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < visibleCount; i++) ...[
                          _buildFbRuleItem(
                            index: i + 1,
                            content: items[i],
                            colors: colors,
                          ),
                          if (i < visibleCount - 1) const SizedBox(height: 14),
                        ],
                        if (isLongList) ...[
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: () {
                              _updateClubState(() {
                                _isAboutRulesExpanded = !_isAboutRulesExpanded;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _isAboutRulesExpanded
                                        ? 'Thu gọn quy tắc'
                                        : 'Xem thêm (${items.length - 3} quy tắc khác)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    _isAboutRulesExpanded
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    size: 18,
                                    color: AppTheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ] else ...[
                Text(
                  l10n.club_aboutRegulationsDefault,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: colors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        _fbDivider(colors),
        const SizedBox(height: 18),

        // ─── 3. HOẠT ĐỘNG TRONG NHÓM & THÀNH VIÊN ───
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hoạt động trong nhóm',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 14),
              _buildFbActivityItem(
                icon: Icons.group_outlined,
                title:
                    'Tổng số thành viên: ${club.memberCount}${club.maxMembers != null ? " / ${club.maxMembers}" : ""}',
                subtitle: club.joinMode == "OPEN"
                    ? 'Bất kỳ ai cũng có thể tự do tham gia CLB'
                    : club.joinMode == "APPROVAL"
                    ? 'Yêu cầu tham gia cần người quản trị phê duyệt'
                    : 'Chỉ nhận thành viên qua lời mời',
                colors: colors,
              ),
              const SizedBox(height: 12),
              _buildFbActivityItem(
                icon: Icons.emoji_events_outlined,
                title: '${club.tournamentCount} giải đấu đã tổ chức',
                subtitle: 'Giao lưu thi đấu chuyên nghiệp và phong trào',
                colors: colors,
              ),
            ],
          ),
        ),

        // ─── 4. KÊNH LIÊN HỆ & MẠNG XÃ HỘI (nếu có) ───
        if (hasSocial) ...[
          const SizedBox(height: 18),
          _fbDivider(colors),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.club_aboutContactChannels,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: club.socialLinks.entries
                      .where((entry) => entry.value.trim().isNotEmpty)
                      .map(
                        (entry) => ActionChip(
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          avatar: Icon(
                            _socialIcon(entry.key),
                            size: 16,
                            color: colors.textSecondary,
                          ),
                          label: Text(
                            _socialLabel(entry.key),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: colors.textPrimary,
                            ),
                          ),
                          backgroundColor: colors.bgSurface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: colors.borderLight),
                          ),
                          onPressed: () => _openSocialLink(entry.value),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}
