extends BaseScreen
## Écran du joueur suivant : l'annonce en GROS, la mise actuelle, et les deux choix
## « JE TE CROIS » / « MENTEUR ! ». Après LA CAISSE, croire = boire la mise tout de suite.


func _build() -> void:
	var s := Game.session
	var is_caisse := s.must_believe_or_accuse()

	content.add_theme_constant_override("separation", 16)

	content.add_child(UI.label("%s annonce" % s.announcer_name(), 44, UI.MUTED))

	# La grosse carte de l'annonce
	var card_fill: Color = UI.AMBER_LIGHT if is_caisse else UI.FOAM
	var card := UI.panel(card_fill, 40, UI.AMBER_DARK, 8, 18)
	content.add_child(card)
	var card_box := VBoxContainer.new()
	card_box.add_theme_constant_override("separation", 0)
	card.add_child(card_box)
	var number := UI.label("LA CAISSE" if is_caisse else str(s.announced), 200 if not is_caisse else 118, UI.WOOD_DARKEST, true)
	card_box.add_child(number)
	var tag := ""
	if is_caisse:
		tag = "le plus fort de tous (21)"
	elif Dice.is_mousse(s.announced):
		tag = "Mousse de %d" % Dice.high_die(s.announced)
	if not tag.is_empty():
		card_box.add_child(UI.label(tag, 34, UI.AMBER_DARK))

	# La mise
	var pot_row := HBoxContainer.new()
	pot_row.alignment = BoxContainer.ALIGNMENT_CENTER
	pot_row.add_theme_constant_override("separation", 12)
	content.add_child(pot_row)
	pot_row.add_child(IconView.new("mug", 64.0, UI.AMBER))
	pot_row.add_child(UI.inline_label("Mise : %s" % Fr.sips(s.pot), 44, UI.AMBER_LIGHT, true))

	content.add_child(UI.spacer(0.7))
	var ask := UI.label("Alors... tu la crois ?" if not is_caisse else "Tu oses la croire ?", 56, UI.AMBER, true)
	UI.outline(ask, UI.WOOD_DARKEST, 8)
	content.add_child(ask)
	content.add_child(UI.spacer(1.0))

	# Croire
	var believe_text := "JE TE CROIS"
	var believe := UI.button(believe_text, "good", 58, 132)
	believe.pressed.connect(func() -> void: Game.believe())
	content.add_child(believe)
	var believe_caption := ""
	if is_caisse:
		believe_caption = "Impossible de faire mieux : tu bois %s tout de suite." % Fr.sips(s.stake_if_believing_caisse())
	else:
		believe_caption = "La mise monte à %s et tu relances tes dés." % Fr.sips(s.pot_if_believed())
	content.add_child(UI.label(believe_caption, 28, UI.MUTED))

	content.add_child(UI.gap(6))

	# Accuser
	var accuse := UI.button("MENTEUR !", "danger", 66, 150)
	accuse.pressed.connect(func() -> void: Game.accuse())
	content.add_child(accuse)
	var stake := s.stake_if_accused()
	var accuse_caption := "Tu as raison : %s boit %s. Tu as tort : c'est toi." % [s.announcer_name(), Fr.sips(stake)]
	if is_caisse:
		accuse_caption += " (mise doublée !)"
	content.add_child(UI.label(accuse_caption, 28, UI.MUTED))

	if is_caisse:
		Sfx.play("caisse", -4.0)


func on_back() -> void:
	open_pause()
