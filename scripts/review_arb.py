import json
import re
from pathlib import Path

vi_path = Path('lib/l10n/app_vi.arb')
en_path = Path('lib/l10n/app_en.arb')
vi = json.loads(vi_path.read_text(encoding='utf-8'))
en = json.loads(en_path.read_text(encoding='utf-8'))

base_vi = {key: value for key, value in vi.items() if not key.startswith('@')}
base_en = {key: value for key, value in en.items() if not key.startswith('@')}
print(f'VI_BASE_KEYS={len(base_vi)}')
print(f'EN_BASE_KEYS={len(base_en)}')
print(f'MISSING_IN_EN={sorted(set(base_vi) - set(base_en))}')
print(f'MISSING_IN_VI={sorted(set(base_en) - set(base_vi))}')

placeholder_re = re.compile(r'\{([A-Za-z_][A-Za-z0-9_]*)\}')
def placeholders(value):
    return sorted(set(placeholder_re.findall(value))) if isinstance(value, str) else []

placeholder_mismatches = []
for key in sorted(set(base_vi) & set(base_en)):
    vi_ph = placeholders(base_vi[key])
    en_ph = placeholders(base_en[key])
    if vi_ph != en_ph:
        placeholder_mismatches.append((key, vi_ph, en_ph))
print(f'PLACEHOLDER_MISMATCHES={len(placeholder_mismatches)}')
for item in placeholder_mismatches:
    print(item)

metadata_missing = []
metadata_mismatch = []
for key, value in base_vi.items():
    expected = f'@{key}'
    if placeholders(value) and expected not in vi:
        metadata_missing.append(('vi', key, placeholders(value)))
    if placeholders(base_en.get(key, '')) and expected not in en:
        metadata_missing.append(('en', key, placeholders(base_en[key])))
    if expected in vi and expected in en:
        vi_meta = vi[expected].get('placeholders', {}) if isinstance(vi[expected], dict) else {}
        en_meta = en[expected].get('placeholders', {}) if isinstance(en[expected], dict) else {}
        if sorted(vi_meta) != sorted(en_meta):
            metadata_mismatch.append((key, sorted(vi_meta), sorted(en_meta)))
print(f'METADATA_MISSING={len(metadata_missing)}')
for item in metadata_missing:
    print(item)
print(f'METADATA_MISMATCHES={len(metadata_mismatch)}')
for item in metadata_mismatch:
    print(item)

empty = []
for locale, catalog in [('vi', base_vi), ('en', base_en)]:
    for key, value in catalog.items():
        if isinstance(value, str) and not value.strip():
            empty.append((locale, key))
print(f'EMPTY_VALUES={len(empty)}')
for item in empty:
    print(item)

same = []
for key in sorted(set(base_vi) & set(base_en)):
    if base_vi[key] == base_en[key] and isinstance(base_vi[key], str):
        same.append(key)
print(f'IDENTICAL_VALUES={len(same)}')
print('IDENTICAL_SAMPLE=', same[:30])
