class_name DieView
extends Control
## Un dé dessiné en code (points blancs sur fond crème). Peut être « caché » (point
## d'interrogation) et peut rouler avant de s'arrêter sur sa vraie valeur.

## Positions des points sur une grille 3×3 (0 = haut-gauche … 8 = bas-droite), par face.
const PIPS := {
	1: [4],
	2: [0, 8],
	3: [0, 4, 8],
	4: [0, 2, 6, 8],
	5: [0, 2, 4, 6, 8],
	6: [0, 2, 3, 5, 6, 8],
}

var value: int = 1:
	set(v):
		value = clampi(v, 1, 6)
		queue_redraw()

## Si vrai, on dessine un « ? » au lieu des points.
var covered: bool = false:
	set(v):
		covered = v
		queue_redraw()

var face_color: Color = UI.FOAM
var pip_color: Color = UI.WOOD_DARKEST

var _tween: Tween = null
var _next_swap: float = 0.0

## Émis quand la roulade est terminée.
signal finished


func _init(p_size: float = 180.0) -> void:
	custom_minimum_size = Vector2(p_size, p_size)
	size = Vector2(p_size, p_size)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_update_pivot)


func _update_pivot() -> void:
	pivot_offset = size / 2.0


func _ready() -> void:
	_update_pivot()


func _draw() -> void:
	var s := size.x
	var sb := StyleBoxFlat.new()
	sb.bg_color = face_color
	sb.set_corner_radius_all(int(s * 0.2))
	sb.border_width_bottom = int(s * 0.05)
	sb.border_color = UI.FOAM_SHADE.darkened(0.15)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = int(s * 0.06)
	sb.shadow_offset = Vector2(0, s * 0.04)
	sb.anti_aliasing = true
	draw_style_box(sb, Rect2(Vector2.ZERO, size - Vector2(0, s * 0.03)))

	if covered:
		var font := UI.display_font()
		var fs := int(s * 0.7)
		var txt := "?"
		var ts := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		draw_string(font, Vector2((s - ts.x) / 2.0, s * 0.5 + ts.y * 0.3), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UI.AMBER_DARK)
		return

	var margin := s * 0.24
	var step := (s - margin * 2.0) / 2.0
	var radius := s * 0.085
	for idx in PIPS[value]:
		var col: int = idx % 3
		var row: int = floori(idx / 3.0)
		draw_circle(Vector2(margin + col * step, margin + row * step - s * 0.01), radius, pip_color)


## Fait rouler le dé : des faces au hasard défilent (de plus en plus lentement) puis il
## s'arrête sur `final_value`. Le signal `finished` est émis à la fin.
func tumble(final_value: int, duration: float = 0.9) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	covered = false
	_next_swap = 0.0
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_method(func(t: float) -> void: _tumble_step(t, final_value), 0.0, 1.0, duration)
	_tween.tween_property(self, "rotation", TAU * 1.5 * (1.0 if randf() > 0.5 else -1.0), duration)\
		.from(0.0).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_tween.chain().tween_callback(func() -> void:
		rotation = 0.0
		scale = Vector2.ONE
		value = final_value
		finished.emit())


## Arrête toute animation et affiche tout de suite la face `final_value`.
func settle(final_value: int) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	covered = false
	rotation = 0.0
	scale = Vector2.ONE
	value = final_value


func _tumble_step(t: float, final_value: int) -> void:
	if t >= 0.92:
		value = final_value
	elif t >= _next_swap:
		value = randi_range(1, 6)
		_next_swap = t + lerpf(0.05, 0.16, t)
	scale = Vector2.ONE * (1.0 + 0.18 * sin(PI * t))
