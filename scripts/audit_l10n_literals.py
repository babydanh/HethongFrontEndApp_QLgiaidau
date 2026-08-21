from __future__ import annotations

import re
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parents[1] / "lib"
EXCLUDED_PARTS = {"l10n", ".dart_tool", "build"}
DISPLAY_MARKERS = (
    "Text(", "TextSpan(", "labelText:", "hintText:", "helperText:",
    "tooltip:", "semanticLabel:", "SnackBar(", "showSnackBar(",
    "title:", "subtitle:", "label:", "message:", "content:",
)
STRING = re.compile(r"(?P<quote>['\"])(?P<value>(?:\\.|(?! (?P=quote)).)*)?(?P=quote)", re.VERBOSE)
VI_CHARS = re.compile(r"[ăâđêôơưĂÂĐÊÔƠƯáàảãạấầẩẫậắằẳẵặéèẻẽẹếềểễệíìỉĩịóòỏõọốồổỗộớờởỡợúùủũụứừửữựýỳỷỹỵ]", re.IGNORECASE)
EN_WORDS = re.compile(r"\b(the|and|or|please|failed|error|retry|cancel|save|delete|edit|create|search|loading|success|password|email|phone|address|home|back|next|previous|submit|settings|profile|team|match|tournament|participant|status|date|time|location|payment|report|invite|share|follow|unfollow|close|confirm|warning|information|unknown|not found|no data)\b", re.IGNORECASE)


def is_candidate(line: str) -> bool:
    return any(marker in line for marker in DISPLAY_MARKERS)


def clean(value: str) -> str:
    value = value.replace("\\'", "'").replace('\\"', '"')
    return re.sub(r"\s+", " ", value).strip()


def main() -> None:
    rows: list[tuple[str, int, str, str, str]] = []
    for path in sorted(ROOT.rglob("*.dart")):
        if any(part in EXCLUDED_PARTS for part in path.parts):
            continue
        try:
            lines = path.read_text(encoding="utf-8").splitlines()
        except UnicodeDecodeError:
            lines = path.read_text(encoding="utf-8-sig", errors="replace").splitlines()
        for number, raw in enumerate(lines, start=1):
            line = raw.strip()
            if not line or line.startswith("//") or line.startswith("import ") or line.startswith("part "):
                continue
            if not is_candidate(line):
                continue
            for match in STRING.finditer(line):
                value = clean(match.group("value") or "")
                if len(value) < 2 or value.startswith("@") or "package:" in value or value.startswith("http"):
                    continue
                if value.startswith("l10n.") or value.startswith("AppLocalizations"):
                    continue
                language = "VI" if VI_CHARS.search(value) else "EN/OTHER" if EN_WORDS.search(value) else "OTHER"
                rows.append((str(path.relative_to(ROOT.parent)).replace("\\", "/"), number, language, value, line))
    print("path\tline\tlanguage\tliteral\tsource")
    for path, number, language, value, source in rows:
        print(f"{path}\t{number}\t{language}\t{value}\t{source}")
    print(f"\nTOTAL_CANDIDATES={len(rows)}")


if __name__ == "__main__":
    main()
