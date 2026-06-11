import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/extensions/animation_extensions.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/widgets/form_section.dart';
import 'package:app_quanly_giaidau/core/widgets/sport_icon_widget.dart';

class TournamentSettingsForm extends StatelessWidget {
  final String selectedSport;
  final String selectedFormat;
  final String? selectedCategory;
  final String selectedBracket;
  final TextEditingController maxTeamsController;
  final FocusNode maxTeamsFocusNode;
  final TextEditingController roundCountController;
  final FocusNode roundCountFocusNode;
  final GlobalKey<FormState> formKey;

  final ValueChanged<String> onSportChanged;
  final ValueChanged<String> onFormatChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String> onBracketChanged;
  final VoidCallback onShowBracketInfo;

  const TournamentSettingsForm({
    super.key,
    required this.selectedSport,
    required this.selectedFormat,
    required this.selectedCategory,
    required this.selectedBracket,
    required this.maxTeamsController,
    required this.maxTeamsFocusNode,
    required this.roundCountController,
    required this.roundCountFocusNode,
    required this.formKey,
    required this.onSportChanged,
    required this.onFormatChanged,
    required this.onCategoryChanged,
    required this.onBracketChanged,
    required this.onShowBracketInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FormSection(
          title: 'Môn thi đấu',
          child: _buildSportSelector(context),
        ).slideInFromBottom(delay: 50.ms),

        FormSection(
          title: 'Hình thức thi đấu',
          child: _buildFormatSelector(context),
        ).slideInFromBottom(delay: 100.ms),

        FormSection(
          title: 'Hạng mục / Nội dung',
          child: _buildCategorySelector(context),
        ).slideInFromBottom(delay: 150.ms),

        FormSection(
          title: 'Thể thức thi đấu',
          titleAction: GestureDetector(
            onTap: onShowBracketInfo,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline,
                    color: AppTheme.primaryLight, size: 16),
                SizedBox(width: 4),
                Text(
                  'Chi tiết',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          child: _buildBracketSelector(context),
        ).slideInFromBottom(delay: 200.ms),

        FormSection(
          title: selectedBracket == AppConstants.bracketRoundRobin
              ? 'Số lượng đội dự kiến (3 - 16 đội)'
              : 'Số lượng đội dự kiến (2 - 32 đội)',
          child: TextFormField(
            controller: maxTeamsController,
            focusNode: maxTeamsFocusNode,
            keyboardType: TextInputType.number,
            style: TextStyle(color: context.colors.textPrimary),
            decoration: InputDecoration(
              hintText: selectedBracket == AppConstants.bracketRoundRobin
                  ? 'VD: 5, 8, 10...'
                  : 'Gợi ý sơ đồ chuẩn nhất: 4, 8, 16, 32',
              prefixIcon:
                  const Icon(Icons.groups, color: AppTheme.secondaryLight),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return null;
              final v = int.tryParse(value.trim());
              if (v == null) return 'Vui lòng nhập số hợp lệ';

              final isRoundRobin =
                  selectedBracket == AppConstants.bracketRoundRobin;
              if (isRoundRobin) {
                if (v < 3) return 'Đấu vòng tròn cần ít nhất 3 đội';
                if (v > 16) return 'Đấu vòng tròn tối đa hỗ trợ 16 đội';
              } else {
                if (v < 2) return 'Cần ít nhất 2 đội';
                if (v > 32) return 'Tối đa chỉ hỗ trợ 32 đội';
              }
              return null;
            },
          ),
        ).slideInFromBottom(delay: 250.ms),

        if (selectedBracket == AppConstants.bracketRoundRobin)
          FormSection(
            title: 'Số vòng đấu (Số vòng bạn muốn diễn ra)',
            child: TextFormField(
              controller: roundCountController,
              focusNode: roundCountFocusNode,
              keyboardType: TextInputType.number,
              style: TextStyle(color: context.colors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'VD: Nhập đúng số vòng mà bạn muốn tổ chức',
                prefixIcon:
                    Icon(Icons.repeat, color: AppTheme.secondaryLight),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                final v = int.tryParse(value.trim());
                if (v == null) return 'Vui lòng nhập số hợp lệ';
                if (v < 1) return 'Số vòng phải lớn hơn 0';
                if (v > 38) return 'Tối đa 38 vòng để tránh quá tải';
                return null;
              },
            ),
          ).slideInFromBottom(delay: 300.ms),
      ],
    );
  }

  Widget _buildSportSelector(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: AppConstants.sportNames.entries.map((entry) {
        final isSelected = selectedSport == entry.key;
        final icon = AppConstants.sportIcons[entry.key] ?? '🏆';
        return GestureDetector(
          onTap: () {
            onSportChanged(entry.key);
            onFormatChanged(AppConstants.formatSingles);
            onCategoryChanged(AppConstants.categoryMenSingles);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary.withValues(alpha: 0.12)
                  : context.colors.bgSurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: isSelected ? AppTheme.primary : context.colors.border,
                width: isSelected ? 1.8 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SportIconWidget(iconData: icon, size: 18),
                const SizedBox(width: 8),
                Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? context.colors.textPrimary
                        : context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ).animate(target: isSelected ? 1 : 0).scale(
                begin: const Offset(1, 1),
                end: const Offset(1.04, 1.04),
                duration: 200.ms,
                curve: Curves.easeOutBack,
              ),
        );
      }).toList(),
    );
  }

  Widget _buildFormatSelector(BuildContext context) {
    final formats = [AppConstants.formatSingles, AppConstants.formatDoubles];

    return Row(
      children: formats.map((formatKey) {
        final isSelected = selectedFormat == formatKey;
        final name = AppConstants.formatNames[formatKey] ?? formatKey;
        final icon = formatKey == AppConstants.formatSingles ? Icons.person : Icons.people;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              onFormatChanged(formatKey);
              // Cập nhật category hợp lệ
              if (formatKey == AppConstants.formatSingles) {
                if (selectedCategory != AppConstants.categoryMenSingles &&
                    selectedCategory != AppConstants.categoryWomenSingles) {
                  onCategoryChanged(AppConstants.categoryMenSingles);
                }
              } else if (formatKey == AppConstants.formatDoubles) {
                if (selectedCategory != AppConstants.categoryMenDoubles &&
                    selectedCategory != AppConstants.categoryWomenDoubles &&
                    selectedCategory != AppConstants.categoryMixedDoubles) {
                  onCategoryChanged(AppConstants.categoryMenDoubles);
                }
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              margin: EdgeInsets.only(
                right: formatKey == AppConstants.formatSingles ? 8 : 0,
                left: formatKey == AppConstants.formatDoubles ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.secondary.withValues(alpha: 0.12)
                    : context.colors.bgSurface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: isSelected ? AppTheme.secondary : context.colors.border,
                  width: isSelected ? 1.8 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.secondary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected ? AppTheme.secondary : context.colors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? context.colors.textPrimary : context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ).animate(target: isSelected ? 1 : 0).scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.02, 1.02),
                  duration: 200.ms,
                ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategorySelector(BuildContext context) {
    final validCategories = selectedFormat == AppConstants.formatSingles
        ? [AppConstants.categoryMenSingles, AppConstants.categoryWomenSingles]
        : [AppConstants.categoryMenDoubles, AppConstants.categoryWomenDoubles, AppConstants.categoryMixedDoubles];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: validCategories.map((categoryKey) {
        final isSelected = selectedCategory == categoryKey;
        final name = AppConstants.categoryNames[categoryKey] ?? categoryKey;
        return GestureDetector(
          onTap: () => onCategoryChanged(categoryKey),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.accent.withValues(alpha: 0.12)
                  : context.colors.bgSurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: isSelected ? AppTheme.accent : context.colors.border,
                width: isSelected ? 1.8 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.accent.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? context.colors.textPrimary : context.colors.textSecondary,
              ),
            ),
          ).animate(target: isSelected ? 1 : 0).scale(
                begin: const Offset(1, 1),
                end: const Offset(1.03, 1.03),
                duration: 200.ms,
              ),
        );
      }).toList(),
    );
  }

  Widget _buildBracketSelector(BuildContext context) {
    return Column(
      children: AppConstants.bracketTypeNames.entries.map((entry) {
        final isSelected = selectedBracket == entry.key;
        final desc = AppConstants.bracketTypeDescriptions[entry.key] ?? '';
        return GestureDetector(
          onTap: () {
            onBracketChanged(entry.key);
            formKey.currentState?.validate();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary.withValues(alpha: 0.08)
                  : context.colors.bgSurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: isSelected ? AppTheme.primary : context.colors.border,
                width: isSelected ? 1.8 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppTheme.primary : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : context.colors.textSecondary,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected ? context.colors.textPrimary : context.colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        desc,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? context.colors.textSecondary
                              : context.colors.textSecondary.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate(target: isSelected ? 1 : 0).scale(
                begin: const Offset(1, 1),
                end: const Offset(1.01, 1.01),
                duration: 200.ms,
              ),
        );
      }).toList(),
    );
  }
}
