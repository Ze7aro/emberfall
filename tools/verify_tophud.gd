extends SceneTree
## Exercise actual TopHud layout and signals without modifying player data.
## With a rendering driver, also export screenshots under artifacts/top_hud.

const Hud := preload("res://scripts/ui/TopHud.gd")
var _failed := false
var _shops := 0
var _profiles := 0
var _settings := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var capture := DisplayServer.get_name() != "headless"
	if capture:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
		DirAccess.make_dir_recursive_absolute("res://artifacts/top_hud")
	for width in [320, 390, 480, 800]:
		var viewport := SubViewport.new()
		viewport.size = Vector2i(width, 100)
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var hud := Hud.new()
		viewport.add_child(hud)
		hud.offset_bottom = 100
		hud.shop_pressed.connect(func(): _shops += 1)
		hud.profile_pressed.connect(func(): _profiles += 1)
		hud.settings_pressed.connect(func(): _settings += 1)
		for step in [0, 7, 25]:
			hud.set_level(42)
			hud.set_experience(step * 4, 100)
			hud.set_energy(step, 25)
			hud.set_gold(999_999)
			hud.set_gems(12_300)
			await process_frame
			await process_frame
			_check(is_equal_approx(hud._energy_bar.ratio, float(step) / 25), "energy ratio")
			_check(is_equal_approx(float(hud._xp_progress_material.get_shader_parameter("progress")), clampf(float(step * 4) / 100.0, 0.0, 1.0)), "experience ratio")
			_check(hud._energy_label.text == "%d/25" % step, "energy label")
			_check(hud._level_label.text == "42", "level label")
			var content := hud._canvas.get_node("Content") as HBoxContainer
			for slot: Control in content.get_children():
				_check(slot.position.x + slot.size.x <= content.size.x + 1.0, "slot fits at width %d" % width)
			for amount in [hud._energy_label, hud._gold_label, hud._gems_label]:
				_check(amount.position.x + amount.size.x <= amount.get_parent().size.x - 25, "amount does not overlap add button")
			if capture:
				# Minimized windows skip automatic drawing; explicitly draw the
				# offscreen viewport so verification never waits for a visible window.
				RenderingServer.force_draw(false)
				var snapshot := viewport.get_texture().get_image()
				_check(snapshot.save_png("res://artifacts/top_hud/hud_%d_%02d.png" % [width, step]) == OK, "screenshot saved")
		var row := hud._canvas.get_node("Content")
		for name in ["Energy", "Gold", "Gems"]:
			var slot := row.get_node(name)
			(slot.get_child(slot.get_child_count() - 1) as Button).pressed.emit()
		var level := row.get_child(0)
		(level.get_child(level.get_child_count() - 1) as Button).pressed.emit()
		(hud._canvas.get_node("Settings") as Button).pressed.emit()
		hud.set_experience(10, 0)
		_check(float(hud._xp_progress_material.get_shader_parameter("progress")) == 0.0, "zero maximum")
		hud.set_energy(50, 25)
		_check(hud._energy_bar.ratio == 1.0, "overflow clamped")
		viewport.queue_free()
		await process_frame
	_check(_shops == 12 and _profiles == 4 and _settings == 4, "navigation signals")
	print("TopHUD: checked 4 widths, empty/partial/full values, large amounts, and navigation signals.")
	quit(1 if _failed else 0)

func _check(valid: bool, description: String) -> void:
	if not valid:
		_failed = true
		push_error(description)
