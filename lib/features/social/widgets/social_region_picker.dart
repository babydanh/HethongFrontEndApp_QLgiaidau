import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/vietnam_address_parser.dart';
import 'package:app_quanly_giaidau/domain/entities/region.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Khu vực đã áp dụng cho buổi: phường/xã trước, tỉnh/thành được suy ra.
///
/// Chỉ giữ tên hiển thị — không lưu mã địa phương vào payload.
class SocialRegionSelection {
  const SocialRegionSelection({this.province, this.ward});

  final Region? province;
  final Region? ward;

  bool get isEmpty => province == null && ward == null;

  /// Tóm tắt hiển thị: "Phường/Xã, Tỉnh/Thành phố".
  String summary(AppLocalizations l10n) {
    final provinceName = province?.name.trim() ?? '';
    final wardName = ward?.name.trim() ?? '';
    if (provinceName.isEmpty) return wardName;
    if (wardName.isEmpty) return provinceName;
    return l10n.socialRegionSelectedSummary(wardName, provinceName);
  }
}

/// Danh mục tỉnh + phường nạp một lần cho cả form: tự điền từ địa chỉ và hai
/// trường khu vực dùng chung, nên host không tải trùng. `null` = mất mạng hoặc
/// danh mục rỗng — khu vực tuỳ chọn nên chỉ mất tiện ích, địa chỉ vẫn gõ tay.
typedef SocialRegionCatalogue = ({List<Region> provinces, List<Region> wards});

/// Hai trường "Tỉnh / thành" và "Phường / xã" hiện sẵn trên form, đúng hình
/// dạng màn "Tạo giải nhanh": host thấy ngay khu vực đang chọn và sửa tay bất
/// cứ lúc nào, không phải mở popup mới thấy được. Phần tự điền từ địa chỉ gõ
/// tay và phần tra ngược từ ghim map cùng đổ vào đúng hai trường này, nên
/// host không bấm "Áp dụng" ở đâu cả.
///
/// Bấm trường mới mở danh sách để sửa tay: chọn xong là áp dụng luôn, đóng
/// sheet mà không chọn gì thì giữ nguyên lựa chọn đang có.
class SocialRegionInlineFields extends StatefulWidget {
  const SocialRegionInlineFields({
    super.key,
    required this.applied,
    required this.onSelect,
    required this.loadCatalogue,
  });

  /// Lựa chọn đang áp dụng — nguồn duy nhất cho cả hai trường.
  final SocialRegionSelection? applied;

  /// Host chọn tay: chọn ở trường nào chỉ thay đúng nửa đó. Chọn tỉnh thì bỏ
  /// phường cũ, chọn phường thì giữ tỉnh đang có.
  final ValueChanged<SocialRegionSelection> onSelect;

  /// Danh mục tỉnh + phường; `refresh` ép nạp lại khi host bấm "Thử lại".
  final Future<SocialRegionCatalogue?> Function({bool refresh}) loadCatalogue;

  @override
  State<SocialRegionInlineFields> createState() =>
      _SocialRegionInlineFieldsState();
}

class _SocialRegionInlineFieldsState extends State<SocialRegionInlineFields> {
  /// Mở danh sách tỉnh hoặc phường để host sửa tay. Chọn xong là áp dụng luôn,
  /// không có bước "Áp dụng" nữa; đóng sheet mà không chọn gì thì giữ nguyên
  /// lựa chọn đang có.
  Future<void> _openList(BuildContext context, {required bool isWard}) async {
    final province = widget.applied?.province;
    // Phường chỉ có nghĩa trong một tỉnh: chưa chọn tỉnh thì trường phường đã
    // khoá, không mở danh sách phường của cả nước.
    if (isWard && province == null) return;

    final picked = await showModalBottomSheet<Region>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.colors.bgDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.86,
        child: _SocialRegionListSheet(
          isWard: isWard,
          province: province,
          loadCatalogue: widget.loadCatalogue,
        ),
      ),
    );
    if (picked == null || !context.mounted) return;
    // Chọn tỉnh thì phường cũ không còn đúng nữa nên bỏ, chọn phường thì giữ
    // tỉnh đang có. Lựa chọn này là của host nên form gọn đường tự điền: nó
    // chỉ lấp chỗ trống, không chen vào lựa chọn vừa bấm.
    widget.onSelect(
      SocialRegionSelection(
        province: isWard ? province : picked,
        ward: isWard ? picked : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selection = widget.applied;
    final province = selection?.province;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _LocalityField(
            icon: Icons.map_outlined,
            label: l10n.socialRegionProvinceFieldLabel,
            hint: l10n.socialRegionProvinceFieldHint,
            value: province?.name,
            onTap: () => _openList(context, isWard: false),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _LocalityField(
            icon: Icons.business_outlined,
            label: l10n.socialRegionWardFieldLabel,
            // Chưa có tỉnh thì phường chưa có nghĩa: nói rõ điều kiện thay vì
            // để trống rồi để host tự đoán vì sao không bấm được.
            hint: province == null
                ? l10n.socialRegionWardNeedsProvinceHint
                : l10n.socialRegionWardFieldHint,
            value: selection?.ward?.name,
            enabled: province != null,
            onTap: () => _openList(context, isWard: true),
          ),
        ),
      ],
    );
  }
}

/// Một trường khu vực: ô nhập chỉ đọc có nhãn hiện thành, tiền tố, mũi tên
/// xuống — đúng như ô chọn của màn "Tạo giải nhanh", nhưng bấm vào thì mở
/// danh sách có ô tìm thay vì kéo dài một menu dài hàng trăm dòng.
class _LocalityField extends StatefulWidget {
  const _LocalityField({
    required this.icon,
    required this.label,
    required this.hint,
    required this.value,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final String hint;

  /// Tên khu vực đang áp dụng, `null` khi ô còn trống. Đây là nguồn duy nhất:
  /// thẻ vị trí và hai ô này cùng đọc một lựa chọn nên host không thấy trạng
  /// thái khác nhau ở hai nơi.
  final String? value;
  final VoidCallback onTap;
  final bool enabled;

  @override
  State<_LocalityField> createState() => _LocalityFieldState();
}

class _LocalityFieldState extends State<_LocalityField> {
  /// Tên đã áp dụng nằm trong chính ô nhập chứ không phải một dòng chữ
  /// ghép cạnh: ô chỉ đọc thì đó là chỗ hintText tự ẩn đi, và cũng là chỗ
  /// trình đọc màn hình đọc tên đang chọn. Khu vực đổi giữa chừng thì đồng
  /// bộ, không dựng lại ô — giữ nguyên controller cho mỗi ô.
  late final TextEditingController _controller = TextEditingController(
    text: widget.value ?? '',
  );

  @override
  void didUpdateWidget(_LocalityField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.value ?? '';
    if (next != _controller.text) _controller.text = next;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TextField(
      controller: _controller,
      readOnly: true,
      showCursor: false,
      enableInteractiveSelection: false,
      enabled: widget.enabled,
      onTap: widget.enabled ? widget.onTap : null,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      decoration: InputDecoration(
        // Nhãn luôn nổi lên, nên khi ô còn trống trong ô là gợi ý ("Chọn
        // tỉnh") thay vì nhãn chui vào ô rồi biến mất — đọc được cả khi
        // trống lẫn khi đã chọn.
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 12,
        ),
        labelText: widget.label,
        // Đã có tên khu vực thì không còn gợi ý nào để hiện: nhãn luôn nổi
        // lên, nên trong ô chỉ còn tên đã chọn — đúng như kỳ vọng của host khi
        // nhìn thấy hai ô này.
        hintText: (widget.value ?? '').isEmpty ? widget.hint : null,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Icon(widget.icon, size: 18),
        ),
        // Ô nằm trong cột hẹp: chừa chỗ cho tiền tố nhỏ để tên tỉnh dài
        // ("TP. Hồ Chí Minh") còn chỗ ở màn 360 px.
        prefixIconConstraints: const BoxConstraints(
          minWidth: 34,
          minHeight: 18,
        ),
        suffixIcon: Icon(
          Icons.arrow_drop_down,
          size: 20,
          color: colors.textMuted,
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 30,
          minHeight: 18,
        ),
        filled: true,
        fillColor: colors.bgSurface,
        border: _border(colors.border),
        enabledBorder: _border(colors.border),
        disabledBorder: _border(colors.border),
        focusedBorder: _border(AppTheme.primary, width: 1.5),
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

/// Danh sách tỉnh, hoặc phường của một tỉnh, mở ra khi host bấm trường tương
/// ứng. Chọn là áp dụng luôn — không có nút "Áp dụng", không có bước xác nhận
/// thừa; đóng sheet thì giữ nguyên lựa chọn đang có.
class _SocialRegionListSheet extends StatefulWidget {
  const _SocialRegionListSheet({
    required this.isWard,
    required this.province,
    required this.loadCatalogue,
  });

  /// Phường/xã hay tỉnh/thành: quyết định nhãn, danh sách và cách tìm.
  final bool isWard;

  /// Tỉnh đang chọn — phường chỉ được lọc trong tỉnh đó.
  final Region? province;

  final Future<SocialRegionCatalogue?> Function({bool refresh}) loadCatalogue;

  @override
  State<_SocialRegionListSheet> createState() => _SocialRegionListSheetState();
}

class _SocialRegionListSheetState extends State<_SocialRegionListSheet> {
  static const _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const _maxVisibleOptions = 50;

  /// Rank of a spelling that does not answer a typed term at all.
  static const int _noMatch = 3;

  final TextEditingController _search = TextEditingController();

  List<Region> _options = const [];
  String? _selectedLetter;

  bool _loading = true;
  /// Danh mục không nạp được (mất mạng) — khác với danh mục rỗng.
  bool _loadFailed = false;
  bool _empty = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    setState(() {
      _loading = true;
      _loadFailed = false;
      _empty = false;
    });
    final catalogue = await widget.loadCatalogue(refresh: refresh);
    if (!mounted) return;
    final options = _optionsOf(catalogue);
    setState(() {
      _options = options;
      _loading = false;
      // Mất mạng và danh mục rỗng là hai nguyên nhân khác nhau nên báo khác
      // nhau, nhưng cùng để lại một đường thoát cho người dùng: nút thử lại,
      // và tuyệt đối không chặn việc gõ địa chỉ tay.
      _loadFailed = catalogue == null;
      _empty = catalogue != null && options.isEmpty;
    });
  }

  /// Danh sách đúng cấp đang mở: tỉnh thì toàn bộ, phường thì chỉ trong tỉnh
  /// đang chọn, nên phường của tỉnh khác không lẫn vào lựa chọn.
  List<Region> _optionsOf(SocialRegionCatalogue? catalogue) {
    if (catalogue == null) return const [];
    final rows = widget.isWard
        ? catalogue.wards.where(
            (ward) => ward.provinceCode == widget.province?.code,
          )
        : catalogue.provinces;
    return _sortRegions(rows.toList(growable: false), isWard: widget.isWard);
  }

  List<Region> _sortRegions(List<Region> regions, {required bool isWard}) {
    final sorted = List<Region>.of(regions);
    sorted.sort((left, right) {
      final normalized = _alphabetKey(
        _searchKey(left),
        isWard: isWard,
      ).compareTo(_alphabetKey(_searchKey(right), isWard: isWard));
      if (normalized != 0) return normalized;
      final byName = left.name.compareTo(right.name);
      if (byName != 0) return byName;
      return left.code.compareTo(right.code);
    });
    return sorted;
  }

  String _searchKey(Region region) =>
      VietnamAddressParser.removeVietnameseTones(region.name);

  /// Tone-free key a name is filed and matched under: a ward drops its
  /// "Phường/Xã" prefix, so "Phường Cầu Giấy" reads as "cau giay". The
  /// parser owns what a type prefix is, so the list and the address
  /// inference can never drift apart.
  String _alphabetKey(String searchKey, {required bool isWard}) =>
      isWard ? VietnamAddressParser.localityName(searchKey) : searchKey;

  /// How well one spelling answers a typed [term]: 0 the spelling is the
  /// term, 1 it opens with the term, 2 it carries the term inside,
  /// [_noMatch] when the term is absent.
  static int _nameRank(String key, String term) {
    if (key == term) return 0;
    if (key.startsWith(term)) return 1;
    if (key.contains(term)) return 2;
    return _noMatch;
  }

  /// The best rank over every spelling a term may match, or `null` when the
  /// term is in none of them.
  ///
  /// A province answers besides its displayed name to its full name and to the
  /// short forms the address parser already accepts ("hcm", "sai gon", ...),
  /// so the list accepts the same wording the applied area is detected from. A
  /// ward answers besides its name to the same name without its locality
  /// prefix, so "my" ranks "Phường Mỹ Đình" above "Phường An Mỹ".
  static int? _relevanceRank(
    Region region, {
    required String searchKey,
    required String alphabetKey,
    required String term,
    required bool isWard,
  }) {
    var best = _noMatch;
    for (final key in [
      searchKey,
      alphabetKey,
      if (!isWard) ..._provinceSpellings(region),
    ]) {
      final rank = _nameRank(key, term);
      if (rank == 0) return 0;
      if (rank < best) best = rank;
    }
    return best == _noMatch ? null : best;
  }

  /// The full name and alias spellings of a province, tone-free. Wards have
  /// neither: the alias table is keyed by province name, and a ward name is
  /// never a province name.
  static List<String> _provinceSpellings(Region region) {
    final fullName = region.fullName?.trim() ?? '';
    final aliases = VietnamAddressParser.provinceAliasesOf(region.name);
    return <String>[
      if (fullName.isNotEmpty)
        VietnamAddressParser.removeVietnameseTones(fullName),
      ...?aliases?.map(VietnamAddressParser.removeVietnameseTones),
    ];
  }

  /// [regions] narrowed to the names that answer [term] and ordered by how
  /// well they answer it: the exact spelling first, then a spelling opening
  /// with the term, then one carrying it inside. Equal ranks keep the loaded
  /// order, so the result is stable for a given term.
  List<Region> _rankByRelevance(
    List<Region> regions, {
    required String term,
  }) {
    final isWard = widget.isWard;
    final ranked = <_RankedRegion>[];
    for (final region in regions) {
      final searchKey = _searchKey(region);
      final alphabetKey = _alphabetKey(searchKey, isWard: isWard);
      final rank = _relevanceRank(
        region,
        searchKey: searchKey,
        alphabetKey: alphabetKey,
        term: term,
        isWard: isWard,
      );
      if (rank == null) continue;
      ranked.add((
        rank: rank,
        key: alphabetKey,
        name: region.name,
        code: region.code,
        region: region,
      ));
    }
    ranked.sort((left, right) {
      final byRank = left.rank.compareTo(right.rank);
      if (byRank != 0) return byRank;
      final byKey = left.key.compareTo(right.key);
      if (byKey != 0) return byKey;
      final byName = left.name.compareTo(right.name);
      if (byName != 0) return byName;
      return left.code.compareTo(right.code);
    });
    return [for (final row in ranked) row.region];
  }

  /// The options the list shows: narrowed by the letter chip and — once
  /// something is typed — by the term as well, the closest name first. An
  /// empty term keeps the loaded options in the order they arrived.
  List<Region> _visibleOptions() {
    final term = VietnamAddressParser.removeVietnameseTones(
      _search.text.trim(),
    );
    final letter = _selectedLetter?.toLowerCase();
    final candidates = <Region>[
      for (final region in _options)
        if (letter == null ||
            _alphabetKey(_searchKey(region), isWard: widget.isWard)
                .startsWith(letter))
          region,
    ];
    final matches = term.isEmpty
        ? candidates
        : _rankByRelevance(candidates, term: term);
    return matches.take(_maxVisibleOptions).toList(growable: false);
  }

  bool _hasOptionsForLetter(String letter) => _options.any(
    (region) => _alphabetKey(_searchKey(region), isWard: widget.isWard)
        .startsWith(letter.toLowerCase()),
  );

  void _selectLetter(String letter) {
    setState(() {
      _selectedLetter = _selectedLetter == letter ? null : letter;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          10,
          18,
          12 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 14),
            _sheetHeader(context, l10n),
            const SizedBox(height: 12),
            _searchField(context, l10n),
            const SizedBox(height: 8),
            _alphabetFilter(context, l10n),
            const SizedBox(height: 8),
            Expanded(child: _optionsList(context, l10n)),
          ],
        ),
      ),
    );
  }

  Widget _sheetHeader(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.socialRegionPickerTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: context.colors.textPrimary,
            ),
          ),
        ),
        IconButton(
          tooltip: l10n.socialRegionCloseAction,
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _searchField(BuildContext context, AppLocalizations l10n) {
    return TextField(
      controller: _search,
      onChanged: (_) => setState(() {}),
      textInputAction: TextInputAction.search,
      style: const TextStyle(fontSize: 14.5),
      decoration: InputDecoration(
        isDense: true,
        labelText: widget.isWard
            ? l10n.socialRegionWardLabel
            : l10n.socialRegionProvinceLabel,
        hintText: widget.isWard
            ? l10n.socialRegionWardSearchHint
            : l10n.socialRegionProvinceSearchHint,
        prefixIcon: const Icon(Icons.search, size: 20),
        filled: true,
        fillColor: context.colors.bgDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _alphabetFilter(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            l10n.socialRegionAlphabetHint,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.colors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final letter in _alphabet.split(''))
                _letterFilter(l10n, letter),
            ],
          ),
        ),
      ],
    );
  }

  /// Một bộ lọc A–Z. Chip giữ callback chạm, nút [Semantics] bao ngoài mang
  /// đúng lựa chọn đó cho trình đọc màn hình: chữ cái không chỉ được đọc mà
  /// còn kích hoạt được. Chữ cái không có kết quả vẫn bị khoá ở cả hai đường.
  Widget _letterFilter(AppLocalizations l10n, String letter) {
    final available = _hasOptionsForLetter(letter);
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Semantics(
        button: true,
        enabled: available,
        selected: _selectedLetter == letter,
        label: '${l10n.socialRegionAlphabetHint}: $letter',
        excludeSemantics: true,
        onTap: available ? () => _selectLetter(letter) : null,
        child: ChoiceChip(
          label: Text(letter),
          selected: _selectedLetter == letter,
          onSelected: available ? (_) => _selectLetter(letter) : null,
          // Mật độ chuẩn giữ vùng chạm tối thiểu 48 px trong hàng cuộn ngang.
          materialTapTargetSize: MaterialTapTargetSize.padded,
          visualDensity: VisualDensity.standard,
        ),
      ),
    );
  }

  Widget _optionsList(BuildContext context, AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadFailed || _empty) {
      return _message(
        context,
        _loadFailed ? l10n.socialRegionLoadError : l10n.socialRegionUnavailable,
        action: TextButton(
          onPressed: () => _load(refresh: true),
          child: Text(l10n.socialRegionRetry),
        ),
      );
    }
    final query = _search.text.trim();
    if (widget.isWard &&
        query.isNotEmpty &&
        query.length < 2 &&
        _selectedLetter == null) {
      return Center(
        child: Text(
          l10n.socialRegionWardSearchPrompt,
          style: TextStyle(color: context.colors.textSecondary),
        ),
      );
    }

    final options = _visibleOptions();
    if (options.isEmpty) {
      return Center(
        child: Text(
          l10n.socialRegionNoResults,
          style: TextStyle(color: context.colors.textSecondary),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: options.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: context.colors.border.withValues(alpha: 0.5),
      ),
      itemBuilder: (context, index) => _regionOption(context, options[index]),
    );
  }

  Widget _regionOption(BuildContext context, Region region) {
    final province = widget.isWard ? widget.province : null;
    final label = province == null
        ? region.name
        : '${region.name}, ${province.name}';

    void onSelect() => Navigator.of(context).pop(region);

    return Semantics(
      button: true,
      selected: false,
      label: label,
      excludeSemantics: true,
      // Cùng lựa chọn với cú chạm, để trình đọc màn hình kích hoạt được
      // tỉnh/phường chứ không chỉ nghe tên.
      onTap: onSelect,
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        title: Text(region.name),
        subtitle: province == null ? null : Text(province.name),
        onTap: onSelect,
      ),
    );
  }

  Widget _message(BuildContext context, String text, {Widget? action}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: context.colors.textSecondary,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 4), action],
          ],
        ),
      ),
    );
  }
}

/// One option in the relevance order: how well it answers the typed term,
/// plus the keys that keep equally good answers in the loaded order.
typedef _RankedRegion =
    ({int rank, String key, String name, String code, Region region});
