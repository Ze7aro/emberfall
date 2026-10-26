"""Split the two supplied JPEG icon sheets and remove their baked backgrounds.

The extraction is deterministic: it keeps source pixels and builds an alpha
mask from the low-chroma background. It does not regenerate or repaint icons.
"""

from __future__ import annotations

import csv
import shutil
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
INPUT = ROOT / "tmp" / "icon_sheets"
OUTPUT = ROOT / "assets" / "ui" / "icon_exports_2026-09-24"


@dataclass(frozen=True)
class Entry:
    name: str
    box: tuple[int, int, int, int]


SHEET_01 = [
    Entry("settings", (0, 0, 512, 350)),
    Entry("mail", (512, 0, 1024, 350)),
    Entry("missions", (0, 350, 385, 720)),
    Entry("lock", (385, 350, 690, 720)),
    Entry("arrow", (690, 350, 1024, 720)),
    Entry("refresh", (0, 720, 380, 1024)),
    Entry("close", (380, 720, 690, 1024)),
    Entry("check", (690, 720, 1024, 1024)),
]

SHEET_02_NAMES = [
    "home", "character", "inventory", "dungeon_key", "portal_purple", "portal_cyan",
    "gold_stack", "gold_coins", "gold_pile", "gold_bag", "chest_common", "chest_rare",
    "chest_locked", "chest_epic", "gold_chest_open", "energy_bottle", "cancel", "confirm",
    "energy_bottles", "close_alt", "play", "pause", "target", "autoplay",
]


def dilate(mask: np.ndarray, radius: int) -> np.ndarray:
    if radius <= 0:
        return mask
    image = Image.fromarray((mask.astype(np.uint8) * 255), "L")
    return np.asarray(image.filter(ImageFilter.MaxFilter(radius * 2 + 1))) > 0


def erode(mask: np.ndarray, radius: int) -> np.ndarray:
    if radius <= 0:
        return mask
    image = Image.fromarray((mask.astype(np.uint8) * 255), "L")
    return np.asarray(image.filter(ImageFilter.MinFilter(radius * 2 + 1))) > 0


def connected_to_edge(candidate: np.ndarray) -> np.ndarray:
    """Return candidate pixels connected to the crop boundary (4-neighbour)."""
    h, w = candidate.shape
    seen = np.zeros_like(candidate, dtype=bool)
    stack: list[tuple[int, int]] = []
    for x in range(w):
        if candidate[0, x]: stack.append((0, x))
        if candidate[h - 1, x]: stack.append((h - 1, x))
    for y in range(h):
        if candidate[y, 0]: stack.append((y, 0))
        if candidate[y, w - 1]: stack.append((y, w - 1))
    while stack:
        y, x = stack.pop()
        if seen[y, x] or not candidate[y, x]:
            continue
        seen[y, x] = True
        if y: stack.append((y - 1, x))
        if y + 1 < h: stack.append((y + 1, x))
        if x: stack.append((y, x - 1))
        if x + 1 < w: stack.append((y, x + 1))
    return seen


def remove_thin_components(mask: np.ndarray) -> np.ndarray:
    """Discard detached horizontal JPEG/shadow remnants from adjacent cells."""
    h, w = mask.shape
    seen = np.zeros_like(mask, dtype=bool)
    cleaned = mask.copy()
    for start_y in range(h):
        for start_x in range(w):
            if seen[start_y, start_x] or not mask[start_y, start_x]:
                continue
            stack = [(start_y, start_x)]
            points: list[tuple[int, int]] = []
            seen[start_y, start_x] = True
            while stack:
                y, x = stack.pop()
                points.append((y, x))
                for ny in range(max(0, y - 1), min(h, y + 2)):
                    for nx in range(max(0, x - 1), min(w, x + 2)):
                        if not seen[ny, nx] and mask[ny, nx]:
                            seen[ny, nx] = True
                            stack.append((ny, nx))
            ys = [point[0] for point in points]
            xs = [point[1] for point in points]
            comp_h = max(ys) - min(ys) + 1
            comp_w = max(xs) - min(xs) + 1
            detached_top_strip = max(ys) < 24 and comp_h < 22
            very_thin_strip = comp_h <= 18 and comp_w >= comp_h * 5
            if detached_top_strip or very_thin_strip:
                for y, x in points:
                    cleaned[y, x] = False
    return cleaned


def extract(crop: Image.Image, checkerboard: bool) -> Image.Image:
    rgb = np.asarray(crop.convert("RGB"), dtype=np.int16)
    hi = rgb.max(axis=2)
    lo = rgb.min(axis=2)
    chroma = hi - lo
    value = rgb.mean(axis=2)

    if checkerboard:
        # The JPEG checkerboard is neutral gray. Icon outlines and shadows are
        # protected when they sit near colored/highlighted object pixels.
        background_like = (chroma <= 11) & (value >= 38) & (value <= 145)
        core = (chroma >= 16) | (value >= 155)
        near_core = dilate(core, 5)
    else:
        # Sheet 1 uses a dark, nearly neutral stone texture.
        background_like = (chroma <= 14) & (value >= 20) & (value <= 125)
        core = (chroma >= 19) | (value >= 145)
        near_core = dilate(core, 6)

    open_background = connected_to_edge(background_like)
    foreground = (~open_background) & dilate(core, 10)
    # Keep dark pixel outlines directly surrounding the colored object.
    foreground |= near_core & (~background_like)
    # Smooth one-pixel JPEG pinholes, while retaining a hard pixel-art edge.
    foreground = dilate(erode(foreground, 1), 1)
    foreground = remove_thin_components(foreground)

    ys, xs = np.where(foreground)
    if len(xs) == 0:
        raise RuntimeError("No foreground found")
    pad = 8
    left = max(0, int(xs.min()) - pad)
    top = max(0, int(ys.min()) - pad)
    right = min(crop.width, int(xs.max()) + pad + 1)
    bottom = min(crop.height, int(ys.max()) + pad + 1)

    rgba = np.dstack((rgb.astype(np.uint8), foreground.astype(np.uint8) * 255))
    return Image.fromarray(rgba, "RGBA").crop((left, top, right, bottom))


def save_contact_sheet(paths: list[Path]) -> None:
    columns, cell_w, cell_h = 6, 220, 210
    rows = (len(paths) + columns - 1) // columns
    for filename, background, label_color in (
        ("preview_dark.jpg", (22, 24, 36, 255), (242, 242, 248, 255)),
        ("preview_light.jpg", (230, 232, 238, 255), (28, 30, 40, 255)),
    ):
        canvas = Image.new("RGBA", (columns * cell_w, rows * cell_h), background)
        draw = ImageDraw.Draw(canvas)
        for i, path in enumerate(paths):
            icon = Image.open(path).convert("RGBA")
            icon.thumbnail((180, 170), Image.Resampling.NEAREST)
            x = (i % columns) * cell_w
            y = (i // columns) * cell_h
            canvas.alpha_composite(icon, (x + (cell_w - icon.width) // 2, y + 4))
            draw.text((x + 8, y + 182), path.stem, fill=label_color)
        canvas.convert("RGB").save(OUTPUT / filename, quality=95)


def main() -> None:
    if OUTPUT.exists():
        shutil.rmtree(OUTPUT)
    OUTPUT.mkdir(parents=True)
    exported: list[Path] = []
    records: list[dict[str, str | int]] = []

    source1 = Image.open(INPUT / "sheet_01.jfif").convert("RGB")
    for index, entry in enumerate(SHEET_01, 1):
        icon = extract(source1.crop(entry.box), checkerboard=False)
        path = OUTPUT / f"{index:02d}_{entry.name}.png"
        icon.save(path)
        exported.append(path)
        records.append({"file": path.name, "source": "sheet_01", "row": "mixed", "column": "mixed"})

    source2 = Image.open(INPUT / "sheet_02.jfif").convert("RGB")
    for index, name in enumerate(SHEET_02_NAMES):
        row, column = divmod(index, 6)
        box = (column * 240, row * 180, (column + 1) * 240, (row + 1) * 180)
        icon = extract(source2.crop(box), checkerboard=True)
        path = OUTPUT / f"{index + 9:02d}_{name}.png"
        icon.save(path)
        exported.append(path)
        records.append({"file": path.name, "source": "sheet_02", "row": row, "column": column})

    with (OUTPUT / "index.csv").open("w", newline="", encoding="utf-8-sig") as handle:
        writer = csv.DictWriter(handle, fieldnames=["file", "source", "row", "column"])
        writer.writeheader()
        writer.writerows(records)

    (OUTPUT / "README.md").write_text(
        "# Iconos individuales\n\n"
        "Esta carpeta contiene 32 iconos separados de las dos láminas entregadas.\n\n"
        "- Formato: PNG RGBA.\n"
        "- Fondo: transparente.\n"
        "- Contenido: píxeles originales de las imágenes, sin regeneración ni cambio de estilo.\n"
        "- Nombres: numeración estable seguida de una descripción funcional.\n"
        "- `index.csv`: relación entre cada archivo y su posición de origen.\n"
        "- `preview_dark.jpg` y `preview_light.jpg`: controles visuales; no son assets del juego.\n\n"
        "Las imágenes de entrada eran JPEG. La transparencia se reconstruyó eliminando "
        "el fondo oscuro de la primera lámina y el damero incrustado de la segunda. "
        "Puede existir compresión JPEG dentro de los propios iconos de origen.\n",
        encoding="utf-8",
    )

    save_contact_sheet(exported)
    print(f"Exported {len(exported)} icons to {OUTPUT}")


if __name__ == "__main__":
    main()
