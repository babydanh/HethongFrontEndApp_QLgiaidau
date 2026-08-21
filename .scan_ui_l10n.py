from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parent
LIB = ROOT / "lib"
quoted = re.compile(r"(['\"])(?:(?!\1).)*[\u00C0-\u1EF9](?:(?!\1).)*\1")
ui_roots = ("features/", "shared/widgets/", "core/widgets/", "providers/")
excluded_parts = (
    "/l10n/",
    "/repositories/",
    "/models/",
    "/entities/",
    "/services/",
    "/strategy/",
    "_localizations",
)
ui_tokens = re.compile(
    r"\b(Text|RichText|InputDecoration|SnackBar|AlertDialog|showDialog|showModalBottomSheet|AppBar|Tooltip|label|title|hint|content|message|description|placeholder|empty|error|status|badge|TextSpan|Semantics)\b",
    re.IGNORECASE,
)
results = []
for path in LIB.rglob("*.dart"):
    rel = path.relative_to(ROOT).as_posix()
    if not rel.startswith("lib/"):
        continue
    if not any(rel.startswith("lib/" + root) for root in ui_roots):
        continue
    if any(part in rel for part in excluded_parts):
        continue
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except UnicodeDecodeError:
        continue
    for number, line in enumerate(lines, 1):
        stripped = line.strip()
        if stripped.startswith("//"):
            continue
        if quoted.search(line) and ui_tokens.search(line):
            results.append({"file": rel, "line": number, "text": stripped})
by_file = {}
for item in results:
    by_file.setdefault(item["file"], []).append(item)
out = {
    "ui_literal_line_count": len(results),
    "file_count": len(by_file),
    "files": [
        {"file": f, "count": len(items), "matches": items}
        for f, items in sorted(by_file.items(), key=lambda pair: (-len(pair[1]), pair[0]))
    ],
}
(ROOT / ".l10n-ui-audit.json").write_text(json.dumps(out, ensure_ascii=False, indent=2), encoding="utf-8")
print(f"UI_LITERAL_LINES={len(results)} FILES={len(by_file)}")
for item in out["files"][:100]:
    print(f"{item['count']:4} {item['file']}")
