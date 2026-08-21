from __future__ import annotations

import json
import re
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / "lib"
OUT = ROOT / ".l10n-existing-key-matches.tsv"
EXCLUDED_PARTS = {"l10n", ".dart_tool", "build"}
DISPLAY_MARKERS = (
    "Text(", "TextSpan(", "labelText:", "hintText:", "helperText:",
    "tooltip:", "semanticLabel:", "SnackBar(", "showSnackBar(",
    "title:", "subtitle:", "label:", "message:", "content:",
)
STRING = re.compile(r"(?P<quote>['\"])(?P<value>(?:\\.|(?! (?P=quote)).)*)?(?P=quote)", re.VERBOSE)


def unescape(value: str) -> str:
    return value.replace("\\'", "'").replace('\\"', '"').replace("\\n", "\n")


def value_to_keys(path: Path) -> dict[str, list[str]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    result: dict[str, list[str]] = defaultdict(list)
    for key, value in data.items():
        if key.startswith("@") or not isinstance(value, str):
            continue
        result[value].append(key)
    return result


def main() -> None:
    vi = value_to_keys(ROOT / "lib/l10n/app_vi.arb")
    en = value_to_keys(ROOT / "lib/l10n/app_en.arb")
    rows: list[str] = ["path\tline\tlanguage\tliteral\tkeys\tsource"]
    for path in sorted(LIB.rglob("*.dart")):
        if any(part in EXCLUDED_PARTS for part in path.parts):
            continue
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
        for number, raw in enumerate(lines, start=1):
            line = raw.strip()
            if not line or line.startswith("//") or not any(marker in line for marker in DISPLAY_MARKERS):
                continue
            for match in STRING.finditer(line):
                value = unescape(match.group("value") or "")
                keys = vi.get(value) or en.get(value)
                if not keys or value in {"Text", "title", "message", "content", "label"}:
                    continue
                language = "VI" if value in vi else "EN"
                source = line.replace("\t", " ")
                rows.append(f"{path.relative_to(ROOT).as_posix()}\t{number}\t{language}\t{value}\t{','.join(keys)}\t{source}")
    OUT.write_text("\n".join(rows) + "\n", encoding="utf-8")
    print(f"WROTE={OUT}")
    print(f"MATCHES={len(rows)-1}")


if __name__ == "__main__":
    main()
