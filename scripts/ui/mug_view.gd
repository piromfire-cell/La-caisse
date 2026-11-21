class_name MugView
extends Control
## Une chope de bière dessinée en code, avec mousse et petites bulles qui montent.
## Sert de mascotte sur l'accueil.

var _time: float = 0.0
var wobble: bool = true


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, 300)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	# On dessine dans un repère de 200 × 240 puis on l'adapte à la taille disponible.
	var s := minf(size.x / 200.0, size.y / 240.0)
	if s <= 0.0:
		return
	var origin := (size - Vector2(200, 240) * s) / 2.0
	var tilt := sin(_time * 1.6) * 0.035 if wobble else 0.0
	draw_set_transform(origin + Vector2(100, 230) * s, tilt, Vector2(s, s))
	var o := Vector2(-100, -230)   # le point d'ancrage (bas de la chope) devient l'origine

	# Ombre au sol
	draw_set_transform(origin + Vector2(100, 232) * s, 0.0, Vector2(s, s * 0.25))
	draw_circle(Vector2.ZERO, 88, Color(0, 0, 0, 0.3))
	draw_set_transform(origin + Vector2(100, 230) * s, tilt, Vector2(s, s))

	# Anse
	draw_arc(o + Vector2(160, 130), 44, -PI / 2.1, PI / 2.1, 24, UI.FOAM, 20, true)
	draw_arc(o + Vector2(160, 130), 44, -PI / 2.1, PI / 2.1, 24, UI.FOAM_SHADE, 8, true)

	# Corps de verre (dégradé ambre)
	var top_l := o + Vector2(30, 52)
	var top_r := o + Vector2(152, 52)
	var bot_r := o + Vector2(140, 224)
	var bot_l := o + Vector2(42, 224)
	draw_polygon(PackedVector2Array([top_l, top_r, bot_r, bot_l]),
		PackedColorArray([UI.AMBER_LIGHT, UI.AMBER_LIGHT, UI.AMBER_DARK, UI.AMBER_DARK]))
	draw_polyline(PackedVector2Array([top_l, bot_l, bot_r, top_r]), UI.FOAM, 7, true)
	# Reflet
	draw_line(o + Vector2(52, 80), o + Vector2(60, 200), Color(1, 1, 1, 0.4), 9, true)

	# Bulles qui montent
	for i in 7:
		var phase := fmod(_time * (0.25 + 0.05 * i) + i * 0.37, 1.0)
		var bx := 56.0 + fmod(i * 23.0, 80.0) + sin(_time * 2.0 + i) * 3.0
		var by := 215.0 - phase * 150.0
		draw_circle(o + Vector2(bx, by), 3.0 + (i % 3) * 1.6, Color(1, 0.97, 0.88, 0.7 * (1.0 - phase * 0.6)))

	# Mousse
	var foam := [
		[Vector2(48, 56), 26.0], [Vector2(84, 40), 32.0], [Vector2(124, 40), 30.0],
		[Vector2(150, 58), 24.0], [Vector2(104, 62), 22.0],
	]
	for f in foam:
		draw_circle(o + (f[0] as Vector2) + Vector2(0, 5), f[1], UI.FOAM_SHADE)
	for f in foam:
		draw_circle(o + (f[0] as Vector2), f[1], UI.FOAM)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
