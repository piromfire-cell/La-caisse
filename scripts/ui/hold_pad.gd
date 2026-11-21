class_name HoldPad
extends Control
## Le « sous-bock » secret : tant qu'on garde le doigt dessus, on voit ses deux dés ;
## dès qu'on lâche, ils disparaissent. (Anti-triche : personne ne voit les dés par-dessus
## l'épaule d'un joueur qui a lâché l'écran.)

## Émis la toute première fois que les dés ont été montrés.
signal first_reveal
## Émis à chaque changement : true = dés visibles, false = cachés.
signal holding_changed(holding: bool)

var dice: Vector2i = Vector2i(1, 1)
var holding: bool = false
var has_seen: bool = false

var _die_a: DieView = null
var _die_b: DieView = null
var _hint: Label = null
var _time: float = 0.0


func _init() -> void:
	custom_minimum_size = Vector2(0, 520)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP

	_die_a = DieView.new(200)
	_die_b = DieView.new(200)
	_die_a.visible = false
	_die_b.visible = false
	add_child(_die_a)
	add_child(_die_b)

	_hint = UI.label("Maintiens ton doigt ici\npour voir tes dés", 40, UI.WOOD_DARK, true)
	_hint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE, 90)
	add_child(_hint)
	resized.connect(_relayout)


func _relayout() -> void:
	var d := minf(size.x * 0.34, 210.0)
	for die in [_die_a, _die_b]:
		(die as DieView).custom_minimum_size = Vector2(d, d)
		(die as DieView).size = Vector2(d, d)
	var gap := d * 0.2
	var total := d * 2.0 + gap
	var y := (size.y - d) / 2.0
	_die_a.position = Vector2((size.x - total) / 2.0, y)
	_die_b.position = Vector2((size.x - total) / 2.0 + d + gap, y)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0 - 16.0
	var pulse := 0.0 if holding else (sin(_time * 3.0) * 0.5 + 0.5)
	draw_circle(c + Vector2(0, 12), r, Color(0, 0, 0, 0.4))
	var rim: Color = UI.WOOD_DARKEST if holding else UI.FOAM_SHADE
	var face: Color = UI.WOOD_DARK if holding else UI.FOAM
	var ring: Color = UI.AMBER if holding else UI.AMBER_DARK
	draw_circle(c, r, rim)
	draw_circle(c, r - 16.0, face)
	draw_arc(c, r - 40.0, 0.0, TAU, 72, ring, 6.0, true)
	# Pointillés décoratifs d'un sous-bock
	for i in 24:
		var a := TAU * i / 24.0
		draw_circle(c + Vector2.from_angle(a) * (r - 62.0), 4.0, ring)
	if not holding:
		draw_arc(c, r + 6.0 + pulse * 10.0, 0.0, TAU, 72, Color(UI.AMBER_LIGHT, 0.55 * (1.0 - pulse)), 5.0, true)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		if (event as InputEventMouseButton).pressed:
			_press()
	elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		_press()


func _input(event: InputEvent) -> void:
	# On cache les dés dès que le doigt se lève, même s'il a glissé hors du sous-bock.
	if not holding:
		return
	if event is InputEventMouseButton and not (event as InputEventMouseButton).pressed:
		_release()
	elif event is InputEventScreenTouch and not (event as InputEventScreenTouch).pressed:
		_release()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_release()
	elif what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		_release()


func _press() -> void:
	if holding:
		return
	holding = true
	_hint.visible = false
	_die_a.visible = true
	_die_b.visible = true
	_relayout()
	var first := not has_seen
	if first:
		has_seen = true
		_die_a.tumble(dice.x, 0.8)
		_die_b.tumble(dice.y, 0.95)
		Sfx.play("dice")
	else:
		_die_a.value = dice.x
		_die_b.value = dice.y
	holding_changed.emit(true)
	if first:
		first_reveal.emit()


func _release() -> void:
	if not holding:
		return
	holding = false
	_die_a.visible = false
	_die_b.visible = false
	_hint.text = "Maintiens ton doigt ici\npour revoir tes dés"
	_hint.visible = true
	holding_changed.emit(false)
