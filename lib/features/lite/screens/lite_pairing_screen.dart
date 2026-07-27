import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';

/// Lightweight model for a Lite participant from the pairing API.
class _LiteParticipant {
  final String id;
  final String status;
  final String teamName;
  final List<_LiteMember> members;

  const _LiteParticipant({
    required this.id,
    required this.status,
    this.teamName = '',
    this.members = const [],
  });

  factory _LiteParticipant.fromJson(Map<String, dynamic> json) {
    final membersList =
        (json['rosters'] as List<dynamic>?)
            ?.map(
              (m) => _LiteMember.fromRosterJson(
                Map<String, dynamic>.from(m as Map),
              ),
            )
            .toList() ??
        [];
    return _LiteParticipant(
      id: json['id']?.toString() ?? '',
      status: (json['teamStatus']?.toString() ?? '').toUpperCase(),
      teamName: json['teamName']?.toString() ?? '',
      members: membersList,
    );
  }

  bool get isPending => status == 'PENDING_PARTNER';
  bool get isComplete => status == 'COMPLETE' || status == 'PENDING_APPROVAL';

  String get displayName => teamName.isNotEmpty
      ? teamName
      : members.map((m) => m.fullName).join(' & ');
}

class _LiteMember {
  final String id;
  final String fullName;
  final String avatarUrl;

  const _LiteMember({
    required this.id,
    this.fullName = '',
    this.avatarUrl = '',
  });

  factory _LiteMember.fromRosterJson(Map<String, dynamic> json) {
    final profile = json['profile'] is Map
        ? Map<String, dynamic>.from(json['profile'] as Map)
        : const <String, dynamic>{};
    return _LiteMember(
      id: json['userId']?.toString() ?? '',
      fullName: profile['fullName']?.toString() ?? '',
      avatarUrl: profile['avatarUrl']?.toString() ?? '',
    );
  }
}

/// Compact organizer screen for Lite tournament pairing.
/// Supports manual pair, RANDOM/ELO_BALANCED generate, and unpair.
class LitePairingScreen extends ConsumerStatefulWidget {
  final String tournamentId;

  const LitePairingScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<LitePairingScreen> createState() => _LitePairingScreenState();
}

class _LitePairingScreenState extends ConsumerState<LitePairingScreen> {
  static const _log = AppLogger('LitePairing');

  bool _loading = true;
  String? _error;
  String? _matchType;
  String? _tournamentName;
  List<_LiteParticipant> _participants = [];
  List<_LiteParticipant> _pairedParticipants = [];
  final Set<String> _selectedIds = {};
  bool _pairing = false;
  bool _generating = false;
  String? _generatingStrategy;

  @override
  void initState() {
    super.initState();
    _fetchTournament();
    _fetchParticipants();
  }

  Future<void> _fetchTournament() async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      final res = await dio.get('/tournaments/${widget.tournamentId}');
      final envelope = res.data;
      final payload = envelope is Map ? envelope['data'] : envelope;
      if (mounted && payload is Map) {
        setState(() {
          _matchType = payload['matchType']?.toString().toUpperCase();
          _tournamentName = payload['name']?.toString();
        });
      }
    } catch (_) {
      // Non-critical: pairing screen still works with default title
    }
  }

  Future<void> _fetchParticipants() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioClientProvider).dio;
      final res = await dio.get(
        '/tournaments/lite/${widget.tournamentId}/participants',
      );
      final envelope = res.data;
      final payload = envelope is Map ? envelope['data'] : envelope;
      final rawParticipants = payload is List ? payload : const <dynamic>[];

      if (mounted) {
        setState(() {
          _participants = rawParticipants
              .map(
                (e) => _LiteParticipant.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList();
          _pairedParticipants = const [];
          _selectedIds.clear();
          _loading = false;
        });
      }
    } catch (e, stack) {
      _log.error('Lỗi tải danh sách người tham gia', e, stack);
      if (mounted) {
        setState(() {
          _error = 'Không thể tải danh sách người tham gia';
          _loading = false;
        });
      }
    }
  }

  Future<void> _manualPair() async {
    if (_selectedIds.length != 2) return;
    final ids = _selectedIds.toList();
    setState(() => _pairing = true);
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.post(
        '/tournaments/lite/${widget.tournamentId}/pairs',
        data: {'participant1Id': ids[0], 'participant2Id': ids[1]},
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ghép cặp thành công')));
        _fetchParticipants();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi ghép cặp: ${e.toString().replaceAll('Exception: ', '').replaceAll('DioException: ', '')}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _pairing = false);
    }
  }

  Future<void> _generatePairs(String strategy) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận ghép cặp'),
        content: Text(
          strategy == 'RANDOM'
              ? 'Ghép ngẫu nhiên tất cả người chơi đang chờ?'
              : 'Ghép tất cả người chơi đang chờ theo ELO cân bằng?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _generating = true;
      _generatingStrategy = strategy;
    });
    try {
      final dio = ref.read(dioClientProvider).dio;
      final res = await dio.post(
        '/tournaments/lite/${widget.tournamentId}/pairs/generate',
        data: {'strategy': strategy},
      );
      final data = res.data is Map ? (res.data as Map)['data'] as Map? : null;
      final unpairedIds =
          (data?['unpairedParticipantIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      if (mounted) {
        final msg = unpairedIds.isEmpty
            ? 'Ghép cặp tự động thành công'
            : 'Ghép cặp thành công (${unpairedIds.length} người lẻ)';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
        _fetchParticipants();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi sinh cặp: ${e.toString().replaceAll('Exception: ', '').replaceAll('DioException: ', '')}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _generating = false;
          _generatingStrategy = null;
        });
      }
    }
  }

  Future<void> _unpair(String participantId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hủy ghép cặp?'),
        content: const Text('Hai người chơi sẽ trở lại danh sách chờ ghép.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Giữ nguyên'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hủy ghép'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.post(
        '/tournaments/lite/${widget.tournamentId}/pairs/$participantId/unpair',
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã hủy ghép cặp')));
        _fetchParticipants();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi hủy cặp: ${e.toString().replaceAll('Exception: ', '').replaceAll('DioException: ', '')}',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _tournamentName ?? 'Ghép cặp người chơi',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: colors.textPrimary),
            onPressed: _loading ? null : _fetchParticipants,
          ),
        ],
      ),
      body: _buildBody(colors),
    );
  }

  Widget _buildBody(AppColorsExtension colors) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 40, color: colors.error),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchParticipants,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final pending = _participants.where((p) => p.isPending).toList();
    final allPaired = [
      ..._pairedParticipants,
      ..._participants.where((p) => p.isComplete),
    ];
    final isDoubles = _matchType == 'DOUBLES';

    return RefreshIndicator(
      onRefresh: _fetchParticipants,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (isDoubles) ...[
            // ─── Pending Section ───
            _sectionHeader(
              colors,
              'Chờ ghép cặp (${pending.length})',
              Icons.people_outline_rounded,
            ),
            const SizedBox(height: 8),
            if (pending.isEmpty)
              _emptyCard(colors, 'Không có người chơi đang chờ ghép cặp')
            else
              ...pending.map((p) => _pendingTile(p, colors)),

            // ─── Manual pair button ───
            if (_selectedIds.length == 2) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton.icon(
                  onPressed: _pairing ? null : _manualPair,
                  icon: _pairing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.link_rounded, size: 18),
                  label: Text(
                    _pairing ? 'Đang ghép...' : 'Ghép 2 người đã chọn',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                    ),
                  ),
                ),
              ),
            ],

            // ─── Auto generate section ───
            if (pending.length >= 2) ...[
              const SizedBox(height: 16),
              _sectionHeader(
                colors,
                'Ghép cặp tự động',
                Icons.auto_fix_high_rounded,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _generating
                          ? null
                          : () => _generatePairs('RANDOM'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusXL,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _generating && _generatingStrategy == 'RANDOM'
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Ngẫu nhiên',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _generating
                          ? null
                          : () => _generatePairs('ELO_BALANCED'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusXL,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child:
                          _generating && _generatingStrategy == 'ELO_BALANCED'
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Cân bằng ELO',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],

            // ─── Odd notice ───
            if (pending.length.isOdd) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  border: Border.all(
                    color: colors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: colors.warning,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Số lẻ: 1 người chơi sẽ ở lại trạng thái chờ ghép',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ─── Paired Section ───
            if (allPaired.isNotEmpty) ...[
              const SizedBox(height: 24),
              _sectionHeader(
                colors,
                'Đã ghép cặp (${allPaired.length})',
                Icons.check_circle_outline_rounded,
              ),
              const SizedBox(height: 8),
              ...allPaired.map((p) => _pairedTile(p, colors)),
            ],
          ] else ...[
            // ─── Singles: just participant list, no pairing ───
            if (_participants.isEmpty)
              _emptyCard(colors, 'Chưa có người tham gia')
            else
              ..._participants.map((p) => _singlesTile(p, colors)),
          ],

          // ─── Bracket generation ───
          if (allPaired.isNotEmpty ||
              (_participants.isNotEmpty && !isDoubles)) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _generating ? null : _generateBracket,
                icon: _generating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(Icons.emoji_events_rounded, size: 20),
                label: Text(
                  _generating ? 'Đang tạo...' : 'Tạo bracket',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _generateBracket() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tạo bracket?'),
        content: const Text(
          'Sau khi tạo bracket, không thể ghép thêm cặp mới. Tiếp tục?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Tạo bracket'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _generating = true);
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.post('/tournaments/lite/${widget.tournamentId}/bracket');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tạo bracket thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Chức năng tạo bracket sẽ khả dụng sau khi backend cập nhật. '
              'Lỗi: ${e.toString().replaceAll('Exception: ', '').replaceAll('DioException: ', '')}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Widget _sectionHeader(
    AppColorsExtension colors,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colors.textSecondary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _emptyCard(AppColorsExtension colors, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: colors.textMuted, fontSize: 13),
      ),
    );
  }

  Widget _pendingTile(_LiteParticipant participant, AppColorsExtension colors) {
    final selected = _selectedIds.contains(participant.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: selected
            ? AppTheme.primary.withValues(alpha: 0.06)
            : colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(
          color: selected ? AppTheme.primary : colors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            if (selected) {
              _selectedIds.remove(participant.id);
            } else {
              if (_selectedIds.length >= 2) {
                _selectedIds.remove(_selectedIds.first);
              }
              _selectedIds.add(participant.id);
            }
          });
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 22,
                color: selected ? AppTheme.primary : colors.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      participant.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (participant.members.isNotEmpty)
                      Text(
                        participant.members.map((m) => m.fullName).join(', '),
                        style: TextStyle(fontSize: 11, color: colors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Chờ cặp',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colors.warning,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _singlesTile(_LiteParticipant participant, AppColorsExtension colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.person_rounded, size: 20, color: colors.info),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                if (participant.members.isNotEmpty)
                  Text(
                    participant.members.map((m) => m.fullName).join(', '),
                    style: TextStyle(fontSize: 11, color: colors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Đã tham gia',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: colors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pairedTile(_LiteParticipant participant, AppColorsExtension colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(Icons.group_rounded, size: 20, color: colors.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                if (participant.members.isNotEmpty)
                  Text(
                    participant.members.map((m) => m.fullName).join(', '),
                    style: TextStyle(fontSize: 11, color: colors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (participant.members.length >= 2)
            SizedBox(
              height: 32,
              child: OutlinedButton(
                onPressed: () => _unpair(participant.id),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.error,
                  side: BorderSide(color: colors.error.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                ),
                child: Text(
                  'Hủy ghép',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
