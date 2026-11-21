class_name WarningDialog
extends Modal
## Avertissement affiché au démarrage : 18+ / âge légal, consommation responsable.

## Émis quand le joueur accepte (avec ou sans mode Soft).
signal accepted


func _init() -> void:
	super._init(620.0)
	var title := UI.label("Avant de commencer", 54, UI.AMBER, true)
	box.add_child(title)
	box.add_child(UI.label("La Caisse est un jeu pour adultes : 18 ans et plus (ou l'âge légal de ta région).", 32))
	box.add_child(UI.label("Bois de façon responsable. Personne n'est obligé de finir son verre.", 32))
	var drive := UI.label("Ne conduis jamais après avoir bu.", 34, UI.AMBER_LIGHT)
	drive.add_theme_font_override("font", UI.body_font(700))
	box.add_child(drive)
	box.add_child(UI.gap(4))

	var ok := UI.button("J'AI L'ÂGE LÉGAL", "primary", 42, 100)
	ok.pressed.connect(func() -> void: _accept(false))
	box.add_child(ok)

	var soft := UI.button("JE JOUE EN MODE SOFT", "ghost", 36, 88)
	soft.pressed.connect(func() -> void: _accept(true))
	box.add_child(soft)
	box.add_child(UI.label("Mode Soft : de l'eau ou des défis à la place de l'alcool.", 26, UI.MUTED))


func _accept(soft_mode: bool) -> void:
	Settings.age_accepted = true
	if soft_mode:
		Settings.soft_mode = true
		Settings.save_settings()
	accepted.emit()
	close()
