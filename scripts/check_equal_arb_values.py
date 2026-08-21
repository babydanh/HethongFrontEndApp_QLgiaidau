from __future__ import annotations

import json
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")

root = Path(__file__).resolve().parents[1] / "lib" / "l10n"
vi = json.loads((root / "app_vi.arb").read_text(encoding="utf-8"))
en = json.loads((root / "app_en.arb").read_text(encoding="utf-8"))
for key, vi_value in vi.items():
    if key.startswith("@") or not isinstance(vi_value, str):
        continue
    en_value = en.get(key)
    if isinstance(en_value, str) and en_value == vi_value:
        print(f"{key}\t{vi_value}")
