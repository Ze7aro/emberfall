extends CanvasLayer

const UiTheme := preload("res://scripts/ui/UiTheme.gd")

const GOLD := Color("e8b84a")

var world: Node
var xp_bar: ProgressBar
var level_label: Label
var timer_label: Label
var hearts: HeartsRow
var boss_label: Label
var boss_bar: ProgressBar
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

## First-run guidance (PLAY-01): a non-blocking hint that states the goal and
## the control scheme, gone as soon as the player actually moves, plus one
## line on the first level-up screen. Never shown again once GameState marks
## it complete — no modal, no forced reading, just gets out of the way.
var _tutorial_active := false
var _tutorial_hint: Label

func setup(owner: Node) -> void:
	world = owner
	_tutorial_active = not GameState.tutorial_completed
	var top := VBoxContainer.new()
	top.theme = UiTheme.make_theme()
	top.position = Vector2(16, 16)
	top.size = Vector2(358, 88)
	add_child(top)
	level_label = Label.new()
	level_label.add_theme_font_size_override("font_size", 16)
	top.add_child(level_label)
	xp_bar = ProgressBar.new()
	xp_bar.custom_minimum_size = Vector2(0, 14)
	UiTheme.style_bar(xp_bar, 14.0, "fill_xp.png")
	top.add_child(xp_bar)
	hearts = HeartsRow.new()
	hearts.heart_size = 16.0
	top.add_child(hearts)
	timer_label = Label.new()
	timer_label.position = Vector2(16, 118)
	timer_label.add_theme_font_size_override("font_size", 16)
	add_child(timer_label)
	_build_bar = VBoxContainer.new()
	_build_bar.position = Vector2(16, 144)
	_build_bar.add_theme_constant_override("separation", 3)
	_build_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_build_bar)
	boss_label = Label.new()
	boss_label.position = Vector2(0, 20)
	boss_label.anchor_left = 0.5; boss_label.anchor_right = 0.5
	boss_label.offset_left = -140; boss_label.offset_right = 140
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_label.text = "¡JEFE!"
	boss_label.add_theme_font_size_override("font_size", 18)
	boss_label.add_theme_color_override("font_color", UiTheme.DANGER)
	boss_label.visible = false
	add_child(boss_label)
	boss_bar = ProgressBar.new()
	boss_bar.anchor_left = 0.5; boss_bar.anchor_right = 0.5
	boss_bar.offset_left = -140; boss_bar.offset_right = 140
	boss_bar.position.y = 48
	boss_bar.custom_minimum_size = Vector2(280, 14)
	UiTheme.style_bar(boss_bar, 14.0, "fill_health.png")
	boss_bar.visible = false
	add_child(boss_bar)
	var joystick: Control = load("res://scripts/components/virtual_joystick.gd").new()
	joystick.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	joystick.direction_changed.connect(_on_joystick)
	add_child(joystick)

	pause_button = Button.new()
	pause_button.text = ""
	pause_button.anchor_left = 1.0; pause_button.anchor_right = 1.0
	pause_button.offset_left = -64; pause_button.offset_right = -16
	pause_button.offset_top = 16; pause_button.offset_bottom = 64
	pause_button.icon = UiTheme.icon("pause.png")
	pause_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_button.theme = UiTheme.make_theme()
	pause_button.pressed.connect(_toggle_pause)
	add_child(pause_button)

	# Testing aid, editor/debug builds only: brings the stage boss right away.
	if OS.is_debug_build():
		var boss_debug := Button.new()
		boss_debug.text = "JEFE"
		boss_debug.anchor_left = 1.0; boss_debug.anchor_right = 1.0
		boss_debug.offset_left = -72; boss_debug.offset_right = -16
		boss_debug.offset_top = 72; boss_debug.offset_bottom = 104
		boss_debug.focus_mode = Control.FOCUS_NONE
		boss_debug.add_theme_font_size_override("font_size", 11)
		boss_debug.pressed.connect(func():
			if is_instance_valid(world) and not world.boss_spawned:
				world.spawn_boss()
			boss_debug.visible = false)
		add_child(boss_debug)

	if _tutorial_active:
		_build_tutorial_hint()

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
	level_label.text = "NV. %d  ·  ELIMINADOS %d" % [world.level, world.kills]
	xp_bar.value = float(world.xp) / float(world.xp_needed) * 100.0
	hearts.set_hearts(world.player.hp, world.player.max_hp)
	timer_label.text = "%02d:%02d" % [int(world.elapsed) / 60, int(world.elapsed) % 60]
	var boss_alive: bool = is_instance_valid(world.boss)
	boss_label.visible = boss_alive
	boss_bar.visible = boss_alive
	if boss_alive:
		if world.boss is EmberfallBoss:
			boss_label.text = (world.boss as EmberfallBoss).display_name.to_upper()
		boss_bar.value = float(world.boss.hp) / float(world.boss.max_hp) * 100.0
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
		kind_text = "ACTIVA" if AbilityCatalog.is_active(option) else "PASIVA"
		if current_level == 0:
			kind_text += " · NUEVA"
	stack.add_child(_card_label(kind_text, 9, GOLD if is_evolution else UiTheme.TEXT_MUTED))
	var icon := _ability_icon(base_id, is_evolution, 56.0)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(icon)
	stack.add_child(_card_label(AbilityCatalog.display_name(base_id, is_evolution), 11, GOLD if is_evolution else UiTheme.ACCENT))
	if is_evolution:
		var paired := str(AbilityCatalog.ACTIVES[base_id]["evolution"]["passive"])
		stack.add_child(_card_label("%s + %s" % [AbilityCatalog.display_name(base_id), AbilityCatalog.display_name(paired)], 8, UiTheme.PURPLE))
	else:
		stack.add_child(_card_label("NV. %d → %d" % [current_level, current_level + 1], 11, UiTheme.PURPLE))
	var desc := _card_label(AbilityCatalog.description(option), 10, UiTheme.TEXT_MUTED)
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(desc)
	# Every active card names its evolution partner, so the player learns
	# recipes while playing instead of needing a wiki.
	if not is_evolution and AbilityCatalog.is_active(option):
		var partner := str(AbilityCatalog.ACTIVES[option]["evolution"]["passive"])
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
	pause_panel.offset_left = -140; pause_panel.offset_right = 140
	pause_panel.offset_top = -220; pause_panel.offset_bottom = 220
	pause_panel.custom_minimum_size = Vector2(280, 440)
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
	if AbilityCatalog.is_active(id) and not evolved:
		var partner := str(AbilityCatalog.ACTIVES[id]["evolution"]["passive"])
		var ready_level: bool = world.ability_level(id) >= AbilityCatalog.MAX_LEVEL
		var has_partner: bool = world.passive_level(partner) > 0
		var hint := _card_label("%s Nv.%d/%d  ·  %s %s" % ["✓" if ready_level else "·", world.ability_level(id), AbilityCatalog.MAX_LEVEL, "✓" if has_partner else "·", AbilityCatalog.display_name(partner)], 9, Color("8a7d9c"))
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		text.add_child(hint)
	return row

func _exit_run() -> void:
	if is_instance_valid(world):
		GameState.change_screen("playing")
		GameState.finish_run(false, world.kills)
