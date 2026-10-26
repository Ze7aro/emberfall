extends Control

const UiTheme := preload("res://scripts/ui/UiTheme.gd")

const STAGE_NAMES := [
	"CRIPTAS DEL VACÍO", "RUINAS VERDANTES", "FORJA DE EMBER", "BOSQUE CENIZO",
	"CAVERNAS ROTAS", "TORRE OLVIDADA", "PANTANO NEGRO", "CUMBRE HELADA",
	"FOSA DE MAGMA", "TRONO DE EMBERFALL",
]
const STAGE_PREVIEWS := ["res://assets/environment/game_bg.png", "res://assets/environment/world_map.png"]

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var map_selection := $MapSelection
	var backdrop := UiTheme.background("bg_inicio.png", 0.4)
	if backdrop != null:
		add_child(backdrop)
		move_child(backdrop, 0)
	map_selection.start_label = "COMENZAR AVENTURA"
	map_selection.start_subtitle = "Explora, lucha, progresa"
	map_selection.show_rewards = false
	map_selection.unlock_check = func(data: Dictionary) -> bool:
		return GameState.is_stage_unlocked(int(data.get("index", 1)))
	map_selection.set_maps(_build_stages())
	map_selection.previous_map_requested.connect(map_selection.show_previous_map)
	map_selection.next_map_requested.connect(map_selection.show_next_map)
	map_selection.start_map_requested.connect(_on_start_map_requested)
	_build_missions_side()

## Floating side shortcut to the existing Misiones screen (left edge), with the
## same "something to claim" indicator the footer uses.
## Floating side shortcuts on the left edge: Notificaciones (moved here from
## the top HUD) above Misiones, each with its "something new" indicator.
func _build_missions_side() -> void:
	var top := UiTheme.CONTENT_TOP + 8.0
	_side_button(top + 12.0, "res://assets/ui/pixel_simple_v1/icons/mail.png", "Avisos", func():
		var main_layout := _find_navigator()
		if main_layout:
			main_layout.open_modal(&"notifications")
			GameState.mark_notifications_read()
	, func() -> bool: return GameState.unread_notification_count() > 0, GameState.notifications_changed)
	_side_button(top + 76.0, "res://assets/ui/pixel_simple_v1/icons/missions.png", "Misiones", func():
		var main_layout := _find_navigator()
		if main_layout:
			main_layout.open_modal(&"missions")
	, func() -> bool: return GameState.has_claimable_missions(), GameState.missions_changed)

func _side_button(y: float, icon_path: String, caption_text: String, on_press: Callable, has_news: Callable, changed: Signal) -> void:
	var side := Control.new()
	side.name = caption_text + "Side"
	side.position = Vector2(6, y)
	side.size = Vector2(48, 48)
	add_child(side)
	var icon := TextureRect.new()
	icon.texture = load(icon_path) as Texture2D
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 4
	icon.offset_right = -4
	icon.offset_top = 4
	icon.offset_bottom = -4
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	side.add_child(icon)
	var badge: Control = UiTheme.icon_rect("badge_notificacion.png", 20)
	badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	badge.position = Vector2(side.size.x - 14.0, -8.0)
	side.add_child(badge)
	badge.visible = has_news.call()
	changed.connect(func(_a = null): badge.visible = has_news.call())
	var button := Button.new()
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = caption_text
	button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.pressed.connect(on_press)
	side.add_child(button)

func _find_navigator() -> Node:
	var node := get_parent()
	while node:
		if node.has_method("navigate_to"):
			return node
		node = node.get_parent()
	return null

func _build_stages() -> Array[Dictionary]:
	var stages: Array[Dictionary] = []
	for i in GameState.STAGE_COUNT:
		var index := i + 1
		stages.append({
			"id": StringName("stage_%02d" % index),
			"type": "stage",
			"index": index,
			"name": STAGE_NAMES[i],
			"chapter": 1 + (i / 4),
			"level": index,
			"preview": STAGE_PREVIEWS[i % STAGE_PREVIEWS.size()],
			"gold_reward": 40 + index * 20,
			"gems_reward": 1 + index / 2,
		})
	return stages

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
