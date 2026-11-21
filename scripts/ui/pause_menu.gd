class_name PauseMenu
extends Modal
## Menu de pause (bouton « ☰ » des écrans de passage et de révélation).
## `back` décrit l'écran où revenir : { "screen": "pass", "args": {...} }.

var _back: Dictionary = {}


func _init(p_back: Dictionary = {}) -> void:
	super._init(600.0)
	_back = p_back
	_show_main()


func _show_main() -> void:
	clear_box()
	box.add_child(UI.label("PAUSE", 60, UI.AMBER, true))

	var resume := UI.button("REPRENDRE", "primary", 44, 100)
	resume.pressed.connect(close)
	box.add_child(resume)

	var stats := UI.button("STATS DE LA PARTIE", "ghost", 38, 92)
	stats.pressed.connect(func() -> void: Game.show_stats(false, _back))
	box.add_child(stats)

	var rules := UI.button("RÈGLES", "ghost", 38, 92)
	rules.pressed.connect(func() -> void: Game.go("rules", { "back": _back }))
	box.add_child(rules)

	var end := UI.button("TERMINER LA PARTIE", "danger", 38, 92)
	end.pressed.connect(_show_confirm)
	box.add_child(end)


func _show_confirm() -> void:
	clear_box()
	box.add_child(UI.label("Terminer la partie ?", 50, UI.AMBER, true))
	box.add_child(UI.label("On passe au tableau final des stats.", 32))
	var yes := UI.button("OUI, VOIR LES STATS", "danger", 38, 96)
	yes.pressed.connect(func() -> void: Game.show_stats(true))
	box.add_child(yes)
	var no := UI.button("NON, ON CONTINUE", "primary", 38, 96)
	no.pressed.connect(_show_main)
	box.add_child(no)
