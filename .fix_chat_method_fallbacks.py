from pathlib import Path
import re

root = Path(__file__).resolve().parent
p = root / 'lib/features/chat/screens/chat_detail_screen.dart'
text = p.read_text(encoding='utf-8')
text, n1 = re.subn(
    r"l10n\?\.chatDetailTyping\(_typingUser!\)\s*\?\?\s*'\$\{_typingUser!\} is typing\.\.\.'",
    "l10n!.chatDetailTyping(_typingUser!)",
    text,
)
text, n2 = re.subn(
    r"l10n\?\.chatDetailOnlineCount\(\s*_onlineUserIds\.length,\s*\)\s*\?\?\s*'\$\{_onlineUserIds\.length\} people online'",
    "l10n!.chatDetailOnlineCount(_onlineUserIds.length)",
    text,
)
p.write_text(text, encoding='utf-8')
print(f'chat_detail typing={n1} online={n2}')

p = root / 'lib/features/chat/widgets/chat_poll_dialog.dart'
text = p.read_text(encoding='utf-8')
text, n3 = re.subn(
    r"l10n\?\.chatPollOptionHint\(idx \+ 1\)\s*\?\?\s*'Option \$\{idx \+ 1\}'",
    "l10n!.chatPollOptionHint(idx + 1)",
    text,
)
p.write_text(text, encoding='utf-8')
print(f'chat_poll option={n3}')
