extends Control

const UiTheme := preload("res://scripts/ui/UiTheme.gd")

## "modifier" is a real rule game_world.gd applies during the run (see its
## _dungeon_modifier()/_difficulty_multiplier()/_boss_time()), not flavor
## text — each dungeon plays differently, not just pays out differently.
const DUNGEONS: Array[Dictionary] = [
	{"id": &"crimson_catacombs", "type": "dungeon", "index": 1, "name": "CATACUMBAS CARMESÍ", "chapter": 1, "level": 1, "preview": "res://assets/environment/game_bg.png", "gold_reward": 150, "gems_reward": 5, "modifier": "swarm", "modifier_label": "Enjambre: oleadas 30% más frecuentes"},
	{"id": &"obsidian_depths", "type": "dungeon", "index": 2, "name": "PROFUNDIDADES DE OBSIDIANA", "chapter": 2, "level": 1, "preview": "res://assets/environment/world_map.png", "gold_reward": 220, "gems_reward": 7, "modifier": "hardened", "modifier_label": "Endurecidos: +30% de vida enemiga"},
	{"id": &"withered_sanctum", "type": "dungeon", "index": 3, "name": "SANTUARIO MARCHITO", "chapter": 3, "level": 1, "preview": "res://assets/environment/game_bg.png", "gold_reward": 300, "gems_reward": 9, "modifier": "reckoning", "modifier_label": "Ajuste de cuentas: el jefe llega a los 8 minutos"},
]

var _locked_box: VBoxContainer
var _map_selection: Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_map_selection = $MapSelection
	_map_selection.unlock_check = func(data: Dictionary) -> bool:
		return GameState.is_dungeon_unlocked(int(data.get("index", 1)))
	_map_selection.set_maps(DUNGEONS)
	_map_selection.previous_map_requested.connect(_map_selection.show_previous_map)
	_map_selection.next_map_requested.connect(_map_selection.show_next_map)
	_map_selection.start_map_requested.connect(_on_start_map_requested)

	_locked_box = VBoxContainer.new()
	_locked_box.anchor_left = 0.5; _locked_box.anchor_right = 0.5
	_locked_box.anchor_top = 0.5; _locked_box.anchor_bottom = 0.5
	_locked_box.offset_left = -140; _locked_box.offset_right = 140
	_locked_box.offset_top = -80; _locked_box.offset_bottom = 80
	_locked_box.add_theme_constant_override("separation", 10)
	add_child(_locked_box)

	var lock_icon := TextureRect.new()
	lock_icon.texture = load("res://assets/iconos main/06_candado.png")
	lock_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	lock_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lock_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	lock_icon.custom_minimum_size = Vector2(0, 64)
	_locked_box.add_child(lock_icon)

	var locked_label := Label.new()
	locked_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	locked_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	locked_label.add_theme_font_size_override("font_size", 18)
	locked_label.add_theme_color_override("font_color", UiTheme.TEXT_MUTED)
	locked_label.text = "MAZMORRAS BLOQUEADAS\nSupera la pantalla 10 para desbloquearlas."
	_locked_box.add_child(locked_label)

	_refresh_lock_state()
	GameState.progress_changed.connect(_refresh_lock_state)

func _refresh_lock_state() -> void:
	var unlocked := GameState.are_dungeons_unlocked()
	_map_selection.visible = unlocked
	_locked_box.visible = not unlocked

func _on_start_map_requested(data: Dictionary) -> void:
	var main_layout := _find_main_layout()
	if main_layout:
		main_layout.start_run(data)

func _find_main_layout() -> Node:
	var node := get_parent()
	while node:
		if node.has_method("start_run"):
			return node
		node = node.get_parent()
	return null
