from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parent
LIB = ROOT / "lib"
# Look for quoted literals containing Vietnamese diacritics.
quoted = re.compile(r"(['\"])(?:(?!\1).)*[\u00C0-\u1EF9](?:(?!\1).)*\1")
results = []
for path in LIB.rglob("*.dart"):
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except UnicodeDecodeError:
        continue
    for number, line in enumerate(lines, 1):
        stripped = line.strip()
        if stripped.startswith("//"):
            continue
        if quoted.search(line):
            results.append({
                "file": str(path.relative_to(ROOT)).replace("\\", "/"),
                "line": number,
                "text": stripped,
            })
by_file = {}
for item in results:
    by_file.setdefault(item["file"], 0)
    by_file[item["file"]] += 1
summary = {
    "literal_line_count": len(results),
    "file_count": len(by_file),
    "files": sorted(by_file.items(), key=lambda pair: (-pair[1], pair[0])),
    "matches": results,
}
(ROOT / ".l10n-hardcoded-scan.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
print(f"LITERAL_LINES={len(results)} FILES={len(by_file)}")
for filename, count in summary["files"][:80]:
    print(f"{count:4} {filename}")
