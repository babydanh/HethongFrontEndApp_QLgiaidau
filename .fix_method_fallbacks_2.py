from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent

def replace_methods(rel, names):
    p = ROOT / rel
    text = p.read_text(encoding='utf-8')
    total = 0
    for name in names:
        pattern = re.compile(
            rf"l10n\?\.{name}\((.*?)\)\s*\?\?\s*(['\"])(?:(?!\2).)*\2",
            re.S,
        )
        text, count = pattern.subn(lambda m, n=name: f"l10n!.{n}({m.group(1)})", text)
        total += count
    p.write_text(text, encoding='utf-8')
    print(f'{rel}: {total} method fallback(s) removed')

replace_methods('lib/core/widgets/countdown_timer.dart', ['coreCountdownDays', 'coreCountdownTime', 'coreCountdownClock'])
replace_methods('lib/core/widgets/app_share_modal.dart', ['coreShareDetailsAt'])
replace_methods('lib/features/home/widgets/explore_tab.dart', [
    'exploreMatchStatusLive', 'exploreMatchStatusCompleted', 'exploreMatchStatusScheduled',
    'exploreShareSubtitle',
])
replace_methods('lib/features/admin/screens/transactions_screen.dart', ['transactionsAmount', 'adminTransactionsReference'])
replace_methods('lib/features/admin/screens/pending_clubs_screen.dart', ['pendingClubsMemberCount', 'pendingClubsRejectQuestion'])
replace_methods('lib/features/admin/screens/disputes_screen.dart', ['adminDisputesCreatedAt'])
replace_methods('lib/features/chat/widgets/chat_room_settings_sheet.dart', [
    'chatRoomSharedMediaSection', 'chatRoomMembersSection', 'chatRoomSlowModeWait',
])
replace_methods('lib/features/chat/screens/chat_detail_screen.dart', ['chatDetailSeenBy', 'chatDetailReplyTo'])
replace_methods('lib/features/profile/screens/settings_screen.dart', [
    'settingsAutoDetected', 'settingsDobDisplay', 'settingsWalletPrefix',
])

p = ROOT / 'lib/features/profile/screens/settings_screen.dart'
text = p.read_text(encoding='utf-8')
text = text.replace('l10n?.settingsNoBank ?? _noBank', 'l10n!.settingsNoBank')
p.write_text(text, encoding='utf-8')
print('settings_screen: settingsNoBank fallback removed')
