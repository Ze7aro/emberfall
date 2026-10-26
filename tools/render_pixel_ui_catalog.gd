extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Use a rendering driver for catalog capture")
		quit(1)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1400, 2800)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var catalog = load("res://scenes/ui/PixelUiKitCatalog.tscn").instantiate()
	catalog.size = Vector2(1400, 2800)
	viewport.add_child(catalog)
	for i in 4:
		await process_frame
	RenderingServer.force_draw(false)
	var screenshot := viewport.get_texture().get_image()
	var error := screenshot.save_png("res://assets/ui/pixel_simple_v1/preview.png")
	print("Pixel UI catalog rendered: ", error_string(error))
	quit(0 if error == OK else 1)
