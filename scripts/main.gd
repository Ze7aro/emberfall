extends Node2D

const BG := Color("071024")
var content: Control
var game: Node
var game_ui: CanvasLayer
var status: Label
var ui_layer: CanvasLayer
var hud_layer: CanvasLayer

func _ready() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 10
	add_child(ui_layer)
	GameState.screen_changed.connect(_on_screen_changed)
	show_menu()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and GameState.screen == "playing":
		GameState.change_screen("paused")
	elif event.is_action_pressed("ui_cancel") and GameState.screen == "paused":
		GameState.change_screen("playing")

func clear_content() -> void:
	if is_instance_valid(hud_layer):
		hud_layer.queue_free()
		hud_layer = null
	if is_instance_valid(game):
		game.queue_free()
		game = null
	if is_instance_valid(game_ui):
		game_ui.queue_free()
		game_ui = null
	if is_instance_valid(content):
		content.queue_free()
		content = null

func new_content() -> Control:
	var result := Control.new()
	result.position = Vector2.ZERO
	result.size = get_viewport_rect().size
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(result)
	return result

func show_menu() -> void:
	clear_content()
	GameState.change_screen("menu")
	content = new_content()
	var background := TextureRect.new()
	background.texture = load("res://assets/environment/game_bg.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	background.position = Vector2(0, 10)
	background.size = Vector2(get_viewport_rect().size.x, get_viewport_rect().size.y - 20)
	background.modulate = Color.WHITE
	content.add_child(background)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.10, 0.28)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_child(shade)
	build_reference_menu()
	return
	var main := VBoxContainer.new()
	main.anchor_left = 0.5
	main.anchor_right = 0.5
	main.anchor_top = 0.5
	main.anchor_bottom = 0.5
	var menu_width := minf(340.0, get_viewport_rect().size.x - 24.0)
	main.offset_left = -menu_width / 2.0
	main.offset_right = menu_width / 2.0
	main.offset_top = -350
	main.offset_bottom = 350
	main.add_theme_constant_override("separation", 12)
	content.add_child(main)
	var title := Label.new()
	title.text = "EMBERFALL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	main.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "1. RUINAS DEL CREPÚSCULO\nSOBREVIVE 3:00"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 13)
	main.add_child(subtitle)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 280)
	main.add_child(spacer)
	var chest := Label.new()
	chest.text = "✦  COFRE DE LAS RUINAS  ✦\nAlcanza la victoria para abrirlo"
	chest.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main.add_child(chest)
	var play := Button.new()
	play.text = "JUGAR  ·  ENERGÍA %d/%d" % [GameState.energy, GameState.MAX_ENERGY]
	play.custom_minimum_size = Vector2(0, 64)
	play.add_theme_font_size_override("font_size", 22)
	play.pressed.connect(start_game)
	main.add_child(play)
	status = Label.new()
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.text = "Oro: %d  ·  Récord: %d" % [GameState.gold, GameState.high_score]
	main.add_child(status)
	var upgrades := Button.new()
	upgrades.text = "MEJORAS PERMANENTES"
	upgrades.custom_minimum_size = Vector2(0, 42)
	upgrades.pressed.connect(show_upgrades)
	main.add_child(upgrades)
	var nav := Label.new()
	nav.text = "▣     ◇     MAPA     ◇     ⚙"
	nav.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nav.add_theme_font_size_override("font_size", 13)
	nav.modulate = Color(0.75, 0.9, 0.95)
	nav.custom_minimum_size = Vector2(0, 42)
	main.add_child(nav)
	# The supplied reference is the visual source of truth. Keep the old
	# generated labels disabled so they cannot overlap or crop the artwork.
	main.visible = false
	shade.visible = false
	add_reference_controls()

func build_reference_menu() -> void:
	var viewport := get_viewport_rect().size
	var width := viewport.x
	var height := viewport.y
	var safe_top := 10.0
	hud_layer = CanvasLayer.new()
	hud_layer.name = "HUD"
	hud_layer.layer = 20
	add_child(hud_layer)
	var top = preload("res://scenes/ui/TopHud.tscn").instantiate()
	top.name = "TopHud"
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_top = safe_top
	top.offset_bottom = safe_top + 88.0
	hud_layer.add_child(top)
	top.set_level(1)
	top.set_energy(GameState.energy, GameState.MAX_ENERGY)
	top.set_gold(GameState.gold)
	top.set_gems(GameState.gems)
	top.set_notifications(0)
	GameState.energy_changed.connect(func(value: int): top.set_energy(value, GameState.MAX_ENERGY))
	GameState.gold_changed.connect(top.set_gold)
	GameState.gems_changed.connect(top.set_gems)

	var map_selection = preload("res://scenes/ui/MapSelection.tscn").instantiate()
	map_selection.name = "MapSelection"
	map_selection.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_selection.offset_top = safe_top + 94.0
	map_selection.offset_bottom = -112.0
	map_selection.previous_map_requested.connect(map_selection.show_previous_map)
	map_selection.next_map_requested.connect(map_selection.show_next_map)
	map_selection.start_map_requested.connect(func(_id: StringName): start_game())
	hud_layer.add_child(map_selection)

	var footer = preload("res://scenes/ui/NavigationFooter.tscn").instantiate()
	footer.name = "NavigationFooter"
	footer.icons = [load("res://assets/iconos main/09_tienda.png"), load("res://assets/iconos main/04_pergamino.png"), load("res://assets/iconos main/05_mapa.png"), load("res://assets/iconos main/03_espada.png"), load("res://assets/iconos main/08_brujula.png")]
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -112.0
	footer.offset_bottom = 0.0
	footer.navigation_requested.connect(_on_navigation_requested)
	hud_layer.add_child(footer)

func _previous_map() -> void:
	# El catálogo de mapas se ampliará aquí sin acoplarlo al HUD.
	pass

func _next_map() -> void:
	# El catálogo de mapas se ampliará aquí sin acoplarlo al HUD.
	pass

func _on_navigation_requested(_index: int, id: StringName) -> void:
	match id:
		&"shop": _footer_action("shop")
		&"upgrades": _footer_action("upgrades")
		&"world": _footer_action("world")
		&"heroes": _footer_action("hero")
		&"dungeons": _footer_action("dungeons")

func _footer_action(section: String) -> void:
	match section:
		"shop": show_placeholder("TIENDA", "Reliquias y objetos estarán disponibles próximamente.")
		"upgrades": show_upgrades()
		"world": show_menu()
		"hero": show_character_selection()
		"dungeons": show_placeholder("MAZMORRAS", "Completa zonas para desbloquear nuevas mazmorras.")

func show_placeholder(title_text: String, subtitle_text: String) -> void:
	clear_content()
	GameState.change_screen("menu")
	content = new_content()
	var background := ColorRect.new()
	background.color = Color("101a2b")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_child(background)
	var box := VBoxContainer.new()
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.anchor_top = 0.5
	box.anchor_bottom = 0.5
	box.offset_left = -150
	box.offset_right = 150
	box.offset_top = -100
	box.offset_bottom = 100
	box.add_theme_constant_override("separation", 14)
	content.add_child(box)
	var title := add_label(box, title_text, Vector2.ZERO, 25, Color("19d8c9"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var subtitle := add_label(box, subtitle_text, Vector2.ZERO, 12, Color.WHITE)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var back := Button.new()
	back.text = "VOLVER AL MAPA"
	back.custom_minimum_size = Vector2(0, 48)
	back.pressed.connect(show_menu)
	box.add_child(back)

func show_character_selection() -> void:
	clear_content(); GameState.change_screen("characters"); content = new_content()
	var bg := ColorRect.new(); bg.color = Color("101a2b"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); content.add_child(bg)
	var selection = preload("res://scenes/ui/CharacterSelection.tscn").instantiate(); selection.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); content.add_child(selection)
	selection.back_requested.connect(show_menu)

func add_label(parent: Node, text_value: String, at: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func add_reference_controls() -> void:
	var viewport := get_viewport_rect().size
	var play := Button.new()
	play.flat = true
	play.position = Vector2(viewport.x * 0.34, viewport.y * 0.39)
	play.size = Vector2(viewport.x * 0.33, viewport.y * 0.10)
	play.tooltip_text = "JUGAR"
	play.pressed.connect(start_game)
	content.add_child(play)
	var world := Button.new()
	world.flat = true
	world.position = Vector2(viewport.x * 0.40, viewport.y * 0.88)
	world.size = Vector2(viewport.x * 0.20, viewport.y * 0.10)
	world.pressed.connect(show_menu)
	content.add_child(world)
	var upgrades := Button.new()
	upgrades.flat = true
	upgrades.position = Vector2(viewport.x * 0.70, viewport.y * 0.88)
	upgrades.size = Vector2(viewport.x * 0.20, viewport.y * 0.10)
	upgrades.pressed.connect(show_upgrades)
	content.add_child(upgrades)

func start_game() -> void:
	if not GameState.start_run():
		if is_instance_valid(status):
			status.text = "ENERGÍA INSUFICIENTE · RECUPERA 1 CADA 5 MINUTOS"
		else:
			show_menu()
		return
	clear_content()
	game = load("res://scripts/game_world.gd").new()
	add_child(game)
	game_ui = load("res://scripts/ui.gd").new()
	add_child(game_ui)
	game_ui.setup(game)

func show_upgrades() -> void:
	clear_content()
	GameState.change_screen("upgrades")
	content = new_content()
	var box := VBoxContainer.new()
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.anchor_top = 0.5
	box.anchor_bottom = 0.5
	box.offset_left = -150
	box.offset_right = 150
	box.offset_top = -210
	box.offset_bottom = 210
	box.add_theme_constant_override("separation", 12)
	content.add_child(box)
	var title := Label.new()
	title.text = "MEJORAS PERMANENTES\nORO: %d" % GameState.gold
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	box.add_child(title)
	for item in [["damage", "DAÑO"], ["health", "VIDA"], ["speed", "VELOCIDAD"]]:
		var button := Button.new()
		var level := GameState.get_upgrade_level(item[0])
		button.text = "%s  NIVEL %d  ·  COSTE %d" % [item[1], level, 40 + level * 35]
		button.custom_minimum_size = Vector2(0, 52)
		button.pressed.connect(_buy_upgrade.bind(item[0]))
		box.add_child(button)
	var back := Button.new()
	back.text = "VOLVER"
	back.pressed.connect(show_menu)
	box.add_child(back)

func _buy_upgrade(kind: String) -> void:
	GameState.buy_upgrade(kind)
	show_upgrades()

func show_result(victory: bool) -> void:
	clear_content()
	content = new_content()
	var box := VBoxContainer.new()
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.anchor_top = 0.5
	box.anchor_bottom = 0.5
	box.offset_left = -150
	box.offset_right = 150
	box.offset_top = -150
	box.offset_bottom = 150
	box.add_theme_constant_override("separation", 14)
	content.add_child(box)
	var title := Label.new()
	title.text = "VICTORIA" if victory else "CAÍSTE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	box.add_child(title)
	var info := Label.new()
	info.text = "Tu progreso se guardó.\nOro total: %d\nRécord: %d" % [GameState.gold, GameState.high_score]
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(info)
	var retry := Button.new()
	retry.text = "VOLVER A INTENTAR"
	retry.disabled = not GameState.can_start()
	retry.pressed.connect(start_game)
	box.add_child(retry)
	var menu := Button.new()
	menu.text = "MENÚ PRINCIPAL"
	menu.pressed.connect(show_menu)
	box.add_child(menu)

func _on_screen_changed(value: String) -> void:
	if value == "victory":
		show_result(true)
	elif value == "defeat":
		show_result(false)
	elif value == "paused":
		# The game loop checks GameState.screen, so pausing is deterministic.
		pass
