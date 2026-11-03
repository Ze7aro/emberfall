class_name CharacterData
extends Resource

@export var id: StringName
@export var display_name := ""
@export var weapon := ""
@export var texture_path := ""
@export var sprite_folder := "" # folder name under assets/emberfall_sprites_2d_simple
@export var cost := 0
@export var currency := "gold" # "gold" or "gems"
@export var requirement := "" # "" or "stage_NN" or "dungeon_NN"
@export var attack_name := "" # display name of this hero's basic shot, e.g. "Disparo de Fuego"
@export var attack_color := Color(0.2, 0.95, 0.85) # tints the basic projectile (fallback when no sprite)
@export var attack_sprite_folder := "" # folder name under assets/emberfall_poderes, "" = colored-circle fallback
@export var attack_range_scale := 1.0 # multiplies projectile lifetime/reach; < 1.0 = short-range shot
@export var attack_frame_names: PackedStringArray = [] # explicit frame filenames in attack_sprite_folder; empty = legacy "projectile_00.png"/"projectile_01.png"
@export var attack_alt_frame_names: PackedStringArray = [] # 2+ single-frame variants that alternate each swing instead of looping (e.g. Mordrak's two slash directions)
@export var attack_aoe_every := 0 # 0 = never; every Nth attack hits everything in attack_aoe_radius instead of a single target
@export var attack_aoe_frame_names: PackedStringArray = [] # frames shown for that Nth-attack AoE hit
@export var attack_aoe_radius := 140.0

## Real per-hero identity (HERO-01): every launch hero gets exactly one clear
## advantage and one clear limitation instead of sharing identical stats.
@export var hp_modifier := 0 # flat max-HP change, in half-heart units (2 = +1 full heart)
@export var damage_modifier := 1.0 # multiplies this hero's own basic-attack damage
@export var attack_speed_modifier := 1.0 # multiplies the basic-attack interval; < 1.0 = fires faster
@export var move_speed_modifier := 1.0 # multiplies movement speed
@export var guaranteed_status := "" # "", "burn", "freeze", or "poison" — applied on every basic-attack hit (not left to the random passive chances), ties the hero's element to their identity instead of luck
