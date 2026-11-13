extends Control

const UiTheme := preload("res://scripts/ui/UiTheme.gd")

## Misiones diarias y semanales.
##
## Layout, top to bottom: tabs (with a red dot when that period has something
## to collect), the activity track (points earned by claiming missions, with a
## chest at each threshold), the mission list (ready-to-claim first, claimed
## last) and a "claim all" button when several are ready.
##
## All the rules live in GameState (missions_for, activity_points,
## milestones_for…); this screen only shows them.

const GOLD := Color("f4bd4e")
const CLAIMED_BORDER := Color("3a3048")
const CLAIMED_BG := Color("140f1e")
const TEXT_MUTED := UiTheme.TEXT_MUTED

const ICON_BY_TYPE := {
	"daily_kills": "res://assets/ui/equipment/weapon.png",
	"weekly_kills": "res://assets/ui/equipment/weapon.png",
	"daily_gold": "res://assets/ui/shop/gold_stack.png",
	"weekly_gold": "res://assets/ui/shop/gold_pile.png",
	"daily_runs": "res://assets/ui/navigation/dungeons.png",
	"weekly_runs": "res://assets/ui/navigation/dungeons.png",
	"daily_chests": "res://assets/ui/shop/chest_common.png",
	"weekly_chests": "res://assets/ui/shop/chest_epic.png",
	"stat:plays": "res://assets/ui/icons/play.png",
	"stat:seconds": "res://assets/mejoras/duracion.png",
	"stat:best_level": "res://assets/mejoras/experiencia_ganada.png",
	"stat:elites": "res://assets/mejoras/dano_a_jefes.png",
	"stat:evolutions": "res://assets/mejoras/mejora_suerte.png",
	"stat:upgrades": "res://assets/ui/navigation/arbol_normal.png",
}
const DEFAULT_ICON := "res://assets/ui/icons/target.png"
const CHEST := "res://assets/ui/shop/chest_common.png"
const CHEST_FINAL := "res://assets/ui/shop/chest_epic.png"

## Activity track geometry (local to the track control).
const TRACK_HEIGHT := 70.0
const TRACK_BAR_Y := 24.0
const TRACK_PAD := 24.0
const CHEST_SIZE := 38.0

signal closed

var modal_mode := false
var _current_tab := "daily" # "daily" | "weekly"
var _tab_buttons := {}
var _tab_dots := {}
var _timer_label: Label
var _activity_title: Label
var _points_label: Label
var _track: Control
var _track_info: Label
var _info_threshold := -1
var _mission_list: VBoxContainer
var _claim_all: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.make_theme()
	var root: VBoxContainer
	if modal_mode:
		var panel := PanelContainer.new()
		panel.anchor_left = 0.04
		panel.anchor_right = 0.96
		panel.anchor_top = 0.1
		panel.anchor_bottom = 0.9
		panel.add_theme_stylebox_override("panel", UiTheme.kit("panel_modal", UiTheme.panel(UiTheme.BORDER, 6, 4)))
		add_child(panel)
		var margin := MarginContainer.new()
		for side in ["left", "right", "top", "bottom"]:
			margin.add_theme_constant_override("margin_" + side, 10)
		panel.add_child(margin)
		root = VBoxContainer.new()
		root.add_theme_constant_override("separation", 8)
		margin.add_child(root)
	else:
		var bg := ColorRect.new(); bg.color = UiTheme.BG_DEEP; bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
		var art := UiTheme.background("bg_misiones.png", 0.62)
		if art != null:
			add_child(art)
		# Full-screen route keeps clear of the persistent HUD and footer.
		root = VBoxContainer.new()
		root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.offset_top = UiTheme.CONTENT_TOP
		root.offset_bottom = -128
		root.offset_left = 14
		root.offset_right = -14
		root.add_theme_constant_override("separation", 8)
		add_child(root)
	_build_content(root)
	GameState.missions_changed.connect(_refresh)
	# Open on the tab that has something to collect.
	_select_tab("weekly" if GameState.has_claimables("weekly") and not GameState.has_claimables("daily") else "daily")

func _build_content(root: VBoxContainer) -> void:
	if modal_mode:
		root.add_child(UiTheme.modal_header("MISIONES", func(): closed.emit()))
	else:
		root.add_child(UiTheme.header("MISIONES", "Pequeñas acciones, grandes leyendas", 30))

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	root.add_child(tabs)
	tabs.add_child(_build_tab_button("DIARIAS", "daily"))
	tabs.add_child(_build_tab_button("SEMANALES", "weekly"))

	_build_activity_panel(root)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	_mission_list = VBoxContainer.new()
	_mission_list.add_theme_constant_override("separation", 8)
	_mission_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_mission_list)

	_claim_all = Button.new()
	_claim_all.custom_minimum_size = Vector2(0, 48)
	_claim_all.add_theme_font_size_override("font_size", 16)
	UiTheme.apply_primary(_claim_all)
	_claim_all.pressed.connect(func(): GameState.claim_all_missions(_current_tab))
	root.add_child(_claim_all)

func _process(_delta: float) -> void:
	var seconds := GameState.seconds_until_daily_reset() if _current_tab == "daily" else GameState.seconds_until_weekly_reset()
	_timer_label.text = "Nuevas en %s" % _format_seconds(seconds)

func _format_seconds(total: int) -> String:
	var hours := total / 3600
	var minutes := (total % 3600) / 60
	if hours >= 24:
		return "%dd %02dh" % [hours / 24, hours % 24]
	return "%dh %02dm" % [hours, minutes]

# --- Tabs ---------------------------------------------------------------------

func _build_tab_button(text_value: String, tab_id: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 44 if modal_mode else 48)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.clip_text = true
	button.add_theme_font_size_override("font_size", 15)
	button.pressed.connect(_select_tab.bind(tab_id))
	_tab_buttons[tab_id] = button
	# "Something to collect here" marker on the tab's corner.
	var dot := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = UiTheme.DANGER
	style.border_color = Color("ffe3e3")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	dot.add_theme_stylebox_override("panel", style)
	dot.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	dot.offset_left = -18.0
	dot.offset_right = -4.0
	dot.offset_top = 4.0
	dot.offset_bottom = 18.0
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(dot)
	_tab_dots[tab_id] = dot
	return button

func _select_tab(tab_id: String) -> void:
	_current_tab = tab_id
	_info_threshold = -1
	for id in _tab_buttons:
		if id == tab_id:
			UiTheme.apply_primary(_tab_buttons[id])
		else:
			UiTheme.apply_secondary(_tab_buttons[id])
	_refresh()

# --- Activity track -------------------------------------------------------------

func _build_activity_panel(parent: Control) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.kit("panel_card", _card_flat(UiTheme.BORDER_SOFT, UiTheme.BG_PANEL)))
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	box.add_child(top)
	_activity_title = Label.new()
	_activity_title.add_theme_font_override("font", UiTheme.bold_font())
	_activity_title.add_theme_font_size_override("font_size", 13)
	_activity_title.add_theme_color_override("font_color", UiTheme.PURPLE)
	top.add_child(_activity_title)
	_points_label = Label.new()
	_points_label.add_theme_font_override("font", UiTheme.bold_font())
	_points_label.add_theme_font_size_override("font_size", 13)
	_points_label.add_theme_color_override("font_color", GOLD)
	_points_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_points_label)
	_timer_label = Label.new()
	_timer_label.add_theme_font_size_override("font_size", 12)
	_timer_label.add_theme_color_override("font_color", TEXT_MUTED)
	top.add_child(_timer_label)

	_track = Control.new()
	_track.custom_minimum_size = Vector2(0, TRACK_HEIGHT)
	_track.draw.connect(_draw_track)
	_track.resized.connect(_layout_track)
	box.add_child(_track)

	_track_info = Label.new()
	_track_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_track_info.clip_text = true
	_track_info.add_theme_font_size_override("font_size", 12)
	_track_info.add_theme_color_override("font_color", TEXT_MUTED)
	box.add_child(_track_info)

func _track_x(points: float) -> float:
	var usable := maxf(1.0, _track.size.x - TRACK_PAD * 2.0)
	return TRACK_PAD + usable * clampf(points / float(GameState.ACTIVITY_MAX), 0.0, 1.0)

func _draw_track() -> void:
	var left := _track_x(0.0)
	var right := _track_x(GameState.ACTIVITY_MAX)
	var points := float(GameState.activity_points(_current_tab))
	var rail := StyleBoxFlat.new()
	rail.bg_color = Color("0b0914")
	rail.border_color = Color(UiTheme.BORDER_SOFT, 0.8)
	rail.set_border_width_all(1)
	rail.set_corner_radius_all(5)
	_track.draw_style_box(rail, Rect2(left - 6.0, TRACK_BAR_Y - 5.0, right - left + 12.0, 10.0))
	if points > 0.0:
		var fill := StyleBoxFlat.new()
		fill.bg_color = GOLD
		fill.set_corner_radius_all(4)
		fill.shadow_color = Color(GOLD, 0.35)
		fill.shadow_size = 4
		_track.draw_style_box(fill, Rect2(left - 5.0, TRACK_BAR_Y - 4.0, _track_x(points) - left + 5.0, 8.0))

## One chest per milestone, placed along the bar at its point threshold.
func _refresh_track() -> void:
	for child in _track.get_children():
		_track.remove_child(child)
		child.queue_free()
	var is_daily := _current_tab == "daily"
	var points := GameState.activity_points(_current_tab)
	_activity_title.text = "ACTIVIDAD DIARIA" if is_daily else "ACTIVIDAD SEMANAL"
	_points_label.text = "%d / %d" % [points, GameState.ACTIVITY_MAX]
	var milestones: Array = GameState.milestones_for(_current_tab)
	var claimed: Array = GameState.claimed_milestones_for(_current_tab)
	var next: Dictionary = {}
	for i in milestones.size():
		var milestone: Dictionary = milestones[i]
		var threshold := int(milestone.threshold)
		var is_claimed := claimed.has(threshold)
		var can_claim := GameState.can_claim_milestone(_current_tab, threshold)
		if next.is_empty() and not is_claimed:
			next = milestone
		_track.add_child(_build_chest(milestone, i == milestones.size() - 1, is_claimed, can_claim))
	var shown: Dictionary = next
	for milestone in milestones:
		if int(milestone.threshold) == _info_threshold:
			shown = milestone
	if shown.is_empty():
		_track_info.text = "¡Todos los cofres reclamados!"
		_track_info.add_theme_color_override("font_color", GOLD)
	else:
		var ready := GameState.can_claim_milestone(_current_tab, int(shown.threshold))
		_track_info.text = ("¡Cofre listo! " if ready else "Cofre a los %d pts: " % int(shown.threshold)) + _reward_text(shown)
		_track_info.add_theme_color_override("font_color", GOLD if ready else TEXT_MUTED)
	_layout_track()
	_track.queue_redraw()

func _build_chest(milestone: Dictionary, is_final: bool, is_claimed: bool, can_claim: bool) -> Control:
	var threshold := int(milestone.threshold)
	var holder := Control.new()
	holder.set_meta("threshold", threshold)
	holder.size = Vector2(CHEST_SIZE, TRACK_HEIGHT)
	var button := Button.new()
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.icon = load(CHEST_FINAL if is_final else CHEST) as Texture2D
	button.expand_icon = true
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.position = Vector2(0, TRACK_BAR_Y - CHEST_SIZE / 2.0)
	button.size = Vector2(CHEST_SIZE, CHEST_SIZE)
	button.pivot_offset = Vector2(CHEST_SIZE, CHEST_SIZE) / 2.0
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	holder.add_child(button)
	if is_claimed:
		button.modulate = Color(0.45, 0.42, 0.55, 0.7)
		var check := UiTheme.icon_rect("check.png", 18.0)
		check.position = Vector2(CHEST_SIZE - 16.0, TRACK_BAR_Y + 2.0)
		check.size = Vector2(18, 18)
		holder.add_child(check)
	elif can_claim:
		# Ready to open: the chest keeps bouncing until it is tapped.
		var tween := button.create_tween().set_loops()
		tween.tween_property(button, "scale", Vector2(1.18, 1.18), 0.4).set_trans(Tween.TRANS_SINE)
		tween.tween_property(button, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_SINE)
	else:
		button.modulate = Color(0.6, 0.58, 0.72)
	button.pressed.connect(func():
		if GameState.can_claim_milestone(_current_tab, threshold):
			_info_threshold = -1
			GameState.claim_milestone(_current_tab, threshold)
		else:
			_info_threshold = threshold
			_refresh_track()
	)
	var label := Label.new()
	label.text = str(threshold)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-6, TRACK_BAR_Y + CHEST_SIZE / 2.0 - 2.0)
	label.size = Vector2(CHEST_SIZE + 12.0, 16)
	label.add_theme_font_override("font", UiTheme.bold_font())
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", GOLD if can_claim else (Color("6a5f7a") if is_claimed else TEXT_MUTED))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(label)
	return holder

func _layout_track() -> void:
	for holder in _track.get_children():
		holder.position = Vector2(_track_x(float(holder.get_meta("threshold", 0))) - CHEST_SIZE / 2.0, 0)
	_track.queue_redraw()

func _reward_text(entry: Dictionary) -> String:
	var bits := PackedStringArray()
	if int(entry.get("gold", 0)) > 0:
		bits.append("%d oro" % int(entry.gold))
	if int(entry.get("gems", 0)) > 0:
		bits.append("%d gema%s" % [int(entry.gems), "s" if int(entry.gems) != 1 else ""])
	if int(entry.get("essence", 0)) > 0:
		bits.append("%d esencia" % int(entry.essence))
	if str(entry.get("item", "")) != "":
		bits.append("1 objeto")
	return " · ".join(bits)

# --- Mission list ---------------------------------------------------------------

func _refresh() -> void:
	if not is_instance_valid(_mission_list):
		return
	for id in _tab_dots:
		_tab_dots[id].visible = GameState.has_claimables(id)
	_refresh_track()
	for child in _mission_list.get_children():
		_mission_list.remove_child(child)
		child.queue_free()
	# Ready to claim first, then in progress, claimed at the bottom.
	var ready: Array = []
	var ongoing: Array = []
	var done: Array = []
	for mission in GameState.missions_for(_current_tab):
		if GameState.is_mission_claimed(mission):
			done.append(mission)
		elif GameState.can_claim_mission(mission):
			ready.append(mission)
		else:
			ongoing.append(mission)
	for mission in ready + ongoing + done:
		_mission_list.add_child(_build_mission_card(mission))
	_claim_all.visible = ready.size() >= 2
	_claim_all.text = "RECLAMAR TODO (%d)" % ready.size()

func _build_mission_card(mission: Dictionary) -> Control:
	var claimed := GameState.is_mission_claimed(mission)
	var can_claim := GameState.can_claim_mission(mission)
	var target := int(mission.get("target", 0))
	var progress := mini(GameState.mission_progress(mission), target)

	var card := PanelContainer.new()
	if claimed:
		card.add_theme_stylebox_override("panel", _card_flat(CLAIMED_BORDER, CLAIMED_BG))
	elif can_claim:
		var ready_style := _card_flat(GOLD, Color("231c2a"))
		ready_style.shadow_color = Color(GOLD, 0.25)
		ready_style.shadow_size = 5
		card.add_theme_stylebox_override("panel", ready_style)
	else:
		card.add_theme_stylebox_override("panel", UiTheme.kit("panel_card", _card_flat(UiTheme.BORDER_SOFT, UiTheme.BG_PANEL)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)

	var icon_frame := PanelContainer.new()
	icon_frame.custom_minimum_size = Vector2(50, 50)
	icon_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_frame.add_theme_stylebox_override("panel", _icon_frame_style(can_claim))
	var icon := TextureRect.new()
	icon.texture = load(str(ICON_BY_TYPE.get(str(mission.get("type", "")), DEFAULT_ICON)))
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = Color(0.5, 0.5, 0.55) if claimed else Color.WHITE
	icon_frame.add_child(icon)
	row.add_child(icon_frame)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(box)

	var title := Label.new()
	title.text = str(mission.get("name", ""))
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.add_theme_font_override("font", UiTheme.bold_font())
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color("6a5f7a") if claimed else UiTheme.GOLD)
	box.add_child(title)

	var desc := Label.new()
	desc.text = str(mission.get("description", ""))
	desc.clip_text = true
	desc.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", TEXT_MUTED if claimed else Color("d8c9ed"))
	box.add_child(desc)

	# Progress bar with the count written on it.
	var bar := ProgressBar.new()
	bar.max_value = maxi(target, 1)
	bar.value = progress
	bar.show_percentage = false
	bar.custom_minimum_size.y = 16
	bar.add_theme_stylebox_override("fill", UiTheme.bar(Color("4a3f5c") if claimed else (GOLD if can_claim else UiTheme.ACCENT_DIM)))
	box.add_child(bar)
	var count := Label.new()
	count.text = _progress_text(mission, progress, target)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	count.add_theme_font_override("font", UiTheme.bold_font())
	count.add_theme_font_size_override("font_size", 11)
	count.add_theme_color_override("font_color", TEXT_MUTED if claimed else UiTheme.TEXT)
	count.add_theme_color_override("font_outline_color", Color("07060d"))
	count.add_theme_constant_override("outline_size", 4)
	bar.add_child(count)

	var rewards := HBoxContainer.new()
	rewards.add_theme_constant_override("separation", 10)
	rewards.modulate = Color(1, 1, 1, 0.45) if claimed else Color.WHITE
	box.add_child(rewards)
	if int(mission.get("gold", 0)) > 0:
		rewards.add_child(_reward_chip("coin.png", str(int(mission.gold)), GOLD))
	if int(mission.get("gems", 0)) > 0:
		rewards.add_child(_reward_chip("gem.png", str(int(mission.gems)), Color("d9a6ff")))
	rewards.add_child(_reward_chip("", "+%d act." % int(mission.get("points", 0)), UiTheme.PURPLE))

	if claimed:
		var check := UiTheme.icon_rect("check.png", 30.0)
		check.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		check.custom_minimum_size = Vector2(64, 30)
		check.modulate = Color(1, 1, 1, 0.6)
		row.add_child(check)
		return card
	var action := Button.new()
	action.custom_minimum_size = Vector2(72, 40)
	action.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	action.add_theme_font_size_override("font_size", 12)
	if can_claim:
		action.text = "RECLAMAR"
		UiTheme.apply_primary_flat(action)
		action.pressed.connect(func(): GameState.claim_mission(str(mission.get("id", ""))))
	else:
		action.text = "IR"
		UiTheme.apply_secondary(action, 8.0)
		action.pressed.connect(_go_to.bind(str(mission.get("route", "home"))))
	row.add_child(action)
	return card

func _progress_text(mission: Dictionary, progress: int, target: int) -> String:
	if str(mission.get("unit", "")) == "time":
		return "%d:%02d / %d:%02d" % [progress / 60, progress % 60, target / 60, target % 60]
	return "%d / %d" % [progress, target]

## Small "icon + amount" reward marker; with no icon it is just the text.
func _reward_chip(icon_file: String, text_value: String, color: Color) -> Control:
	var chip := HBoxContainer.new()
	chip.add_theme_constant_override("separation", 3)
	if icon_file != "":
		chip.add_child(UiTheme.icon_rect(icon_file, 16.0))
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_override("font", UiTheme.bold_font())
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", color)
	chip.add_child(label)
	return chip

## The IR button: closes the modal (if any) and opens the screen where the
## mission is done.
func _go_to(route: String) -> void:
	var main_layout := _find_main_layout()
	if main_layout == null:
		return
	if modal_mode:
		closed.emit()
		if main_layout.has_method("close_active_modal") and main_layout.has_open_modal():
			main_layout.close_active_modal()
	main_layout.navigate_to(StringName(route))

func _find_main_layout() -> Node:
	var node := get_parent()
	while node:
		if node.has_method("navigate_to"):
			return node
		node = node.get_parent()
	return null

# --- Styles ---------------------------------------------------------------------

func _card_flat(border: Color, bg: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(UiTheme.CORNER)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _icon_frame_style(highlight: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("140f1f")
	style.border_color = GOLD if highlight else UiTheme.BORDER_SOFT
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(5)
	return style
