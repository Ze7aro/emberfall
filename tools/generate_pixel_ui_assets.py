from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1] / "assets" / "ui" / "pixel_simple_v1"
SOURCE = ROOT / "source"

NAVY = "#101321"
INTERIOR = "#141827"
STONE = "#55446e"
STONE_LIGHT = "#87739f"
CYAN = "#42d8e8"
IVORY = "#ecedf4"
PURPLE_DARK = "#30213f"
PURPLE = "#9255d8"
MAGENTA = "#c747e0"
WOOD_DARK = "#513043"
WOOD = "#9b5b37"
WOOD_LIGHT = "#c17a46"
GOLD_DARK = "#9b652b"
GOLD = "#dfaa39"
GOLD_LIGHT = "#f4d06a"


def canvas(size, opaque=False):
    return Image.new("RGBA", size, (16, 19, 33, 255) if opaque else (0, 0, 0, 0))


def save(im, rel):
    target = ROOT / rel
    target.parent.mkdir(parents=True, exist_ok=True)
    im.save(target, "PNG")
    source = SOURCE / Path(rel).name
    SOURCE.mkdir(parents=True, exist_ok=True)
    im.save(source, "PNG")


def bar_fill(color, hi):
    im = canvas((96, 12)); d = ImageDraw.Draw(im)
    d.polygon([(1, 0), (94, 0), (95, 1), (95, 10), (94, 11), (1, 11), (0, 10), (0, 1)], fill=color)
    d.line([(2, 1), (93, 1)], fill=hi, width=1)
    return im


def bar_track():
    im = canvas((96, 16)); d = ImageDraw.Draw(im)
    d.polygon([(2, 0), (93, 0), (95, 2), (95, 13), (93, 15), (2, 15), (0, 13), (0, 2)], fill=STONE)
    d.polygon([(2, 2), (93, 2), (93, 3), (94, 3), (94, 12), (92, 13), (3, 13), (1, 12), (1, 3)], fill=INTERIOR)
    return im


def arrow():
    im = canvas((24, 24)); d = ImageDraw.Draw(im)
    d.polygon([(20, 10), (12, 2), (8, 6), (13, 11), (8, 16), (12, 20), (20, 12)], fill=NAVY)
    d.polygon([(17, 10), (12, 5), (11, 6), (15, 11), (11, 16), (12, 17), (17, 12)], fill=STONE_LIGHT)
    d.polygon([(17, 10), (12, 5), (11, 6), (15, 11), (15, 12), (17, 12)], fill=IVORY)
    return im


def close_icon():
    im = canvas((24, 24)); d = ImageDraw.Draw(im)
    d.polygon([(6, 3), (12, 9), (18, 3), (21, 6), (15, 12), (21, 18), (18, 21), (12, 15), (6, 21), (3, 18), (9, 12), (3, 6)], fill=NAVY)
    d.polygon([(7, 5), (12, 10), (17, 5), (19, 7), (14, 12), (19, 17), (17, 19), (12, 14), (7, 19), (5, 17), (10, 12), (5, 7)], fill=STONE)
    d.polygon([(7, 5), (12, 10), (17, 5), (18, 7), (13, 12), (10, 12), (5, 7)], fill=IVORY)
    return im


def lock_icon():
    im = canvas((24, 24)); d = ImageDraw.Draw(im)
    d.rectangle((6, 10, 19, 21), fill=NAVY)
    d.rectangle((8, 12, 17, 19), fill=STONE)
    d.rectangle((8, 12, 16, 14), fill=STONE_LIGHT)
    d.rectangle((9, 4, 10, 9), fill=NAVY); d.rectangle((16, 4, 17, 9), fill=NAVY)
    d.rectangle((10, 3, 16, 5), fill=NAVY); d.rectangle((10, 5, 11, 9), fill=STONE_LIGHT)
    d.rectangle((15, 5, 16, 9), fill=STONE)
    d.rectangle((11, 14, 14, 17), fill=CYAN); d.rectangle((12, 16, 13, 18), fill=PURPLE_DARK)
    return im


def check_icon():
    im = canvas((24, 24)); d = ImageDraw.Draw(im)
    d.polygon([(2, 12), (6, 8), (10, 12), (18, 3), (22, 7), (10, 21)], fill=NAVY)
    d.polygon([(4, 12), (6, 10), (10, 14), (18, 5), (20, 7), (10, 18)], fill=STONE)
    d.polygon([(4, 12), (6, 10), (10, 14), (17, 6), (18, 8), (10, 18)], fill=CYAN)
    return im


def mail_icon():
    im = canvas((48, 48)); d = ImageDraw.Draw(im)
    d.polygon([(6, 13), (10, 9), (38, 9), (42, 13), (42, 34), (38, 38), (10, 38), (6, 34)], fill=NAVY)
    d.polygon([(9, 15), (12, 12), (36, 12), (39, 15), (39, 32), (36, 35), (12, 35), (9, 32)], fill=STONE)
    d.polygon([(10, 16), (24, 26), (38, 16), (38, 21), (24, 32), (10, 21)], fill=PURPLE_DARK)
    d.polygon([(10, 15), (24, 25), (38, 15), (38, 19), (24, 29), (10, 19)], fill=STONE_LIGHT)
    d.line([(11, 31), (20, 24)], fill=PURPLE, width=2)
    d.line([(37, 31), (28, 24)], fill=PURPLE, width=2)
    d.polygon([(24, 22), (29, 27), (24, 32), (19, 27)], fill=NAVY)
    d.polygon([(24, 23), (28, 27), (24, 31), (20, 27)], fill=CYAN)
    d.point((24, 25), fill=IVORY)
    return im


def missions_icon():
    im = canvas((48, 48)); d = ImageDraw.Draw(im)
    # A single compact parchment scroll with violet rolled ends; no side ornaments.
    d.rectangle((8, 8, 14, 39), fill=NAVY); d.rectangle((34, 8, 40, 39), fill=NAVY)
    d.rectangle((10, 10, 13, 37), fill=STONE); d.rectangle((35, 10, 38, 37), fill=STONE_LIGHT)
    d.rectangle((13, 11, 35, 36), fill=NAVY)
    d.rectangle((15, 13, 33, 34), fill="#d8c5a3")
    d.rectangle((15, 13, 33, 15), fill="#f0dfbd")
    d.polygon([(18, 24), (21, 21), (25, 25), (31, 18), (34, 21), (25, 31)], fill=NAVY)
    d.polygon([(19, 24), (21, 23), (25, 27), (31, 20), (32, 21), (25, 29)], fill=CYAN)
    return im


def energy():
    im = canvas((32, 32)); d = ImageDraw.Draw(im)
    pts = [(11, 2), (26, 2), (20, 11), (27, 11), (9, 30), (12, 17), (5, 17)]
    d.polygon(pts, fill=NAVY)
    inner = [(13, 5), (22, 5), (17, 13), (22, 13), (12, 25), (15, 16), (9, 16)]
    d.polygon(inner, fill=CYAN)
    d.polygon([(13, 5), (16, 5), (13, 15), (9, 15)], fill="#238d9a")
    d.polygon([(17, 13), (22, 13), (12, 25), (14, 17)], fill="#238d9a")
    d.line([(14, 6), (20, 6)], fill="#87f4ec", width=1)
    return im


def coin_icon():
    im = canvas((32, 32)); d = ImageDraw.Draw(im)
    d.polygon([(16, 2), (24, 5), (29, 12), (29, 20), (24, 27), (16, 30), (8, 27), (3, 20), (3, 12), (8, 5)], fill=NAVY)
    d.polygon([(16, 5), (23, 7), (26, 13), (26, 19), (22, 25), (16, 27), (10, 24), (6, 19), (6, 12), (10, 7)], fill=GOLD_DARK)
    d.polygon([(16, 6), (22, 8), (24, 13), (16, 13), (9, 10), (11, 8)], fill=GOLD_LIGHT)
    d.polygon([(9, 11), (16, 14), (16, 24), (10, 22), (7, 18), (7, 13)], fill=GOLD)
    d.polygon([(16, 14), (24, 14), (24, 19), (21, 23), (16, 25)], fill="#c9872e")
    d.polygon([(16, 12), (19, 15), (16, 18), (13, 15)], fill=WOOD_DARK)
    d.polygon([(16, 13), (18, 15), (16, 17), (14, 15)], fill=GOLD_LIGHT)
    return im


def gem():
    im = canvas((32, 32)); d = ImageDraw.Draw(im)
    outer = [(16, 2), (26, 11), (23, 25), (16, 30), (9, 25), (6, 11)]
    d.polygon(outer, fill=NAVY)
    d.polygon([(16, 4), (24, 12), (21, 23), (16, 27), (11, 23), (8, 12)], fill="#9255d8")
    d.polygon([(16, 4), (24, 12), (16, 14)], fill="#c747e0")
    d.polygon([(16, 14), (21, 23), (16, 27), (11, 23)], fill=STONE)
    d.polygon([(16, 4), (16, 14), (8, 12)], fill="#d77be8")
    d.line([(9, 13), (12, 22)], fill=STONE_LIGHT, width=1)
    return im


def gold_pile():
    im = canvas((48, 48)); d = ImageDraw.Draw(im)
    # Two short stacks with visibly layered coin rims, plus three loose coins.
    for x, y, w in [(8, 28, 16), (24, 24, 14)]:
        d.rectangle((x - 2, y - 2, x + w + 1, 39), fill=WOOD_DARK)
        for row in range(3):
            top = y + row * 3
            d.rectangle((x, top, x + w, top + 3), fill=NAVY)
            d.rectangle((x + 1, top, x + w - 1, top + 2), fill=GOLD_DARK)
            d.rectangle((x + 2, top, x + w - 2, top + 1), fill=GOLD)
            d.line((x + 3, top, x + w - 3, top), fill=GOLD_LIGHT)
    for x, y in [(7, 39), (19, 40), (32, 39)]:
        d.ellipse((x - 1, y - 1, x + 8, y + 5), fill=NAVY)
        d.ellipse((x, y - 1, x + 7, y + 4), fill=GOLD_DARK)
        d.rectangle((x + 1, y, x + 6, y + 2), fill=GOLD)
        d.line((x + 2, y, x + 5, y), fill=GOLD_LIGHT)
    return im


def gold_bag():
    im = canvas((48, 48)); d = ImageDraw.Draw(im)
    d.polygon([(18, 7), (30, 7), (32, 12), (39, 17), (40, 34), (34, 41), (14, 41), (8, 34), (9, 18), (16, 12)], fill=NAVY)
    d.polygon([(18, 10), (29, 10), (30, 14), (36, 19), (37, 33), (32, 38), (16, 38), (11, 33), (12, 20), (18, 14)], fill=WOOD)
    d.polygon([(18, 10), (29, 10), (30, 14), (18, 15), (15, 13)], fill=WOOD_LIGHT)
    d.polygon([(12, 21), (17, 17), (31, 17), (36, 21), (35, 32), (31, 36), (17, 36), (13, 32)], fill="#87502f")
    d.rectangle((19, 6, 29, 12), fill=NAVY); d.rectangle((21, 7, 27, 10), fill=STONE)
    d.polygon([(24, 19), (30, 25), (24, 31), (18, 25)], fill=NAVY)
    d.polygon([(24, 20), (29, 25), (24, 30), (19, 25)], fill=GOLD)
    d.polygon([(24, 20), (24, 25), (19, 25)], fill=GOLD_LIGHT)
    d.line((14, 33, 18, 36), fill=WOOD_LIGHT, width=1); d.line((34, 33, 30, 36), fill=WOOD_DARK, width=1)
    return im


def gold_chest():
    im = canvas((48, 48)); d = ImageDraw.Draw(im)
    # Raised lid and open rim sit behind a sturdy, shaded front chest.
    d.polygon([(7, 21), (9, 11), (14, 7), (34, 7), (40, 12), (41, 21), (35, 25), (13, 25)], fill=NAVY)
    d.polygon([(11, 19), (13, 12), (17, 10), (32, 10), (37, 13), (38, 19), (33, 22), (15, 22)], fill=WOOD_DARK)
    d.polygon([(14, 17), (16, 13), (19, 12), (31, 12), (35, 15), (35, 18), (31, 20), (17, 20)], fill=WOOD)
    d.polygon([(14, 16), (17, 13), (30, 13), (34, 15), (30, 16), (18, 16)], fill=WOOD_LIGHT)
    # Gold coins peek over the front rim without overflowing the chest.
    d.rectangle((17, 17, 21, 20), fill=GOLD_DARK); d.rectangle((18, 16, 21, 19), fill=GOLD_LIGHT)
    d.rectangle((23, 15, 28, 20), fill=GOLD_DARK); d.rectangle((24, 14, 28, 19), fill=GOLD_LIGHT)
    d.rectangle((30, 17, 33, 20), fill=GOLD_DARK); d.rectangle((30, 16, 33, 19), fill=GOLD)
    d.polygon([(8, 21), (39, 20), (41, 25), (39, 37), (34, 41), (12, 39), (7, 35)], fill=NAVY)
    d.polygon([(11, 24), (37, 23), (38, 27), (36, 35), (33, 38), (14, 36), (10, 33)], fill=WOOD)
    d.polygon([(11, 24), (23, 23), (23, 36), (14, 35), (10, 32)], fill=WOOD_LIGHT)
    d.polygon([(16, 23), (19, 23), (19, 37), (16, 37)], fill=STONE)
    d.polygon([(32, 22), (35, 22), (36, 36), (33, 36)], fill=STONE_LIGHT)
    d.rectangle((23, 29, 28, 35), fill=NAVY); d.rectangle((24, 30, 27, 34), fill=STONE_LIGHT)
    d.point((25, 31), fill=GOLD_LIGHT)
    return im


def energy_bottle():
    im = canvas((48, 48)); d = ImageDraw.Draw(im)
    d.polygon([(19, 4), (29, 4), (31, 8), (30, 15), (35, 19), (38, 25), (37, 36), (33, 41), (15, 41), (11, 36), (10, 25), (13, 19), (18, 15), (17, 8)], fill=NAVY)
    d.rectangle((20, 6, 28, 12), fill=STONE); d.rectangle((21, 6, 27, 8), fill=STONE_LIGHT)
    d.rectangle((18, 13, 30, 17), fill=PURPLE_DARK); d.rectangle((19, 13, 29, 15), fill=STONE_LIGHT)
    d.polygon([(19, 17), (29, 17), (33, 21), (35, 26), (34, 35), (31, 38), (17, 38), (14, 35), (13, 26), (15, 21)], fill=STONE)
    d.polygon([(20, 19), (28, 19), (31, 22), (33, 26), (32, 34), (29, 36), (19, 36), (16, 34), (15, 26), (17, 22)], fill="#238d9a")
    d.polygon([(16, 27), (32, 27), (32, 34), (29, 36), (19, 36), (16, 34)], fill=CYAN)
    d.line((18, 28, 29, 28), fill="#87f4ec", width=1)
    d.polygon([(24, 28), (29, 28), (26, 32), (29, 32), (21, 37), (23, 33), (20, 33)], fill=NAVY)
    d.polygon([(24, 29), (27, 29), (24, 33), (27, 33), (22, 35), (23, 32), (21, 32)], fill=IVORY)
    d.rectangle((14, 22, 16, 33), fill=STONE_LIGHT); d.rectangle((32, 22, 34, 33), fill=PURPLE_DARK)
    return im


def closed_chest(epic=False):
    # Start from the navigation chest so shape, pixel scale and shading match exactly.
    im = Image.open(ROOT / "navigation" / "inventory.png").convert("RGBA")
    if not epic:
        return im
    pixels = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            # Recolor only warm wood and gold; keep the dark outline and violet hardware intact.
            if r > 65 and g < 175 and b < 145 and r > g * 1.18:
                light = (r + g + b) / 3.0
                pixels[x, y] = ((199, 71, 224, 255) if light > 155 else (146, 85, 216, 255) if light > 105 else (85, 68, 110, 255))
    # A small magenta diamond replaces the common chest's silver clasp jewel.
    d = ImageDraw.Draw(im)
    d.polygon([(25, 22), (28, 25), (25, 28), (22, 25)], fill=NAVY)
    d.polygon([(25, 23), (27, 25), (25, 27), (23, 25)], fill=MAGENTA)
    d.point((25, 24), fill="#f29aef")
    return im


def chest_epic():
    im = canvas((48, 48)); d = ImageDraw.Draw(im)
    # Compact closed chest in a restrained three-quarter view: top plane,
    # broad front and narrow right side stay readable on the 48px grid.
    d.polygon([(7, 18), (14, 12), (36, 12), (43, 17), (35, 23), (13, 25)], fill=NAVY)
    d.polygon([(10, 18), (15, 14), (34, 14), (39, 17), (33, 21), (14, 23)], fill="#87739f")
    d.polygon([(8, 22), (35, 20), (35, 36), (11, 40), (8, 37)], fill=NAVY)
    d.polygon([(35, 20), (43, 17), (43, 34), (35, 38)], fill="#101321")
    d.polygon([(10, 24), (33, 22), (33, 35), (11, 38)], fill="#55446e")
    d.polygon([(35, 22), (41, 20), (41, 33), (35, 35)], fill="#403653")
    # Two broad metal bands continue over the lid and body planes.
    d.polygon([(15, 14), (18, 14), (18, 22), (15, 22)], fill="#87739f")
    d.polygon([(15, 25), (18, 25), (18, 37), (15, 37)], fill="#87739f")
    d.polygon([(30, 14), (33, 14), (37, 17), (34, 19), (33, 22), (30, 22)], fill="#87739f")
    d.polygon([(30, 24), (33, 23), (33, 36), (30, 36)], fill="#87739f")
    # Square central latch with one tiny magenta gem.
    d.rectangle((25, 22, 29, 29), fill=NAVY); d.rectangle((26, 23, 28, 28), fill="#9255d8"); d.point((27, 24), fill="#c747e0")
    return im


def weapon():
    im = canvas((32, 32)); d = ImageDraw.Draw(im)
    d.line([(8, 25), (24, 5)], fill=NAVY, width=6); d.line([(10, 24), (24, 7)], fill="#c7cbd5", width=3); d.line([(13, 20), (21, 10)], fill=CYAN, width=1)
    d.line([(8, 21), (14, 26)], fill=NAVY, width=4); d.line([(8, 21), (14, 26)], fill=STONE, width=2); d.line([(10, 25), (7, 28)], fill="#8a542d", width=3)
    return im


def armor():
    im = canvas((32, 32)); d = ImageDraw.Draw(im)
    d.polygon([(9, 10), (13, 8), (19, 8), (23, 10), (27, 13), (24, 18), (23, 27), (9, 27), (8, 18), (5, 13)], fill=NAVY)
    d.polygon([(10, 12), (14, 10), (18, 10), (22, 12), (24, 14), (21, 17), (21, 25), (11, 25), (11, 17), (8, 14)], fill="#75677f")
    d.polygon([(12, 12), (15, 11), (17, 11), (19, 12), (18, 16), (13, 16)], fill="#a494ad")
    d.rectangle((15, 17, 17, 19), fill=CYAN)
    return im


def ring():
    im = canvas((32, 32)); d = ImageDraw.Draw(im)
    d.ellipse((6, 8, 26, 25), fill=NAVY); d.ellipse((9, 10, 23, 22), fill="#c7cbd5"); d.ellipse((12, 12, 20, 20), fill=(0,0,0,0)); d.rectangle((14, 6, 18, 10), fill="#9255d8"); d.rectangle((15, 6, 17, 7), fill="#d77be8")
    return im


def amulet():
    im = canvas((32, 32)); d = ImageDraw.Draw(im)
    d.rectangle((14, 3, 17, 8), fill=NAVY); d.rectangle((15, 3, 16, 7), fill="#c7cbd5")
    d.ellipse((7, 7, 24, 25), fill=NAVY); d.ellipse((9, 9, 22, 23), fill=STONE); d.polygon([(15, 11), (20, 16), (15, 21), (11, 16)], fill=CYAN); d.rectangle((14, 12, 16, 14), fill="#87f4ec")
    return im


def boots():
    im = canvas((32, 32)); d = ImageDraw.Draw(im)
    d.polygon([(6, 9), (15, 9), (17, 20), (23, 21), (26, 26), (25, 28), (7, 28), (5, 25)], fill=NAVY)
    d.polygon([(8, 11), (13, 11), (14, 21), (21, 22), (23, 25), (8, 25)], fill="#9b5b37"); d.rectangle((8, 11, 14, 14), fill=STONE); d.rectangle((8, 24, 24, 26), fill="#3d2c35")
    d.polygon([(17, 8), (23, 9), (23, 18), (27, 20), (27, 24), (16, 24), (15, 21)], fill=NAVY); d.polygon([(18, 10), (21, 10), (21, 18), (25, 20), (25, 22), (18, 22)], fill="#9b5b37"); d.rectangle((18, 10, 21, 12), fill=STONE); d.rectangle((17, 22, 26, 24), fill="#3d2c35")
    return im


def heart():
    im = canvas((24, 24)); d = ImageDraw.Draw(im)
    p=[(4,7),(7,4),(11,5),(12,7),(13,5),(17,4),(20,7),(20,13),(12,21),(4,13)]
    d.polygon(p, fill=NAVY); d.polygon([(6,8),(8,6),(11,7),(12,10),(14,7),(17,6),(18,8),(18,12),(12,18),(6,12)], fill="#d96168"); d.polygon([(6,8),(8,6),(11,7),(10,10),(7,10)], fill="#f29a9f"); d.polygon([(6,12),(12,18),(12,20),(4,13)], fill="#9f3949")
    return im


def speed():
    im = canvas((24, 24)); d = ImageDraw.Draw(im)
    d.line([(6, 14), (13, 9), (17, 10), (15, 14), (19, 17), (18, 19), (8, 19)], fill=NAVY, width=3); d.polygon([(8,14),(13,10),(15,11),(13,15),(17,17),(17,18),(9,18)], fill="#9b5b37")
    d.line([(3, 9),(8,9)], fill=CYAN, width=1); d.line([(2, 12),(7,12)], fill=CYAN, width=1)
    return im


def target():
    im = canvas((24, 24)); d = ImageDraw.Draw(im)
    d.ellipse((3,3,20,20), fill=NAVY); d.ellipse((5,5,18,18), fill=STONE); d.ellipse((7,7,16,16), fill=IVORY); d.ellipse((10,10,13,13), fill=CYAN)
    d.line((14, 10, 21, 4), fill=NAVY, width=3); d.line((15, 10, 20, 5), fill=STONE_LIGHT, width=1)
    return im


def play():
    im = canvas((24, 24)); d = ImageDraw.Draw(im); d.polygon([(5,2),(21,12),(5,22)], fill=NAVY); d.polygon([(8,5),(17,12),(8,19)], fill=PURPLE); d.polygon([(8,5),(14,9),(14,15),(8,19)], fill=CYAN); d.line((9,6,13,8), fill="#87f4ec", width=1); return im


def pause():
    im = canvas((24, 24)); d = ImageDraw.Draw(im); d.rectangle((5,3,12,21), fill=NAVY); d.rectangle((14,3,21,21), fill=NAVY); d.rectangle((6,4,10,20), fill=STONE); d.rectangle((15,4,19,20), fill=STONE); d.rectangle((7,4,9,19), fill=IVORY); d.rectangle((16,4,18,19), fill=IVORY); return im


def background():
    im = canvas((192, 320), opaque=True); d = ImageDraw.Draw(im)
    d.rectangle((0,0,191,319), fill=NAVY); d.rectangle((0,0,24,319), fill=INTERIOR); d.rectangle((168,0,191,319), fill=INTERIOR)
    d.rectangle((0,0,191,18), fill=INTERIOR); d.rectangle((0,300,191,319), fill=INTERIOR)
    d.rectangle((0,286,18,319), fill=STONE); d.rectangle((174,286,191,319), fill=STONE)
    return im


ASSETS = {
    "bars/bar_track.png": bar_track, "bars/fill_xp.png": lambda: bar_fill("#9255d8", "#c897f4"), "bars/fill_energy.png": lambda: bar_fill("#24bfc5", "#87f4ec"), "bars/fill_health.png": lambda: bar_fill("#d96168", "#f29a9f"),
    "icons/close.png": close_icon, "icons/arrow.png": arrow, "icons/lock.png": lock_icon, "icons/check.png": check_icon, "icons/mail.png": mail_icon, "icons/missions.png": missions_icon, "icons/energy.png": energy, "icons/coin.png": coin_icon, "icons/gem.png": gem, "shop/gold_pile.png": gold_pile, "shop/gold_bag.png": gold_bag, "shop/gold_chest.png": gold_chest, "shop/energy_bottle.png": energy_bottle, "shop/chest_common.png": lambda: closed_chest(False), "shop/chest_epic.png": lambda: closed_chest(True), "equipment/weapon.png": weapon, "equipment/armor.png": armor, "equipment/ring.png": ring, "equipment/amulet.png": amulet, "equipment/boots.png": boots, "icons/heart.png": heart, "icons/speed.png": speed, "icons/target.png": target, "icons/play.png": play, "icons/pause.png": pause, "backgrounds/background.png": background,
}

for rel, fn in ASSETS.items():
    save(fn(), rel)
