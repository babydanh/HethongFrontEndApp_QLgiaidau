import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/sport_icon_widget.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/social_place.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/providers/social_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/social_location_flow.dart';
import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/social_location_row.dart';
import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/social_duration_sheet.dart';
import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/social_price_dialog.dart';
import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/social_privacy_sheet.dart';
import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/social_setting_tile.dart';
import 'package:app_quanly_giaidau/features/social/widgets/participant_tab/social_participant_counter.dart';

class CreateSocialScreen extends ConsumerStatefulWidget {
  final String clubId;
  final String clubName;
  final String? clubLogoUrl;
  final SocialSessionModel? initialSession;

  const CreateSocialScreen({
    super.key,
    required this.clubId,
    required this.clubName,
    this.clubLogoUrl,
    this.initialSession,
  });

  @override
  ConsumerState<CreateSocialScreen> createState() => _CreateSocialScreenState();
}

class _CreateSocialScreenState extends ConsumerState<CreateSocialScreen> {
  // Môn thể thao đến từ danh mục đang bật; chỉ slug/tên được gửi lên API.
  late String _selectedSportKey;
  late String _selectedSportName;
  // Người dùng đã tự chọn môn: không còn tự chọn danh mục đầu tiên.
  bool _userPickedSport = false;

  // Format options: Giao lưu, Đánh vòng tròn, Đánh đơn, Đánh đôi
  final List<String> _formats = const [
    'Giao lưu',
    'Đánh vòng tròn',
    'Đánh đơn',
    'Đánh đôi',
  ];
  late String _selectedFormat;

  // Date and Time
  late DateTime _selectedDateTime;
  double _durationHours = 1.0;

  SocialPlace? _selectedPlace;

  // Configurations
  int _maxParticipants = 6;
  String _privacy = 'Công khai';
  int _price = 0;

  // Title and Notes
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  // Buổi mới chỉ gắn CLB khi route có clubId; buổi đang sửa dùng CLB hiện tại.
  late bool _isClubAttached;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final init = widget.initialSession;
    if (init != null) {
      _selectedSportKey = init.sport;
      _selectedSportName = init.sportName;
      _selectedFormat = init.playFormat;
      _selectedDateTime = init.startAt;
      _durationHours = init.durationMinutes / 60.0;
      _maxParticipants = init.maxSlots;
      _privacy = init.visibility == 'CLUB_ONLY' ? 'Nội bộ CLB' : 'Công khai';
      _price = init.feePerSlot;
      if (init.venueName.trim().isNotEmpty &&
          init.venueAddress.trim().isNotEmpty) {
        _selectedPlace = SocialPlace(
          name: init.venueName,
          formattedAddress: init.venueAddress,
          latitude: init.latitude,
          longitude: init.longitude,
        );
      }
      _titleController.text = init.title;
      _notesController.text = init.description ?? '';
      _isClubAttached =
          (init.communityId != null && init.communityId!.isNotEmpty);
    } else {
      // Môn được chọn khi danh mục nạp xong, không hard-code danh sách.
      _selectedSportKey = '';
      _selectedSportName = '';
      _isClubAttached = widget.clubId.isNotEmpty;
      _selectedFormat = _formats.first;

      // Default time: next hour or 14:45
      final now = DateTime.now();
      _selectedDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        now.hour + 1,
        0,
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _getHostName() {
    final user = ref.read(userProfileProvider).asData?.value;
    final fullName = user?.fullName?.trim();
    if (fullName != null && fullName.isNotEmpty) {
      final parts = fullName.split(' ');
      return parts.last;
    }
    return 'Host';
  }

  /// Chỉ danh mục đang bật mới được chọn cho buổi mới.
  List<CategoryModel> _activeSports(AsyncValue<List<CategoryModel>> catalog) {
    final all = catalog.asData?.value ?? const <CategoryModel>[];
    return all
        .where(
          (category) => category.isActive && category.slug.trim().isNotEmpty,
        )
        .toList(growable: false);
  }

  /// Môn đang giữ: lựa chọn của người dùng, hoặc danh mục đầu tiên khi form
  /// mới vừa nạp xong danh mục. Môn cũ đã bị gỡ vẫn giữ nguyên slug.
  ({String slug, String name}) _resolveSport(List<CategoryModel> active) {
    final slug = _selectedSportKey.trim();
    if (slug.isEmpty) {
      if (widget.initialSession != null || _userPickedSport) {
        return (slug: '', name: _selectedSportName);
      }
      final first = active.isEmpty ? null : active.first;
      return (slug: first?.slug ?? '', name: first?.name ?? '');
    }
    for (final category in active) {
      if (category.slug == slug) return (slug: slug, name: category.name);
    }
    return (slug: slug, name: _selectedSportName);
  }

  /// Môn của buổi đang sửa không còn trong danh mục đang bật.
  bool _isRetiredSport(List<CategoryModel> active) {
    if (widget.initialSession == null || _userPickedSport) return false;
    final slug = _selectedSportKey.trim();
    if (slug.isEmpty) return false;
    return !active.any((category) => category.slug == slug);
  }

  String _getComputedDefaultTitle(String sportName) {
    final hostName = _getHostName();
    return '$sportName $_selectedFormat với $hostName';
  }

  // ─── Wording: phân biệt buổi gắn CLB và kèo độc lập ───
  String _createUpdateTitle(AppLocalizations l10n) {
    if (widget.initialSession != null) {
      return _isClubAttached
          ? l10n.socialClubUpdateTitle
          : l10n.socialOpenUpdateTitle;
    }
    return _isClubAttached
        ? l10n.socialClubCreateTitle
        : l10n.socialOpenCreateTitle;
  }

  String _detailsLabel(AppLocalizations l10n) => _isClubAttached
      ? l10n.socialClubDetailsLabel
      : l10n.socialOpenDetailsLabel;

  String _titleFieldLabel(AppLocalizations l10n) => _isClubAttached
      ? l10n.socialClubTitleFieldLabel
      : l10n.socialOpenTitleFieldLabel;

  String _feeLabel(AppLocalizations l10n) =>
      _isClubAttached ? l10n.socialClubFeeLabel : l10n.socialOpenFeeLabel;

  /// `_privacy` giữ nguyên giá trị nội bộ ('Nội bộ CLB' / 'Công khai') vì
  /// _submit() so sánh nó để suy ra 'CLUB_ONLY' / 'PUBLIC' cho API. Chỉ khi hiển
  /// thị mới dịch — tách state khỏi cách hiển thị để đổi ngôn ngữ không làm hỏng
  /// payload.
  String _privacyLabel(AppLocalizations l10n) => _privacy == 'Nội bộ CLB'
      ? l10n.socialPrivacyClubOnly
      : l10n.socialPrivacyPublic;

  /// Danh mục môn đang bật: thẻ vector xuống dòng, kèm nạp/lỗi/rỗng + thử lại.
  Widget _buildSportSection(
    BuildContext context, {
    required AppLocalizations l10n,
    required AsyncValue<List<CategoryModel>> catalog,
    required List<CategoryModel> activeSports,
    required ({String slug, String name}) sport,
  }) {
    final colors = context.colors;
    final label = Text(
      l10n.socialActiveSportsLabel,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: colors.textSecondary,
        letterSpacing: 0.3,
      ),
    );

    if (catalog.isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          label,
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.socialActiveSportsLoading,
                style: TextStyle(fontSize: 13.5, color: colors.textSecondary),
              ),
            ],
          ),
        ],
      );
    }

    if (catalog.hasError || activeSports.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          label,
          const SizedBox(height: 10),
          Text(
            catalog.hasError
                ? l10n.socialActiveSportsError
                : l10n.socialActiveSportsEmpty,
            style: TextStyle(fontSize: 13.5, color: colors.textSecondary),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => ref.invalidate(categoriesProvider),
              child: Text(l10n.socialActiveSportsRetry),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label,
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 10.0;
            final columns = constraints.maxWidth >= 330 ? 3 : 2;
            final itemWidth =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                if (_isRetiredSport(activeSports))
                  SizedBox(
                    width: itemWidth,
                    child: _buildSportCard(
                      context,
                      sportSlug: _selectedSportKey,
                      name: _selectedSportName,
                      isSelected: sport.slug == _selectedSportKey,
                      isEnabled: false,
                      note: l10n.socialLegacyInactiveSport,
                    ),
                  ),
                for (final category in activeSports)
                  SizedBox(
                    width: itemWidth,
                    child: _buildSportCard(
                      context,
                      sportSlug: category.slug,
                      name: category.name,
                      isSelected: category.slug == sport.slug,
                      isEnabled: true,
                      onTap: () => setState(() {
                        _selectedSportKey = category.slug;
                        _selectedSportName = category.name;
                        _userPickedSport = true;
                      }),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSportCard(
    BuildContext context, {
    required String sportSlug,
    required String name,
    required bool isSelected,
    required bool isEnabled,
    String? note,
    VoidCallback? onTap,
  }) {
    final colors = context.colors;
    return Semantics(
      button: isEnabled,
      enabled: isEnabled,
      selected: isSelected,
      label: note == null ? name : '$name, $note',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.success.withValues(alpha: 0.16)
                : colors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? colors.success : colors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SportIconWidget(iconData: sportSlug, size: 26),
              const SizedBox(height: 4),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isEnabled ? colors.textPrimary : colors.textMuted,
                ),
              ),
              if (note != null)
                Text(
                  note,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: colors.textMuted),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCurrency(int amount, AppLocalizations l10n) {
    if (amount <= 0) return l10n.socialCreateFeeNone;
    // NumberFormat.currency chuẩn hoá theo locale: vi_VN dùng "12.000 ₫",
    // còn en dùng "12,000 ₫" — bám theo convention sẵn có ở social_payment_tab.dart.
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final formatter = NumberFormat.currency(
      locale: localeName,
      symbol: '₫',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String _formatDateTimeDisplay(DateTime dt) {
    // Tên thứ lấy từ locale qua DateFormat thay vì bảng hardcode, đúng như
    // chat_screen.dart:241 — cùng một cách, không cần thêm 7 key vào ARB.
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final weekdayName = DateFormat('EEEE', localeName).format(dt);
    final timeStr = DateFormat('HH:mm', localeName).format(dt);
    final dateStr = DateFormat('dd/MM/yyyy', localeName).format(dt);
    return '$timeStr $weekdayName, $dateStr';
  }

  Future<void> _pickDateTime() async {
    final colors = context.colors;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: colors.bgCard,
              onSurface: colors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: colors.bgCard,
              onSurface: colors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null || !mounted) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _showDurationPicker() async {
    final hours = await SocialDurationSheet.show(context, _durationHours);
    if (hours != null && mounted) setState(() => _durationHours = hours);
  }

  Future<void> _showPriceInputDialog() async {
    final price = await SocialPriceDialog.show(context, _price);
    if (price != null && mounted) setState(() => _price = price);
  }

  Future<void> _showPrivacyPicker() async {
    final privacy = await SocialPrivacySheet.show(context, _privacy);
    if (privacy != null && mounted) setState(() => _privacy = privacy);
  }

  Future<void> _chooseLocation() async {
    final selected = await SocialLocationFlow.show(
      context,
      initialPlace: _selectedPlace,
    );
    if (selected != null && mounted) setState(() => _selectedPlace = selected);
  }

  /// Invalidate cache Social theo CLB để tab Hoạt động cập nhật ngay.
  /// [session] là kèo vừa tạo/sửa (lấy communityId thực tế từ server).
  void _invalidateClubSocialProviders(
    WidgetRef ref,
    SocialSessionModel session,
  ) {
    final attachedId = session.communityId ?? session.community?.id;
    final initialAttachedId = widget.initialSession?.communityId;
    final ids = <String>{
      if (widget.clubId.isNotEmpty) widget.clubId,
      if (attachedId != null && attachedId.isNotEmpty) attachedId,
      if (initialAttachedId != null && initialAttachedId.isNotEmpty)
        initialAttachedId,
    };
    for (final id in ids) {
      ref.invalidate(clubSocialSessionsQueryProvider(id));
      ref.invalidate(communitySocialSessionsQueryProvider(id));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final sport = _resolveSport(_activeSports(ref.read(categoriesProvider)));
    if (sport.slug.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final place = _selectedPlace;
    if (place == null || !place.canApply) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.socialPlaceRequired),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final user = ref.read(userProfileProvider).asData?.value;
    final customTitle = _titleController.text.trim();
    final resolvedTitle = customTitle.isNotEmpty
        ? customTitle
        : _getComputedDefaultTitle(sport.name);

    final notes = _notesController.text.trim().isNotEmpty
        ? _notesController.text.trim()
        : null;

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(socialSessionRepositoryProvider);

      if (widget.initialSession != null) {
        final sessionId = widget.initialSession!.id;
        final updateFields = <String, dynamic>{
          'sport': sport.slug,
          'title': resolvedTitle.length > 100
              ? resolvedTitle.substring(0, 100)
              : resolvedTitle,
          if (notes != null && notes.isNotEmpty) 'description': notes,
          'playFormat': _selectedFormat,
          'startAt': _selectedDateTime.toIso8601String(),
          'durationMinutes': (_durationHours * 60).round(),
          'venueName': place.name.trim(),
          'venueAddress': place.formattedAddress.trim(),
          if (place.hasPin) ...{
            'latitude': place.latitude,
            'longitude': place.longitude,
          },
          'maxSlots': _maxParticipants,
          'feePerSlot': _price,
          'levelRequirement': 'ALL',
          'visibility': _privacy == 'Nội bộ CLB' ? 'CLUB_ONLY' : 'PUBLIC',
          if (_isClubAttached && widget.clubId.isNotEmpty)
            'communityId': widget.clubId,
        };

        final updatedSession = await repo.update(sessionId, updateFields);

        ref.read(socialSessionsProvider.notifier).refresh();
        ref.read(socialSessionDetailProvider(sessionId).notifier).refresh();
        // Tab Hoạt động CLB dùng provider riêng theo communityId —
        // phải invalidate để kèo mới/sửa hiện ngay ở filter "Mở".
        _invalidateClubSocialProviders(ref, updatedSession);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.socialCreateUpdateSuccess(resolvedTitle)),
              backgroundColor: context.colors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop(updatedSession);
        }
      } else {
        final request = CreateSocialSessionRequest(
          sport: sport.slug,
          title: resolvedTitle.length > 100
              ? resolvedTitle.substring(0, 100)
              : resolvedTitle,
          description: notes,
          playFormat: _selectedFormat,
          startAt: _selectedDateTime,
          durationMinutes: (_durationHours * 60).round(),
          venueName: place.name.trim(),
          venueAddress: place.formattedAddress.trim(),
          latitude: place.hasPin ? place.latitude : null,
          longitude: place.hasPin ? place.longitude : null,
          maxSlots: _maxParticipants,
          feePerSlot: _price,
          levelRequirement: 'ALL',
          visibility: _privacy == 'Nội bộ CLB' ? 'CLUB_ONLY' : 'PUBLIC',
          contactPhone: user?.phoneNumber,
          communityId: _isClubAttached && widget.clubId.isNotEmpty
              ? widget.clubId
              : null,
        );

        final createdSession = await repo.create(request);

        ref.read(socialSessionsProvider.notifier).refresh();
        ref
            .read(socialFilterProvider.notifier)
            .setSelectedDate(_selectedDateTime);
        // Tab Hoạt động CLB dùng provider riêng theo communityId —
        // phải invalidate để kèo mới hiện ngay ở filter "Mở".
        _invalidateClubSocialProviders(ref, createdSession);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.socialCreateSuccess(resolvedTitle)),
              backgroundColor: context.colors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop(createdSession);
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final catalog = ref.watch(categoriesProvider);
    final activeSports = _activeSports(catalog);
    final sport = _resolveSport(activeSports);
    final canSubmit = sport.slug.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: colors.bgDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 8, bottom: 4),
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        _createUpdateTitle(l10n),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: widget.initialSession == null
                          ? Center(
                              child: Icon(
                                Icons.swap_horiz_rounded,
                                color: colors.textPrimary,
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.border),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── 1. SECTION CLB (Hình 1) ───
                      if (_isClubAttached) ...[
                        Text(
                          'CLB',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: colors.success.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.bgCard,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: colors.border),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: colors.success.withValues(
                                          alpha: 0.2,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.sports_tennis_rounded,
                                        color: colors.success,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        widget.clubName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                l10n.socialClubLinkedStatus(
                                  widget.clubName.trim(),
                                ),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.socialClubNoAutoInviteHint,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: colors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: InkWell(
                                  onTap: () {
                                    setState(() => _isClubAttached = false);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Text(
                                      l10n.socialClubUnlinkAction,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: colors.error,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ─── 2. SECTION MÔN THỂ THAO & THỂ THỨC ───
                      _buildSportSection(
                        context,
                        l10n: l10n,
                        catalog: catalog,
                        activeSports: activeSports,
                        sport: sport,
                      ),
                      const SizedBox(height: 12),

                      // Format Chips: Giao lưu, Đánh vòng tròn, Đánh đơn, Đánh đôi
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _formats.map((fmt) {
                          final isSelected = _selectedFormat == fmt;
                          return InkWell(
                            onTap: () {
                              setState(() => _selectedFormat = fmt);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: colors.bgCard,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : colors.border,
                                  width: isSelected ? 1.8 : 1,
                                ),
                              ),
                              child: Text(
                                fmt,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppTheme.primary
                                      : colors.textPrimary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: colors.border),
                      const SizedBox(height: 16),

                      // ─── 3. SECTION KÈO (Hình 2) ───
                      Text(
                        _detailsLabel(l10n),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: colors.textSecondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 12),

                      SocialSettingTile(
                        icon: Icons.calendar_month_outlined,
                        label: _formatDateTimeDisplay(_selectedDateTime),
                        onTap: _pickDateTime,
                      ),
                      const SizedBox(height: 10),

                      SocialSettingTile(
                        icon: Icons.access_time_rounded,
                        label:
                            '${_durationHours == _durationHours.toInt() ? _durationHours.toInt() : _durationHours} giờ',
                        onTap: _showDurationPicker,
                      ),
                      const SizedBox(height: 10),

                      SocialLocationRow(
                        place: _selectedPlace,
                        onTap: _chooseLocation,
                      ),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: colors.border),
                      const SizedBox(height: 16),

                      // ─── 4. CẤU HÌNH NGƯỜI CHƠI, QUYỀN RIÊNG TƯ, PHÍ (Hình 2) ───
                      SocialParticipantCounter(
                        initialValue: _maxParticipants,
                        onChanged: (value) => _maxParticipants = value,
                      ),
                      const SizedBox(height: 14),

                      SocialSettingTile(
                        icon: Icons.lock_outline_rounded,
                        label: l10n.socialCreatePrivacyLabel,
                        value: _privacyLabel(l10n),
                        verticalPadding: 6,
                        onTap: _showPrivacyPicker,
                      ),
                      const SizedBox(height: 14),

                      SocialSettingTile(
                        icon: Icons.local_offer_outlined,
                        label: _feeLabel(l10n),
                        value: _formatCurrency(_price, l10n),
                        valueColor: _price > 0 ? colors.success : null,
                        verticalPadding: 6,
                        onTap: _showPriceInputDialog,
                      ),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: colors.border),
                      const SizedBox(height: 16),

                      // ─── 5. SECTION TÊN KÈO & GHI CHÚ (Hình 3) ───
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _titleFieldLabel(l10n).toUpperCase(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: colors.textSecondary,
                              letterSpacing: 0.3,
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _titleController,
                            builder: (context, child) {
                              final length = _titleController.text.length;
                              return Text(
                                '$length/100',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: colors.textMuted,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _titleController,
                        maxLength: 100,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: _getComputedDefaultTitle(sport.name),
                          counterText: '',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Ghi chú
                      TextFormField(
                        controller: _notesController,
                        maxLines: 4,
                        minLines: 3,
                        style: TextStyle(
                          fontSize: 14.5,
                          color: colors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: l10n.socialCreateNotesHint,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Action Button
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  color: colors.bgCard,
                  border: Border(top: BorderSide(color: colors.border)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting || !canSubmit ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            _createUpdateTitle(l10n),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
