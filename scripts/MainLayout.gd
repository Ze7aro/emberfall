extends Control

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

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_host = Control.new(); content_host.name = "ContentHost"; content_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(content_host)

	hud_layer = CanvasLayer.new(); hud_layer.name = "HudLayer"; hud_layer.layer = 10; add_child(hud_layer)

	top_hud = preload("res://scenes/ui/TopHud.tscn").instantiate() as TopHud; top_hud.name = "TopHud"; top_hud.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE); top_hud.offset_bottom = 98; hud_layer.add_child(top_hud)
	_wire_top_hud()

	navigation_footer = preload("res://scenes/ui/NavigationFooter.tscn").instantiate(); navigation_footer.name = "NavigationFooter"; navigation_footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE); navigation_footer.offset_top = -112
	navigation_footer.icons = [load("res://assets/iconos main/08_brujula.png"), load("res://assets/iconos main/03_espada.png"), load("res://assets/iconos main/07_objetivo.png"), load("res://assets/iconos main/04_pergamino.png"), load("res://assets/iconos main/09_tienda.png")]
	hud_layer.add_child(navigation_footer)
	navigation_footer.navigation_requested.connect(func(_index: int, route_id: StringName): navigate_to(route_id))

	var modal_layer := CanvasLayer.new(); modal_layer.name = "ModalLayer"; modal_layer.layer = 20; add_child(modal_layer)
	modal_host = Control.new(); modal_host.name = "ModalHost"; modal_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); modal_layer.add_child(modal_host)

	GameState.screen_changed.connect(_on_game_screen_changed)
	navigate_to(&"home")

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if has_open_modal():
		close_active_modal()
		get_viewport().set_input_as_handled()
	elif is_instance_valid(_active_game):
		if GameState.screen == "playing":
			GameState.change_screen("paused")
		elif GameState.screen == "paused":
			GameState.change_screen("playing")
		get_viewport().set_input_as_handled()
	elif current_route != &"home":
		navigate_to(&"home")
		get_viewport().set_input_as_handled()

func _wire_top_hud() -> void:
	top_hud.set_level(GameState.level)
	top_hud.set_experience(GameState.experience, GameState.experience_to_next)
	top_hud.set_energy(GameState.energy, GameState.MAX_ENERGY)
	top_hud.set_gold(GameState.gold)
	top_hud.set_gems(GameState.gems)
	top_hud.set_notifications(GameState.unread_notification_count())

	GameState.level_changed.connect(top_hud.set_level)
	GameState.experience_changed.connect(top_hud.set_experience)
	GameState.energy_changed.connect(func(value: int): top_hud.set_energy(value, GameState.MAX_ENERGY))
	GameState.gold_changed.connect(top_hud.set_gold)
	GameState.gems_changed.connect(top_hud.set_gems)
	GameState.notifications_changed.connect(top_hud.set_notifications)

	top_hud.profile_pressed.connect(func(): open_modal(&"profile"))
	top_hud.notifications_pressed.connect(func():
		open_modal(&"notifications")
		GameState.mark_notifications_read()
	)
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
		&"characters": return preload("res://scenes/screens/CharacterSelectionScreen.tscn").instantiate()
		&"dungeons": return preload("res://scenes/screens/DungeonSelectionScreen.tscn").instantiate()
		&"upgrades": return preload("res://scenes/screens/PermanentUpgradesScreen.tscn").instantiate()
		&"shop": return preload("res://scenes/screens/ShopScreen.tscn").instantiate()
		_: return _placeholder_screen(route_id)

func _placeholder_screen(route_id: StringName) -> Control:
	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new(); bg.color = Color("101a2b"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); screen.add_child(bg)
	var label := Label.new(); label.text = str(route_id).to_upper(); label.set_anchors_and_offsets_preset(Control.PRESET_CENTER); label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.add_theme_font_size_override("font_size", 28); label.add_theme_color_override("font_color", Color("20e6bd")); screen.add_child(label)
	return screen

func open_modal(modal_id: StringName, payload: Variant = null) -> void:
	if is_instance_valid(active_modal): return
	var blocker := ColorRect.new(); blocker.color = Color(0, 0, 0, 0.72); blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); blocker.mouse_filter = Control.MOUSE_FILTER_STOP; modal_host.add_child(blocker)
	var content := _modal_for(modal_id)
	if content:
		modal_host.add_child(content)
		if content.has_signal("closed"): content.closed.connect(close_active_modal)
	active_modal = blocker
	_active_modal_content = content
	modal_opened.emit(modal_id)

func _modal_for(modal_id: StringName) -> Control:
	match modal_id:
		&"profile": return preload("res://scenes/ui/ProfileModal.tscn").instantiate()
		&"notifications": return preload("res://scenes/ui/NotificationsModal.tscn").instantiate()
		&"settings": return preload("res://scenes/ui/SettingsModal.tscn").instantiate()
		_: return null

func close_active_modal() -> void:
	if is_instance_valid(_active_modal_content): _active_modal_content.queue_free(); _active_modal_content = null
	if not is_instance_valid(active_modal): return
	active_modal.queue_free(); active_modal = null; modal_closed.emit(&"active")

func has_open_modal() -> bool: return is_instance_valid(active_modal)

func start_run(map_id: StringName) -> void:
	if not GameState.can_start():
		return
	GameState.select_map(map_id)
	if not GameState.start_run():
		return
	close_active_modal()
	if is_instance_valid(current_screen): current_screen.queue_free(); current_screen = null
	hud_layer.visible = false
	_active_game = load("res://scripts/game_world.gd").new()
	content_host.add_child(_active_game)
	_active_game_ui = load("res://scripts/ui.gd").new()
	content_host.add_child(_active_game_ui)
	_active_game_ui.setup(_active_game)

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
	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new(); bg.color = Color("101a2b"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); screen.add_child(bg)
	var box := VBoxContainer.new()
	box.anchor_left = 0.5; box.anchor_right = 0.5; box.anchor_top = 0.5; box.anchor_bottom = 0.5
	box.offset_left = -150; box.offset_right = 150; box.offset_top = -140; box.offset_bottom = 140
	box.add_theme_constant_override("separation", 14)
	screen.add_child(box)
	var title := Label.new()
	title.text = "VICTORIA" if victory else "CAÍSTE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color("20e6bd") if victory else Color("e65a5a"))
	box.add_child(title)
	var info := Label.new()
	info.text = "Progreso guardado.\nOro: %d  ·  Récord: %d" % [GameState.gold, GameState.high_score]
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(info)
	var retry := Button.new()
	retry.text = "REINTENTAR"
	retry.custom_minimum_size = Vector2(0, 52)
	retry.disabled = not GameState.can_start()
	retry.pressed.connect(func(): start_run(GameState.selected_map_id))
	box.add_child(retry)
	var home := Button.new()
	home.text = "VOLVER A INICIO"
	home.custom_minimum_size = Vector2(0, 52)
	home.pressed.connect(func(): navigate_to(&"home"))
	box.add_child(home)
	return screen
