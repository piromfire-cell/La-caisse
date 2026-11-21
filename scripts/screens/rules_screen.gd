extends BaseScreen
## Règles illustrées, courtes et claires. Les dés sont dessinés avec le même widget
## que dans le jeu.


func _build() -> void:
	content.add_theme_constant_override("separation", 14)

	var header := HBoxContainer.new()
	content.add_child(header)
	var back := UI.icon_button("left", "ghost", 84)
	back.pressed.connect(on_back)
	header.add_child(back)
	header.add_child(UI.label("Les règles", 62, UI.AMBER, true))
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

	# 1. Le but
	var goal := _card(list, "1", "Le but")
	goal.add_child(_text("Bluffe... ou démasque les menteurs ! À ton tour, tu lances 2 dés en secret et tu annonces un résultat : la vérité, ou un bluff. Celui qui se fait prendre boit."))

	# 2. Lire les dés
	var read := _card(list, "2", "Lire les dés")
	read.add_child(_text("Le plus gros chiffre se lit en premier."))
	read.add_child(_dice_example([3, 5], "= 53"))
	read.add_child(_dice_example([1, 2], "= 21"))

	# 3. Le classement
	var rank := _card(list, "3", "Du plus faible au plus fort")
	rank.add_child(_tier_label("Les normaux (le plus faible)", UI.MUTED))
	rank.add_child(_chips([31, 32, 41, 42, 43, 51, 52, 53, 54, 61, 62, 63, 64, 65], UI.WOOD_LIGHT, UI.FOAM))
	rank.add_child(_tier_label("Les mousses (doubles) : plus forts", UI.AMBER_LIGHT))
	rank.add_child(_chips([11, 22, 33, 44, 55, 66], UI.FOAM, UI.WOOD_DARKEST))
	rank.add_child(_tier_label("LA CAISSE : le plus fort de tous", UI.AMBER))
	rank.add_child(_chips([21], UI.AMBER_LIGHT, UI.WOOD_DARKEST))

	# 4. Ton tour
	var turn := _card(list, "4", "À ton tour")
	turn.add_child(_text("• Le téléphone te passe : maintiens ton doigt sur l'écran pour voir tes dés (ils se cachent quand tu lâches)."))
	turn.add_child(_text("• Annonce un résultat PLUS FORT que le précédent. Vrai ou bluff, à toi de voir. Premier de la manche : tout est permis."))
	turn.add_child(_text("• Passe le téléphone au joueur suivant."))

	# 5. Croire ou accuser
	var answer := _card(list, "5", "Croire ou accuser ?")
	answer.add_child(_text("JE TE CROIS : la mise monte de 1 gorgée. Tu relances tes dés en secret et tu annonces plus fort."))
	answer.add_child(_text("MENTEUR ! : les vrais dés sont révélés."))
	answer.add_child(_text("• Il avait bluffé (dés plus faibles) : le menteur boit la mise."))
	answer.add_child(_text("• C'était vrai (dés égaux ou plus forts) : l'accusateur boit la mise."))

	# 6. La mise
	var pot := _card(list, "6", "La mise")
	pot.add_child(_text("Elle commence à 1 gorgée et monte de 1 à chaque « Je te crois ». Si l'annonce contestée est LA CAISSE, la mise est doublée. Une punition ne dépasse jamais la limite des réglages."))
	pot.add_child(_text("Après une accusation : mise remise à 1, annonces effacées, et le perdant commence la manche suivante."))

	# 7. LA CAISSE
	var caisse := _card(list, "7", "LA CAISSE")
	caisse.add_child(_dice_example([2, 1], "= LA CAISSE"))
	caisse.add_child(_text("Rien ne bat LA CAISSE. Le joueur suivant peut seulement la croire (il boit la mise tout de suite, et la manche recommence) ou accuser."))

	list.add_child(UI.label("Mode Soft : de l'eau ou des défis à la place de l'alcool. Bois de façon responsable !", 28, UI.MUTED))

	var ok := UI.button("COMPRIS !", "primary", 52, 112)
	ok.pressed.connect(on_back)
	content.add_child(ok)


func _card(parent: Control, number: String, title: String) -> VBoxContainer:
	var card := UI.panel(Color(0, 0, 0, 0.3), 28, Color.TRANSPARENT, 0, 22)
	parent.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	card.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	col.add_child(head)
	var badge := UI.panel(UI.AMBER, 24, Color.TRANSPARENT, 0, 0)
	badge.custom_minimum_size = Vector2(52, 52)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var n := UI.label(number, 34, UI.WOOD_DARKEST, true)
	badge.add_child(n)
	head.add_child(badge)
	head.add_child(UI.label(title, 40, UI.AMBER_LIGHT, true, HORIZONTAL_ALIGNMENT_LEFT))
	return col


func _text(t: String) -> Label:
	var l := UI.label(t, 30, UI.FOAM, false, HORIZONTAL_ALIGNMENT_LEFT)
	return l


func _tier_label(t: String, color: Color) -> Label:
	var l := UI.label(t, 26, color, false, HORIZONTAL_ALIGNMENT_LEFT)
	l.add_theme_font_override("font", UI.body_font(700))
	return l


## Deux petits dés suivis d'un texte (ex. « = 53 »).
func _dice_example(faces: Array, result: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for f in faces:
		var d := DieView.new(84)
		d.value = int(f)
		row.add_child(d)
	row.add_child(UI.inline_label(result, 56, UI.AMBER, true))
	return row


## Une série de pastilles numérotées (retour à la ligne automatique).
func _chips(values: Array, fill: Color, text_color: Color) -> Control:
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	for v in values:
		var chip := UI.panel(fill, 16, Color.TRANSPARENT, 0, 6)
		var l := UI.inline_label(str(v), 32, text_color, true)
		l.custom_minimum_size = Vector2(62, 0)
		chip.add_child(l)
		flow.add_child(chip)
	return flow


func on_back() -> void:
	var back: Dictionary = args.get("back", {})
	if back.has("screen"):
		Game.go(str(back["screen"]), back.get("args", {}))
	else:
		Game.go_home()
