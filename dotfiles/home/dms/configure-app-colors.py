#!/usr/bin/env python3
"""Add DMS colors without replacing desktop-managed settings."""
from pathlib import Path
import re
import sys

config = Path(sys.argv[1])

for toolkit in ("gtk-3.0", "gtk-4.0"):
    path = config / toolkit / "gtk.css"
    if path.is_symlink():
        print(f"Skipping managed GTK CSS: {path}", file=sys.stderr)
        continue
    path.parent.mkdir(parents=True, exist_ok=True)
    content = path.read_text() if path.exists() else ""
    if not re.search(r"@import\s+(?:url\()?\s*['\"]?dank-colors\.css", content):
        # CSS imports must precede ordinary rules.
        path.write_text('@import url("dank-colors.css");\n' + content)

for toolkit in ("qt5ct", "qt6ct"):
    path = config / toolkit / f"{toolkit}.conf"
    scheme = path.parent / "colors" / "matugen.conf"
    if path.is_symlink():
        print(f"Skipping managed Qt config: {path}", file=sys.stderr)
        continue
    path.parent.mkdir(parents=True, exist_ok=True)
    content = path.read_text() if path.exists() else ""
    header = re.search(r"(?m)^\[Appearance\]\s*$", content)
    if not header:
        content = content.rstrip() + "\n\n[Appearance]\n"
        header = re.search(r"(?m)^\[Appearance\]\s*$", content)
    start = header.end()
    next_section = re.search(r"(?m)^\[", content[start:])
    end = start + next_section.start() if next_section else len(content)
    section = content[start:end]
    section = re.sub(r"(?m)^(?:custom_palette|color_scheme_path)=.*\n?", "", section)
    content = content[:start] + f"\ncustom_palette=true\ncolor_scheme_path={scheme}\n" + section.lstrip("\n") + content[end:]
    path.write_text(content)
