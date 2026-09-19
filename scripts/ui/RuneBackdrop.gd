extends Control
class_name RuneBackdrop

## Discreet turquoise rune/pedestal behind a hero portrait, with a slow
## breathing pulse. Reused for the equipment-state hero preview and for the
## focused card in the hero-selection carousel.
var _t := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	var center := size / 2.0
	var r := minf(size.x, size.y) / 2.0
	var pulse := 1.0 + sin(_t * 1.3) * 0.05
	draw_circle(center, r * 0.92 * pulse, Color(0.12, 0.35, 0.4, 0.16))
	draw_arc(center, r * 0.92 * pulse, 0.0, TAU, 48, Color("20e6bd", 0.45), 2.0)
	draw_arc(center, r * 0.68, 0.0, TAU, 40, Color("20e6bd", 0.28), 1.5)
	for i in 8:
		var angle := TAU / 8.0 * i
		var p1 := center + Vector2(cos(angle), sin(angle)) * r * 0.68
		var p2 := center + Vector2(cos(angle), sin(angle)) * r * 0.92 * pulse
		draw_line(p1, p2, Color("20e6bd", 0.22), 1.5)
