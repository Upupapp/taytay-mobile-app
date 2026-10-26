#!/usr/bin/env python3
"""Review measure for a 1170×2532 design against a render.

A row is dark when any pixel from x 60 to 1110 has mean RGB below 110.
Runs shorter than 8 rows are dropped. Pairing is in order. Deviation is
the start row, in image pixels.

Stroke edges are rows with more than 400 pixels of exact #E7EBF3
(231, 235, 243) in x 120 to 1050. A run of those rows is one edge.

Sheet edges are the first row of a white band in x 200 to 900: at least
90 percent of the band is RGB ≥ 252, and the row above that band is
under 45 percent white. Auth sheets are this edge. A screen with no
#E7EBF3 strokes reports "strokes none". An empty list is not a match.

Mismatch is CIE76 ΔE above 6 over the full frame.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image


def _load(path: Path) -> np.ndarray:
    image = Image.open(path).convert("RGB")
    array = np.asarray(image)
    if array.shape[1] == 3510:
        array = array[:, :1170]
    if array.shape != (2532, 1170, 3):
        raise SystemExit(f"{path} is {array.shape}, expected 2532×1170")
    return array


def _runs(mask: np.ndarray, minimum: int) -> list[tuple[int, int]]:
    runs: list[tuple[int, int]] = []
    start = None
    for index, on in enumerate(mask.tolist()):
        if on and start is None:
            start = index
        elif not on and start is not None:
            if index - start >= minimum:
                runs.append((start, index - 1))
            start = None
    if start is not None and len(mask) - start >= minimum:
        runs.append((start, len(mask) - 1))
    return runs


def dark_runs(image: np.ndarray) -> list[tuple[int, int]]:
    band = image[:, 60:1110].astype(np.int16)
    mean = band.mean(axis=2)
    dark = (mean < 110).any(axis=1)
    return _runs(dark, 8)


def stroke_edges(image: np.ndarray) -> list[tuple[int, int]]:
    band = image[:, 120:1050]
    exact = (
        (band[:, :, 0] == 231) & (band[:, :, 1] == 235) & (band[:, :, 2] == 243)
    )
    rows = exact.sum(axis=1) > 400
    return _runs(rows, 1)


def sheet_edges(image: np.ndarray) -> list[int]:
    """First rows of a sustained white sheet in x 200–900.

    A row qualifies when it is at least 90 percent white, the row above is
    under 45 percent white, and the next 24 rows stay mostly white. Short
    gaps between letters are not sheets. An empty list is not a match.
    """
    band = image[:, 200:900]
    white = (band >= 252).all(axis=2)
    frac = white.mean(axis=1)
    edges: list[int] = []
    for y in range(1, len(frac) - 24):
        if frac[y] < 0.90 or frac[y - 1] >= 0.45:
            continue
        window = frac[y : y + 24]
        if (window >= 0.70).mean() > 0.8:
            edges.append(y)
    return edges


def _lab(rgb: np.ndarray) -> np.ndarray:
    channel = rgb.astype(np.float64) / 255.0
    linear = np.where(
        channel <= 0.04045,
        channel / 12.92,
        ((channel + 0.055) / 1.055) ** 2.4,
    )
    r, g, b = linear[:, :, 0], linear[:, :, 1], linear[:, :, 2]
    x = (r * 0.4124564 + g * 0.3575761 + b * 0.1804375) / 0.95047
    y = (r * 0.2126729 + g * 0.7151522 + b * 0.0721750)
    z = (r * 0.0193339 + g * 0.1191920 + b * 0.9503041) / 1.08883

    def f(t: np.ndarray) -> np.ndarray:
        return np.where(t > 0.008856, np.cbrt(t), (7.787 * t) + (16 / 116))

    fx, fy, fz = f(x), f(y), f(z)
    return np.stack((116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)), axis=2)


def mismatch(design: np.ndarray, render: np.ndarray) -> tuple[int, int]:
    delta = _lab(design) - _lab(render)
    distance = np.sqrt((delta * delta).sum(axis=2))
    differing = int((distance > 6).sum())
    return differing, design.shape[0] * design.shape[1]


def heat(design: np.ndarray, render: np.ndarray) -> np.ndarray:
    delta = _lab(design) - _lab(render)
    distance = np.sqrt((delta * delta).sum(axis=2))
    differs = distance > 6
    dim = (render.astype(np.float32) * 0.35).astype(np.uint8)
    painted = dim.copy()
    painted[differs] = (220, 40, 40)
    return painted


def _pair(left: list, right: list) -> int | None:
    if len(left) != len(right) or not left:
        return None
    return max(abs(a[0] - b[0]) for a, b in zip(left, right))


def _pair_points(left: list[int], right: list[int]) -> int | None:
    if len(left) != len(right) or not left:
        return None
    return max(abs(a - b) for a, b in zip(left, right))


def report(name: str, design: np.ndarray, render: np.ndarray) -> str:
    d_lines, r_lines = dark_runs(design), dark_runs(render)
    d_strokes, r_strokes = stroke_edges(design), stroke_edges(render)
    d_sheet, r_sheet = sheet_edges(design), sheet_edges(render)
    differing, total = mismatch(design, render)
    line_dev = _pair(d_lines, r_lines)
    line_text = (
        f"{line_dev}px" if line_dev is not None else f"count {len(r_lines)}/{len(d_lines)}"
    )
    if not d_strokes and not r_strokes:
        stroke_text = "strokes none"
    else:
        stroke_dev = _pair(d_strokes, r_strokes)
        stroke_text = (
            f"strokes {len(r_strokes)}/{len(d_strokes)} dev {stroke_dev}px"
            if stroke_dev is not None
            else f"strokes {len(r_strokes)}/{len(d_strokes)}"
        )
    if not d_sheet and not r_sheet:
        sheet_text = "sheet none"
    else:
        sheet_dev = _pair_points(d_sheet[:1], r_sheet[:1])
        first = (
            f"first {r_sheet[0]}/{d_sheet[0]} dev {sheet_dev}px"
            if sheet_dev is not None
            else f"first design {d_sheet[:1]} render {r_sheet[:1]}"
        )
        sheet_text = f"sheet {len(r_sheet)}/{len(d_sheet)} {first}"
    percent = differing * 100 / total
    return (
        f"{name} lines {len(r_lines)}/{len(d_lines)} dev {line_text} "
        f"{stroke_text} {sheet_text} "
        f"mismatch {percent:.2f}% ({differing})"
    )


def side_by_side(design: np.ndarray, render: np.ndarray) -> Image.Image:
    canvas = Image.new("RGB", (3510, 2532))
    canvas.paste(Image.fromarray(design), (0, 0))
    canvas.paste(Image.fromarray(render), (1170, 0))
    canvas.paste(Image.fromarray(heat(design, render)), (2340, 0))
    return canvas


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--design", type=Path, required=True)
    parser.add_argument("--render", type=Path, required=True)
    parser.add_argument("--out", type=Path)
    parser.add_argument("--name", default="")
    args = parser.parse_args()
    design = _load(args.design)
    render = _load(args.render)
    name = args.name or args.render.stem
    print(report(name, design, render))
    if args.out:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        side_by_side(design, render).save(args.out)


if __name__ == "__main__":
    main()
