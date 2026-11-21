extends BaseScreen
## Révélation animée : « MENTEUR ! », les vrais dés qui roulent, le verdict (bluff démasqué
## ou accusation à tort) et le nombre de gorgées à boire, en TRÈS gros.
## Toucher l'écran pendant l'animation saute directement à la fin.
## Sert aussi pour la règle spéciale : croire LA CAISSE = boire la mise sans révéler les dés.

var _v: Verdict = null
var _penalty: Dictionary = {}
var _special: bool = false
var _finished: bool = false
var _sequence: Tween = null
## Toutes les animations en cours (pour pouvoir les arrêter net quand on saute à la fin).
var _tweens: Array[Tween] = []

var _title: Label = null
var _sub: Label = null
var _die_a: DieView = null
var _die_b: DieView = null
var _dice_row: HBoxContainer = null
var _readout: Label = null
var _verdict: Label = null
var _loser: Label = null
var _amount_row: HBoxContainer = null
var _amount: Label = null
var _unit: Label = null
var _note: Label = null
var _challenge: PanelContainer = null
var _buttons: VBoxContainer = null
var _next_button: Button = null
var _end_button: Button = null


func _build() -> void:
	var s := Game.session
	_v = s.last_verdict
	_special = _v.kind == Verdict.Kind.CAISSE_BELIEVED
	_penalty = Game.describe_penalty(_v.sips)

	content.add_theme_constant_override("separation", 10)

	# Bouton menu posé dans le coin (hors de la colonne, pour gagner de la hauteur).
	var menu := UI.icon_button("menu", "ghost", 72)
	menu.position = Vector2(36, UI.safe_top())
	menu.pressed.connect(open_pause)
	add_child(menu)

	_title = UI.label("LA CAISSE !" if _special else "MENTEUR !", 108, UI.FOAM, true)
	UI.outline(_title, UI.RED_DARK if not _special else UI.AMBER_DARK, 16)
	content.add_child(_title)

	var sub_text := ""
	if _special:
		sub_text = "%s croit %s : impossible de faire mieux !" % [s.players[_v.accuser], s.players[_v.announcer]]
	else:
		sub_text = "%s avait annoncé %s" % [s.players[_v.announcer], "LA CAISSE" if _v.announced == Dice.CAISSE else str(_v.announced)]
	_sub = UI.label(sub_text, 36, UI.AMBER_LIGHT)
	content.add_child(_sub)
	content.add_child(UI.spacer(0.35))

	# Dés (seulement quand il y a eu accusation)
	_dice_row = HBoxContainer.new()
	_dice_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_dice_row.add_theme_constant_override("separation", 34)
	content.add_child(_dice_row)
	_die_a = DieView.new(150)
	_die_b = DieView.new(150)
	_die_a.covered = true
	_die_b.covered = true
	_dice_row.add_child(_die_a)
	_dice_row.add_child(_die_b)
	_dice_row.visible = not _special

	_readout = UI.label("", 40, UI.FOAM, true)
	if not _special:
		_readout.text = "Vrais dés : %s" % ("LA CAISSE" if _v.real_value == Dice.CAISSE else str(_v.real_value))
	content.add_child(_readout)
	content.add_child(UI.spacer(0.35))

	_verdict = UI.label(_verdict_text(), 62, _verdict_color(), true)
	UI.outline(_verdict, UI.WOOD_DARKEST, 10)
	content.add_child(_verdict)

	var loser_name := s.players[_v.loser]
	var loser_text := "%s boit" % loser_name
	if _penalty["type"] == "challenge":
		loser_text = "%s relève un défi !" % loser_name
	_loser = UI.label(loser_text, 54, UI.AMBER, true)
	content.add_child(_loser)
	content.add_child(UI.spacer(0.25))

	# Quantité à boire, en très gros
	_amount_row = HBoxContainer.new()
	_amount_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_amount_row.add_theme_constant_override("separation", 20)
	content.add_child(_amount_row)
	_amount = UI.inline_label(str(_v.sips), 240, UI.FOAM, true)
	UI.outline(_amount, UI.AMBER_DARK, 18)
	_amount_row.add_child(_amount)
	_unit = UI.inline_label(_unit_text(), 50, UI.AMBER_LIGHT, true)
	_amount_row.add_child(_unit)

	_challenge = UI.panel(UI.FOAM, 32, UI.AMBER_DARK, 6, 24)
	var challenge_label := UI.label(str(_penalty["text"]), 40, UI.WOOD_DARKEST)
	challenge_label.add_theme_font_override("font", UI.body_font(600))
	_challenge.add_child(challenge_label)
	content.add_child(_challenge)

	var is_challenge: bool = _penalty["type"] == "challenge"
	_amount_row.visible = not is_challenge
	_challenge.visible = is_challenge

	_note = UI.label("LA CAISSE double la mise !" if _v.doubled else "", 30, UI.AMBER_LIGHT)
	content.add_child(_note)

	content.add_child(UI.spacer(0.9))

	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 12)
	content.add_child(_buttons)
	_next_button = UI.button("MANCHE SUIVANTE", "primary", 52, 116)
	_next_button.pressed.connect(func() -> void: Game.next_round())
	_buttons.add_child(_next_button)
	_end_button = UI.button("TERMINER LA PARTIE", "ghost", 32, 70)
	_end_button.pressed.connect(func() -> void: Game.show_stats(true))
	_buttons.add_child(_end_button)

	# Tout est caché au départ : l'animation fait apparaître les éléments un par un.
	for node: CanvasItem in [_sub, _dice_row, _readout, _verdict, _loser, _amount_row, _challenge, _note, _buttons]:
		node.modulate.a = 0.0
	_next_button.disabled = true
	_end_button.disabled = true

	if args.get("instant", false):
		_finish()
	else:
		_play()


func resume_args() -> Dictionary:
	return { "instant": true }


# ── Textes ────────────────────────────────────────────────────────────────────

func _verdict_text() -> String:
	if _special:
		return "ON LA CROIT !"
	return "BLUFF DÉMASQUÉ !" if _v.was_bluff else "C'ÉTAIT VRAI !"


func _verdict_color() -> Color:
	if _special:
		return UI.AMBER_LIGHT
	return Color("ff7b6e") if _v.was_bluff else Color("8be07a")


## « gorgée(s) » (+ « d'EAU » en mode Soft).
func _unit_text() -> String:
	var word := "gorgée" if _v.sips <= 1 else "gorgées"
	if _penalty["type"] == "water":
		word += " d'EAU"
	return word


# ── Animation ─────────────────────────────────────────────────────────────────

func _play() -> void:
	_sequence = create_tween()
	_sequence.tween_callback(_step_title)
	_sequence.tween_interval(1.2)
	_sequence.tween_callback(_step_sub)
	if _special:
		_sequence.tween_interval(1.0)
	else:
		_sequence.tween_interval(0.9)
		_sequence.tween_callback(_step_dice)
		_sequence.tween_interval(1.9)
		_sequence.tween_callback(_step_readout)
		_sequence.tween_interval(0.9)
	_sequence.tween_callback(_step_verdict)
	_sequence.tween_interval(1.0)
	_sequence.tween_callback(_step_loser)
	_sequence.tween_interval(0.7)
	_sequence.tween_callback(_step_amount)
	_sequence.tween_interval(0.9)
	_sequence.tween_callback(_step_buttons)


func _track(tw: Tween) -> Tween:
	_tweens.append(tw)
	return tw


func _pop(node: Control, from_scale: float = 1.9, duration: float = 0.35) -> void:
	node.modulate.a = 1.0
	node.pivot_offset = node.size / 2.0
	node.scale = Vector2.ONE * from_scale
	_track(node.create_tween()).tween_property(node, "scale", Vector2.ONE, duration)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _fade(node: CanvasItem, duration: float = 0.3) -> void:
	_track(node.create_tween()).tween_property(node, "modulate:a", 1.0, duration)


func _step_title() -> void:
	_title.pivot_offset = _title.size / 2.0
	_title.scale = Vector2.ONE * 2.4
	_title.modulate.a = 0.0
	var tw := _track(_title.create_tween()).set_parallel(true)
	tw.tween_property(_title, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_title, "modulate:a", 1.0, 0.15)
	if _special:
		Sfx.play("caisse")
	else:
		Sfx.play("slam")
		Sfx.play("buzzer", -3.0)
		Sfx.shout_menteur()
	Sfx.vibrate(250)


func _step_sub() -> void:
	_fade(_sub)


func _step_dice() -> void:
	_fade(_dice_row, 0.25)
	var tw := _track(create_tween())
	tw.tween_interval(0.35)
	tw.tween_callback(func() -> void:
		Sfx.play("dice")
		_die_a.tumble(_v.dice.x, 1.0)
		_die_b.tumble(_v.dice.y, 1.25))


func _step_readout() -> void:
	_fade(_readout, 0.25)


func _step_verdict() -> void:
	_pop(_verdict)
	if _special:
		Sfx.play("gulp")
	elif _v.was_bluff:
		Sfx.play("win")
	else:
		Sfx.play("fail")


func _step_loser() -> void:
	_pop(_loser, 1.5)


func _step_amount() -> void:
	var target: CanvasItem = _challenge if _penalty["type"] == "challenge" else _amount_row
	_pop(target as Control, 2.2, 0.45)
	_fade(_note)
	Sfx.play("clink")
	if _penalty["type"] != "challenge":
		Sfx.play("gulp", -2.0)
	Sfx.vibrate(400)
	Confetti.burst(self, Vector2(size.x / 2.0, size.y * 0.6))


func _step_buttons() -> void:
	_finished = true
	_fade(_buttons, 0.25)
	_next_button.disabled = false
	_end_button.disabled = false


## Saute à l'état final : tout est visible, plus d'animation en cours.
func _finish() -> void:
	if _sequence != null and _sequence.is_valid():
		_sequence.kill()
	for tw in _tweens:
		if tw.is_valid():
			tw.kill()
	_finished = true
	_title.scale = Vector2.ONE
	for node: CanvasItem in [_title, _sub, _dice_row, _readout, _verdict, _loser, _amount_row, _challenge, _note, _buttons]:
		node.modulate.a = 1.0
		if node is Control:
			(node as Control).scale = Vector2.ONE
	if not _special:
		_die_a.settle(_v.dice.x)
		_die_b.settle(_v.dice.y)
	_next_button.disabled = false
	_end_button.disabled = false


func _gui_input(event: InputEvent) -> void:
	if _finished:
		return
	var pressed := (event is InputEventMouseButton and (event as InputEventMouseButton).pressed) \
		or (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed)
	if pressed:
		_finish()


func on_back() -> void:
	open_pause()
