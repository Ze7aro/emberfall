extends Control

const UiTheme := preload("res://scripts/ui/UiTheme.gd")

## PROMPT_MISIONES_EMBERFALL.md: Misiones diarias/semanales con progreso,
## recompensas individuales y una barra de progreso acumulado con hitos
## (cofres). Los hitos se escalan a la cantidad real de misiones por período
## (3 diarias, 4 semanales) en vez del ejemplo ilustrativo del prompt
## (1/3/5/7/10), que asume un catálogo más grande del que existe hoy.

const BG := UiTheme.BG_DEEP
const PANEL := UiTheme.BG_PANEL
const STONE_BORDER := UiTheme.BORDER_SOFT
const TURQ := UiTheme.ACCENT
const GOLD := Color("f4bd4e")
const CLAIMED_BORDER := Color("3a3048")
const CLAIMED_BG := Color("140f1e")
const TEXT_MUTED := UiTheme.TEXT_MUTED
const TEXT_BRIGHT := UiTheme.TEXT

const ICON_BY_TYPE := {
	"daily_kills": "res://assets/ui/equipment/weapon.png",
	"weekly_kills": "res://assets/ui/equipment/weapon.png",
	"daily_gold": "res://assets/ui/icons/target.png",
	"weekly_gold": "res://assets/ui/icons/target.png",
	"daily_runs": "res://assets/ui/navigation/dungeons.png",
	"weekly_runs": "res://assets/ui/navigation/dungeons.png",
	"weekly_chests": "res://assets/ui/shop/chest_epic.png",
}

signal closed

var modal_mode := false
var _tab_buttons: Array[Button] = []
var _period_root: Control
var _current_tab := "daily" # "daily" | "weekly"
var _timer_label: Label
var _milestone_row: HBoxContainer
var _milestone_title: Label
var _mission_list: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.make_theme()
	var root: VBoxContainer
	if modal_mode:
		var panel := PanelContainer.new()
		panel.anchor_left = 0.04
		panel.anchor_right = 0.96
		panel.anchor_top = 0.12
		panel.anchor_bottom = 0.88
		panel.add_theme_stylebox_override("panel", UiTheme.kit("panel_modal", UiTheme.panel(UiTheme.BORDER, 6, 4)))
		add_child(panel)
		var margin := MarginContainer.new()
		for side in ["left", "right", "top", "bottom"]:
			margin.add_theme_constant_override("margin_" + side, 12)
		panel.add_child(margin)
		root = VBoxContainer.new()
		root.add_theme_constant_override("separation", 8)
		margin.add_child(root)
	else:
		var bg := ColorRect.new(); bg.color = BG; bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
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
		root.add_theme_constant_override("separation", 10)
		add_child(root)
	_build_content(root)
	GameState.missions_changed.connect(_refresh)
	_select_tab("daily")

func _build_content(root: VBoxContainer) -> void:

	var header := HBoxContainer.new()
	root.add_child(header)
	var title := UiTheme.header("MISIONES", "PEQUEÑAS ACCIONES, GRANDES LEYENDAS", 34 if not modal_mode else 24, "misiones_header.png")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	if modal_mode:
		var close := Button.new()
		close.text = "×"
		close.custom_minimum_size = Vector2(42, 42)
		close.add_theme_font_size_override("font_size", 26)
		close.pressed.connect(func(): closed.emit())
		header.add_child(close)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	root.add_child(tabs)
	var daily_tab := _build_tab_button("DIARIAS", "daily")
	var weekly_tab := _build_tab_button("SEMANALES", "weekly")
	tabs.add_child(daily_tab); tabs.add_child(weekly_tab)
	_tab_buttons = [daily_tab, weekly_tab]

	# Own row under the tabs so it never pushes them past the panel edge.
	_timer_label = Label.new()
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_timer_label.add_theme_font_size_override("font_size", 10)
	_timer_label.add_theme_color_override("font_color", TEXT_MUTED)
	root.add_child(_timer_label)


	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	_mission_list = VBoxContainer.new()
	_mission_list.add_theme_constant_override("separation", 10)
	_mission_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_mission_list)

	_build_milestone_panel(root)

func _find_main_layout() -> Node:
	var node := get_parent()
	while node:
		if node.has_method("navigate_to"):
			return node
		node = node.get_parent()
	return null

func _process(_delta: float) -> void:
	var seconds := GameState.seconds_until_daily_reset() if _current_tab == "daily" else GameState.seconds_until_weekly_reset()
	_timer_label.text = "Se reinician en: %s" % _format_seconds(seconds)

func _format_seconds(total: int) -> String:
	var hours := total / 3600
	var minutes := (total % 3600) / 60
	if hours >= 24:
		return "%dd %02dh" % [hours / 24, hours % 24]
	return "%d h %02d min" % [hours, minutes]

func _build_tab_button(text_value: String, tab_id: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 48 if modal_mode else 54)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.clip_text = true
	button.add_theme_font_size_override("font_size", _tab_font_size())
	button.pressed.connect(_select_tab.bind(tab_id))
	return button

func _select_tab(tab_id: String) -> void:
	_current_tab = tab_id
	for i in _tab_buttons.size():
		var is_active := (i == 0 and tab_id == "daily") or (i == 1 and tab_id == "weekly")
		if is_active:
			UiTheme.apply_primary(_tab_buttons[i], _tab_font_size())
		else:
			UiTheme.apply_secondary(_tab_buttons[i], _tab_font_size())
	_refresh()

func _tab_font_size() -> float:
	return 14.0 if modal_mode else 16.0

func _build_milestone_panel(parent: Control) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _stone_style(false))
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	_milestone_title = Label.new()
	_milestone_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_milestone_title.add_theme_font_size_override("font_size", 14)
	_milestone_title.add_theme_color_override("font_color", UiTheme.PURPLE)
	box.add_child(_milestone_title)

	_milestone_row = HBoxContainer.new()
	_milestone_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_milestone_row.add_theme_constant_override("separation", 14)
	box.add_child(_milestone_row)

## Cada hito es una "ficha" clickeable: apagada y con check si ya se
## reclamó, con brillo turquesa y botón si está disponible, atenuada si
## todavía no se alcanzó — igual criterio visual que las misiones mismas.
func _refresh_milestones() -> void:
	for child in _milestone_row.get_children():
		child.queue_free()
	var is_daily := _current_tab == "daily"
	_milestone_title.text = "RECOMPENSA POR ACTIVIDAD DIARIA" if is_daily else "RECOMPENSA POR ACTIVIDAD SEMANAL"
	var milestones: Array = GameState.DAILY_MILESTONES if is_daily else GameState.WEEKLY_MILESTONES
	var claimed_count := GameState.daily_missions_claimed_count() if is_daily else GameState.weekly_missions_claimed_count()
	for milestone in milestones:
		var threshold := int(milestone.threshold)
		var can_claim: bool = GameState.can_claim_daily_milestone(threshold) if is_daily else GameState.can_claim_weekly_milestone(threshold)
		var already_claimed: bool = (GameState.claimed_daily_milestones if is_daily else GameState.claimed_weekly_milestones).has(threshold)
		var reached := claimed_count >= threshold
		_milestone_row.add_child(_build_milestone_chip(threshold, can_claim, already_claimed, reached, is_daily))

func _build_milestone_chip(threshold: int, can_claim: bool, already_claimed: bool, reached: bool, is_daily: bool) -> Control:
	var chip := VBoxContainer.new()
	chip.alignment = BoxContainer.ALIGNMENT_CENTER
	chip.add_theme_constant_override("separation", 4)

	var badge := Button.new()
	badge.custom_minimum_size = Vector2(52, 52)
	badge.text = "✓" if already_claimed else str(threshold)
	badge.disabled = not can_claim
	var style := _stone_style(can_claim)
	if already_claimed:
		style = _claimed_style()
	badge.add_theme_stylebox_override("normal", style)
	badge.add_theme_stylebox_override("disabled", style)
	badge.add_theme_color_override("font_color", TURQ if can_claim else (TEXT_MUTED if already_claimed else Color("4a3f5c")))
	badge.add_theme_color_override("font_disabled_color", TURQ if can_claim else (TEXT_MUTED if already_claimed else Color("4a3f5c")))
	if can_claim:
		badge.pressed.connect(func():
			if is_daily: GameState.claim_daily_milestone(threshold)
			else: GameState.claim_weekly_milestone(threshold)
		)
	chip.add_child(badge)

	var label := Label.new()
	label.text = "%d misión%s" % [threshold, "es" if threshold != 1 else ""]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", TEXT_MUTED)
	chip.add_child(label)
	return chip

func _refresh() -> void:
	_refresh_milestones()
	var missions: Array = GameState.DAILY_MISSIONS if _current_tab == "daily" else GameState.WEEKLY_MISSIONS
	for child in _mission_list.get_children():
		child.queue_free()
	for mission in missions:
		_mission_list.add_child(_build_mission_card(mission))

func _build_mission_card(mission: Dictionary) -> Control:
	var claimed := GameState.is_mission_claimed(mission)
	var progress := GameState.mission_progress(mission)
	var target := int(mission.get("target", 0))
	var can_claim := GameState.can_claim_mission(mission)

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _claimed_style() if claimed else _stone_style(can_claim))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)

	var icon_frame := PanelContainer.new()
	icon_frame.custom_minimum_size = Vector2(56, 56)
	icon_frame.add_theme_stylebox_override("panel", _icon_frame_style())
	var icon_path: String = ICON_BY_TYPE.get(str(mission.get("type", "")), "res://assets/ui/icons/target.png")
	var icon := TextureRect.new()
	icon.texture = load(icon_path)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = Color(1, 1, 1) if not claimed else Color(0.5, 0.5, 0.55)
	icon_frame.add_child(icon)
	row.add_child(icon_frame)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(box)

	var title := Label.new()
	title.text = str(mission.get("name", ""))
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", TURQ if not claimed else Color("6a5f7a"))
	box.add_child(title)

	var desc := Label.new()
	desc.text = str(mission.get("description", ""))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color("d8c9ed") if not claimed else TEXT_MUTED)
	box.add_child(desc)

	var bar := ProgressBar.new()
	bar.max_value = maxi(target, 1)
	bar.value = mini(progress, target)
	bar.show_percentage = false
	bar.custom_minimum_size.y = 10
	box.add_child(bar)

	# Progress and rewards on separate lines: side by side they were wider
	# than the card on weekly missions and pushed it past the panel.
	var progress_label := Label.new()
	progress_label.text = "%d / %d" % [mini(progress, target), target]
	progress_label.add_theme_font_size_override("font_size", 11)
	progress_label.add_theme_color_override("font_color", TEXT_MUTED)
	box.add_child(progress_label)

	var reward_bits: Array[String] = []
	if int(mission.get("gold", 0)) > 0:
		reward_bits.append("%d oro" % int(mission.get("gold", 0)))
	if int(mission.get("gems", 0)) > 0:
		reward_bits.append("%d esmeraldas" % int(mission.get("gems", 0)))
	var reward_label := Label.new()
	reward_label.text = " · ".join(reward_bits)
	reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reward_label.add_theme_font_size_override("font_size", 11)
	reward_label.add_theme_color_override("font_color", GOLD if not claimed else TEXT_MUTED)
	box.add_child(reward_label)

	if claimed:
		var action := Button.new()
		action.custom_minimum_size = Vector2(44, 44)
		action.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		action.text = "✓"
		action.disabled = true
		action.add_theme_stylebox_override("disabled", _claimed_style())
		row.add_child(action)
	elif can_claim:
		var action := Button.new()
		action.custom_minimum_size = Vector2(84, 44)
		action.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		action.add_theme_font_size_override("font_size", 12)
		action.text = "RECLAMAR"
		action.add_theme_color_override("font_color", Color("102018"))
		action.add_theme_stylebox_override("normal", _claim_button_style())
		action.add_theme_stylebox_override("hover", _claim_button_style())
		action.pressed.connect(func(): GameState.claim_mission(str(mission.get("id", ""))))
		row.add_child(action)
	return card

## "Marco grueso de piedra oscura" — chunky border, low corner radius (not
## the softly-rounded panels used elsewhere), a turquoise border when
## something here is actionable.
func _stone_style(actionable: bool) -> StyleBox:
	if not actionable:
		return UiTheme.kit("panel_card", _stone_flat(false))
	return _stone_flat(true)

func _stone_flat(actionable: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = TURQ if actionable else STONE_BORDER
	style.set_border_width_all(3)
	style.set_corner_radius_all(UiTheme.CORNER)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _claimed_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = CLAIMED_BG
	style.border_color = CLAIMED_BORDER
	style.set_border_width_all(3)
	style.set_corner_radius_all(UiTheme.CORNER)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _icon_frame_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("140f1f")
	style.border_color = STONE_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	return style

func _claim_button_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = TURQ
	style.border_color = TURQ
	style.set_border_width_all(2)
	style.set_corner_radius_all(UiTheme.CORNER)
	return style

func _tab_style(active: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = TURQ if active else PANEL
	style.border_color = TURQ if active else STONE_BORDER
	style.set_border_width_all(3)
	style.set_corner_radius_all(UiTheme.CORNER)
	return style
