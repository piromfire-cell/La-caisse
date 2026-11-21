extends BaseScreen
## Écran d'accueil : mascotte (chope), titre, et les boutons Jouer / Règles / Réglages.
## Au premier affichage de la session, l'avertissement 18+ s'affiche par-dessus.


func _build() -> void:
	content.add_theme_constant_override("separation", 14)
	content.add_child(UI.spacer(0.5))

	var mug := MugView.new()
	mug.custom_minimum_size = Vector2(0, 340)
	mug.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mug.size_flags_stretch_ratio = 2.0
	content.add_child(mug)

	var title := UI.label("LA CAISSE", 124, UI.FOAM, true)
	UI.outline(title, UI.AMBER_DARK, 14)
	content.add_child(title)
	content.add_child(UI.label("Le jeu de bluff qui se boit", 38, UI.AMBER_LIGHT))

	content.add_child(UI.spacer(0.6))

	var play := UI.button("JOUER", "primary", 70, 150)
	play.pressed.connect(func() -> void: Game.go("players"))
	content.add_child(play)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	content.add_child(row)
	var rules := UI.button("RÈGLES", "ghost", 42, 108)
	rules.pressed.connect(func() -> void: Game.go("rules"))
	row.add_child(rules)
	var settings := UI.button("RÉGLAGES", "ghost", 42, 108)
	settings.pressed.connect(func() -> void: Game.go("settings"))
	row.add_child(settings)

	var footer := "Mode Soft activé : eau et défis" if Settings.soft_mode else "18 ans et plus · Bois de façon responsable"
	content.add_child(UI.label(footer, 26, UI.MUTED))

	if not Settings.age_accepted:
		add_child(WarningDialog.new())


func on_back() -> void:
	get_tree().quit()
