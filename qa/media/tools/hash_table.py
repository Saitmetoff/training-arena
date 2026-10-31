"""Print the asset hash table used by docs/media/FORM_REVIEW.md.

Usage (from the repository root):
    python qa/media/tools/hash_table.py
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from arena_athlete.spec import ASSET_ROOT, REPO_ROOT  # noqa: E402


def main() -> int:
    manifest = json.loads((ASSET_ROOT / "manifest.json").read_text(encoding="utf-8"))
    for label, entry in [
        ("models.athlete", manifest["models"]["athlete"]),
    ] + [
        (f"{exercise}.{name}", entry)
        for exercise, record in manifest["exercises"].items()
        for name, entry in record["assets"].items()
    ]:
        print(
            f"| `{label}` | `{entry['asset']}` | {entry['bytes']} | `{entry['sha256']}` |"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
