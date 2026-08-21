from pathlib import Path
import re
ROOT = Path(__file__).resolve().parent
roots = (ROOT/'lib/features', ROOT/'lib/shared/widgets', ROOT/'lib/core/widgets')
quoted = re.compile(r"(['\"])(?P<value>(?:(?!\1).){2,})\1")
ui = re.compile(r"\b(Text|RichText|InputDecoration|SnackBar|AlertDialog|showDialog|showModalBottomSheet|AppBar|Tooltip|label|title|hintText|helperText|content|message|description|placeholder|empty|error|status|badge|Tab)\b", re.I)
ignore = re.compile(r"^(https?://|/|[A-Za-z0-9_./\\-]+$)|[{}$]")
lines=[]
for root in roots:
    if not root.exists(): continue
    for p in root.rglob('*.dart'):
        rel=p.relative_to(ROOT).as_posix()
        if '/l10n/' in rel or '_localizations' in rel: continue
        for n,line in enumerate(p.read_text(encoding='utf-8', errors='ignore').splitlines(),1):
            if not ui.search(line) or line.strip().startswith('//'): continue
            for m in quoted.finditer(line):
                v=m.group('value').strip()
                if len(v)<3 or ignore.search(v): continue
                if re.search(r'[A-Za-z]', v) and not re.search(r'[\u00C0-\u024F\u1E00-\u1EFF]', v):
                    lines.append((rel,n,line.strip()))
with (ROOT/'l10n_ui_en_audit_latest.log').open('w',encoding='utf-8') as f:
    f.write(f'UI_EN_CANDIDATES={len(lines)} FILES={len(set(x[0] for x in lines))}\n')
    for rel,n,line in lines:
        f.write(f'{rel}:{n}: {line}\n')
print(f'UI_EN_CANDIDATES={len(lines)} FILES={len(set(x[0] for x in lines))}')
for rel,n,line in lines[:200]: print(f'{rel}:{n}: {line}')
