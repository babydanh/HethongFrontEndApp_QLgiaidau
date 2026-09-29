import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/vietnam_address_parser.dart';
import 'package:app_quanly_giaidau/core/widgets/sport_icon_widget.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/domain/entities/region.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/features/social/widgets/social_region_picker.dart';
import 'package:app_quanly_giaidau/providers/social_provider.dart';
import 'package:app_quanly_giaidau/providers/user_location_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/features/social/widgets/social_location_picker.dart';
import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/social_duration_sheet.dart';
import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/social_price_dialog.dart';
import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/social_privacy_sheet.dart';
import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/social_setting_tile.dart';
import 'package:app_quanly_giaidau/features/social/widgets/participant_tab/social_participant_counter.dart';

/// Ngừng gõ bao lâu thì ghim tạm theo tâm phường.
const Duration _autoPlaceDelay = Duration(milliseconds: 600);

/// Ngừng gõ bao lâu thì tự điền khu vực từ địa chỉ.
const Duration _autoRegionDelay = Duration(milliseconds: 600);

/// Cổng bật/tắt cho hai đường đi qua dữ liệu hình học GeoJSON/PostGIS.
///
/// Trước đây cổng này tắt vì server chưa bao giờ có tâm phường: ảnh Docker
/// không nạp cây GeoJSON ~630 MB nên `wards.center_lat/center_lng` toàn NULL và
/// cả hai endpoint trả rỗng cho mọi điểm. Nay tâm phường nằm trong file
/// `seed/ward-centroids.tsv` (~250 KB) được commit cùng ảnh, nên đường dữ liệu
/// không còn phụ thuộc import ranh giới:
///
///  * `GET /regions/wards/centroid` — tỉnh + phường → ghim tạm theo tâm.
///  * `GET /regions/resolve` — điểm host vừa ghim tay → tỉnh/phường. Chỉ tự
///    điền hai ô khu vực khi server trả `isEstimated: false` (phường thật sự
///    chứa điểm); khớp bằng tâm gần nhất là ước lượng nên để host tự chọn.
///
/// Tắt thì app không gọi mạng cho hai việc đó: tỉnh/phường lấp từ danh mục
/// theo tên trong ô địa chỉ (tự điền) hoặc từ hai ô khu vực host tự chọn;
/// toạ độ thì chỉ có khi host tự ghim map. Thẻ "Vị trí" vẫn hiện đúng trạng
/// thái thật: chưa ghim thì hiện nút "Ghim vị trí sân".
///
/// Đã kiểm trên DB dev: `/regions/resolve` trả đúng Phường Phú Lâm (HCMC) và
/// Phường Ô Chợ Dừa (Hà Nội), `/regions/wards/centroid` trả tâm cho mã phường
/// hợp lệ và null cho mã không có. Điểm ở nước khác trả null chứ không bị gán
/// bừa phường Việt Nam.
const bool _kGeometryLookupEnabled = true;

/// Định danh thẻ vị trí: thẻ tự hiển thị tóm tắt khu vực đã áp dụng, nên có
/// định danh để test kiểm tra đúng chỗ đó thay vì dò chuỗi trên cả form.
const Key _venueLocationCardKey = ValueKey('venue-location-card');

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
  // Khu vực đã áp dụng (tuỳ chọn): chỉ ghép vào venueAddress lúc lưu.
  SocialRegionSelection? _appliedRegion;

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

  // Venue / Location (Tách 2 trường theo Yêu cầu 5)
  final TextEditingController _venueNameController = TextEditingController();
  final TextEditingController _venueAddressController = TextEditingController();

  /// Tọa độ sân do host ghim map (null = chưa ghim).
  double? _latitude;
  double? _longitude;

  /// Pin do hệ thống suy ra từ tâm phường (false = host tự ghim tay).
  /// UI đọc cờ này để phân biệt hai nguồn ghim.
  bool _pinAutoPlaced = false;

  /// Địa chỉ gõ lần cuối đã lên lịch ghim tự động — chống lên lịch lại
  /// vô ích mỗi lần form rebuild với cùng một nội dung ô địa chỉ.
  String? _autoPlaceScheduledFor;

  /// Hẹn giờ debounce trước khi gọi tâm phường.
  Timer? _autoPlaceDebounce;

  /// Địa chỉ gõ lần cuối đã lên lịch tự điền khu vực — chống lên lịch lại
  /// vô ích mỗi lần form rebuild với cùng nội dung ô địa chỉ.
  String? _autoRegionScheduledFor;

  /// Hẹn giờ debounce trước khi tự điền khu vực.
  Timer? _autoRegionDebounce;

  /// Host đã tự chọn khu vực (hai trường khu vực hoặc ghim map): tự điền chỉ
  /// lấp chỗ trống, nên cờ này tắt hẳn đường tự động cho tới hết buổi tạo kèo.
  bool _regionChosenByHost = false;

  /// Danh mục tỉnh + phường phục vụ tự điền và hai trường khu vực: nạp một
  /// lần rồi dùng lại cho cả hai. Giữ future để các lần gọi chồng nhau dùng
  /// chung một lần nạp; lần lỡ mạng thì bỏ cache để lần sau thử lại.
  Future<SocialRegionCatalogue?>? _regionCatalogue;

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
      _venueNameController.text = init.venueName;
      _venueAddressController.text = init.venueAddress;
      _latitude = init.latitude;
      _longitude = init.longitude;
      _titleController.text = init.title;
      _notesController.text = init.description ?? '';
      // Sửa kèo: địa chỉ nạp sẵn không đi qua onChanged nên không có lần
      // hẹn nào cả — trước đây builder gọi hẹn mỗi lần form dựng lại. Hẹn ở
      // đây (ngoài build) để giữ nguyên đường tự điền khi mở kèo cũ.
      final prefilledAddress = _venueAddressController.text.trim();
      if (prefilledAddress.isNotEmpty) {
        _scheduleAutoPlaceForAddress(prefilledAddress);
        _scheduleAutoRegionForAddress(prefilledAddress);
      }
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
    _autoPlaceDebounce?.cancel();
    _autoRegionDebounce?.cancel();
    _venueNameController.dispose();
    _venueAddressController.dispose();
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

  /// Ghép khu vực đã áp dụng vào địa chỉ gõ tay, bỏ qua nhãn đã có sẵn.
  String _composeVenueAddress() {
    var composed = _venueAddressController.text.trim();
    final region = _appliedRegion;
    if (region == null) return composed;
    final province = region.province;
    final provinceAlreadyNamed =
        province != null &&
        VietnamAddressParser.detectProvince(
              rawAddress: composed,
              provinces: [province],
              getCode: (item) => item.code,
              getName: (item) => item.name,
              getFullName: (item) => item.fullName ?? item.name,
            ) !=
            null;
    for (final name in [
      region.ward?.name,
      if (!provinceAlreadyNamed) province?.name,
    ]) {
      final label = name?.trim() ?? '';
      if (label.isEmpty || composed.isEmpty) continue;
      final parts = composed
          .split(',')
          .map((part) => part.trim().toLowerCase());
      if (parts.contains(label.toLowerCase())) continue;
      composed = '$composed, $label';
    }
    return composed;
  }

  /// Tỉnh của CLB gắn kèm: chỉ làm ngữ cảnh dự phòng cho phần khu vực khi
  /// địa chỉ gõ tay không nêu thành phố. Kèo độc lập hoặc CLB không có tỉnh
  /// thì không có ngữ cảnh nào — phần khu vực tự tìm tay.
  ///
  /// Chờ future thay vì đọc đồng bộ: phần tự điền thường là nơi đầu tiên đọc
  /// provider này, mà `ref.watch` ngay lần đầu chỉ trả về "đang tải" — đọc
  /// kiểu đó âm thầm mất luôn tỉnh của CLB rồi không thử lại nữa. CLB không
  /// tải được cũng chỉ mất ngữ cảnh dự phòng, không được làm hỏng cả kèo.
  Future<String?> _clubProvinceCode() async {
    if (!_isClubAttached || widget.clubId.isEmpty) return null;
    try {
      final community = await ref.read(
        communityDetailProvider(widget.clubId).future,
      );
      final code = community?.provinceCode?.trim();
      return (code == null || code.isEmpty) ? null : code;
    } catch (_) {
      return null;
    }
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

  /// Lên lịch ghim tự động, chỉ khi nội dung ô địa chỉ thực sự đổi.
  /// Ô địa chỉ đổi thì lựa chọn khu vực cũ bị bỏ, nên phải chờ ngừng gõ.
  void _scheduleAutoPlaceForAddress(String address) {
    if (_autoPlaceScheduledFor == address) return;
    _autoPlaceScheduledFor = address;
    _restartAutoPlaceDebounce();
  }

  /// Huỷ lần hẹn trước và hẹn lại sau [debounce].
  void _restartAutoPlaceDebounce([Duration debounce = _autoPlaceDelay]) {
    _autoPlaceDebounce?.cancel();
    _autoPlaceDebounce = Timer(debounce, () {
      // Xoá cờ "đã hẹn" ngay lúc hẹn nổ, chứ không phải trước khi hẹn: lần
      // chạy này có thể hỏng (mất mạng, danh mục rỗng, host đã tự chọn khu
      // vực...) và nếu giữ cờ thì mọi lần hẹn sau với đúng nội dung địa chỉ
      // đó đều dừng ở guard, ghim tạm chết âm thầm tới khi host gõ thêm một
      // ký tự. Xoá trước thì hẹn kế tiếp không còn chờ đợi thay đổi nào nữa.
      _autoPlaceScheduledFor = null;
      unawaited(_autoPlacePinFromWard());
    });
  }

  /// Một chỗ duy nhất để đổi khu vực đã áp dụng. Chốt đủ tỉnh + phường thì
  /// hẹn ghim tạm theo tâm phường, khỏi phải chờ gõ thêm.
  void _applyRegion(SocialRegionSelection selection, {required bool byHost}) {
    setState(() {
      _appliedRegion = selection;
      if (byHost) _regionChosenByHost = true;
    });
    if (selection.province != null && selection.ward != null) {
      _restartAutoPlaceDebounce();
    }
  }

  /// Lên lịch tự điền khu vực, chỉ khi nội dung ô địa chỉ thực sự đổi:
  /// mỗi lần ngừng gõ mới nhận diện một lần, không bám từng phím.
  void _scheduleAutoRegionForAddress(String address) {
    if (_autoRegionScheduledFor == address) return;
    _autoRegionScheduledFor = address;
    _autoRegionDebounce?.cancel();
    _autoRegionDebounce = Timer(_autoRegionDelay, () {
      // Xoá cờ "đã hẹn" ngay lúc hẹn nổ, lý do như _restartAutoPlaceDebounce:
      // một lần tự điền hỏng (mất mạng lúc nạp danh mục, host đã tự chọn khu
      // vực) không được biến thành tự điền chết vĩnh viễn với nội dung địa
      // chỉ đó.
      _autoRegionScheduledFor = null;
      unawaited(_autoFillRegionFromAddress());
    });
  }

  /// Tự điền khu vực từ địa chỉ gõ tay, host không phải bấm gì.
  ///
  /// Nhận diện được tỉnh thì chốt tỉnh; nhận diện thêm phường và tên phường
  /// là duy nhất trong tỉnh đó thì chốt cả hai. Không nhận diện được gì thì
  /// để trống chứ không đoán — khu vực chỉ là tuỳ chọn, suy ra sai còn tệ
  /// hơn để host tự chọn.
  Future<void> _autoFillRegionFromAddress() async {
    if (!mounted || _regionChosenByHost) return;
    final address = _venueAddressController.text.trim();
    if (address.isEmpty) return;
    final applied = _appliedRegion;
    if (applied != null && !applied.isEmpty) return;

    final catalogue = await _regionCatalogueFor();
    // Nạp danh mục xong mà host đã tự chọn khu vực hoặc vừa gõ tiếp thì
    // để host làm chủ: đừng đè lên lựa chọn đó.
    if (catalogue == null ||
        !mounted ||
        _regionChosenByHost ||
        _venueAddressController.text.trim() != address) {
      return;
    }
    final current = _appliedRegion;
    if (current != null && !current.isEmpty) return;

    final detected = await _detectProvinceIn(address, catalogue);
    if (detected == null) return;

    final scope = catalogue.wards
        .where((ward) => ward.provinceCode == detected.code)
        .toList(growable: false);
    final ward = scope.isEmpty
        ? null
        : VietnamAddressParser.detectWard<Region>(
            rawAddress: address,
            wards: scope,
            getCode: (region) => region.code,
            // Parser tự bỏ tiền tố loại, nên "Bãy Hiến" cũng khớp "Phường Bãy Hiến".
            getName: (region) => region.name,
            getFullName: (region) => region.fullName ?? region.name,
          );
    _applyRegion(
      SocialRegionSelection(
        province: detected,
        // Trùng tên trong cùng tỉnh thì địa chỉ không đủ tin: chỉ chốt tỉnh.
        ward: ward != null && _isUniquelyNamed(ward, scope) ? ward : null,
      ),
      byHost: false,
    );
  }

  /// Tỉnh mà địa chỉ đang nêu. Địa chỉ không nêu thành phố thì mượn tỉnh của
  /// CLB gắn kèp làm ngữ cảnh dự phòng — cùng cách đã dùng để gợi ý, nay
  /// áp thẳng vào hai trường nên host không phải bấm "Áp dụng". Tỉnh của CLB
  /// chỉ làm phạm vi tìm phường: phường không nằm trong tỉnh đó thì không
  /// chốt gì, chứ không đoán.
  Future<Region?> _detectProvinceIn(
    String address,
    SocialRegionCatalogue catalogue,
  ) async {
    final detected = VietnamAddressParser.detectProvince<Region>(
      rawAddress: address,
      provinces: catalogue.provinces,
      getCode: (region) => region.code,
      getName: (region) => region.name,
      getFullName: (region) => region.fullName ?? region.name,
    );
    if (detected != null) return detected;
    final contextCode = await _clubProvinceCode() ?? '';
    if (contextCode.isEmpty) return null;
    for (final province in catalogue.provinces) {
      if (province.code == contextCode) return province;
    }
    return null;
  }

  /// Danh mục tỉnh + phường cho tự điền và hai trường khu vực, nạp một lần
  /// rồi dùng lại. `null` = mất mạng: tự điền là tiện ích nên im lặng bỏ qua
  /// và thử lại ở lần ngừng gõ sau, tuyệt đối không báo lỗi lên form. Danh
  /// mục rỗng không cache, để lần sau vẫn thử lại được.
  Future<SocialRegionCatalogue?> _regionCatalogueFor({
    bool refresh = false,
  }) async {
    if (refresh) _regionCatalogue = null;
    final pending = _regionCatalogue ??= _fetchRegionCatalogue();
    final catalogue = await pending;
    if (catalogue == null || catalogue.provinces.isEmpty) {
      _regionCatalogue = null;
    }
    return catalogue;
  }

  Future<SocialRegionCatalogue?> _fetchRegionCatalogue() async {
    final repository = ref.read(regionRepositoryProvider);
    final List<Region> provinces;
    try {
      provinces = await repository.getProvinces();
    } catch (_) {
      return null;
    }
    // Server trả rỗng vẫn là một câu trả lời: trả về danh mục rỗng để hai
    // trường báo "chưa dùng được" thay vì báo nhầm thành lỗi mạng.
    // Mã tỉnh rỗng là lấy toàn bộ phường, giống hệt danh mục hai trường khu
    // vực dùng. Thiếu phường vẫn chốt được tỉnh nên lỗi phường không loại cả
    // danh mục.
    List<Region> wards = const [];
    try {
      wards = await repository.getWardsByProvince('');
    } catch (_) {
      // Bỏ trống: chỉ chốt được tỉnh.
    }
    return (provinces: provinces, wards: wards);
  }

  /// Trùng tên phường trong cùng tỉnh thì địa chỉ không đủ tin để chọn —
  /// cùng cách danh sách phường loại tên mơ hồ, chỉ chốt tỉnh.
  bool _isUniquelyNamed(Region ward, List<Region> scope) {
    final key = VietnamAddressParser.localityName(ward.name);
    return scope
            .where(
              (item) => VietnamAddressParser.localityName(item.name) == key,
            )
            .length ==
        1;
  }

  /// Tâm phường — GET /regions/wards/centroid. Trả null khi server không
  /// tìm thấy hoặc lỗi mạng: ghim tạm là tiện ích, không được chặn lưu kèo.
  Future<({double lat, double lng})?> _fetchWardCentroid({
    required String provinceCode,
    required String wardCode,
  }) async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get(
        '/regions/wards/centroid',
        queryParameters: {'provinceCode': provinceCode, 'wardCode': wardCode},
      );
      final raw = response.data;
      final payload = raw is Map ? (raw['data'] ?? raw) : null;
      if (payload is! Map) return null;
      final lat = (payload['centerLat'] as num?)?.toDouble();
      final lng = (payload['centerLng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      return (lat: lat, lng: lng);
    } catch (_) {
      return null;
    }
  }

  /// Ghim tạm theo tâm phường khi host đã chọn đủ tỉnh + phường và chưa ghim tay.
  /// Thiếu phường thì bỏ qua: tâm tỉnh lệch tới hàng chục km ở tỉnh lớn.
  Future<void> _autoPlacePinFromWard() async {
    // Tâm phường lấy từ dữ liệu hình học. Cổng tắt thì hẹn giờ vẫn nổ — để
    // cờ được xoá đúng lúc — nhưng không gọi mạng.
    if (!_kGeometryLookupEnabled) return;
    final selection = _appliedRegion;
    final province = selection?.province;
    final ward = selection?.ward;
    if (province == null || ward == null) return;
    if (province.code.isEmpty || ward.code.isEmpty) return;
    if (_latitude != null || _longitude != null) return;

    final centroid = await _fetchWardCentroid(
      provinceCode: province.code,
      wardCode: ward.code,
    );
    if (centroid == null || !mounted) return;
    // Chờ xong mà host vừa kéo ghim tay thì giữ pin của host.
    if (_latitude != null || _longitude != null) return;
    setState(() {
      _latitude = centroid.lat;
      _longitude = centroid.lng;
      _pinAutoPlaced = true;
    });
  }

  /// Pin có toạ độ nhưng chưa có khu vực đi kèm. Ghim tay xong mà tra
  /// ngược hỏng (mất mạng, server lỗi, điểm nằm ngoài vùng có ranh giới)
  /// đều rơi vào đây: thẻ vị trí vẫn hiện "đã ghim" trong khi hai ô khu
  /// vực vẫn trống, nên form phải nói ra chứ không được im lặng. Một chỗ
  /// duy nhất quyết định "hai phần này có khớp nhau không", thay vì rải
  /// điều kiện ở từng chỗ nên lệch nhau.
  ///
  /// Khi cổng hình học đang tắt thì "ghim tay + chưa có khu vực" là trạng
  /// thái bình thường, vì khu vực lấp từ địa chỉ chứ không lấp từ pin. Cảnh
  /// báo phải tắt theo: bật lên chỉ để mời host bấm "Tra lại", tức một nút
  /// không bao giờ có kết quả.
  bool get _pinWithoutRegion =>
      _kGeometryLookupEnabled &&
      _latitude != null &&
      _longitude != null &&
      (_appliedRegion == null || _appliedRegion!.isEmpty);

  /// Tra lại khu vực cho điểm đang ghim. Lần tra đầu có thể hỏng vì mất
  /// mạng lúc host đang ghim, nên cho host bấm lại thay vì phải mở bản đồ
  /// dò lại từ đầu. Pin của host giữ nguyên — chỉ khu vực được điền thêm.
  Future<void> _retryRegionForPin() {
    final lat = _latitude;
    final lng = _longitude;
    if (lat == null || lng == null) return Future<void>.value();
    return _applyReverseLookup(LatLng(lat, lng));
  }

  /// Mở bản đồ cho host ghim vị trí sân. Tâm map ưu tiên:
  /// tọa độ cũ (sửa kèo) → vị trí user → fallback TP.HCM.
  Future<void> _openLocationPicker() async {
    final userLoc = ref.read(userLocationProvider);
    final LatLng center;
    if (_latitude != null && _longitude != null) {
      center = LatLng(_latitude!, _longitude!);
    } else if (userLoc.hasPosition) {
      center = LatLng(userLoc.latitude!, userLoc.longitude!);
    } else {
      center = const LatLng(10.7769, 106.7009);
    }
    final picked = await SocialLocationPicker.show(
      context,
      initialCenter: center,
      initialPin: (_latitude != null && _longitude != null)
          ? LatLng(_latitude!, _longitude!)
          : null,
    );
    if (picked != null && mounted) {
      setState(() {
        _latitude = picked.latitude;
        _longitude = picked.longitude;
        // Host tự ghim tay: không phải tọa độ suy ra từ tâm phường.
        _pinAutoPlaced = false;
      });
      await _applyReverseLookup(picked);
    }
  }

  /// Suy ngược điểm host vừa ghim thành tỉnh/phường rồi điền ngược vào form.
  ///
  /// Best-effort: mất mạng, server lỗi, điểm nằm ngoài vùng phủ ranh giới hay
  /// body thiếu trường đều chỉ báo lại chứ không bao giờ chặn lưu kèo.
  Future<void> _applyReverseLookup(LatLng point) async {
    // Tra ngược cần ranh giới phường trên server. Cổng tắt thì ghim tay của
    // host vẫn lưu bình thường, chỉ là không lấp thêm tỉnh/phường từ điểm.
    if (!_kGeometryLookupEnabled) return;
    Map<String, dynamic>? body;
    var callFailed = false;
    try {
      final response = await ref
          .read(dioProvider)
          .get(
            '/regions/resolve',
            queryParameters: {'lat': point.latitude, 'lng': point.longitude},
          );
      final raw = response.data;
      final payload = raw is Map ? (raw['data'] ?? raw) : null;
      if (payload is Map) body = Map<String, dynamic>.from(payload);
    } catch (_) {
      callFailed = true;
    }
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    if (callFailed) {
      _showLocationMessage(l10n.socialLocationReverseFailed);
      return;
    }
    // `isEstimated` = phường server tìm bằng KHOẢNG CÁCH tới tâm gần nhất,
    // không phải phường chứa điểm. Không được điền vào hai ô khu vực: ghim
    // tự đặt nằm đúng ở tâm phường nên tra ngược sẽ khớp thẳng về lại chính
    // phường đó, tức là điền phỏng đoán của chính hệ thống vào chỗ của host;
    // ở khu vực đông (phường HCM cách nhau ~500 m) ghim sát ranh giới còn
    // khớp nhầm sang phường kế bên. Hai ô để trống thì thẻ vị trí đã tự báo
    // "Chưa nhận ra tỉnh/phường" và mời host chọn tay — đó mới là câu trả lời
    // trung thực. Chỉ `isEstimated: false` mới được điền: đáp án thiếu cờ là
    // của server cũ, lúc đó ta không chứng minh được phường chứa điểm.
    if (body?['isEstimated'] != false) return;
    final wardCode = body?['wardCode']?.toString() ?? '';
    final wardName = body?['wardName']?.toString() ?? '';
    final provinceCode = body?['provinceCode']?.toString() ?? '';
    final provinceName = body?['provinceName']?.toString() ?? '';
    if (wardCode.isEmpty ||
        wardName.isEmpty ||
        provinceCode.isEmpty ||
        provinceName.isEmpty) {
      _showLocationMessage(l10n.socialLocationNoAddressFound);
      return;
    }
    // centerLat/centerLng là tâm của phường, không phải tâm tỉnh.
    final selection = SocialRegionSelection(
      province: Region(code: provinceCode, name: provinceName),
      ward: Region(
        code: wardCode,
        name: wardName,
        provinceCode: provinceCode,
        latitude: (body?['centerLat'] as num?)?.toDouble(),
        longitude: (body?['centerLng'] as num?)?.toDouble(),
      ),
    );
    setState(() {
      // Host chủ động ghim map: đây là lựa chọn của host, tự điền từ địa
      // chỉ không được đè lên.
      _appliedRegion = selection;
      _regionChosenByHost = true;
      // Chỉ điền khi host chưa gõ: tuyệt đối không xoá địa chỉ đã gõ tay.
      if (_venueAddressController.text.trim().isEmpty) {
        _venueAddressController.text = selection.summary(l10n);
      }
    });
  }

  void _showLocationMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
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
    final venueNameText = _venueNameController.text.trim();
    final venueAddressText = _venueAddressController.text.trim();
    final l10n = AppLocalizations.of(context)!;
    if (venueNameText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.socialCreateVenueNameDialogTitle),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (venueAddressText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.socialCreateLocationDialogTitle),
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
          'venueName': venueNameText,
          'venueAddress': _composeVenueAddress(),
          // Tọa độ ghim (null = xóa vị trí đã ghim).
          'latitude': _latitude,
          'longitude': _longitude,
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
          venueName: venueNameText,
          venueAddress: _composeVenueAddress(),
          latitude: _latitude,
          longitude: _longitude,
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

                      // Tách venueName và venueAddress thành 2 input field (Yêu cầu 5)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Icon(
                              Icons.location_on_outlined,
                              color: AppTheme.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _venueNameController,
                                  maxLength: 100,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: l10n.socialCreateVenueNameLabel,
                                    hintText: l10n.socialCreateVenueNameHint,
                                    counterText: '',
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return l10n.socialCreateVenueNameRequired;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _venueAddressController,
                                  onChanged: (value) {
                                    // Ghim do form suy ra từ tâm phường cũ
                                    // thì trỏ vào địa chỉ cũ, nên địa chỉ đổi là
                                    // bỏ, khỏi chỉ vào một chỗ không còn đúng.
                                    // Ghim tay của host thì giữ nguyên: host
                                    // sửa lỗi chính tả trong địa chỉ không có
                                    // nghĩa là muốn mất điểm mình vừa chọn,
                                    // muốn bỏ thì bấm "×" ngay trên thẻ vị trí.
                                    final dropPin = _pinAutoPlaced;
                                    // Địa chỉ đổi thì lựa chọn khu vực do
                                    // form tự nhận diện cũ không còn đúng nên
                                    // bỏ, khỏi ghép nhầm vào địa chỉ lúc lưu.
                                    // Lựa chọn của host thì giữ nguyên: host
                                    // sửa lại địa chỉ không có nghĩa là host
                                    // đổi ý về khu vực, mà đổi ý thì bấm
                                    // vào chính ô khu vực để chọn lại.
                                    final dropRegion =
                                        _appliedRegion != null &&
                                        !_regionChosenByHost;
                                    if (dropPin || dropRegion) {
                                      setState(() {
                                        if (dropPin) {
                                          _latitude = null;
                                          _longitude = null;
                                          _pinAutoPlaced = false;
                                        }
                                        if (dropRegion) _appliedRegion = null;
                                      });
                                    }
                                    // Hẹn giờ là tác dụng phụ nên thuộc về
                                    // onChanged chứ không thuộc build: người gõ,
                                    // không phải lần dựng widget, mới là người
                                    // quyết định khi nào đã ngừng gõ. Địa chỉ
                                    // nạp sẵn khi sửa kèo không đi qua onChanged
                                    // nên initState tự hẹn một lần cho đúng.
                                    // Ngừng gõ 600ms rồi mới ghim tạm theo tâm
                                    // phường: không cần mở map, và không bao giờ
                                    // ghi đè pin host đã tự ghim tay.
                                    _scheduleAutoPlaceForAddress(value);
                                    // Ngừng gõ 600ms thì tự điền khu vực từ
                                    // địa chỉ, host khỏi phải bấm gì cả.
                                    _scheduleAutoRegionForAddress(value);
                                  },
                                  maxLength: 500,
                                  maxLines: 2,
                                  minLines: 1,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w400,
                                    color: colors.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: l10n.socialCreateLocationLabel,
                                    hintText: l10n.socialCreateLocationHint,
                                    counterText: '',
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return l10n.socialCreateLocationRequired;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                // Khu vực tuỳ chọn hiện sẵn hai trường "Tỉnh /
                                // thành" + "Phường / xã": tự điền từ địa chỉ
                                // gõ tay vào thẳng hai trường, host sửa tay
                                // được bất cứ lúc nào. Khi địa chỉ đổi, bỏ lựa
                                // chọn cũ để không ghép nhầm phường/tỉnh vào
                                // venueAddress lúc lưu.
                                ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: _venueAddressController,
                                  // Builder chỉ dựng lại, không hẹn giờ: hẹn
                                  // giờ trong build là tác dụng phụ và làm
                                  // hành vi tuỳ vào lúc nào form dựng lại.
                                  builder: (context, address, _) {
                                    return SocialRegionInlineFields(
                                      applied: _appliedRegion,
                                      onSelect: (selection) =>
                                          _applyRegion(selection, byHost: true),
                                      loadCatalogue: _regionCatalogueFor,
                                    );
                                  },
                                ),
                                const SizedBox(height: 10),
                                // Thẻ "Vị trí" chỉ còn trạng thái ghim (chưa
                                // ghim / tay / tự động). Địa chỉ nằm ngay ở ô
                                // phía trên, khu vực nằm ở hai ô khu vực, nên
                                _VenueLocationCard(
                                  key: _venueLocationCardKey,
                                  latitude: _latitude,
                                  longitude: _longitude,
                                  autoPlaced: _pinAutoPlaced,
                                  // Pin mà không có khu vực là trạng thái lệch
                                  // nhau, nên thẻ phải nói ra chứ không để hai
                                  // ô khu vực trống dưới một thẻ "đã ghim".
                                  regionMissing: _pinWithoutRegion,
                                  onRetryRegion: _retryRegionForPin,
                                  onPick: _openLocationPicker,
                                  onClear: () => setState(() {
                                    _latitude = null;
                                    _longitude = null;
                                    _pinAutoPlaced = false;
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                          labelText: _titleFieldLabel(l10n),
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

/// Trạng thái ghim của thẻ vị trí. Màu KHÔNG đủ để phân biệt: mỗi trạng
/// thái luôn đi kèm nhãn chữ riêng (xem [_VenueLocationCard._stateLabel]).
enum _VenuePinState { unpinned, manual, auto }

/// Thẻ "Vị trí" duy nhất của form: chỉ trạng thái ghim (chưa ghim / host ghim
/// tay / suy ra tự động) với tọa độ, kèm nút mở bản đồ để ghim lại cho
/// chính xác hơn và nút "×" để gỡ.
///
/// Thẻ không lặp lại địa chỉ lẫn khu vực: ô "Địa điểm" ngay phía trên và hai
/// ô khu vực bên dưới nó đã hiện sẵn, host đọc một chỗ duy nhất mà không
/// phải so hai nơi có khớp nhau hay không.
class _VenueLocationCard extends StatelessWidget {
  final double? latitude;
  final double? longitude;

  /// Tọa độ do tâm phường suy ra, chưa phải ghim tay của host.
  final bool autoPlaced;
  final VoidCallback onPick;
  final VoidCallback onClear;

  /// Có toạ độ nhưng chưa có tỉnh/phường đi kèm. Trạng thái lệch nhau: thẻ
  /// không được hiện như đã xong khi hai ô khu vực phía trên vẫn trống.
  final bool regionMissing;

  /// Tra lại khu vực cho chính điểm đang ghim — đường sửa lại khi lần tra
  /// ngược đầu hỏng, thay vì bắt host mở bản đồ dò lại từ đầu.
  final VoidCallback onRetryRegion;

  const _VenueLocationCard({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.autoPlaced,
    required this.onPick,
    required this.onClear,
    required this.regionMissing,
    required this.onRetryRegion,
  });

  bool get _hasPin => latitude != null && longitude != null;

  _VenuePinState get _state {
    if (!_hasPin) return _VenuePinState.unpinned;
    return autoPlaced ? _VenuePinState.auto : _VenuePinState.manual;
  }

  /// Nhãn chữ của trạng thái — bắt buộc khác nhau, không dựa màu một mình.
  String _stateLabel(AppLocalizations l10n) {
    return switch (_state) {
      _VenuePinState.unpinned => l10n.socialLocationPinAction,
      _VenuePinState.manual => l10n.socialLocationPinDone,
      _VenuePinState.auto => l10n.socialLocationAutoPlaced,
    };
  }

  IconData _stateIcon() {
    return switch (_state) {
      _VenuePinState.unpinned => Icons.map_outlined,
      _VenuePinState.manual => Icons.location_on_rounded,
      _VenuePinState.auto => Icons.gps_fixed_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final state = _state;
    final hasPin = state != _VenuePinState.unpinned;
    final accent = switch (state) {
      _VenuePinState.unpinned => colors.border,
      _VenuePinState.manual => colors.success,
      _VenuePinState.auto => colors.warning,
    };

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: hasPin ? accent.withValues(alpha: 0.10) : colors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasPin ? accent.withValues(alpha: 0.45) : accent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _stateIcon(),
                  color: hasPin ? accent : AppTheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _stateLabel(l10n),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasPin
                            ? '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}'
                            : l10n.socialLocationPinHint,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasPin)
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      tooltip: l10n.socialLocationPinClear,
                      icon: Icon(
                        Icons.close_rounded,
                        color: colors.textMuted,
                        size: 20,
                      ),
                      onPressed: onClear,
                    ),
                  )
                else
                  Icon(Icons.chevron_right_rounded, color: colors.textMuted),
              ],
            ),
            if (hasPin && regionMissing) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                decoration: BoxDecoration(
                  color: colors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colors.warning.withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.help_outline_rounded,
                      color: colors.warning,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.socialLocationRegionMissing,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: colors.textPrimary,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: onRetryRegion,
                      style: TextButton.styleFrom(
                        foregroundColor: colors.warning,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        l10n.socialLocationRegionRetry,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (hasPin) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: onPick,
                  icon: const Icon(Icons.edit_location_alt_rounded, size: 18),
                  label: Text(
                    l10n.socialLocationEditPin,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accent,
                    side: BorderSide(color: accent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
