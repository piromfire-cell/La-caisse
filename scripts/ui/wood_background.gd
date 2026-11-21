class_name WoodBackground
extends Control
## Fond du jeu : planches de bois sombres avec vignette (dessinées UNE fois), et par-dessus
## une couche de petites bulles de bière qui montent doucement (animées).

const PLANK_HEIGHT := 190.0
const BUBBLE_COUNT := 22

var _grain: Array[PackedFloat32Array] = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	# Veines du bois : valeurs fixes pour que le fond ne « scintille » pas au redimensionnement.
	for i in 40:
		var line := PackedFloat32Array()
		for j in 8:
			line.append(rng.randf())
		_grain.append(line)
	resized.connect(queue_redraw)
	add_child(BubbleLayer.new())


func _draw() -> void:
	var w := size.x
	var h := size.y
	# Dégradé de base
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
		PackedColorArray([UI.WOOD_LIGHT.darkened(0.1), UI.WOOD_LIGHT.darkened(0.1), UI.WOOD_DARK, UI.WOOD_DARK]))

	# Planches
	var plank_index := 0
	var y := 0.0
	while y < h:
		var shade := 0.0 if plank_index % 2 == 0 else 0.1
		draw_rect(Rect2(0, y, w, PLANK_HEIGHT), Color(0, 0, 0, shade))
		var grain: PackedFloat32Array = _grain[plank_index % _grain.size()]
		for k in 4:
			var gy := y + 18.0 + grain[k] * (PLANK_HEIGHT - 36.0)
			var gx := grain[k + 4] * w * 0.5
			draw_line(Vector2(gx, gy), Vector2(gx + w * (0.35 + grain[(k + 2) % 8] * 0.4), gy + 3.0),
				Color(0, 0, 0, 0.12), 3.0, true)
		draw_rect(Rect2(0, y + PLANK_HEIGHT - 4, w, 4), Color(0, 0, 0, 0.4))
		draw_rect(Rect2(0, y, w, 2), Color(1, 0.85, 0.6, 0.05))
		y += PLANK_HEIGHT
		plank_index += 1

	# Vignette (bords plus sombres)
	var edge := Color(0, 0, 0, 0.42)
	var clear := Color(0, 0, 0, 0)
	var v := minf(w, h) * 0.45
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, v), Vector2(0, v)]), PackedColorArray([edge, edge, clear, clear]))
	draw_polygon(PackedVector2Array([Vector2(0, h - v), Vector2(w, h - v), Vector2(w, h), Vector2(0, h)]), PackedColorArray([clear, clear, edge, edge]))
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(v, 0), Vector2(v, h), Vector2(0, h)]), PackedColorArray([edge, clear, clear, edge]))
	draw_polygon(PackedVector2Array([Vector2(w - v, 0), Vector2(w, 0), Vector2(w, h), Vector2(w - v, h)]), PackedColorArray([clear, edge, edge, clear]))


## Couche de bulles animées (seule partie redessinée à chaque image).
class BubbleLayer extends Control:
	var _bubbles: Array[Dictionary] = []
	var _time: float = 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var rng := RandomNumberGenerator.new()
		rng.seed = 77
		for i in BUBBLE_COUNT:
			_bubbles.append({
				"x": rng.randf(), "y": rng.randf(), "r": rng.randf_range(4.0, 13.0),
				"v": rng.randf_range(0.015, 0.05), "ph": rng.randf() * TAU,
			})

	func _process(delta: float) -> void:
		_time += delta
		for b in _bubbles:
			b["y"] = float(b["y"]) - float(b["v"]) * delta
			if float(b["y"]) < -0.05:
				b["y"] = 1.05
		queue_redraw()

	func _draw() -> void:
		for b in _bubbles:
			var bx := float(b["x"]) * size.x + sin(_time * 0.9 + float(b["ph"])) * 10.0
			var by := float(b["y"]) * size.y
			var r := float(b["r"])
			draw_circle(Vector2(bx, by), r, Color(1, 0.8, 0.35, 0.10))
			draw_arc(Vector2(bx, by), r, 0.0, TAU, 14, Color(1, 0.9, 0.6, 0.22), 2.0, true)
			draw_circle(Vector2(bx - r * 0.3, by - r * 0.3), r * 0.22, Color(1, 1, 1, 0.3))
