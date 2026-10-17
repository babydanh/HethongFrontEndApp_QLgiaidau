import 'package:flutter/material.dart';

import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Hộp chọn nội dung thi đấu dùng chung cho màn Lite. Trả id nội dung BTC
/// xác nhận, hoặc null nếu BTC huỷ (khi đó không được gọi API nào).
Future<String?> showLiteDivisionPicker(
  BuildContext context,
  List<TournamentDivision> divisions,
) {
  final l10n = AppLocalizations.of(context)!;
  String? selectedId;
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(l10n.registerSelectDivision),
        content: DropdownButtonFormField<String>(
          initialValue: selectedId,
          isExpanded: true,
          items: [
            for (final division in divisions)
              DropdownMenuItem(value: division.id, child: Text(division.name)),
          ],
          onChanged: (value) => setDialogState(() => selectedId = value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: selectedId == null
                ? null
                : () => Navigator.pop(dialogContext, selectedId),
            child: Text(l10n.lite_confirmButton),
          ),
        ],
      ),
    ),
  );
}
