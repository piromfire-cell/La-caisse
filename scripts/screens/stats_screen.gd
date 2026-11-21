extends BaseScreen
## Tableau des stats : « prix » (plus gros menteur, meilleur détecteur, bluffs réussis,
## plus assoiffé) et le détail par joueur (gorgées bues, bluffs, accusations).
## Paramètres : final (bool) = fin de partie ; back = écran où « Reprendre » ramène.

const AWARD_ICONS := {
	"liar": "bubble",
	"detector": "magnifier",
	"bluffer": "crown",
	"thirsty": "mug",
}


func _build() -> void:
	var s := Game.session
	var final: bool = args.get("final", true)

	content.add_theme_constant_override("separation", 14)
	content.add_child(UI.label("Fin de la partie" if final else "Stats de la partie", 62, UI.AMBER, true))
	content.add_child(UI.label("%s · %s bues en tout" % [
		Fr.plural(s.round_number - (0 if s.phase == MatchState.Phase.ROUND_OVER else 1), "manche jouée", "manches jouées"),
		Fr.sips(s.total_sips()) if not Settings.soft_mode else Fr.sips(s.total_sips()) + " (eau/défis)"], 28, UI.MUTED))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 14)
	scroll.add_child(list)

	var awards := s.awards()
	if awards.is_empty():
		list.add_child(UI.label("Aucune statistique pour l'instant : jouez quelques manches !", 32, UI.FOAM))
	for award in awards:
		list.add_child(_award_card(award))

	list.add_child(UI.label("DÉTAIL PAR JOUEUR", 26, UI.MUTED))
	var order: Array[int] = []
	for i in s.player_count():
		order.append(i)
	order.sort_custom(func(a: int, b: int) -> bool: return s.stats[a].sips > s.stats[b].sips)
	var max_sips := 1
	for st in s.stats:
		max_sips = maxi(max_sips, st.sips)
	for i in order:
		list.add_child(_player_row(s.players[i], s.stats[i], max_sips))

	if final:
		var again := UI.button("REJOUER", "primary", 52, 116)
		again.pressed.connect(func() -> void: Game.restart_same_players())
		content.add_child(again)
		var home := UI.button("ACCUEIL", "ghost", 38, 88)
		home.pressed.connect(func() -> void: Game.go_home())
		content.add_child(home)
	else:
		var resume := UI.button("REPRENDRE LA PARTIE", "primary", 46, 116)
		resume.pressed.connect(func() -> void: _resume())
		content.add_child(resume)


func _award_card(award: Dictionary) -> Control:
	var card := UI.panel(Color(0, 0, 0, 0.32), 28, UI.AMBER_DARK, 3, 18)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	card.add_child(row)

	var badge := UI.panel(UI.AMBER, 40, Color.TRANSPARENT, 0, 0)
	badge.custom_minimum_size = Vector2(80, 80)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var icon := IconView.new(AWARD_ICONS.get(award["id"], "crown"), 56.0, UI.WOOD_DARKEST)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	badge.add_child(icon)
	row.add_child(badge)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 0)
	row.add_child(col)
	col.add_child(UI.label(str(award["title"]).to_upper(), 24, UI.MUTED, false, HORIZONTAL_ALIGNMENT_LEFT))
	var names := Fr.join_names(award["players"])
	var name_label := UI.label(names, 44, UI.FOAM, true, HORIZONTAL_ALIGNMENT_LEFT)
	col.add_child(name_label)
	col.add_child(UI.label(str(award["detail"]), 28, UI.AMBER_LIGHT, false, HORIZONTAL_ALIGNMENT_LEFT))
	return card


func _player_row(player_name: String, st: PlayerStats, max_sips: int) -> Control:
	var card := UI.panel(Color(0, 0, 0, 0.22), 24, Color.TRANSPARENT, 0, 16)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	card.add_child(col)

	var head := HBoxContainer.new()
	col.add_child(head)
	head.add_child(UI.label(player_name, 40, UI.FOAM, true, HORIZONTAL_ALIGNMENT_LEFT))
	var sips_label := UI.label(Fr.sips(st.sips), 36, UI.AMBER, true, HORIZONTAL_ALIGNMENT_RIGHT)
	head.add_child(sips_label)

	# Barre de gorgées
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(0, 18)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ratio := float(st.sips) / float(max_sips)
	bar.draw.connect(func() -> void:
		bar.draw_rect(Rect2(Vector2.ZERO, bar.size), Color(0, 0, 0, 0.35))
		if ratio > 0.0:
			bar.draw_rect(Rect2(Vector2.ZERO, Vector2(bar.size.x * ratio, bar.size.y)), UI.AMBER))
	col.add_child(bar)

	var detail := "Bluffs réussis : %d/%d · Accusations justes : %d/%d" % [
		st.bluffs_succeeded, st.bluffs, st.accusations_correct, st.accusations]
	col.add_child(UI.label(detail, 26, UI.MUTED, false, HORIZONTAL_ALIGNMENT_LEFT))
	return card


func _resume() -> void:
	var back: Dictionary = args.get("back", {})
	if back.has("screen"):
		Game.go(str(back["screen"]), back.get("args", {}))
	else:
		Game.go("pass", { "kind": "roll" })


func on_back() -> void:
	if args.get("final", true):
		Game.go_home()
	else:
		_resume()
