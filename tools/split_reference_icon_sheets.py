"""Split the user-provided reference atlases into unchanged grid-cell PNGs.

The output is a browsing/reference library only. It does not import these
third-party sprites into the game or apply edits to their pixels.
"""

from __future__ import annotations

import csv
import shutil
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw


PROJECT = Path(__file__).resolve().parents[1]
OUT = PROJECT / "assets" / "ui" / "reference_icon_sheets"


@dataclass(frozen=True)
class Sheet:
    slug: str
    filename: str
    columns: int
    rows: int
    cell_width: int
    cell_height: int
    offset_x: int = 0
    offset_y: int = 0


SHEETS = [
    Sheet(
        "bof6_item_boosters",
        "Mobile - Breath of Fire 6 - Icons - Item Boosters.png",
        11, 11, 66, 66,
    ),
    Sheet(
        "bof6_materials",
        "Mobile - Breath of Fire 6 - Icons - Materials.png",
        11, 27, 66, 66,
    ),
    Sheet(
        "bof6_miscellaneous",
        "Mobile - Breath of Fire 6 - Icons - Miscellaneous.png",
        9, 23, 66, 66,
    ),
    Sheet(
        "rpgmaker_vxace_miscellaneous",
        "PC _ Computer - RPG Maker VX Ace - Miscellaneous - Icons.png",
        16, 33, 24, 24,
    ),
    Sheet(
        "ffxiii_status_icons",
        "PlayStation 3 - Final Fantasy XIII - Miscellaneous - Status Icons.png",
        8, 7, 30, 30, 3, 3,
    ),
]


def is_empty(tile: Image.Image, opaque_black_sheet: bool) -> bool:
    rgba = tile.convert("RGBA")
    if opaque_black_sheet:
        # Breath of Fire sheets are flattened over opaque black.
        extrema = rgba.getchannel("R").getextrema()
        green = rgba.getchannel("G").getextrema()
        blue = rgba.getchannel("B").getextrema()
        return max(extrema[1], green[1], blue[1]) <= 12
    return rgba.getchannel("A").getbbox() is None


def visible_bounds(tile: Image.Image, opaque_black_sheet: bool) -> tuple[int, int, int, int] | None:
    rgba = tile.convert("RGBA")
    if opaque_black_sheet:
        mask = Image.new("L", tile.size, 0)
        src = rgba.load()
        dst = mask.load()
        for y in range(tile.height):
            for x in range(tile.width):
                r, g, b, _a = src[x, y]
                if max(r, g, b) > 12:
                    dst[x, y] = 255
        return mask.getbbox()
    return rgba.getchannel("A").getbbox()


def make_contact_sheet(
    tiles: list[tuple[int, int, str, Image.Image, tuple[int, int, int, int] | None]],
    columns: int,
    dest: Path,
) -> None:
    thumb = 64
    label_height = 14
    gutter = 4
    rows = (len(tiles) + columns - 1) // columns
    width = gutter + columns * (thumb + gutter)
    height = gutter + rows * (thumb + label_height + gutter)
    sheet = Image.new("RGBA", (width, height), (21, 24, 38, 255))
    draw = ImageDraw.Draw(sheet)
    for i, (_row, _col, name, tile, _bounds) in enumerate(tiles):
        x = gutter + (i % columns) * (thumb + gutter)
        y = gutter + (i // columns) * (thumb + label_height + gutter)
        preview = tile.convert("RGBA")
        preview.thumbnail((thumb, thumb), Image.Resampling.NEAREST)
        px = x + (thumb - preview.width) // 2
        py = y + (thumb - preview.height) // 2
        sheet.alpha_composite(preview, (px, py))
        draw.text((x + 2, y + thumb), name, fill=(236, 237, 244, 255))
    dest.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(dest)


def split(sheet: Sheet) -> int:
    source = Path.home() / "Downloads" / sheet.filename
    if not source.is_file():
        raise FileNotFoundError(source)

    base = OUT / sheet.slug
    originals = base / "originals"
    sprites = base / "sprites"
    originals.mkdir(parents=True, exist_ok=True)
    sprites.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, originals / sheet.filename)

    image = Image.open(source)
    rows: list[tuple[int, int, str, Image.Image, tuple[int, int, int, int] | None]] = []
    opaque_black_sheet = sheet.slug.startswith("bof6_")
    records: list[dict[str, str | int]] = []
    for row in range(sheet.rows):
        for col in range(sheet.columns):
            x = sheet.offset_x + col * sheet.cell_width
            y = sheet.offset_y + row * sheet.cell_height
            tile = image.crop((x, y, x + sheet.cell_width, y + sheet.cell_height))
            if is_empty(tile, opaque_black_sheet):
                continue
            bounds = visible_bounds(tile, opaque_black_sheet)
            if sheet.slug == "ffxiii_status_icons" and bounds is not None:
                bx, by, br, bb = bounds
                # Ignore clipped fragments beneath the final complete icon row.
                if br - bx < 10 or bb - by < 12:
                    continue
            name = f"r{row:02d}_c{col:02d}.png"
            target = sprites / name
            tile.save(target)
            records.append({
                "row": row,
                "column": col,
                "filename": name,
                "source_x": x,
                "source_y": y,
                "cell_width": sheet.cell_width,
                "cell_height": sheet.cell_height,
                "visible_bounds": "" if bounds is None else ",".join(map(str, bounds)),
                "direct_use": "reference_only",
            })
            rows.append((row, col, f"{row:02d}-{col:02d}", tile, bounds))

    with (base / "index.csv").open("w", newline="", encoding="utf-8-sig") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(records[0]))
        writer.writeheader()
        writer.writerows(records)

    contact_columns = min(sheet.columns, 11)
    make_contact_sheet(rows, contact_columns, base / "contact_sheet.png")
    return len(records)


def main() -> None:
    counts: dict[str, int] = {}
    for sheet in SHEETS:
        counts[sheet.slug] = split(sheet)
        print(f"{sheet.slug}: {counts[sheet.slug]} sprites")
    total = sum(counts.values())
    print(f"Total: {total} non-empty grid cells")


if __name__ == "__main__":
    main()
