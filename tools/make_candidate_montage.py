"""Create a labeled preview of shortlisted reference motifs."""

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "assets/ui/reference_icon_sheets"
OUTPUT = BASE / "selected_candidates.png"
PICKS = [
    ("Burning", "r07_c00", "bof6_item_boosters"),
    ("Potion", "r01_c00", "bof6_item_boosters"),
    ("Sword", "r00_c06", "bof6_item_boosters"),
    ("Flash", "r00_c04", "bof6_item_boosters"),
    ("Status badge", "r02_c08", "bof6_item_boosters"),
    ("Vials", "r02_c04", "bof6_miscellaneous"),
    ("Crossed weapons", "r00_c08", "bof6_miscellaneous"),
    ("Crystal/herbs", "r02_c03", "bof6_miscellaneous"),
    ("Orb", "r00_c06", "bof6_materials"),
    ("Heart", "r00_c05", "bof6_item_boosters"),
]

columns, cell_w, cell_h = 4, 112, 120
rows = (len(PICKS) + columns - 1) // columns
canvas = Image.new("RGBA", (columns * cell_w, rows * cell_h), (21, 24, 38, 255))
draw = ImageDraw.Draw(canvas)
for i, (label, sprite, pack) in enumerate(PICKS):
    icon = Image.open(BASE / pack / "sprites" / f"{sprite}.png").convert("RGBA")
    icon.thumbnail((88, 88), Image.Resampling.NEAREST)
    x = (i % columns) * cell_w
    y = (i // columns) * cell_h
    canvas.alpha_composite(icon, (x + (cell_w - icon.width) // 2, y + 2))
    draw.text((x + 4, y + 94), f"{label} {sprite}", fill=(240, 240, 248, 255))

canvas.save(OUTPUT)
print(OUTPUT)
