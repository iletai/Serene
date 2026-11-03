#!/usr/bin/env python3
"""Turn `xcresulttool export attachments` output into a self-contained screenshot gallery.

Usage: gallery.py <export-dir> <out-dir>
Reads <export-dir>/manifest.json, copies attachments named `<screen>--<variant>` to
<out-dir>/<screen>--<variant>.<ext>, writes <out-dir>/index.html and <out-dir>/summary.md.
"""
import html
import json
import re
import shutil
import sys
from pathlib import Path

VARIANTS = ["light", "dark", "xxxl", "xxxl-bottom"]
# xcresulttool suggests "<attachment name>_<index>_<UUID>.<ext>".
SUFFIX = re.compile(r"_\d+_[0-9A-Fa-f-]{36}$")


def attachment_name(suggested: str) -> str:
    return SUFFIX.sub("", Path(suggested).stem)


def collect(export_dir: Path, out_dir: Path) -> dict:
    manifest = json.loads((export_dir / "manifest.json").read_text())
    shots: dict = {}
    for test in manifest:
        for item in test.get("attachments", []):
            name = attachment_name(item["suggestedHumanReadableName"])
            if "--" not in name:
                continue
            screen, variant = name.split("--", 1)
            source = export_dir / item["exportedFileName"]
            target = f"{name}{source.suffix or '.png'}"
            shutil.copyfile(source, out_dir / target)
            shots.setdefault(screen, {})[variant] = target
    return shots


def render(shots: dict) -> str:
    head = "".join(f"<th>{v}</th>" for v in VARIANTS)
    rows = []
    for screen in sorted(shots):
        cells = []
        for variant in VARIANTS:
            file = shots[screen].get(variant)
            if file:
                src = html.escape(file)
                cells.append(f'<td><a href="{src}"><img src="{src}" loading="lazy" alt="{src}"></a></td>')
            else:
                cells.append("<td class=missing>-</td>")
        rows.append(f"<tr><th scope=row>{html.escape(screen)}</th>{''.join(cells)}</tr>")
    return f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>An Niên UI gallery</title>
<style>
:root {{ color-scheme: light dark; font-family: -apple-system, system-ui, sans-serif; }}
body {{ margin: 16px; background: #FEF9F1; color: #1D1C17; }}
@media (prefers-color-scheme: dark) {{ body {{ background: #1D1C17; color: #FEF9F1; }} }}
.wrap {{ overflow-x: auto; }}
table {{ border-collapse: collapse; }}
th, td {{ padding: 8px; vertical-align: top; text-align: left; }}
thead th {{ position: sticky; top: 0; background: inherit; }}
img {{ width: min(240px, 40vw); height: auto; border: 1px solid #C5A05966; border-radius: 12px; }}
.missing {{ opacity: .5; }}
</style></head><body>
<h1>An Niên UI gallery</h1>
<p>{len(shots)} screens, {sum(len(v) for v in shots.values())} screenshots. Click an image for full size.</p>
<div class="wrap"><table><thead><tr><th>screen</th>{head}</tr></thead>
<tbody>{''.join(rows)}</tbody></table></div>
</body></html>
"""


def main() -> None:
    export_dir, out_dir = Path(sys.argv[1]), Path(sys.argv[2])
    out_dir.mkdir(parents=True, exist_ok=True)
    shots = collect(export_dir, out_dir)
    (out_dir / "index.html").write_text(render(shots))
    total = sum(len(v) for v in shots.values())
    lines = [f"**{len(shots)} screens, {total} screenshots**", ""]
    lines += [f"- {s}: {', '.join(v for v in VARIANTS if v in shots[s])}" for s in sorted(shots)]
    (out_dir / "summary.md").write_text("\n".join(lines) + "\n")
    print(f"gallery: {len(shots)} screens, {total} screenshots -> {out_dir / 'index.html'}")


if __name__ == "__main__":
    main()
