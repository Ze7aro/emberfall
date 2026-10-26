"""Split the generated transparent Top HUD sprite sheet into Godot assets."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "ui" / "TopHUD" / "tophud_modular_sheet.png"
OUT = SOURCE.parent / "generated"

REGIONS = {
    "top_hud_frame_clean.png": (10, 8, 2160, 365),
    "level_plate_clean.png": (20, 370, 345, 670),
    "xp_track_clean.png": (340, 425, 1330, 570),
    "xp_fill_clean.png": (340, 565, 1330, 655),
    "resource_plate_clean.png": (1325, 420, 1805, 595),
    "button_add_clean.png": (1770, 405, 2080, 660),
}


def trim(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    return image.crop(bbox) if bbox else image


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    sheet = Image.open(SOURCE).convert("RGBA")
    for name, box in REGIONS.items():
        trim(sheet.crop(box)).save(OUT / name)


if __name__ == "__main__":
    main()
