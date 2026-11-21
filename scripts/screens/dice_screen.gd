extends BaseScreen
## Écran SECRET des dés : on maintient le doigt sur le sous-bock pour voir ses dés ;
## ils se cachent dès qu'on lâche. On ne peut continuer qu'après les avoir vus une fois.

var _pad: HoldPad = null
var _readout: Label = null
var _next_button: Button = null
## Les dés ont-ils déjà été montrés une fois ? (la première fois, ils roulent avant de s'arrêter)
var _shown_once: bool = false


func _build() -> void:
	var s := Game.session
	# Lance les dés pour ce tour (ne relance jamais si c'est déjà fait).
	var dice := s.roll_dice()
	var value := s.real_value

	var intro := "%s, relance tes dés !" if s.has_announcement() else "%s, à toi de jouer !"
	var player := s.current_name()
	var title := UI.label(intro % player, 56, UI.AMBER, true)
	title.add_theme_font_size_override("font_size", UI.fit_font_size(intro % player, UI.display_font(), 56, 640.0, 36))
	content.add_child(title)

	var rank_hint := "Ta mise est de %s." % Fr.sips(s.pot) if s.has_announcement() else "Personne ne doit voir l'écran !"
	content.add_child(UI.label(rank_hint, 30, UI.MUTED))

	_pad = HoldPad.new()
	_pad.dice = dice
	content.add_child(_pad)

	_readout = UI.label(" ", 56, UI.FOAM, true)
	UI.outline(_readout, UI.WOOD_DARKEST, 8)
	_readout.modulate.a = 0.0
	content.add_child(_readout)

	_next_button = UI.button("J'AI VU : ANNONCER", "primary", 48, 124)
	_next_button.disabled = true
	_next_button.pressed.connect(func() -> void: Game.dice_done())
	content.add_child(_next_button)

	_pad.first_reveal.connect(func() -> void: _next_button.disabled = false)
	_pad.holding_changed.connect(func(h: bool) -> void: _on_holding(h, value))


func _on_holding(holding: bool, value: int) -> void:
	if not holding:
		_readout.modulate.a = 0.0
		return
	var text := "Tu lis : %d" % value
	var color: Color = UI.FOAM
	if Dice.is_caisse(value):
		text = "LA CAISSE !"
		color = UI.AMBER_LIGHT
	elif Dice.is_mousse(value):
		text = "Mousse de %d (%d)" % [Dice.high_die(value), value]
		color = UI.AMBER_LIGHT
	_readout.text = text
	_readout.add_theme_color_override("font_color", color)
	_readout.modulate.a = 0.0
	# Le résultat apparaît quand les dés ont fini de rouler.
	var tw := _readout.create_tween()
	tw.tween_interval(0.0 if _shown_once else 0.95)
	tw.tween_property(_readout, "modulate:a", 1.0, 0.12)
	_shown_once = true


func on_back() -> void:
	open_pause()
