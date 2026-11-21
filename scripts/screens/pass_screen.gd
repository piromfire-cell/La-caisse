extends BaseScreen
## « Passe le téléphone à NOM » — écran anti-triche entre deux joueurs.
## Paramètre : kind = "roll" (le joueur va lancer ses dés) ou "decide" (il doit répondre
## à une annonce). Rien de secret n'est affiché ici.


func _build() -> void:
	var kind: String = args.get("kind", "roll")
	var s := Game.session

	var top := HBoxContainer.new()
	content.add_child(top)
	top.add_child(UI.spacer())
	var menu := UI.icon_button("menu", "ghost", 80)
	menu.pressed.connect(open_pause)
	top.add_child(menu)

	content.add_child(UI.spacer(0.6))

	var phone := IconView.new("phone", 190.0, UI.AMBER)
	content.add_child(phone)
	var wiggle := phone.create_tween().set_loops()
	wiggle.tween_property(phone, "rotation_degrees", 9.0, 0.5).set_trans(Tween.TRANS_SINE)
	wiggle.tween_property(phone, "rotation_degrees", -9.0, 0.5).set_trans(Tween.TRANS_SINE)

	content.add_child(UI.label("Passe le téléphone à", 44, UI.MUTED))

	var player := s.current_name()
	var name_label := UI.label(player, 120, UI.FOAM, true)
	name_label.add_theme_font_size_override("font_size", UI.fit_font_size(player, UI.display_font(), 120, 640.0, 56))
	UI.outline(name_label, UI.AMBER_DARK, 12)
	content.add_child(name_label)

	var hint := ""
	if kind == "decide":
		hint = "Une annonce t'attend. Tu la crois... ou tu démasques le menteur ?"
	elif s.has_announcement():
		hint = "Relance tes dés en secret et fais plus fort !"
	else:
		hint = "Tu ouvres la manche : lance tes dés en secret !"
	content.add_child(UI.label(hint, 34, UI.AMBER_LIGHT))

	content.add_child(UI.spacer(1.0))

	var ready := UI.button("C'EST MOI !", "primary", 62, 140)
	ready.pressed.connect(func() -> void: Game.pass_done(kind))
	content.add_child(ready)

	content.add_child(UI.label(_status_line(kind), 28, UI.MUTED))


func _status_line(kind: String) -> String:
	var s := Game.session
	var line := "Manche %d" % s.round_number
	if kind == "decide":
		line += " · Mise : %s" % Fr.sips(s.pot)
	return line


func on_back() -> void:
	open_pause()
