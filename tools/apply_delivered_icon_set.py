"""Apply the user-delivered 2026-09-24 icon set to pixel_simple_v1.

Copies every delivered icon into the kit source library, preserving the
current versions once in artifacts/, and updates prompts.json metadata. The
Godot packer remains responsible for native canvas sizes and binary alpha.
"""

from __future__ import annotations

import json
import shutil
from dataclasses import dataclass
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
DELIVERY = ROOT / "assets/ui/emberfall_icons_transparent_2026-09-24/icon_exports_2026-09-24"
KIT = ROOT / "assets/ui/pixel_simple_v1"
BACKUP = ROOT / "artifacts/ui_assets_style_backup_2026-09-24"


@dataclass(frozen=True)
class Asset:
    delivered: str
    name: str
    folder: str
    size: tuple[int, int]
    flip_h: bool = False


ASSETS = [
    Asset("01_settings.png", "settings", "icons", (24, 24)),
    Asset("02_mail.png", "mail", "icons", (48, 48)),
    Asset("03_missions.png", "missions", "icons", (48, 48)),
    Asset("04_lock.png", "lock", "icons", (24, 24)),
    Asset("05_arrow.png", "arrow", "icons", (24, 24), True),
    Asset("06_refresh.png", "refresh", "icons", (24, 24)),
    Asset("07_close.png", "close", "icons", (24, 24)),
    Asset("08_check.png", "check", "icons", (24, 24)),
    Asset("09_home.png", "home_alt", "icons", (48, 48)),
    Asset("10_character.png", "character_alt", "icons", (48, 48)),
    Asset("11_inventory.png", "inventory_alt", "icons", (48, 48)),
    Asset("12_dungeon_key.png", "dungeon_key", "icons", (48, 48)),
    Asset("13_portal_purple.png", "portal_purple", "icons", (48, 48)),
    Asset("14_portal_cyan.png", "portal_cyan", "icons", (48, 48)),
    Asset("15_gold_stack.png", "gold_stack", "shop", (48, 48)),
    Asset("16_gold_coins.png", "gold_coins", "shop", (48, 48)),
    Asset("17_gold_pile.png", "gold_pile", "shop", (48, 48)),
    Asset("18_gold_bag.png", "gold_bag", "shop", (48, 48)),
    Asset("19_chest_common.png", "chest_common", "shop", (48, 48)),
    Asset("20_chest_rare.png", "chest_rare", "shop", (48, 48)),
    Asset("21_chest_locked.png", "chest_locked", "shop", (48, 48)),
    Asset("22_chest_epic.png", "chest_epic", "shop", (48, 48)),
    Asset("23_gold_chest_open.png", "gold_chest", "shop", (48, 48)),
    Asset("24_energy_bottle.png", "energy_bottle", "shop", (48, 48)),
    Asset("24_energy_bottle.png", "energy", "icons", (32, 32)),
    Asset("25_cancel.png", "cancel", "icons", (24, 24)),
    Asset("26_confirm.png", "confirm", "icons", (24, 24)),
    Asset("27_energy_bottles.png", "energy_bottles", "shop", (48, 48)),
    Asset("28_close_alt.png", "close_alt", "icons", (24, 24)),
    Asset("29_play.png", "play", "icons", (24, 24)),
    Asset("30_pause.png", "pause", "icons", (24, 24)),
    Asset("31_target.png", "target", "icons", (24, 24)),
    Asset("32_autoplay.png", "autoplay", "icons", (24, 24)),
]


def backup(path: Path) -> None:
    if not path.exists():
        return
    relative = path.relative_to(KIT)
    target = BACKUP / relative
    if target.exists():
        return
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, target)


def main() -> None:
    manifest_path = KIT / "prompts.json"
    backup(manifest_path)
    payload = json.loads(manifest_path.read_text(encoding="utf-8"))
    by_key = {(entry["folder"], entry["name"]): entry for entry in payload["assets"]}

    for asset in ASSETS:
        delivered = DELIVERY / asset.delivered
        if not delivered.is_file():
            raise FileNotFoundError(delivered)
        source_target = KIT / "source" / f"{asset.name}.png"
        export_target = KIT / asset.folder / f"{asset.name}.png"
        backup(source_target)
        backup(export_target)

        image = Image.open(delivered).convert("RGBA")
        if asset.flip_h:
            image = image.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        source_target.parent.mkdir(parents=True, exist_ok=True)
        image.save(source_target)

        source_rel = delivered.relative_to(ROOT).as_posix()
        prompt = (
            "User-delivered Emberfall pixel-art icon, adapted to match the approved navigation style. "
            "Preserve its supplied silhouette, colors and transparent background during deterministic packaging."
        )
        entry = by_key.get((asset.folder, asset.name))
        if entry is None:
            entry = {"name": asset.name, "folder": asset.folder, "size": list(asset.size)}
            payload["assets"].append(entry)
            by_key[(asset.folder, asset.name)] = entry
        entry.update({
            "size": list(asset.size),
            "prompt": prompt,
            "source": source_rel,
            "status": "review_pending",
            "generation_method": "user-provided adapted icon; deterministic crop and nearest packaging",
        })
        if asset.flip_h:
            entry["source_transform"] = "horizontal flip so icons/arrow.png points right"
        else:
            entry.pop("source_transform", None)

    payload["tool"] = "built-in image generation references + user-delivered adapted icon set + deterministic packaging"
    payload["status"] = "review_in_progress"
    manifest_path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Applied {len(ASSETS)} mappings from {DELIVERY}")
    print(f"Backup preserved at {BACKUP}")


if __name__ == "__main__":
    main()
