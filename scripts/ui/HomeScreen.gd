extends Control

const UiTheme := preload("res://scripts/ui/UiTheme.gd")

const STAGE_NAMES := [
	"CRIPTAS DEL VACÍO", "RUINAS VERDANTES", "FORJA DE EMBER", "BOSQUE CENIZO",
	"CAVERNAS ROTAS", "TORRE OLVIDADA", "PANTANO NEGRO", "CUMBRE HELADA",
	"FOSA DE MAGMA", "TRONO DE EMBERFALL",
]
## Stage card art: the chapter's own floor, so the card shows where you'll fight.
const CHAPTER_PREVIEWS := {
	1: "res://assets/mundo/suelos/cap1_criptas.png",
	2: "res://assets/mundo/suelos/cap2_cavernas.png",
	3: "res://assets/mundo/suelos/cap3_forja.png",
}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var map_selection := $MapSelection
	var backdrop := UiTheme.background("bg_inicio.png", 0.4)
	if backdrop != null:
		add_child(backdrop)
		move_child(backdrop, 0)
	map_selection.start_label = "JUGAR"
	map_selection.start_subtitle = ""
	map_selection.show_rewards = false
	map_selection.energy_cost = GameState.ENERGY_COST
	map_selection.enable_hero()
	# Room for the shortcut row under the HUD.
	map_selection.add_theme_constant_override("margin_top", int(UiTheme.CONTENT_TOP) + 76)
	if GameState.has_resumable_run():
		_build_resume_card()
	map_selection.unlock_check = func(data: Dictionary) -> bool:
		return GameState.is_stage_unlocked(int(data.get("index", 1)))
	map_selection.set_maps(_build_stages())
	map_selection.previous_map_requested.connect(map_selection.show_previous_map)
	map_selection.next_map_requested.connect(map_selection.show_next_map)
	map_selection.start_map_requested.connect(_on_start_map_requested)
	_build_missions_side()

## RUN-RESUME: the saved run, in the free left end of the shortcut row so the
## stage card below keeps all its room (its column has ~28 px to spare at
## 390×844). Shows where it was left and REANUDAR; abandoning goes through
## the confirmations of JUGAR ("ABANDONAR Y JUGAR") or of the run's pause.
func _build_resume_card() -> void:
	var summary := GameState.resumable_run_summary()
	var card := PanelContainer.new()
	card.name = "ResumeCard"
	card.theme = UiTheme.make_theme()
	var style := UiTheme.panel(UiTheme.GOLD, 10, 2)
	style.bg_color = Color(0.07, 0.05, 0.13, 0.94)
	style.content_margin_left = 8; style.content_margin_right = 8
	style.content_margin_top = 5; style.content_margin_bottom = 6
	card.add_theme_stylebox_override("panel", style)
	# From the left edge to just before Misiones (the row is right-anchored).
	card.anchor_left = 0.0; card.anchor_right = 1.0
	card.offset_left = 16; card.offset_right = -196
	card.offset_top = UiTheme.CONTENT_TOP + 4.0; card.offset_bottom = UiTheme.CONTENT_TOP + 76.0
	add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	card.add_child(column)
	var info := HBoxContainer.new()
	info.add_theme_constant_override("separation", 6)
	column.add_child(info)
	var title := Label.new()
	title.text = str(summary.get("name", "")) if str(summary.get("name", "")) != "" else "PARTIDA EN CURSO"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", UiTheme.GOLD)
	info.add_child(title)
	var seconds := int(summary.get("time", 0))
	var clock := Label.new()
	clock.text = "%02d:%02d" % [seconds / 60, seconds % 60]
	clock.add_theme_font_size_override("font_size", 11)
	clock.add_theme_color_override("font_color", UiTheme.TEXT_MUTED)
	info.add_child(clock)
	var resume := Button.new()
	resume.name = "ResumeButton"
	resume.text = "REANUDAR"
	resume.custom_minimum_size = Vector2(0, 44)
	resume.size_flags_vertical = Control.SIZE_EXPAND_FILL
	resume.add_theme_font_size_override("font_size", 15)
	UiTheme.apply_primary(resume)
	resume.pressed.connect(func():
		var main_layout := _find_main_layout()
		if main_layout and main_layout.has_method("resume_run"):
			main_layout.resume_run()
	)
	column.add_child(resume)

## Floating shortcuts in a row under the HUD: Misiones, Avisos y Ajustes.
func _build_missions_side() -> void:
	var top := UiTheme.CONTENT_TOP + 8.0
	_side_button(Vector2(74, top), "res://assets/ui/icons/mail.png", "Avisos", func():
		var main_layout := _find_navigator()
		if main_layout:
			main_layout.open_modal(&"notifications")
			GameState.mark_notifications_read()
	, func() -> bool: return GameState.unread_notification_count() > 0, GameState.notifications_changed, true)
	_side_button(Vector2(132, top), "res://assets/ui/icons/missions.png", "Misiones", func():
		var main_layout := _find_navigator()
		if main_layout:
			main_layout.open_modal(&"missions")
	, func() -> bool: return GameState.has_claimable_missions(), GameState.missions_changed, true)
	_side_button(Vector2(16, top), "res://assets/ui/icons/engranajes.png", "Ajustes", func():
		var main_layout := _find_navigator()
		if main_layout:
			main_layout.open_modal(&"settings")
	, func() -> bool: return false, GameState.notifications_changed, true)

func _side_button(at: Vector2, icon_path: String, caption_text: String, on_press: Callable, has_news: Callable, changed: Signal, on_right := false) -> void:
	var side := Control.new()
	side.name = caption_text + "Side"
	add_child(side)
	if on_right:
		# Anchored to the right edge so it follows any screen width.
		side.anchor_left = 1.0
		side.anchor_right = 1.0
		side.offset_left = -at.x - 50.0
		side.offset_right = -at.x
		side.offset_top = at.y
		side.offset_bottom = at.y + 50.0
	else:
		side.position = at
		side.size = Vector2(50, 50)
	var ring := Panel.new()
	var ring_style := StyleBoxFlat.new()
	ring_style.bg_color = Color(0.06, 0.04, 0.12, 0.85)
	ring_style.border_color = Color(UiTheme.GOLD, 0.6)
	ring_style.set_border_width_all(2)
	ring_style.set_corner_radius_all(25)
	ring_style.shadow_color = Color(0, 0, 0, 0.5)
	ring_style.shadow_size = 4
	ring.add_theme_stylebox_override("panel", ring_style)
	ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	side.add_child(ring)
	var caption := Label.new()
	caption.text = caption_text
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.position = Vector2(-10, 50)
	caption.size = Vector2(70, 18)
	caption.add_theme_font_size_override("font_size", 13)
	caption.add_theme_color_override("font_color", UiTheme.TEXT)
	caption.add_theme_color_override("font_outline_color", Color("07060d"))
	caption.add_theme_constant_override("outline_size", 4)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	side.add_child(caption)
	var icon := TextureRect.new()
	icon.texture = load(icon_path) as Texture2D
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 10
	icon.offset_right = -10
	icon.offset_top = 10
	icon.offset_bottom = -10
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	side.add_child(icon)
	# "Something new" marker: a plain red dot on the shortcut's corner.
	var badge := Panel.new()
	var dot := StyleBoxFlat.new()
	dot.bg_color = UiTheme.DANGER
	dot.border_color = Color("ffe3e3")
	dot.set_border_width_all(2)
	dot.set_corner_radius_all(8)
	badge.add_theme_stylebox_override("panel", dot)
	badge.size = Vector2(14, 14)
	badge.position = Vector2(side.size.x - 13.0, 0.0)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	side.add_child(badge)
	badge.visible = has_news.call()
	# The signal lives on an autoload, so disconnect when the badge goes away;
	# otherwise the lambda keeps firing after leaving Home and hits a freed node.
	var refresh := func(_a = null):
		if is_instance_valid(badge):
			badge.visible = has_news.call()
	changed.connect(refresh)
	badge.tree_exiting.connect(func():
		if changed.is_connected(refresh):
			changed.disconnect(refresh))
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
			"preview": CHAPTER_PREVIEWS.get(1 + (i / 4), CHAPTER_PREVIEWS[3]),
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
