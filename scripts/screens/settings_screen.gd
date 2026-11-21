extends BaseScreen
## Réglages : limite de gorgées, mode Soft (eau/défis), sons, voix, vibrations, indice.
## Tout est sauvegardé automatiquement à chaque changement.

var _max_label: Label = null
var _soft_buttons: HBoxContainer = null


func _build() -> void:
	content.add_theme_constant_override("separation", 14)

	var header := HBoxContainer.new()
	content.add_child(header)
	var back := UI.icon_button("left", "ghost", 84)
	back.pressed.connect(on_back)
	header.add_child(back)
	header.add_child(UI.label("Réglages", 62, UI.AMBER, true))
	var balance := Control.new()
	balance.custom_minimum_size = Vector2(84, 0)
	header.add_child(balance)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 16)
	scroll.add_child(list)

	# Limite de gorgées
	var sips_card := _card(list, "Limite de gorgées par punition",
		"Une punition ne dépassera jamais ce nombre, même avec une grosse mise.")
	var stepper := HBoxContainer.new()
	stepper.add_theme_constant_override("separation", 16)
	sips_card.add_child(stepper)
	var minus := UI.icon_button("minus", "ghost", 92)
	minus.pressed.connect(func() -> void: _change_max(-1))
	stepper.add_child(minus)
	_max_label = UI.label(str(Settings.max_sips), 76, UI.AMBER, true)
	stepper.add_child(_max_label)
	var plus := UI.icon_button("plus", "ghost", 92)
	plus.pressed.connect(func() -> void: _change_max(1))
	stepper.add_child(plus)

	# Mode Soft
	var soft_card := _card(list, "Mode Soft (sans alcool)",
		"De l'eau ou des défis à la place des gorgées d'alcool.")
	_toggle_row(soft_card, "Activer le mode Soft", Settings.soft_mode, func(v: bool) -> void:
		Settings.soft_mode = v
		Settings.save_settings()
		_refresh_soft())
	_soft_buttons = HBoxContainer.new()
	_soft_buttons.add_theme_constant_override("separation", 10)
	soft_card.add_child(_soft_buttons)
	for opt: Array in [["Eau", Challenges.KIND_WATER], ["Défis", Challenges.KIND_CHALLENGE], ["Les deux", Challenges.KIND_MIX]]:
		var b := UI.button(opt[0], "ghost", 32, 80)
		var kind: String = opt[1]
		b.pressed.connect(func() -> void:
			Settings.soft_kind = kind
			Settings.save_settings()
			_refresh_soft())
		b.set_meta("kind", kind)
		_soft_buttons.add_child(b)
	_refresh_soft()

	# Sons, voix, vibrations, indice
	var device_card := _card(list, "Sons et vibrations", "")
	_toggle_row(device_card, "Sons", Settings.sound_on, func(v: bool) -> void:
		Settings.sound_on = v
		Settings.save_settings())
	_toggle_row(device_card, "Voix « Menteur ! »", Settings.voice_on, func(v: bool) -> void:
		Settings.voice_on = v
		Settings.save_settings())
	_toggle_row(device_card, "Vibrations", Settings.vibration_on, func(v: bool) -> void:
		Settings.vibration_on = v
		Settings.save_settings())

	var hint_card := _card(list, "Aide pour annoncer",
		"Un petit point discret montre ton vrai résultat dans la grille d'annonce.")
	_toggle_row(hint_card, "Afficher le point", Settings.show_hint, func(v: bool) -> void:
		Settings.show_hint = v
		Settings.save_settings())

	var ok := UI.button("OK", "primary", 52, 112)
	ok.pressed.connect(on_back)
	content.add_child(ok)


func _card(parent: Control, title: String, subtitle: String) -> VBoxContainer:
	var card := UI.panel(Color(0, 0, 0, 0.3), 28, Color.TRANSPARENT, 0, 22)
	parent.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	card.add_child(col)
	col.add_child(UI.label(title, 38, UI.FOAM, true, HORIZONTAL_ALIGNMENT_LEFT))
	if not subtitle.is_empty():
		col.add_child(UI.label(subtitle, 26, UI.MUTED, false, HORIZONTAL_ALIGNMENT_LEFT))
	return col


## Une ligne « texte ........ [OUI/NON] ».
func _toggle_row(parent: Control, text: String, value: bool, on_change: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	row.add_child(UI.label(text, 34, UI.FOAM, false, HORIZONTAL_ALIGNMENT_LEFT))
	_add_toggle(row, value, on_change)


## Un bouton OUI/NON qui bascule.
func _add_toggle(parent: Control, value: bool, on_change: Callable) -> void:
	var b := UI.button("OUI" if value else "NON", "good" if value else "ghost", 36, 80)
	b.size_flags_horizontal = Control.SIZE_SHRINK_END
	b.custom_minimum_size = Vector2(150, 80)
	var state := [value]
	b.pressed.connect(func() -> void:
		state[0] = not state[0]
		b.text = "OUI" if state[0] else "NON"
		UI.apply_button_style(b, "good" if state[0] else "ghost")
		on_change.call(state[0]))
	parent.add_child(b)


func _change_max(delta: int) -> void:
	Settings.max_sips = clampi(Settings.max_sips + delta, Rules.MIN_MAX_SIPS, Rules.MAX_MAX_SIPS)
	_max_label.text = str(Settings.max_sips)
	Settings.save_settings()


## Active/désactive visuellement le choix eau/défis selon le mode Soft.
func _refresh_soft() -> void:
	for b: Button in _soft_buttons.get_children():
		var selected: bool = b.get_meta("kind") == Settings.soft_kind
		UI.apply_button_style(b, "primary" if selected else "ghost")
		b.disabled = not Settings.soft_mode


func on_back() -> void:
	Game.go_home()
