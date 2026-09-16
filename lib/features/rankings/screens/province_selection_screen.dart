import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/province_picker.dart';

class ProvinceSelectionScreen extends StatefulWidget {
  final String? selectedProvinceCode;

  const ProvinceSelectionScreen({
    super.key,
    this.selectedProvinceCode,
  });

  static String _removeDiacritics(String str) {
    const withDia =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ'
        'ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ';
    const withoutDia =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd'
        'AAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD';
    var result = str;
    for (int i = 0; i < withDia.length; i++) {
      result = result.replaceAll(withDia[i], withoutDia[i]);
    }
    return result;
  }

  @override
  State<ProvinceSelectionScreen> createState() =>
      _ProvinceSelectionScreenState();
}

class _ProvinceSelectionScreenState extends State<ProvinceSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ProvinceData> _filteredProvinces = ProvinceData.all;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _filteredProvinces = ProvinceData.all;
      });
      return;
    }

    final normalizedQuery =
        ProvinceSelectionScreen._removeDiacritics(query).toLowerCase();

    setState(() {
      _filteredProvinces = ProvinceData.all.where((province) {
        final normalizedName =
            ProvinceSelectionScreen._removeDiacritics(province.name)
                .toLowerCase();
        return normalizedName.contains(normalizedQuery) ||
            province.name.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top Search Bar + Huỷ button (matching image 4)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: colors.bgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.border),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Chọn tỉnh',
                          hintStyle: TextStyle(
                            color: colors.textMuted,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: colors.textMuted,
                            size: 20,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear_rounded,
                                    size: 18,
                                    color: colors.textMuted,
                                  ),
                                  onPressed: () => _searchController.clear(),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      // "Huỷ" sẽ xoá bộ lọc tỉnh đã chọn trước đó
                      Navigator.of(context).pop(const {'action': 'clear'});
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      child: Text(
                        'Huỷ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Province List
            Expanded(
              child: _filteredProvinces.isEmpty
                  ? Center(
                      child: Text(
                        'Không tìm thấy tỉnh / thành',
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredProvinces.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final province = _filteredProvinces[index];
                        final isSelected =
                            province.code == widget.selectedProvinceCode;

                        return InkWell(
                          onTap: () {
                            Navigator.of(context).pop({
                              'action': 'select',
                              'code': province.code,
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    province.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? AppTheme.primary
                                          : colors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_rounded,
                                    color: AppTheme.primary,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
