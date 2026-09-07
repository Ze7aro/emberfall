extends Control

const DUNGEONS: Array[Dictionary] = [
	{"id": &"crimson_catacombs", "type": "dungeon", "index": 1, "name": "CATACUMBAS CARMESÍ", "chapter": 1, "level": 1, "preview": "res://assets/environment/game_bg.png", "gold_reward": 150, "gems_reward": 5},
	{"id": &"obsidian_depths", "type": "dungeon", "index": 2, "name": "PROFUNDIDADES DE OBSIDIANA", "chapter": 2, "level": 1, "preview": "res://assets/environment/world_map.png", "gold_reward": 220, "gems_reward": 7},
	{"id": &"withered_sanctum", "type": "dungeon", "index": 3, "name": "SANTUARIO MARCHITO", "chapter": 3, "level": 1, "preview": "res://assets/environment/game_bg.png", "gold_reward": 300, "gems_reward": 9},
]

var _locked_label: Label
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

	_locked_label = Label.new()
	_locked_label.anchor_left = 0.5; _locked_label.anchor_right = 0.5
	_locked_label.anchor_top = 0.5; _locked_label.anchor_bottom = 0.5
	_locked_label.offset_left = -140; _locked_label.offset_right = 140
	_locked_label.offset_top = -50; _locked_label.offset_bottom = 50
	_locked_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_locked_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_locked_label.add_theme_font_size_override("font_size", 18)
	_locked_label.add_theme_color_override("font_color", Color("9b8eaa"))
	_locked_label.text = "MAZMORRAS BLOQUEADAS\nSupera la pantalla 10 para desbloquearlas."
	add_child(_locked_label)
	_refresh_lock_state()
	GameState.progress_changed.connect(_refresh_lock_state)

func _refresh_lock_state() -> void:
	var unlocked := GameState.are_dungeons_unlocked()
	_map_selection.visible = unlocked
	_locked_label.visible = not unlocked

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
