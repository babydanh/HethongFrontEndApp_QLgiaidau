import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/social/models/social_session_model.dart';
import 'package:app_quanly_giaidau/features/social/providers/social_provider.dart';
import 'package:app_quanly_giaidau/features/social/widgets/social_join_bottom_sheet.dart';

class SocialDetailScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const SocialDetailScreen({super.key, required this.sessionId});

  @override
  ConsumerState<SocialDetailScreen> createState() => _SocialDetailScreenState();
}

class _SocialDetailScreenState extends ConsumerState<SocialDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _chatInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = ref.watch(socialSessionDetailProvider(widget.sessionId));

    if (session == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text('Chi tiết Social'),
        ),
        body: const Center(child: Text('Không tìm thấy thông tin buổi Social')),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: _buildAppBar(context, isDark, session),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Session Title Headline (IMG2 & IMG3)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              session.title.toUpperCase(),
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: 0.2,
                height: 1.25,
              ),
            ),
          ),

          // 4 Horizontal Tabs (IMG2 & IMG3)
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              labelColor: const Color(0xFF2563EB), // Vibrant blue active tab
              unselectedLabelColor:
                  isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              labelStyle: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
              ),
              indicatorColor: const Color(0xFF2563EB),
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: 'Chi tiết'),
                Tab(text: 'Người tham gia'),
                Tab(text: 'Trận đấu'),
                Tab(text: 'Trò chuyện'),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(isDark, session),
                _buildParticipantsTab(isDark, session),
                _buildMatchesTab(isDark, session),
                _buildChatTab(isDark, session),
              ],
            ),
          ),

          // Bottom Sticky Action Bar (IMG2 & IMG3)
          _buildBottomActionBar(context, isDark, session),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    bool isDark,
    SocialSessionModel session,
  ) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          size: 24,
        ),
        onPressed: () => context.pop(),
      ),
      centerTitle: true,
      title: Text(
        session.dateDisplay,
        style: const TextStyle(
          fontSize: 16.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF2563EB), // Blue time header matching IMG2 & IMG3
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.ios_share_rounded,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            size: 22,
          ),
          onPressed: () => _handleShare(session),
        ),
        IconButton(
          icon: Icon(
            Icons.more_vert_rounded,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            size: 22,
          ),
          onPressed: () => _showMoreOptions(context, session),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  //  TAB 1: CHI TIẾT (IMG2 Upper + IMG3 Lower)
  // ═══════════════════════════════════════════════════════
  Widget _buildDetailsTab(bool isDark, SocialSessionModel session) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── UPPER PART (IMG2) ───

          // 1. Club Host Banner Card (Light green background matching IMG2)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E2922)
                  : const Color(0xFFF0FDF4), // Mint/light-green
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF166534).withValues(alpha: 0.3)
                    : const Color(0xFFDCFCE7),
              ),
            ),
            child: Row(
              children: [
                // Club Logo Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? Colors.black26 : Colors.white,
                    border: Border.all(
                      color: const Color(0xFF22C55E),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.sports_tennis_rounded,
                      size: 22,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Host Name & Frequency
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🇻🇳 ', style: TextStyle(fontSize: 13)),
                          Expanded(
                            child: Text(
                              session.hostClubName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        session.hostFrequency,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

                // 'Xem lịch' outlined button
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Xem lịch sinh hoạt của ${session.hostClubName}',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2563EB)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Xem lịch',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 2. Participants Avatars Row & 'Liên hệ BTC' (IMG2)
          Row(
            children: [
              // Host Avatar Circle (e.g. MQ)
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF6EE7B7), // Mint green circle
                ),
                child: const Center(
                  child: Text(
                    'MQ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF064E3B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Empty Slot Circles (Dashed/Grey border circles)
              for (int i = 0; i < 3; i++)
                Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  ),
                ),

              // '+4' Counter Badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                ),
                child: const Center(
                  child: Text(
                    '+4',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 'Liên hệ BTC' link
          GestureDetector(
            onTap: () => _handleContactHost(session),
            child: const Text(
              'Liên hệ BTC',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. Date & Time Row (IMG2)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 22,
                color: isDark ? Colors.white70 : const Color(0xFF1E293B),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.fullDateTimeDisplay,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${session.durationHours} giờ',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Đã lưu buổi Social vào lịch điện thoại!',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text(
                        'Thêm vào lịch',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 4. Location Row (IMG2)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 24,
                color: isDark ? Colors.white70 : const Color(0xFF1E293B),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.venueName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2563EB), // Blue location name
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.venueAddress,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF334155),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${session.distanceKm.toStringAsFixed(1)} km từ Nhà',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 5. Play Format Row (IMG2)
          Row(
            children: [
              Icon(
                Icons.sports_tennis_outlined,
                size: 22,
                color: isDark ? Colors.white70 : const Color(0xFF1E293B),
              ),
              const SizedBox(width: 14),
              Text(
                session.playFormat,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 6. Price Row (IMG2)
          Row(
            children: [
              Icon(
                Icons.local_offer_outlined,
                size: 22,
                color: isDark ? Colors.white70 : const Color(0xFF1E293B),
              ),
              const SizedBox(width: 14),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Mỗi người · ',
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                    TextSpan(
                      text: currencyFormatter.format(session.pricePerSlot),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Divider between upper details and lower notes
          Divider(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFFE2E8F0),
            thickness: 1,
          ),
          const SizedBox(height: 16),

          // ─── LOWER PART: LƯU Ý / GHI CHÚ (IMG3) ───
          Text(
            'Lưu ý',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
              ),
            ),
            child: SelectableText(
              session.descriptionNotes,
              style: TextStyle(
                fontSize: 14.5,
                color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                height: 1.6,
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  TAB 2: NGƯỜI THAM GIA
  // ═══════════════════════════════════════════════════════
  Widget _buildParticipantsTab(bool isDark, SocialSessionModel session) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        // Capacity Header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Danh sách người tham gia',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Text(
                '${session.currentParticipants}/${session.maxParticipants}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // List of Participants
        if (session.participants.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text('Chưa có thành viên nào tham gia'),
            ),
          )
        else
          ...session.participants.map((p) {
            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              leading: CircleAvatar(
                radius: 22,
                backgroundColor: p.isHost
                    ? const Color(0xFF6EE7B7)
                    : const Color(0xFF93C5FD),
                child: Text(
                  p.initials,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: p.isHost
                        ? const Color(0xFF064E3B)
                        : const Color(0xFF1E3A8A),
                  ),
                ),
              ),
              title: Row(
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (p.isHost) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'HOST',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: Text(
                '${p.status} · ${p.skillLevel}',
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            );
          }),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  //  TAB 3: TRẬN ĐẤU
  // ═══════════════════════════════════════════════════════
  Widget _buildMatchesTab(bool isDark, SocialSessionModel session) {
    if (session.matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports_tennis_rounded,
                size: 48,
                color: isDark ? Colors.white30 : Colors.black26,
              ),
              const SizedBox(height: 12),
              const Text(
                'Trận đấu sẽ được cập nhật khi buổi Social diễn ra',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                'Host sẽ chia cặp giao lưu và xếp sân trực tiếp cho các bạn tham gia.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: session.matches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final match = session.matches[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${match.courtName} · ${match.matchType}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: match.status == 'Đã xong'
                          ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                          : Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      match.status,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: match.status == 'Đã xong'
                            ? const Color(0xFF16A34A)
                            : Colors.amber[800],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '🎾 ${match.team1Name}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                '🎾 ${match.team2Name}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (match.score != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Tỉ số: ${match.score}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════
  //  TAB 4: TRÒ CHUYỆN
  // ═══════════════════════════════════════════════════════
  Widget _buildChatTab(bool isDark, SocialSessionModel session) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: session.chatMessages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final msg = session.chatMessages[index];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: msg.isHost
                        ? const Color(0xFF6EE7B7)
                        : const Color(0xFF93C5FD),
                    child: Text(
                      msg.senderInitials,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF262626)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                msg.senderName,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${msg.time.hour}:${msg.time.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            msg.message,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // Chat Input Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatInputController,
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn giao lưu...',
                      hintStyle: TextStyle(
                        fontSize: 13.5,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF262626)
                          : const Color(0xFFF1F5F9),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.send_rounded,
                    color: Color(0xFF2563EB),
                  ),
                  onPressed: () {
                    final text = _chatInputController.text.trim();
                    if (text.isNotEmpty) {
                      ref
                          .read(socialSessionsProvider.notifier)
                          .addChatMessage(session.id, text);
                      _chatInputController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  //  BOTTOM ACTION BAR (IMG2 & IMG3)
  // ═══════════════════════════════════════════════════════
  Widget _buildBottomActionBar(
    BuildContext context,
    bool isDark,
    SocialSessionModel session,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18191A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Left Button: 'Chat với host' (Outlined button with blue border)
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => _handleContactHost(session),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xFF2563EB),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    foregroundColor: const Color(0xFF2563EB),
                  ),
                  child: const Text(
                    'Chat với host',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Right Button: 'Yêu cầu tham gia' (Solid blue button)
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _handleRequestJoin(context, session),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB), // Vibrant blue
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Yêu cầu tham gia',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleContactHost(SocialSessionModel session) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Liên hệ Host: ${session.hostClubName}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (session.hostPhone != null)
                  ListTile(
                    leading: const Icon(Icons.phone, color: Color(0xFF16A34A)),
                    title: Text('Gọi điện: ${session.hostPhone}'),
                    onTap: () {
                      Navigator.pop(ctx);
                      launchUrl(Uri.parse('tel:${session.hostPhone}'));
                    },
                  ),
                if (session.zaloGroupUrl != null)
                  ListTile(
                    leading: const Icon(Icons.group, color: Color(0xFF2563EB)),
                    title: const Text('Tham gia nhóm Zalo'),
                    subtitle: Text(session.zaloGroupUrl!),
                    onTap: () {
                      Navigator.pop(ctx);
                      launchUrl(
                        Uri.parse(session.zaloGroupUrl!),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline, color: AppTheme.primary),
                  title: const Text('Gửi tin nhắn trong app'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _tabController.animateTo(3); // Switch to Chat tab
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleRequestJoin(BuildContext context, SocialSessionModel session) {
    SocialJoinBottomSheet.show(context, session);
  }

  void _handleShare(SocialSessionModel session) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép link chia sẻ buổi ${session.title}!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showMoreOptions(BuildContext context, SocialSessionModel session) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.report_problem_outlined),
                title: const Text('Báo cáo buổi Social này'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cảm ơn bạn đã gửi báo cáo.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.block_outlined),
                title: const Text('Ẩn các buổi của Host này'),
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
