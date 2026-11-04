extends CanvasLayer

const UiTheme := preload("res://scripts/ui/UiTheme.gd")

const GOLD := Color("e8b84a")

var world: Node
var xp_bar: ProgressBar
var level_label: Label
var timer_label: Label
var hearts: HeartsRow
var panel: PanelContainer
var pause_button: Button
var pause_panel: PanelContainer
var _confirm_exit := false
## Owned abilities, always visible under the timer (actives row, passives
## row). Rebuilt only when `_build_signature` changes, not every frame.
var _build_bar: VBoxContainer
var _build_signature := ""
## "Descartar" arms this; the next card tapped is banished instead of picked.
var _banish_mode := false
var _announce_label: Label
var _announce_tween: Tween

## First-run guidance (PLAY-01): a non-blocking hint that states the goal and
## the control scheme, gone as soon as the player actually moves, plus one
## line on the first level-up screen. Never shown again once GameState marks
## it complete — no modal, no forced reading, just gets out of the way.
var _tutorial_active := false
var _tutorial_hint: Label

func setup(owner: Node) -> void:
	world = owner
	_tutorial_active = not GameState.tutorial_completed
	# Layout: XP bar glued to the top edge; under it, hearts on the left and
	# the level on the right; then timer/kills and the build bar.
	var top := _safe_top()
	xp_bar = ProgressBar.new()
	xp_bar.theme = UiTheme.make_theme()
	xp_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	xp_bar.offset_top = top; xp_bar.offset_bottom = top + XP_BAR_HEIGHT
	xp_bar.show_percentage = false
	xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Flat thin style: the kit's framed bar needs ~24px of height to show a fill.
	var xp_back := UiTheme.bar(Color(0.05, 0.03, 0.10, 0.92))
	xp_back.set_corner_radius_all(0)
	xp_back.border_color = Color("55446e")
	xp_back.border_width_bottom = 2
	var xp_fill := UiTheme.bar(Color("42d8e8"))
	xp_fill.set_corner_radius_all(0)
	xp_fill.border_color = Color("b6f4fb")
	xp_fill.border_width_top = 2
	xp_bar.add_theme_stylebox_override("background", xp_back)
	xp_bar.add_theme_stylebox_override("fill", xp_fill)
	add_child(xp_bar)
	hearts = HeartsRow.new()
	hearts.heart_size = 24.0
	hearts.spacing = 4.0
	hearts.position = Vector2(12, top + XP_BAR_HEIGHT + 8)
	hearts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hearts)
	level_label = Label.new()
	level_label.theme = UiTheme.make_theme()
	level_label.anchor_left = 1.0; level_label.anchor_right = 1.0
	level_label.offset_left = -140; level_label.offset_right = -12
	level_label.offset_top = top + XP_BAR_HEIGHT + 6
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	level_label.add_theme_font_size_override("font_size", 18)
	level_label.add_theme_color_override("font_color", Color("9fe8ff"))
	level_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	level_label.add_theme_constant_override("shadow_offset_x", 1)
	level_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(level_label)
	timer_label = Label.new()
	timer_label.position = Vector2(12, top + XP_BAR_HEIGHT + 40)
	timer_label.add_theme_font_size_override("font_size", 14)
	timer_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	timer_label.add_theme_constant_override("shadow_offset_x", 1)
	timer_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(timer_label)
	_build_bar = VBoxContainer.new()
	_build_bar.position = Vector2(12, top + XP_BAR_HEIGHT + 64)
	_build_bar.add_theme_constant_override("separation", 3)
	_build_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_build_bar)
	var joystick: Control = load("res://scripts/components/virtual_joystick.gd").new()
	joystick.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	joystick.direction_changed.connect(_on_joystick)
	add_child(joystick)

	pause_button = Button.new()
	pause_button.text = ""
	pause_button.anchor_left = 1.0; pause_button.anchor_right = 1.0
	pause_button.offset_left = -64; pause_button.offset_right = -16
	pause_button.offset_top = top + XP_BAR_HEIGHT + 34; pause_button.offset_bottom = top + XP_BAR_HEIGHT + 82
	pause_button.icon = UiTheme.icon("pause.png")
	pause_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_button.theme = UiTheme.make_theme()
	pause_button.pressed.connect(_toggle_pause)
	add_child(pause_button)

	# Testing aid, editor/debug builds only (never in an exported release).
	if OS.is_debug_build():
		var debug_column := VBoxContainer.new()
		debug_column.anchor_left = 1.0; debug_column.anchor_right = 1.0
		debug_column.offset_left = -76; debug_column.offset_right = -16
		debug_column.offset_top = top + XP_BAR_HEIGHT + 90
		debug_column.add_theme_constant_override("separation", 4)
		add_child(debug_column)
		for entry in [["JEFE", "boss"], ["ÉLITE", "elite"], ["MINI", "miniboss"], ["HORDA", "horde"], ["DROPS", "drops"], ["HAB ›", "ability_next"], ["NV +", "ability_up"]]:
			var debug_button := Button.new()
			debug_button.text = str(entry[0])
			debug_button.focus_mode = Control.FOCUS_NONE
			debug_button.add_theme_font_size_override("font_size", 10)
			debug_button.custom_minimum_size = Vector2(60, 26)
			var action := str(entry[1])
			debug_button.pressed.connect(func(): world.debug_action(action))
			debug_column.add_child(debug_button)

	_announce_label = Label.new()
	_announce_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_announce_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_announce_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_announce_label.anchor_left = 0.5; _announce_label.anchor_right = 0.5
	_announce_label.offset_left = -170; _announce_label.offset_right = 170
	_announce_label.anchor_top = 0.3; _announce_label.anchor_bottom = 0.3
	_announce_label.add_theme_font_size_override("font_size", 20)
	_announce_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_announce_label.add_theme_constant_override("shadow_offset_x", 2)
	_announce_label.add_theme_constant_override("shadow_offset_y", 2)
	_announce_label.modulate.a = 0.0
	add_child(_announce_label)
	if world.has_signal("announced"):
		world.announced.connect(_announce)

	if _tutorial_active:
		_build_tutorial_hint()

const XP_BAR_HEIGHT := 12.0

## Top inset for notches/cutouts on phones, in viewport units.
func _safe_top() -> float:
	if not OS.has_feature("mobile"):
		return 0.0
	var window := DisplayServer.window_get_size()
	if window.y <= 0:
		return 0.0
	var safe := DisplayServer.get_display_safe_area()
	return maxf(0.0, float(safe.position.y) * get_viewport().get_visible_rect().size.y / float(window.y))

## Centered banner that pops in and fades out; a newer one replaces it.
func _announce(text: String, color: Color) -> void:
	if _announce_tween:
		_announce_tween.kill()
	_announce_label.text = text
	_announce_label.add_theme_color_override("font_color", color)
	_announce_label.modulate.a = 1.0
	_announce_label.scale = Vector2(1.15, 1.15)
	_announce_label.pivot_offset = Vector2(170, 14)
	_announce_tween = create_tween()
	_announce_tween.tween_property(_announce_label, "scale", Vector2.ONE, 0.18)
	_announce_tween.tween_interval(1.8)
	_announce_tween.tween_property(_announce_label, "modulate:a", 0.0, 0.5)

func _build_tutorial_hint() -> void:
	_tutorial_hint = Label.new()
	_tutorial_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tutorial_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tutorial_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tutorial_hint.anchor_left = 0.5; _tutorial_hint.anchor_right = 0.5
	_tutorial_hint.offset_left = -160; _tutorial_hint.offset_right = 160
	_tutorial_hint.anchor_top = 1.0; _tutorial_hint.anchor_bottom = 1.0
	_tutorial_hint.offset_top = -160; _tutorial_hint.offset_bottom = -100
	_tutorial_hint.add_theme_font_size_override("font_size", 15)
	_tutorial_hint.add_theme_color_override("font_color", UiTheme.TEXT)
	_tutorial_hint.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	_tutorial_hint.add_theme_constant_override("shadow_offset_x", 1)
	_tutorial_hint.add_theme_constant_override("shadow_offset_y", 1)
	_tutorial_hint.text = "Sobreviví y derrotá al jefe.\nTocá y arrastrá en cualquier parte de la pantalla para moverte."
	add_child(_tutorial_hint)

func _toggle_pause() -> void:
	if GameState.screen == "playing":
		SfxPlayer.play_ui("ui/pause.wav")
		GameState.change_screen("paused")
	elif GameState.screen == "paused":
		SfxPlayer.play_ui("ui/resume.wav")
		GameState.change_screen("playing")

func _process(_delta: float) -> void:
	if not is_instance_valid(world):
		return
	pause_button.visible = GameState.screen == "playing"
	if GameState.screen == "paused" and not pause_panel:
		show_pause_panel()
	if GameState.screen != "paused" and pause_panel:
		pause_panel.queue_free()
		pause_panel = null
		_confirm_exit = false
	if GameState.screen not in ["playing", "level_up"]:
		return
	if is_instance_valid(_tutorial_hint) and is_instance_valid(world.player) and world.player.velocity.length_squared() > 400.0:
		_tutorial_hint.queue_free()
		_tutorial_hint = null
	level_label.text = "NV. %d" % world.level
	xp_bar.value = float(world.xp) / float(world.xp_needed) * 100.0
	hearts.set_hearts(world.player.hp, world.player.max_hp)
	timer_label.text = "%02d:%02d  ·  %d BAJAS" % [int(world.elapsed) / 60, int(world.elapsed) % 60, world.kills]
	# The boss draws its own name and health bar over its head.
	_refresh_build_bar()
	if GameState.screen == "level_up" and not panel:
		show_level_up()
	if GameState.screen != "level_up" and panel:
		panel.queue_free()
		panel = null

## Full-screen dimmer that also swallows touches, so the joystick underneath
## can't react while a modal panel (level-up / pause) is open. Lives and dies
## with the panel it backs.
func _add_blocker_for(target: Control) -> void:
	var blocker := ColorRect.new()
	blocker.color = Color(0.03, 0.02, 0.07, 0.72)
	blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(blocker)
	target.tree_exited.connect(blocker.queue_free)

func show_level_up() -> void:
	_banish_mode = false
	panel = PanelContainer.new()
	panel.theme = UiTheme.make_theme()
	panel.add_theme_stylebox_override("panel", UiTheme.kit("panel_modal", UiTheme.panel(UiTheme.PURPLE, UiTheme.CORNER, 4)))
	_add_blocker_for(panel)
	# Centered on any screen size instead of a fixed 390×844 position.
	panel.anchor_left = 0.5; panel.anchor_right = 0.5
	panel.anchor_top = 0.5; panel.anchor_bottom = 0.5
	panel.offset_left = -LEVEL_UP_SIZE.x / 2.0; panel.offset_right = LEVEL_UP_SIZE.x / 2.0
	panel.offset_top = -LEVEL_UP_SIZE.y / 2.0; panel.offset_bottom = LEVEL_UP_SIZE.y / 2.0
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	box.add_child(UiTheme.header("ELIGE UN PODER", "TU LEYENDA EVOLUCIONA", 24))
	var slots := Label.new()
	slots.text = "ACTIVAS %d/%d  ·  PASIVAS %d/%d" % [world.skills.size(), AbilityCatalog.ACTIVE_SLOTS, world.passives.size(), AbilityCatalog.PASSIVE_SLOTS]
	slots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slots.add_theme_font_size_override("font_size", 12)
	slots.add_theme_color_override("font_color", UiTheme.ACCENT)
	box.add_child(slots)
	if _tutorial_active:
		var hint := Label.new()
		hint.text = "Elegí una para mejorar a tu personaje"
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.add_theme_font_size_override("font_size", 11)
		hint.add_theme_color_override("font_color", UiTheme.TEXT_MUTED)
		box.add_child(hint)
	# Cards side by side, as in the design reference.
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(row)
	for option in world.current_level_up_options:
		row.add_child(_build_power_card(option))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	box.add_child(actions)
	actions.add_child(_action_button("CAMBIAR (%d)" % world.rerolls, world.rerolls > 0, _reroll))
	var banish := _action_button("DESCARTAR (%d)" % world.banishes, world.banishes > 0, _toggle_banish)
	banish.toggle_mode = true
	actions.add_child(banish)
	actions.add_child(_action_button("SALTAR", true, _skip))
	add_child(panel)
	panel.pivot_offset = LEVEL_UP_SIZE * 0.5
	panel.scale = Vector2(0.96, 0.96)
	panel.modulate.a = 0.0
	var appear := panel.create_tween().set_parallel(true)
	appear.tween_property(panel, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	appear.tween_property(panel, "modulate:a", 1.0, 0.10)

const LEVEL_UP_SIZE := Vector2(350, 420)

func _action_button(text: String, enabled: bool, on_press: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.disabled = not enabled
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 11)
	button.custom_minimum_size = Vector2(0, 44)
	button.pressed.connect(on_press)
	return button

func _build_power_card(option: String) -> Control:
	var is_evolution := AbilityCatalog.is_evolution(option)
	var base_id := AbilityCatalog.evolution_source(option) if is_evolution else option
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 230)
	var card_style := UiTheme.slot(true, 6)
	if is_evolution:
		card_style.border_color = GOLD
		card_style.shadow_color = Color(GOLD, 0.45)
		card_style.shadow_size = 10
		card.add_theme_stylebox_override("panel", card_style)
	else:
		card.add_theme_stylebox_override("panel", UiTheme.kit("panel_card", card_style, 6.0))
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 4)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(stack)
	var current_level: int = 0 if is_evolution else world.ability_level(option)
	var kind_text := "EVOLUCIÓN"
	if not is_evolution:
		if AbilityCatalog.is_weapon(option):
			kind_text = "ARMA"
		else:
			kind_text = "ACTIVA" if AbilityCatalog.is_active(option) else "PASIVA"
		if current_level == 0:
			kind_text += " · NUEVA"
	stack.add_child(_card_label(kind_text, 9, GOLD if is_evolution else UiTheme.TEXT_MUTED))
	var icon := _ability_icon(base_id, is_evolution, 56.0)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(icon)
	stack.add_child(_card_label(AbilityCatalog.display_name(base_id, is_evolution), 11, GOLD if is_evolution else UiTheme.ACCENT))
	if is_evolution:
		var paired := AbilityCatalog.evolution_partner(base_id)
		stack.add_child(_card_label("%s + %s" % [AbilityCatalog.display_name(base_id), AbilityCatalog.display_name(paired)], 8, UiTheme.PURPLE))
	else:
		stack.add_child(_card_label("NV. %d → %d" % [current_level, current_level + 1], 11, UiTheme.PURPLE))
	var desc_text := AbilityCatalog.description(option)
	if AbilityCatalog.is_weapon(option) and current_level > 0:
		desc_text = AbilityCatalog.weapon_level_text(current_level + 1)
	var desc := _card_label(desc_text, 10, UiTheme.TEXT_MUTED)
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(desc)
	# Every active card names its evolution partner, so the player learns
	# recipes while playing instead of needing a wiki.
	if not is_evolution and AbilityCatalog.has_evolution(option):
		var partner := AbilityCatalog.evolution_partner(option)
		stack.add_child(_card_label("Evoluciona con %s" % AbilityCatalog.display_name(partner), 8, Color(GOLD, 0.75)))
	# The whole card is the button.
	var pick := Button.new()
	pick.flat = true
	pick.focus_mode = Control.FOCUS_NONE
	pick.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pick.pressed.connect(_on_card_pressed.bind(option))
	card.add_child(pick)
	return card

func _card_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

## Icon for an ability, or a drawn placeholder (colored tile with the
## initial) until its generated art exists — see AbilityCatalog.icon().
func _ability_icon(id: String, evolved: bool, size: float) -> Control:
	var texture := AbilityCatalog.icon(id, evolved)
	if texture != null:
		var rect := TextureRect.new()
		rect.texture = texture
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.custom_minimum_size = Vector2(size, size)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if evolved:
			rect.modulate = Color(1.15, 1.05, 0.8)
		return rect
	var tile := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1a1028")
	style.border_color = GOLD if evolved else AbilityCatalog.color(id)
	style.set_border_width_all(2)
	style.set_corner_radius_all(int(size * 0.2))
	tile.add_theme_stylebox_override("panel", style)
	tile.custom_minimum_size = Vector2(size, size)
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var initial := _card_label(AbilityCatalog.display_name(id).left(1), int(size * 0.5), style.border_color)
	initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tile.add_child(initial)
	return tile

func _on_card_pressed(option: String) -> void:
	if _banish_mode:
		if world.banish_option(option):
			SfxPlayer.play_ui("ui/ui_select.wav")
			_close_level_up_panel()
		return
	_choose(option)

func _toggle_banish() -> void:
	_banish_mode = not _banish_mode

func _skip() -> void:
	world.skip_level_up()
	_close_level_up_panel()

func _close_level_up_panel() -> void:
	if is_instance_valid(panel):
		panel.queue_free()
		panel = null

func _choose(option: String) -> void:
	world.choose_power(option)
	if _tutorial_active:
		_tutorial_active = false
		GameState.mark_tutorial_completed()
	_close_level_up_panel()

## Actives row + passives row; evolved actives get a gold border.
func _refresh_build_bar() -> void:
	var signature := "%s|%s|%s" % [world.skills, world.passives, world.evolved]
	if signature == _build_signature:
		return
	_build_signature = signature
	for child in _build_bar.get_children():
		child.queue_free()
	for group in [world.skills, world.passives]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_build_bar.add_child(row)
		for id in group:
			row.add_child(_build_slot(id, int(group[id]), world.is_evolved(id), 26.0))
	_build_bar.visible = not world.skills.is_empty() or not world.passives.is_empty()

func _build_slot(id: String, lvl: int, evolved: bool, size: float) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(size, size)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := _ability_icon(id, evolved, size)
	holder.add_child(icon)
	var badge := Label.new()
	badge.text = "★" if evolved else str(lvl)
	badge.position = Vector2(size - 9, size - 13)
	badge.add_theme_font_size_override("font_size", 10)
	badge.add_theme_color_override("font_color", GOLD if evolved else UiTheme.TEXT)
	badge.add_theme_color_override("font_shadow_color", Color.BLACK)
	badge.add_theme_constant_override("shadow_offset_x", 1)
	badge.add_theme_constant_override("shadow_offset_y", 1)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(badge)
	return holder

func _on_joystick(value: Vector2) -> void:
	if is_instance_valid(world) and is_instance_valid(world.player):
		world.player.touch_direction = value

func _reroll() -> void:
	if world.reroll_power_choices():
		SfxPlayer.play_ui("ui/ui_select.wav")
		_close_level_up_panel()

func show_pause_panel() -> void:
	pause_panel = PanelContainer.new()
	pause_panel.theme = UiTheme.make_theme()
	pause_panel.add_theme_stylebox_override("panel", UiTheme.kit("panel_modal", UiTheme.panel(UiTheme.PURPLE, UiTheme.CORNER, 4)))
	_add_blocker_for(pause_panel)
	pause_panel.anchor_left = 0.5; pause_panel.anchor_right = 0.5
	pause_panel.anchor_top = 0.5; pause_panel.anchor_bottom = 0.5
	pause_panel.offset_left = -165; pause_panel.offset_right = 165
	pause_panel.offset_top = -260; pause_panel.offset_bottom = 260
	pause_panel.custom_minimum_size = Vector2(330, 520)
	add_child(pause_panel)
	_build_pause_content()

func _build_pause_content() -> void:
	for child in pause_panel.get_children():
		child.queue_free()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	pause_panel.add_child(box)
	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", UiTheme.PURPLE)
	box.add_child(title)
	if _confirm_exit:
		title.text = "¿SALIR?"
		var warning := Label.new()
		warning.text = "Perdés el progreso de esta partida."
		warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		warning.add_theme_color_override("font_color", UiTheme.TEXT_MUTED)
		box.add_child(warning)
		var confirm := Button.new()
		confirm.text = "SÍ, SALIR"
		confirm.icon = UiTheme.icon("confirm.png")
		confirm.custom_minimum_size = Vector2(0, 52)
		confirm.add_theme_color_override("font_color", UiTheme.DANGER)
		confirm.pressed.connect(_exit_run)
		box.add_child(confirm)
		var cancel := Button.new()
		cancel.text = "CANCELAR"
		cancel.icon = UiTheme.icon("cancel.png")
		cancel.custom_minimum_size = Vector2(0, 52)
		cancel.pressed.connect(func():
			_confirm_exit = false
			_build_pause_content()
		)
		box.add_child(cancel)
	else:
		title.text = "EN PAUSA"
		var pause_sub := Label.new()
		pause_sub.text = "UN RESPIRO TAMBIÉN ES PARTE DE LA BATALLA"
		pause_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pause_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		pause_sub.add_theme_font_size_override("font_size", 11)
		pause_sub.add_theme_color_override("font_color", UiTheme.TEXT_MUTED)
		box.add_child(pause_sub)
		box.add_child(_pause_stats())
		box.add_child(_card_label("TU BUILD", 14, UiTheme.ACCENT))
		var build_scroll := ScrollContainer.new()
		build_scroll.custom_minimum_size = Vector2(0, 160)
		build_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		build_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		box.add_child(build_scroll)
		var build_list := VBoxContainer.new()
		build_list.add_theme_constant_override("separation", 6)
		build_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		build_scroll.add_child(build_list)
		for id in world.skills:
			build_list.add_child(_build_row(id))
		for id in world.passives:
			build_list.add_child(_build_row(id))
		var resume := Button.new()
		resume.text = "REANUDAR"
		resume.icon = UiTheme.icon("play.png")
		resume.custom_minimum_size = Vector2(0, 52)
		UiTheme.apply_primary(resume)
		resume.pressed.connect(_toggle_pause)
		box.add_child(resume)
		var exit := Button.new()
		exit.text = "SALIR"
		exit.custom_minimum_size = Vector2(0, 52)
		exit.pressed.connect(func():
			_confirm_exit = true
			_build_pause_content()
		)
		box.add_child(exit)

## Run-so-far numbers plus the top damage sources, so the pause doubles as
## a quick check of how the build is performing.
func _pause_stats() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var seconds := int(world.elapsed)
	var line := "%d:%02d  ·  %d BAJAS  ·  NV.%d  ·  +%d ORO" % [seconds / 60, seconds % 60, world.kills, world.level, world.gold_this_run()]
	box.add_child(_card_label(line, 12, UiTheme.TEXT))
	var damage: Dictionary = world.damage_by_source
	if damage.is_empty():
		return box
	var ids: Array = damage.keys()
	ids.sort_custom(func(a, b): return int(damage[a]) > int(damage[b]))
	var total := 0
	for id in ids:
		total += int(damage[id])
	var parts := PackedStringArray()
	for i in mini(3, ids.size()):
		var id := str(ids[i])
		var label := RunResultScreen.EXTRA_SOURCES.get(id, {}).get("name", AbilityCatalog.display_name(id, world.is_evolved(id))) as String
		parts.append("%s %d%%" % [label, int(round(100.0 * int(damage[id]) / maxf(1.0, float(total))))])
	box.add_child(_card_label("DAÑO: " + "  ·  ".join(parts), 10, UiTheme.TEXT_MUTED))
	return box

## One pause-screen line per owned ability; actives also show how close
## they are to evolving (level + paired passive).
func _build_row(id: String) -> Control:
	var evolved: bool = world.is_evolved(id)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(_ability_icon(id, evolved, 32.0))
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	var title := _card_label("%s  NV.%d" % [AbilityCatalog.display_name(id, evolved), world.ability_level(id)], 11, GOLD if evolved else UiTheme.TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	text.add_child(title)
	if AbilityCatalog.is_weapon(id):
		var weapon_hint := _card_label("Arma · %s" % AbilityCatalog.description(id), 9, Color("8a7d9c"))
		weapon_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		text.add_child(weapon_hint)
	if AbilityCatalog.has_evolution(id) and not evolved:
		var partner := AbilityCatalog.evolution_partner(id)
		var ready_level: bool = world.ability_level(id) >= AbilityCatalog.MAX_LEVEL
		var has_partner: bool = world.passive_level(partner) > 0
		var hint := _card_label("%s Nv.%d/%d  ·  %s %s" % ["✓" if ready_level else "·", world.ability_level(id), AbilityCatalog.MAX_LEVEL, "✓" if has_partner else "·", AbilityCatalog.display_name(partner)], 9, Color("8a7d9c"))
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		text.add_child(hint)
	return row

func _exit_run() -> void:
	if is_instance_valid(world):
		GameState.change_screen("playing")
		world.end_run(false)
