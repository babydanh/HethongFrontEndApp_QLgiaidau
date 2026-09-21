import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/core/widgets/app_icons.dart';
import 'package:app_quanly_giaidau/core/widgets/app_text_field.dart';
import 'package:app_quanly_giaidau/core/widgets/sport_choice_tile.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/providers/regions_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Mobile counterpart of the web “Tạo trận giao lưu phong trào” dialog.
///
/// The payload is intentionally kept identical to the web contract
/// (`POST /social/pickups`); this screen only owns input and validation.
class CreatePersonalPickupScreen extends ConsumerStatefulWidget {
  const CreatePersonalPickupScreen({super.key});

  @override
  ConsumerState<CreatePersonalPickupScreen> createState() =>
      _CreatePersonalPickupScreenState();
}

class _CreatePersonalPickupScreenState
    extends ConsumerState<CreatePersonalPickupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _feeController = TextEditingController();
  final _slotsController = TextEditingController(text: '4');

  String? _categoryId;
  String? _provinceCode;
  String? _wardCode;
  DateTime? _start;
  int _durationMinutes = 120;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _feeController.dispose();
    _slotsController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final initial = _start ?? now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(initial.year, initial.month, initial.day),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    setState(() {
      _start = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final categories = ref.read(categoriesProvider).asData?.value ?? const [];
    final categoryId =
        _categoryId ?? (categories.isNotEmpty ? categories.first.id : '');
    if (categoryId.isEmpty) {
      _showMessage('Chưa có môn thể thao khả dụng');
      return;
    }
    final start = _start;
    if (start == null) {
      _showMessage('Vui lòng chọn ngày và giờ chơi');
      return;
    }
    final end = start.add(Duration(minutes: _durationMinutes));
    if (end.day != start.day) {
      _showMessage('Thời lượng không được vượt sang ngày mới');
      return;
    }
    final maxSlots = int.tryParse(_slotsController.text.trim());
    if (maxSlots == null || maxSlots < 2 || maxSlots > 128) {
      _showMessage('Tổng số người phải từ 2 đến 128');
      return;
    }
    final feeText = _feeController.text.trim();
    final fee = feeText.isEmpty ? null : int.tryParse(feeText);
    if (feeText.isNotEmpty && (fee == null || fee < 0)) {
      _showMessage('Phí mỗi người không hợp lệ');
      return;
    }
    final location = _locationPayload();

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(activityFeedRepositoryProvider)
          .createPersonalPickup(
            categoryId: categoryId,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            playDate: DateFormat('yyyy-MM-dd').format(start),
            startTime: DateFormat('HH:mm').format(start),
            endTime: DateFormat('HH:mm').format(end),
            location: location,
            feePerSlot: fee,
            maxSlots: maxSlots,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        _showMessage(
          ErrorParser.parse(
            error,
            'Không thể tạo trận giao lưu',
            AppLocalizations.of(context),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _locationPayload() {
    Province? province;
    for (final item
        in ref.read(provincesProvider).asData?.value ?? const <Province>[]) {
      if (item.code == _provinceCode) {
        province = item;
        break;
      }
    }
    Ward? ward;
    if (_provinceCode != null && _wardCode != null) {
      for (final item
          in ref.read(wardsProvider(_provinceCode!)).asData?.value ??
              const <Ward>[]) {
        if (item.code == _wardCode) {
          ward = item;
          break;
        }
      }
    }
    return [
      _locationController.text.trim(),
      province?.name,
      ward?.name,
    ].whereType<String>().where((part) => part.isNotEmpty).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).asData?.value ?? const [];
    final provinces =
        ref.watch(provincesProvider).asData?.value ?? const <Province>[];
    final wards = _provinceCode == null
        ? const <Ward>[]
        : ref.watch(wardsProvider(_provinceCode!)).asData?.value ??
              const <Ward>[];
    final selectedId =
        _categoryId ?? (categories.isNotEmpty ? categories.first.id : null);
    return Scaffold(
      backgroundColor: context.colors.bgSurface,
      appBar: AppBar(
        title: const Text('Tạo trận giao lưu phong trào'),
        leading: IconButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          icon: const Icon(AppIcons.close),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _section(
                    context,
                    title: 'Môn thể thao',
                    child: categories.isEmpty
                        ? const LinearProgressIndicator()
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: categories
                                .map(
                                  (category) => SportChoiceTile(
                                    sportKey: category.slug,
                                    label: category.name,
                                    selected: selectedId == category.id,
                                    expanded: false,
                                    onTap: () => setState(
                                      () => _categoryId = category.id,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  _section(
                    context,
                    title: 'Thông tin trận',
                    child: Column(
                      children: [
                        AppTextFormField(
                          controller: _titleController,
                          label: 'Tiêu đề',
                          hint: 'Ví dụ: Giao lưu Pickleball buổi tối',
                          validator: (value) =>
                              (value == null || value.trim().length < 3)
                              ? 'Nhập ít nhất 3 ký tự'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        AppTextFormField(
                          controller: _locationController,
                          label: 'Địa điểm thi đấu / Giao lưu',
                          hint: 'Ví dụ: Sân Pickleball D-Sport Quận 7',
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? 'Nhập địa điểm'
                              : null,
                        ),
                        if (provinces.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _regionDropdown<Province>(
                                  context,
                                  label: 'Tỉnh/thành phố',
                                  value: _provinceCode,
                                  items: provinces,
                                  itemValue: (item) => item.code,
                                  itemLabel: (item) => item.name,
                                  onChanged: (value) => setState(() {
                                    _provinceCode = value;
                                    _wardCode = null;
                                  }),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _regionDropdown<Ward>(
                                  context,
                                  label: 'Phường/xã',
                                  value: _wardCode,
                                  items: wards,
                                  itemValue: (item) => item.code,
                                  itemLabel: (item) => item.name,
                                  enabled:
                                      _provinceCode != null && wards.isNotEmpty,
                                  onChanged: (value) =>
                                      setState(() => _wardCode = value),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        AppTextFormField(
                          controller: _descriptionController,
                          label: 'Mô tả (tùy chọn)',
                          hint:
                              'Nói thêm về trình độ, luật chơi hoặc cách chia sân...',
                          minLines: 3,
                          maxLines: 5,
                        ),
                      ],
                    ),
                  ),
                  _section(
                    context,
                    title: 'Ngày chơi và giờ bắt đầu',
                    child: _dateButton(context),
                  ),
                  _section(
                    context,
                    title: 'Thời lượng',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [60, 90, 120, 180].map((minutes) {
                        return _choiceChip(
                          context,
                          label: _durationLabel(minutes),
                          selected: _durationMinutes == minutes,
                          onTap: () =>
                              setState(() => _durationMinutes = minutes),
                        );
                      }).toList(),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextFormField(
                          controller: _feeController,
                          label: 'Phí mỗi người (tùy chọn)',
                          hint: 'Miễn phí',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextFormField(
                          controller: _slotsController,
                          label: 'Tổng số người',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            final parsed = int.tryParse(value?.trim() ?? '');
                            return parsed == null || parsed < 2 || parsed > 128
                                ? 'Từ 2 đến 128'
                                : null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(AppIcons.forward, size: 18),
                        label: Text(
                          _isSubmitting ? 'Đang tạo...' : 'Tạo trận giao lưu',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.colors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Widget _regionDropdown<T>(
    BuildContext context, {
    required String label,
    required String? value,
    required List<T> items,
    required String Function(T) itemValue,
    required String Function(T) itemLabel,
    required ValueChanged<String?> onChanged,
    bool enabled = true,
  }) {
    final safeValue = items.any((item) => itemValue(item) == value)
        ? value
        : null;
    return DropdownButtonFormField<String>(
      key: ValueKey('$label:$safeValue'),
      initialValue: safeValue,
      isExpanded: true,
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 12,
          color: context.colors.textSecondary,
        ),
        filled: true,
        fillColor: context.colors.bgCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: itemValue(item),
              child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
    );
  }

  Widget _dateButton(BuildContext context) {
    final text = _start == null
        ? 'Chọn ngày và giờ'
        : DateFormat('dd/MM/yyyy HH:mm').format(_start!);
    return InkWell(
      onTap: _pickDateTime,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: context.colors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _start == null ? context.colors.border : context.colors.info,
          ),
        ),
        child: Row(
          children: [
            Icon(AppIcons.calendarClock, size: 18, color: context.colors.info),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: _start == null
                    ? context.colors.textMuted
                    : context.colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _choiceChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? context.colors.info.withValues(alpha: 0.10)
              : context.colors.bgSurface,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? context.colors.info : context.colors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected
                ? context.colors.info
                : context.colors.textSecondary,
          ),
        ),
      ),
    );
  }

  String _durationLabel(int minutes) => switch (minutes) {
    60 => '1 giờ',
    90 => '1 giờ 30',
    120 => '2 giờ',
    _ => '3 giờ',
  };
}
