extends Node
## Test d'interface : un robot joue au jeu en appuyant sur les VRAIS boutons des écrans.
##
##   godot --headless --path . res://tests/ui_flow_test.tscn
##
## 1) un scénario écrit à la main (avec vérifications précises) ;
## 2) des parties jouées au hasard (« monkey test ») pour traquer les plantages.
## Toute erreur de script s'affiche dans la sortie (cherchez « ERROR »).

var main: Node = null
var checks: int = 0
var failed: Array[String] = []
var visited := {}


func _ready() -> void:
	Engine.time_scale = 12.0
	# Le test ne doit dépendre d'aucun réglage sauvegardé lors d'une exécution précédente.
	Settings.sound_on = false
	Settings.age_accepted = false
	Settings.players.clear()
	Settings.soft_mode = false
	Settings.max_sips = Rules.DEFAULT_MAX_SIPS
	Settings.show_hint = true
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames(3)
	await _scripted_scenario()
	await _special_caisse_scenario()
	await _soft_mode_scenario()
	await _monkey(int(OS.get_environment("MONKEY_GAMES") if OS.has_environment("MONKEY_GAMES") else "40"))
	_report()


# ── Utilitaires ───────────────────────────────────────────────────────────────

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func check(cond: bool, message: String) -> void:
	checks += 1
	if not cond:
		failed.append(message)
		print("   ✗ " + message)


func screen_id() -> String:
	var s: Node = main.current_screen()
	return String(s.name) if s != null else ""


func screen() -> Node:
	return main.current_screen()


func find_buttons(root: Node, result: Array[Button]) -> void:
	for c in root.get_children():
		if c is Button:
			result.append(c)
		find_buttons(c, result)


## Appuie (en émettant « pressed ») sur le premier bouton actif dont le texte commence par `prefix`.
func press(prefix: String) -> bool:
	var buttons: Array[Button] = []
	find_buttons(screen(), buttons)
	for b in buttons:
		if b.text.begins_with(prefix) and not b.disabled and b.is_visible_in_tree():
			b.pressed.emit()
			await _frames(2)
			return true
	return false


func press_checked(prefix: String) -> void:
	var ok := await press(prefix)
	check(ok, "bouton « %s » introuvable sur l'écran « %s »" % [prefix, screen_id()])


func expect_screen(id: String) -> void:
	check(screen_id() == id, "écran attendu « %s », obtenu « %s »" % [id, screen_id()])


func reveal_dice_on_dice_screen() -> void:
	var pad := _find_pad(screen())
	check(pad != null, "sous-bock introuvable")
	if pad == null:
		return
	var next_btn := _find_button_starting(screen(), "J'AI VU")
	check(next_btn != null and next_btn.disabled, "ANNONCER doit être bloqué tant qu'on n'a pas vu les dés")
	pad._press()
	await _frames(2)
	check(pad.holding, "les dés sont visibles pendant qu'on appuie")
	check(pad._die_a.visible and pad._die_b.visible, "dés dessinés pendant l'appui")
	pad._release()
	await _frames(2)
	check(not pad.holding, "les dés se cachent dès qu'on lâche")
	check(not pad._die_a.visible and not pad._die_b.visible, "dés cachés après l'appui")
	check(next_btn != null and not next_btn.disabled, "ANNONCER débloqué après avoir vu les dés")


func _find_pad(root: Node) -> HoldPad:
	for c in root.get_children():
		if c is HoldPad:
			return c
		var found := _find_pad(c)
		if found != null:
			return found
	return null


func _find_button_starting(root: Node, prefix: String) -> Button:
	var buttons: Array[Button] = []
	find_buttons(root, buttons)
	for b in buttons:
		if b.text.begins_with(prefix):
			return b
	return null


func skip_reveal() -> void:
	var s := screen()
	if s.has_method("_finish"):
		s._finish()
	await _frames(2)


func pick_tile(value: int) -> void:
	var s := screen()
	var tile: Button = s._tiles.get(value)
	check(tile != null, "la tuile %d doit être proposée" % value)
	if tile != null:
		tile.pressed.emit()
		await _frames(1)


func start_game(names: Array[String]) -> void:
	Settings.players.clear()
	for n in names:
		Settings.players.append(n)
	Game.go("players")
	await _frames(3)
	await press_checked("C'EST PARTI")
	await _frames(3)


# ── 1) Scénario écrit à la main ───────────────────────────────────────────────

func _scripted_scenario() -> void:
	print("• Scénario principal")
	expect_screen("home")
	check(screen().get_node_or_null("WarningDialog") == null, "pas de nom attendu pour le dialogue")
	var has_warning := false
	for c in screen().get_children():
		if c is WarningDialog:
			has_warning = true
	check(has_warning, "l'avertissement 18+ s'affiche au démarrage")
	await press_checked("J'AI L'ÂGE")
	await _frames(2)
	check(Settings.age_accepted, "avertissement accepté")

	await press_checked("RÈGLES")
	expect_screen("rules")
	await press_checked("COMPRIS")
	expect_screen("home")
	await press_checked("RÉGLAGES")
	expect_screen("settings")
	var before := Settings.max_sips
	var buttons: Array[Button] = []
	find_buttons(screen(), buttons)
	check(buttons.size() > 5, "des boutons de réglages existent")
	await press_checked("OK")
	expect_screen("home")
	check(Settings.max_sips == before, "limite inchangée")

	await press_checked("JOUER")
	expect_screen("players")
	# Ajouter un joueur, saisir des noms, démarrer.
	await press_checked("+ AJOUTER")
	var edits: Array[Node] = screen().find_children("*", "LineEdit", true, false)
	check(edits.size() == 4, "4 champs de noms après l'ajout (obtenu %d)" % edits.size())
	var names := ["Alice", "Bob", "Chloé", "Dan"]
	for i in edits.size():
		(edits[i] as LineEdit).text = names[i]
		(edits[i] as LineEdit).text_changed.emit(names[i])
	await press_checked("C'EST PARTI")

	expect_screen("pass")
	var s: MatchState = Game.session
	check(s != null and s.player_count() == 4, "4 joueurs dans la partie")
	var expected_names: Array[String] = ["Alice", "Bob", "Chloé", "Dan"]
	check(s.players == expected_names, "noms et ordre conservés")
	await press_checked("C'EST MOI")
	expect_screen("dice")
	await reveal_dice_on_dice_screen()
	s.set_dice(Vector2i(6, 4))   # Alice a vraiment 64
	await press_checked("J'AI VU")
	expect_screen("announce")
	check(not screen()._tiles.is_empty(), "la grille propose des résultats")
	check(screen()._tiles.has(31) and screen()._tiles.has(21), "tout est permis pour la première annonce")
	var confirm := _find_button_starting(screen(), "CHOISIS")
	check(confirm != null and confirm.disabled, "bouton de confirmation bloqué sans choix")
	await pick_tile(54)           # Alice annonce 54 (vrai : 64 > 54)
	await press_checked("ANNONCER 54")
	expect_screen("pass")
	check(s.phase == MatchState.Phase.DECIDING and s.current == 1, "Bob doit décider")
	await press_checked("C'EST MOI")
	expect_screen("decide")
	await press_checked("JE TE CROIS")
	expect_screen("dice")
	check(s.pot == 2, "la mise monte à 2 (obtenu %d)" % s.pot)
	await reveal_dice_on_dice_screen()
	s.set_dice(Vector2i(3, 1))   # Bob a 31 : il va bluffer
	await press_checked("J'AI VU")
	expect_screen("announce")
	check(not screen()._tiles.has(54) and not screen()._tiles.has(31) and screen()._tiles.has(61),
		"seules les annonces plus fortes que 54 sont offertes")
	await pick_tile(61)
	await press_checked("ANNONCER 61")
	expect_screen("pass")
	await press_checked("C'EST MOI")
	expect_screen("decide")
	await press_checked("MENTEUR")
	expect_screen("reveal")
	var v := s.last_verdict
	check(v.was_bluff and v.loser == 1 and v.sips == 2, "Bob a bluffé : il boit 2 gorgées")
	await skip_reveal()
	check(screen()._next_button != null and not screen()._next_button.disabled, "bouton « manche suivante » actif")
	await press_checked("MANCHE SUIVANTE")
	expect_screen("pass")
	check(s.current == 1 and s.pot == 1 and not s.has_announcement(), "Bob commence la manche 2, mise remise à 1")

	# Pause → stats → reprendre
	await press("")  # (rien : on ouvre le menu directement)
	screen().open_pause()
	await _frames(2)
	await press_checked("STATS DE LA PARTIE")
	expect_screen("stats")
	await press_checked("REPRENDRE")
	expect_screen("pass")
	# Pause → terminer → stats finales
	screen().open_pause()
	await _frames(2)
	await press_checked("TERMINER LA PARTIE")
	await _frames(2)
	await press_checked("OUI, VOIR")
	expect_screen("stats")
	await press_checked("ACCUEIL")
	expect_screen("home")
	check(Game.session == null, "la partie est effacée à l'accueil")


# ── 2) La règle spéciale LA CAISSE ────────────────────────────────────────────

func _special_caisse_scenario() -> void:
	print("• Règle spéciale LA CAISSE")
	await start_game(["A", "B", "C"])
	var s: MatchState = Game.session
	await press_checked("C'EST MOI")
	await reveal_dice_on_dice_screen()
	s.set_dice(Vector2i(2, 1))
	await press_checked("J'AI VU")
	await pick_tile(Dice.CAISSE)
	await press_checked("ANNONCER LA CAISSE")
	await press_checked("C'EST MOI")
	expect_screen("decide")
	check(s.must_believe_or_accuse(), "après LA CAISSE : croire ou accuser seulement")
	check(_find_button_starting(screen(), "JE TE CROIS") != null, "bouton croire présent")
	await press_checked("JE TE CROIS")
	expect_screen("reveal")
	check(s.last_verdict.kind == Verdict.Kind.CAISSE_BELIEVED and s.last_verdict.loser == 1, "B boit la mise")
	await skip_reveal()
	await press_checked("MANCHE SUIVANTE")
	check(s.current == 1 and s.pot == 1, "B (perdant) commence, mise remise à 1")

	# Accuser LA CAISSE : mise doublée.
	await press_checked("C'EST MOI")
	await reveal_dice_on_dice_screen()
	s.set_dice(Vector2i(5, 5))
	await press_checked("J'AI VU")
	await pick_tile(Dice.CAISSE)
	await press_checked("ANNONCER LA CAISSE")
	await press_checked("C'EST MOI")
	await press_checked("MENTEUR")
	expect_screen("reveal")
	check(s.last_verdict.doubled and s.last_verdict.sips == 2 and s.last_verdict.was_bluff, "fausse CAISSE accusée : 2 gorgées pour le menteur")
	await skip_reveal()
	await press_checked("TERMINER LA PARTIE")
	expect_screen("stats")
	Game.go_home()
	await _frames(2)


# ── 3) Mode Soft ──────────────────────────────────────────────────────────────

func _soft_mode_scenario() -> void:
	print("• Mode Soft")
	Settings.soft_mode = true
	Settings.soft_kind = Challenges.KIND_CHALLENGE
	await start_game(["A", "B"])
	var s: MatchState = Game.session
	await press_checked("C'EST MOI")
	await reveal_dice_on_dice_screen()
	s.set_dice(Vector2i(3, 1))
	await press_checked("J'AI VU")
	await pick_tile(65)
	await press_checked("ANNONCER 65")
	await press_checked("C'EST MOI")
	await press_checked("MENTEUR")
	expect_screen("reveal")
	check(screen()._penalty["type"] == "challenge", "défi proposé en mode Soft")
	check(screen()._challenge.visible and not screen()._amount_row.visible, "le défi remplace le nombre de gorgées")
	await skip_reveal()
	Settings.soft_kind = Challenges.KIND_WATER
	Game.go("reveal", { "instant": true })
	await _frames(2)
	check(screen()._penalty["type"] == "water" and screen()._unit.text.contains("EAU"), "gorgées d'eau en mode Soft")
	Settings.soft_mode = false
	Game.go_home()
	await _frames(2)


# ── 4) Test « singe » : des parties jouées au hasard ──────────────────────────

func _monkey(games: int) -> void:
	print("• Test aléatoire (%d parties)" % games)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	for g in games:
		var count := rng.randi_range(2, 10)
		var names: Array[String] = []
		for i in count:
			names.append("J%d" % (i + 1))
		await start_game(names)
		var steps := 0
		while Game.session != null and steps < 140:
			steps += 1
			var id := screen_id()
			visited[id] = true
			match id:
				"pass":
					await press_checked("C'EST MOI")
				"dice":
					var pad := _find_pad(screen())
					if rng.randf() < 0.9:
						pad._press()
						await _frames(1)
						pad._release()
					await _frames(1)
					await press("J'AI VU")
				"announce":
					var keys: Array = screen()._tiles.keys()
					check(not keys.is_empty(), "la grille n'est jamais vide")
					if keys.is_empty():
						break
					await pick_tile(keys[rng.randi_range(0, keys.size() - 1)])
					await press("ANNONCER")
				"decide":
					if rng.randf() < 0.45:
						await press_checked("MENTEUR")
					else:
						await press_checked("JE TE CROIS")
				"reveal":
					if rng.randf() < 0.3:
						await _frames(8)
					await skip_reveal()
					if rng.randf() < 0.04:
						await press_checked("TERMINER LA PARTIE")
					else:
						await press_checked("MANCHE SUIVANTE")
				"stats":
					visited["stats"] = true
					if screen().args.get("final", true):
						Game.go_home()
						await _frames(2)
					else:
						await press_checked("REPRENDRE")
				_:
					Game.go_home()
					await _frames(2)
			if rng.randf() < 0.03 and screen_id() in ["pass", "reveal"]:
				screen().open_pause()
				await _frames(1)
				await press("STATS")
				if screen_id() == "stats":
					await press("REPRENDRE")
		if Game.session != null:
			Game.go_home()
			await _frames(2)


func _report() -> void:
	print("")
	print("Écrans visités par le robot : %s" % ", ".join(PackedStringArray(visited.keys())))
	if failed.is_empty():
		print("✅ TEST D'INTERFACE OK : %d vérifications." % checks)
		get_tree().quit(0)
	else:
		print("❌ %d ÉCHEC(S) sur %d vérifications." % [failed.size(), checks])
		get_tree().quit(1)
