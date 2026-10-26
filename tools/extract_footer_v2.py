"""Extract only directly observable footer artwork from footer_V2.png.

This is deliberately conservative: it does not synthesize the hidden parts of
the button backgrounds or outer frame. Those are documented in the README.
"""
from collections import deque
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "footer_V2.png"
OUT = ROOT / "assets" / "ui" / "footer"


def flood_transparent(image: Image.Image) -> Image.Image:
    """Remove only the contiguous near-black surround, preserving dark art."""
    rgba = image.convert("RGBA")
    px = rgba.load()
    width, height = rgba.size
    queue = deque()
    seen = set()

    def is_background(x: int, y: int) -> bool:
        r, g, b, a = px[x, y]
        return a > 0 and r < 24 and g < 25 and b < 38

    for x in range(width):
        queue.extend(((x, 0), (x, height - 1)))
    for y in range(height):
        queue.extend(((0, y), (width - 1, y)))
    while queue:
        x, y = queue.popleft()
        if (x, y) in seen or not (0 <= x < width and 0 <= y < height):
            continue
        seen.add((x, y))
        if not is_background(x, y):
            continue
        px[x, y] = (0, 0, 0, 0)
        queue.extend(((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)))
    return rgba


def icon(source: Image.Image, box: tuple[int, int, int, int], name: str) -> None:
    crop = flood_transparent(source.crop(box))
    crop.thumbnail((58, 58), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (64, 64))
    canvas.alpha_composite(crop, ((64 - crop.width) // 2, (64 - crop.height) // 2))
    canvas.save(OUT / "icons" / name)


def transparent_crop(source: Image.Image, box: tuple[int, int, int, int], path: Path) -> None:
    flood_transparent(source.crop(box)).save(path)


def main() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    for folder in ("frames", "buttons", "icons", "decorations"):
        (OUT / folder).mkdir(parents=True, exist_ok=True)

    # Coordinates are measured against the original 2172 x 724 artwork.
    icon(source, (220, 245, 404, 414), "icon_inicio.png")
    icon(source, (605, 250, 793, 415), "icon_tienda.png")
    icon(source, (995, 240, 1184, 418), "icon_personaje.png")
    icon(source, (1390, 250, 1550, 414), "icon_inventario.png")
    icon(source, (1750, 230, 1940, 418), "icon_mazmorras.png")

    transparent_crop(source, (42, 176, 208, 530), OUT / "frames" / "footer_left_cap.png")
    transparent_crop(source, (1966, 176, 2132, 530), OUT / "frames" / "footer_right_cap.png")
    transparent_crop(source, (475, 176, 531, 531), OUT / "decorations" / "footer_separator.png")

    # The whole reference is retained as an audit/provenance preview only. It
    # is not used by Godot as a static navigation control.
    preview = source.crop((42, 176, 2132, 531))
    preview.thumbnail((1170, 199), Image.Resampling.LANCZOS)
    preview.save(OUT / "footer_reference_preview.png")

    archive = ROOT / "assets" / "ui" / "footer_assets_v2.zip"
    with ZipFile(archive, "w", ZIP_DEFLATED) as bundle:
        for path in OUT.rglob("*"):
            if path.is_file():
                bundle.write(path, path.relative_to(OUT.parent))


if __name__ == "__main__":
    main()
