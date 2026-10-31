extends Control

const UiTheme := preload("res://scripts/ui/UiTheme.gd")

signal route_changed(route_id: StringName)
signal modal_opened(modal_id: StringName)
signal modal_closed(modal_id: StringName)

var current_route: StringName = &"home"
var current_screen: Node
var modal_host: Control
var content_host: Control
var active_modal: Control
var navigation_footer: Node
var hud_layer: CanvasLayer
var top_hud: TopHud

var _active_modal_content: Control
var _active_game: Node
var _active_game_ui: Node
var _starting_run := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Editor/debug builds start every session with full energy for testing.
	if OS.is_debug_build() and GameState.energy < GameState.MAX_ENERGY:
		GameState.energy = GameState.MAX_ENERGY
		GameState.energy_changed.emit(GameState.energy)
		GameState.save()
	# Shared dark backdrop: screens without their own background (Inicio,
	# Mazmorras) would otherwise show the engine's default gray.
	var backdrop := TextureRect.new(); backdrop.name = "Backdrop"; backdrop.texture = load("res://assets/ui/pixel_simple_v1/backgrounds/background.png"); backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; backdrop.stretch_mode = TextureRect.STRETCH_SCALE; backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE; backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(backdrop)
	content_host = Control.new(); content_host.name = "ContentHost"; content_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(content_host)

	hud_layer = CanvasLayer.new(); hud_layer.name = "HudLayer"; hud_layer.layer = 10; add_child(hud_layer)

	top_hud = preload("res://scenes/ui/TopHud.tscn").instantiate() as TopHud; top_hud.name = "TopHud"; top_hud.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE); top_hud.offset_bottom = UiTheme.HUD_HEIGHT; hud_layer.add_child(top_hud)
	_wire_top_hud()

	navigation_footer = preload("res://scenes/ui/NavigationFooter.tscn").instantiate(); navigation_footer.name = "NavigationFooter"; navigation_footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE); navigation_footer.offset_top = -112
	# Five footer destinations; missions open from the home shortcut.
	navigation_footer.icons = [
		load("res://assets/ui/pixel_simple_v1/navigation/shop.png"),
		load("res://assets/ui/pixel_simple_v1/navigation/character.png"),
		load("res://assets/ui/pixel_simple_v1/navigation/home.png"),
		load("res://assets/ui/pixel_simple_v1/navigation/inventory.png"),
		load("res://assets/ui/pixel_simple_v1/navigation/dungeons.png"),
	]
	hud_layer.add_child(navigation_footer)
	navigation_footer.navigation_requested.connect(func(_index: int, route_id: StringName): navigate_to(route_id))

	var modal_layer := CanvasLayer.new(); modal_layer.name = "ModalLayer"; modal_layer.layer = 20; add_child(modal_layer)
	modal_host = Control.new(); modal_host.name = "ModalHost"; modal_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); modal_host.mouse_filter = Control.MOUSE_FILTER_IGNORE; modal_layer.add_child(modal_host)

	GameState.screen_changed.connect(_on_game_screen_changed)
	navigate_to(&"home")

## Auto-pauses combat when the app loses focus or the OS suspends it (phone
## call, home button, app switch, notification shade) — otherwise a long
## background gap gets processed as a single huge delta on resume (enemies
## piling up, a surprise multi-hit death) instead of just picking up where
## the player left off. Never auto-resumes on focus/return: that's always an
## explicit tap, same as manually unpausing.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if is_instance_valid(_active_game) and GameState.screen == "playing":
			GameState.change_screen("paused")
		# The OS may kill a backgrounded app without warning: flush progress.
		if what == NOTIFICATION_APPLICATION_PAUSED:
			GameState.save()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		# Android back button (quit_on_go_back is off in project.godot).
		if not _handle_back():
			GameState.save()
			get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _handle_back():
		get_viewport().set_input_as_handled()

## Back/Escape: close a modal, toggle pause in a run, or return to Inicio.
## False when there is nothing left to go back to (Inicio with no modal).
func _handle_back() -> bool:
	if has_open_modal():
		close_active_modal()
		return true
	if is_instance_valid(_active_game):
		if GameState.screen == "playing":
			SfxPlayer.play_ui("ui/pause.wav")
			GameState.change_screen("paused")
		elif GameState.screen == "paused":
			SfxPlayer.play_ui("ui/resume.wav")
			GameState.change_screen("playing")
		return true
	if current_route != &"home":
		navigate_to(&"home")
		return true
	return false

func _wire_top_hud() -> void:
	top_hud.set_level(GameState.level)
	top_hud.set_experience(GameState.experience, GameState.experience_to_next)
	top_hud.set_energy(GameState.energy, GameState.MAX_ENERGY)
	top_hud.set_energy_countdown(GameState.seconds_until_next_energy())
	top_hud.set_gold(GameState.gold)
	top_hud.set_gems(GameState.gems)

	GameState.level_changed.connect(top_hud.set_level)
	GameState.experience_changed.connect(top_hud.set_experience)
	GameState.energy_changed.connect(func(value: int): top_hud.set_energy(value, GameState.MAX_ENERGY))
	GameState.energy_countdown_changed.connect(top_hud.set_energy_countdown)
	GameState.gold_changed.connect(top_hud.set_gold)
	GameState.gems_changed.connect(top_hud.set_gems)

	top_hud.shop_pressed.connect(func(): navigate_to(&"shop"))
	top_hud.profile_pressed.connect(func(): open_modal(&"profile"))
	top_hud.settings_pressed.connect(func(): open_modal(&"settings"))

func navigate_to(route_id: StringName) -> void:
	if route_id == current_route and is_instance_valid(current_screen): return
	close_active_modal()
	if is_instance_valid(current_screen): current_screen.queue_free()
	current_screen = _screen_for(route_id)
	content_host.add_child(current_screen); current_route = route_id
	if navigation_footer.has_method("select_by_id"): navigation_footer.select_by_id(route_id)
	route_changed.emit(route_id)

func get_current_route() -> StringName: return current_route

func _screen_for(route_id: StringName) -> Node:
	match route_id:
		&"home": return preload("res://scenes/screens/HomeScreen.tscn").instantiate()
		&"character": return _character_equipment_screen(&"character")
		&"inventory": return _character_equipment_screen(&"inventory")
		&"missions": return preload("res://scenes/screens/MissionsScreen.tscn").instantiate()
		&"dungeons": return preload("res://scenes/screens/DungeonSelectionScreen.tscn").instantiate()
		&"upgrades": return preload("res://scenes/screens/PermanentUpgradesScreen.tscn").instantiate()
		&"shop": return preload("res://scenes/screens/ShopScreen.tscn").instantiate()
		_: return _placeholder_screen(route_id)

func _character_equipment_screen(section: StringName) -> Control:
	var screen := preload("res://scenes/ui/CharacterEquipmentScreen.tscn").instantiate() as Control
	screen.set("initial_section", str(section))
	return screen

func _placeholder_screen(route_id: StringName) -> Control:
	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := TextureRect.new(); bg.texture = load("res://assets/ui/pixel_simple_v1/backgrounds/background.png"); bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; bg.stretch_mode = TextureRect.STRETCH_SCALE; bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); screen.add_child(bg)
	var label := Label.new(); label.text = str(route_id).to_upper(); label.set_anchors_and_offsets_preset(Control.PRESET_CENTER); label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.add_theme_font_size_override("font_size", 28); label.add_theme_color_override("font_color", UiTheme.ACCENT); screen.add_child(label)
	return screen

func open_modal(modal_id: StringName, payload: Variant = null) -> void:
	if is_instance_valid(active_modal): return
	var blocker := ColorRect.new(); blocker.color = Color(0, 0, 0, 0.72); blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); blocker.mouse_filter = Control.MOUSE_FILTER_STOP; modal_host.add_child(blocker)
	var content := _modal_for(modal_id)
	if content:
		modal_host.add_child(content)
		if content.has_signal("closed"): content.closed.connect(close_active_modal)
		if content.has_signal("settings_requested"):
			content.settings_requested.connect(func():
				close_active_modal()
				open_modal(&"settings")
			)
	active_modal = blocker
	_active_modal_content = content
	modal_opened.emit(modal_id)

func _modal_for(modal_id: StringName) -> Control:
	match modal_id:
		&"profile": return preload("res://scenes/ui/ProfileModal.tscn").instantiate()
		&"settings": return preload("res://scenes/ui/SettingsModal.tscn").instantiate()
		&"notifications": return preload("res://scenes/ui/NotificationsModal.tscn").instantiate()
		&"missions": return _missions_modal()
		_: return null

func _missions_modal() -> Control:
	var screen := preload("res://scenes/screens/MissionsScreen.tscn").instantiate()
	screen.set("modal_mode", true)
	return screen

func close_active_modal() -> void:
	if is_instance_valid(_active_modal_content): _active_modal_content.queue_free(); _active_modal_content = null
	if not is_instance_valid(active_modal): return
	active_modal.queue_free(); active_modal = null; modal_closed.emit(&"active")

func has_open_modal() -> bool: return is_instance_valid(active_modal)

func start_run(map_data: Dictionary) -> void:
	# Guards against a double-tap (or any other stray repeat call) re-entering
	# this while a run is already active — without it, energy could be spent
	# twice and a second, orphaned game_world would keep running in the
	# background and could grant its own victory/defeat reward later.
	if is_instance_valid(_active_game) or _starting_run:
		return
	# Editor/debug builds top energy up so testing never gets blocked;
	# exported releases keep the real cost.
	if OS.is_debug_build() and not GameState.can_start():
		GameState.energy = GameState.MAX_ENERGY
		GameState.energy_changed.emit(GameState.energy)
		_show_toast("[debug] Energía recargada")
	if not GameState.can_start():
		_show_toast("Sin energía: necesitás %d y tenés %d.\nSe recarga con el tiempo o en la Tienda." % [GameState.ENERGY_COST, GameState.energy])
		SfxPlayer.play_ui("economy/purchase_failed.wav")
		return
	if not GameState.begin_stage(map_data):
		_show_toast("Ese mapa todavía está bloqueado.")
		return
	if not GameState.start_run():
		return
	close_active_modal()
	if is_instance_valid(current_screen): current_screen.queue_free(); current_screen = null
	hud_layer.visible = false
	# Warm the run's real resources through the threaded loader; the loading
	# screen only becomes visible if something is actually still loading.
	_starting_run = true
	var loading := preload("res://scripts/ui/LoadingScreen.gd").new()
	loading.setup(_run_resource_paths())
	content_host.add_child(loading)
	await loading.finished
	loading.queue_free()
	_starting_run = false
	_active_game = load("res://scripts/game_world.gd").new()
	content_host.add_child(_active_game)
	_active_game_ui = load("res://scripts/ui.gd").new()
	content_host.add_child(_active_game_ui)
	_active_game_ui.setup(_active_game)

## Short message over everything that fades out on its own.
func _show_toast(text: String) -> void:
	var toast := Label.new()
	toast.text = text
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast.anchor_left = 0.5; toast.anchor_right = 0.5; toast.anchor_top = 0.5; toast.anchor_bottom = 0.5
	toast.offset_left = -170; toast.offset_right = 170; toast.offset_top = -30; toast.offset_bottom = 30
	toast.add_theme_font_size_override("font_size", 15)
	toast.add_theme_color_override("font_color", UiTheme.TEXT)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.06, 0.04, 0.12, 0.92)
	box.border_color = UiTheme.DANGER
	box.set_border_width_all(2)
	box.set_corner_radius_all(6)
	box.set_content_margin_all(10)
	toast.add_theme_stylebox_override("normal", box)
	add_child(toast)
	var tween := toast.create_tween()
	tween.tween_interval(2.2)
	tween.tween_property(toast, "modulate:a", 0.0, 0.5)
	tween.tween_callback(toast.queue_free)

func _run_resource_paths() -> Array[String]:
	var paths: Array[String] = [
		"res://scripts/game_world.gd", "res://scripts/ui.gd", "res://scripts/components/player.gd",
		"res://assets/characters/enemy.png", "res://assets/environment/game_bg.png",
	]
	var folder := str(GameState.selected_character_sprite_folder)
	if folder != "":
		var base := "%s/%s" % [CharacterAnimations.BASE_DIR, folder]
		for dir in ["right", "left"]:
			for i in 3:
				paths.append("%s/walk_%s_%02d.png" % [base, dir, i])
		for i in 2:
			paths.append("%s/attack_%02d.png" % [base, i])
	return paths

func _on_game_screen_changed(value: String) -> void:
	if value == "victory" or value == "defeat":
		_end_run(value == "victory")

func _end_run(victory: bool) -> void:
	if is_instance_valid(_active_game): _active_game.queue_free()
	if is_instance_valid(_active_game_ui): _active_game_ui.queue_free()
	_active_game = null; _active_game_ui = null
	hud_layer.visible = true
	current_screen = _result_screen(victory)
	content_host.add_child(current_screen)
	current_route = &"result"
	if navigation_footer.has_method("select_by_id"): navigation_footer.select_by_id(&"home")

func _result_screen(victory: bool) -> Control:
	var screen := RunResultScreen.new()
	screen.setup(victory)
	screen.retry_pressed.connect(func(): start_run(GameState.last_stage_context))
	screen.home_pressed.connect(func(): navigate_to(&"home"))
	return screen
