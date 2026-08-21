from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent
files = [
    'lib/features/admin/screens/change_requests_screen.dart',
    'lib/features/admin/screens/disputes_screen.dart',
    'lib/features/admin/screens/pending_clubs_screen.dart',
    'lib/features/admin/screens/verification_screen.dart',
    'lib/features/chat/screens/chat_detail_screen.dart',
    'lib/features/chat/widgets/chat_poll_dialog.dart',
    'lib/features/chat/widgets/chat_room_settings_sheet.dart',
    'lib/features/profile/screens/settings_screen.dart',
    'lib/core/widgets/app_share_modal.dart',
    'lib/core/widgets/app_update_gate.dart',
    'lib/core/widgets/countdown_timer.dart',
    'lib/features/home/widgets/explore_tab.dart',
    'lib/features/chat/widgets/chat_image_viewer.dart',
    'lib/features/profile/widgets/language_setting_card.dart',
    'lib/features/admin/screens/transactions_screen.dart',
    'lib/features/admin/screens/pending_clubs_screen.dart',
    'lib/features/admin/screens/disputes_screen.dart',
]
pattern = re.compile(r"l10n\?\.(\w+)\s*\?\?\s*('[^'\n]*'|\"[^\"\n]*\")")
for rel in files:
    p = ROOT / rel
    text = p.read_text(encoding='utf-8')
    updated, count = pattern.subn(r'l10n!.\1', text)
    if count:
        p.write_text(updated, encoding='utf-8')
    print(f'{rel}: {count} fallback(s) removed')
