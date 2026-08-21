from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PATH = ROOT / "lib/features/community/screens/club_detail_screen.dart"
DISPLAY_MARKERS = (
    "Text(", "TextSpan(", "labelText:", "hintText:", "helperText:",
    "tooltip:", "semanticLabel:", "SnackBar(", "showSnackBar(",
    "title:", "subtitle:", "label:", "message:", "content:",
)
STRING = re.compile(r"(?P<quote>['\"])(?P<value>(?:\\.|(?! (?P=quote)).)*)?(?P=quote)", re.VERBOSE)
VI_CHARS = re.compile(r"[ăâđêôơưĂÂĐÊÔƠƯáàảãạấầẩẫậắằẳẵặéèẻẽẹếềểễệíìỉĩịóòỏõọốồổỗộớờởỡợúùủũụứừửữựýỳỷỹỵ]", re.IGNORECASE)

def clean(value: str) -> str:
    return re.sub(r"\s+", " ", value.replace("\\'", "'").replace('\\"', '"')).strip()

rows = []
for number, raw in enumerate(PATH.read_text(encoding="utf-8").splitlines(), start=1):
    line = raw.strip()
    if not line or line.startswith("//") or line.startswith("import ") or not any(marker in line for marker in DISPLAY_MARKERS):
        continue
    for match in STRING.finditer(line):
        value = clean(match.group("value") or "")
        if len(value) < 2 or value.startswith("@") or "package:" in value or value.startswith("http") or value.startswith("l10n."):
            continue
        rows.append({"line": number, "language": "VI" if VI_CHARS.search(value) else "EN/OTHER", "literal": value, "source": line})

(ROOT / ".club-detail-literals.json").write_text(__import__("json").dumps(rows, ensure_ascii=False, indent=2), encoding="utf-8")
print(f"WROTE={len(rows)}")
for row in rows:
    print(f"{row['line']}: [{row['language']}] {row['literal']}")

def main() -> None:
    pass

if __name__ == "__main__":
    main()

