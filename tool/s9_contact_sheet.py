#!/usr/bin/env python3
"""84-screen contact sheet: design | render, light mode, local files only."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
COMPARE = ROOT / "test" / "goldens" / "compare"
OUT = COMPARE / "s9" / "contact-sheet.png"

SCREENS: list[str] = (
    [f"01-0{i}" for i in range(1, 4)]
    + [f"02-{i:02d}" for i in range(1, 12)]
    + [f"03-{i:02d}" for i in range(1, 10)]
    + [f"04-{i:02d}" for i in range(1, 9)]
    + [f"05-{i:02d}" for i in range(1, 24)]
    + [f"06-{i:02d}" for i in range(1, 9)]
    + [f"07-{i:02d}" for i in range(1, 13)]
    + [f"08-{i:02d}" for i in range(1, 11)]
)


def _source(screen: str) -> tuple[Path, int, Path, int]:
    """Return design path, design panel, render path, render panel.

    A 3510-wide file is design | render | heat. Panel 0 is the design and
    panel 1 is the render. A 1170-wide file is used whole.
    """
    group = screen[:2]
    if group == "01":
        return (
            COMPARE / f"welcome_{screen}.png",
            0,
            ROOT / "test" / "goldens" / "welcome" / f"{screen}.png",
            0,
        )
    if group == "02":
        return (
            COMPARE / "s2" / f"{screen}.png",
            0,
            COMPARE / "s9" / f"{screen}.png",
            1,
        )
    folder = {"03": "s3", "04": "s4", "05": "s5", "06": "s6", "07": "s7", "08": "s8"}[
        group
    ]
    path = COMPARE / folder / f"{screen}.png"
    return path, 0, path, 1


def _panel(path: Path, index: int) -> Image.Image:
    image = Image.open(path).convert("RGB")
    if image.width >= 3510:
        image = image.crop((index * 1170, 0, (index + 1) * 1170, 2532))
    if image.size != (1170, 2532):
        raise SystemExit(f"{path} panel {index} is {image.size}")
    return image.resize((94, 203), Image.Resampling.BOX)


def main() -> None:
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--sha", required=True, help="Full tip SHA the renders were painted from")
    args = parser.parse_args()
    sha = args.sha.strip()
    if len(sha) != 40 or any(c not in "0123456789abcdef" for c in sha):
        raise SystemExit(f"expected a 40-character sha, got {sha!r}")
    if len(SCREENS) != 84:
        raise SystemExit(f"expected 84 screens, got {len(SCREENS)}")
    columns = 7
    rows = 12
    cell_w, cell_h = 210, 236
    margin = 16
    header = 44
    width = margin * 2 + columns * cell_w
    height = margin * 2 + header + rows * cell_h
    sheet = Image.new("RGB", (width, height), (221, 227, 238))
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()
    draw.text((margin, 6), "Taytay resident app — 84 screens, design | render", fill=(6, 35, 88), font=font)
    draw.text((margin, 22), sha, fill=(11, 61, 145), font=font)
    for index, screen in enumerate(SCREENS):
        design_path, design_i, render_path, render_i = _source(screen)
        column = index % columns
        row = index // columns
        x = margin + column * cell_w
        y = margin + header + row * cell_h
        design = _panel(design_path, design_i)
        render = _panel(render_path, render_i)
        sheet.paste(design, (x, y + 16))
        sheet.paste(render, (x + 98, y + 16))
        draw.text((x, y), screen, fill=(15, 26, 51), font=font)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(OUT, optimize=True)
    print(f"wrote {OUT} {sheet.size} {OUT.stat().st_size} bytes")


if __name__ == "__main__":
    main()
