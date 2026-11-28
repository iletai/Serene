#!/usr/bin/env python3
"""Turn `xcresulttool export attachments` output into the UI Screenshot Gallery.

Usage: gallery.py <export-dir> <out-dir> [--image-base URL] [--title T --device D --locale L --sha S --build N --artifact-url U]

Reads <export-dir>/manifest.json; attachments named `<screen>--<variant>` become
  <out-dir>/full/<name>.png    full resolution (artifact)
  <out-dir>/thumbs/<name>.jpg  downscaled (published to the ui-gallery branch)
  <out-dir>/index.html         offline gallery (artifact)
  <out-dir>/summary.md         GitHub Job Summary / PR comment; images are <img src="{image-base}/<name>.jpg">
"""
import argparse
import html
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

ORDER = ["light", "dark", "xxxl", "xxxl-bottom"]  # Serene variants; unknown ones follow alphabetically
THUMB_PX = 480
# xcresulttool suggests "<attachment name>_<index>_<UUID>.<ext>".
SUFFIX = re.compile(r"_\d+_[0-9A-Fa-f-]{36}$")


def attachment_name(suggested: str) -> str:
    return SUFFIX.sub("", Path(suggested).stem)


def thumbnail(src: Path, dst: Path) -> None:
    # shortcut: sips is macOS-only, runs on the macOS runner; falls back to the original elsewhere.
    cmd = ["sips", "-Z", str(THUMB_PX), "-s", "format", "jpeg", "-s", "formatOptions", "70", str(src), "--out", str(dst)]
    try:
        subprocess.run(cmd, check=True, capture_output=True)
    except (OSError, subprocess.CalledProcessError):
        shutil.copyfile(src, dst)


def collect(export_dir: Path, out_dir: Path) -> dict:
    (out_dir / "full").mkdir(parents=True, exist_ok=True)
    (out_dir / "thumbs").mkdir(parents=True, exist_ok=True)
    shots: dict = {}
    for test in json.loads((export_dir / "manifest.json").read_text()):
        for item in test.get("attachments", []):
            name = attachment_name(item["suggestedHumanReadableName"])
            if "--" not in name:
                continue
            screen, variant = name.split("--", 1)
            source = export_dir / item["exportedFileName"]
            shutil.copyfile(source, out_dir / "full" / f"{name}.png")
            thumbnail(source, out_dir / "thumbs" / f"{name}.jpg")
            shots.setdefault(screen, {})[variant] = name
    return shots


def variants(shots: dict) -> list:
    found = {v for s in shots.values() for v in s}
    return [v for v in ORDER if v in found] + sorted(found - set(ORDER))


def meta_line(a) -> str:
    parts = [("device", a.device), ("locale", a.locale), ("commit", a.sha[:7]), ("build", a.build)]
    return " | ".join(f"{k}: `{v}`" for k, v in parts if v)


def summary(shots: dict, a) -> str:
    cols = variants(shots)
    lines = [f"## {a.title}", "", meta_line(a)]
    if a.artifact_url:
        lines += ["", f"Full resolution + offline `index.html`: [artifact ui-gallery]({a.artifact_url})"]
    if not shots:
        return "\n".join(lines + ["", "No screenshots were produced."]) + "\n"
    lines += ["", "| screen | " + " | ".join(cols) + " |", "|---|" + "---|" * len(cols)]
    for screen in sorted(shots):
        def cell(v: str) -> str:
            if v not in shots[screen]:
                return "-"
            return f'<img src="{a.image_base}/{shots[screen][v]}.jpg?raw=true" width="160" alt="{screen} {v}">' if a.image_base else "captured"

        cells = [cell(v) for v in cols]
        lines.append(f"| {screen} | " + " | ".join(cells) + " |")
    return "\n".join(lines) + "\n"


def index_html(shots: dict, a) -> str:
    cols = variants(shots)
    head = "".join(f"<th>{html.escape(v)}</th>" for v in cols)
    rows = []
    for screen in sorted(shots):
        cells = "".join(
            f'<td><a href="full/{shots[screen][v]}.png"><img src="thumbs/{shots[screen][v]}.jpg" loading="lazy"></a></td>'
            if v in shots[screen] else "<td>-</td>"
            for v in cols
        )
        rows.append(f"<tr><th scope=row>{html.escape(screen)}</th>{cells}</tr>")
    meta = html.escape(meta_line(a).replace("`", ""))
    return f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>{html.escape(a.title)}</title>
<style>
:root {{ color-scheme: light dark; font-family: -apple-system, system-ui, sans-serif; }}
body {{ margin: 16px; }}
.wrap {{ overflow-x: auto; }}
th, td {{ padding: 8px; vertical-align: top; text-align: left; }}
img {{ width: min(240px, 40vw); height: auto; border: 1px solid #8884; border-radius: 12px; }}
</style></head><body>
<h1>{html.escape(a.title)}</h1><p>{meta}</p>
<div class="wrap"><table><thead><tr><th>screen</th>{head}</tr></thead><tbody>{''.join(rows)}</tbody></table></div>
</body></html>
"""


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("export_dir", type=Path)
    p.add_argument("out_dir", type=Path)
    p.add_argument("--image-base", default="")  # empty: list names only (no published images)
    p.add_argument("--title", default="UI Screenshot Gallery")
    for k in ("device", "locale", "sha", "build", "artifact-url"):
        p.add_argument(f"--{k}", default="")
    a = p.parse_args()
    a.out_dir.mkdir(parents=True, exist_ok=True)
    shots = collect(a.export_dir, a.out_dir)
    (a.out_dir / "index.html").write_text(index_html(shots, a))
    (a.out_dir / "summary.md").write_text(summary(shots, a))
    print(f"gallery: {len(shots)} screens, {sum(len(v) for v in shots.values())} screenshots -> {a.out_dir}", file=sys.stderr)


if __name__ == "__main__":
    main()
