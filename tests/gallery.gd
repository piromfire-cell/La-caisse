extends Node
## Galerie de captures d'écran : met le jeu dans des états précis et sauvegarde des PNG.
## (Outil de vérification visuelle, pas un test automatique.)
##   GALLERY_DIR=/chemin xvfb-run -a godot --path . res://tests/gallery.tscn --resolution 540x960

var out_dir: String = ""
var main: Node = null


func _ready() -> void:
	out_dir = OS.get_environment("GALLERY_DIR") if OS.has_environment("GALLERY_DIR") else "/tmp/gallery"
	DirAccess.make_dir_recursive_absolute(out_dir)
	Settings.sound_on = false
	Settings.age_accepted = true
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _wait(0.6)
	await _gallery()
	get_tree().quit(0)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func snap(name: String, delay: float = 0.7) -> void:
	await _wait(delay)
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [out_dir, name])
	print("saved ", name, " ", img.get_size())


func new_game(names: Array, max_sips: int = 5) -> MatchState:
	Settings.max_sips = max_sips
	Game.new_game(names)
	await _wait(0.5)
	return Game.session


func _gallery() -> void:
	# Stats avec des données : plusieurs manches jouées
	var s := await new_game(["Alice", "Bob", "Chloé", "Dan"])
	var plan := [
		[Vector2i(5, 2), 64, true],    # Alice bluffe, Bob accuse -> Alice boit
		[Vector2i(6, 5), 65, true],    # Alice vrai, Bob accuse à tort -> Bob boit
		[Vector2i(3, 1), 51, false],   # Bob bluffe, Chloé le croit
	]
	for step in plan:
		s.set_dice(step[0])
		s.announce(step[1])
		if step[2]:
			s.accuse()
			s.next_round()
		else:
			s.believe()
	s.set_dice(Vector2i(2, 1))
	s.announce(Dice.CAISSE)
	s.accuse()
	Game.go("stats", { "final": true })
	await snap("g_stats_final")

	# Règle spéciale : on croit LA CAISSE
	s = await new_game(["Alice", "Bob", "Chloé"])
	s.set_dice(Vector2i(2, 1))
	s.announce(Dice.CAISSE)
	Game.go("decide")
	await snap("g_decide_caisse")
	Game.believe()
	await snap("g_reveal_caisse_a", 1.8)
	await snap("g_reveal_caisse_b", 5.0)

	# Fausse CAISSE accusée avec une grosse mise (plafond 5) -> mise doublée
	s = await new_game(["Alice", "Bob", "Chloé"], 5)
	s.set_dice(Vector2i(6, 5))
	s.announce(65)
	s.believe()
	s.set_dice(Vector2i(4, 2))
	s.announce(Dice.CAISSE)
	Game.accuse()
	await snap("g_reveal_caisse_doubled", 7.5)

	# Annonce après une mousse : seulement les mousses plus fortes + LA CAISSE
	s = await new_game(["Alice", "Bob", "Chloé"])
	s.set_dice(Vector2i(4, 4))
	s.announce(44)
	Game.believe()
	await _wait(0.6)
	Game.go("dice")
	await _wait(0.5)
	s.set_dice(Vector2i(3, 1))
	Game.go("announce")
	await snap("g_announce_after_44")

	# Après 66 : un seul choix, présélectionné
	s = await new_game(["Alice", "Bob", "Chloé"])
	s.set_dice(Vector2i(6, 6))
	s.announce(66)
	s.believe()
	Game.go("announce")
	await snap("g_announce_after_66")

	# Mode Soft : défi, puis eau
	Settings.soft_mode = true
	Settings.soft_kind = Challenges.KIND_CHALLENGE
	s = await new_game(["Alice", "Bob"], 5)
	s.set_dice(Vector2i(3, 1))
	s.announce(65)
	s.believe()
	s.set_dice(Vector2i(3, 1))
	s.announce(66)
	s.believe()
	s.set_dice(Vector2i(3, 1))
	s.announce(Dice.CAISSE)
	Game.accuse()
	await snap("g_reveal_soft_challenge", 7.5)
	Settings.soft_kind = Challenges.KIND_WATER
	Game.go("reveal", { "instant": true })
	await snap("g_reveal_soft_water", 0.8)
	Game.go("settings")
	await snap("g_settings_soft")
	Settings.soft_mode = false

	# 10 joueurs avec noms longs
	Settings.players = ["Alexandre-Mathieu", "Bob", "Chloé", "Dan", "Émilie", "Félix", "Gabrielle", "Hugo", "Isabelle", "Jean-Philippe"]
	Game.go("players")
	await snap("g_players_10")
	s = await new_game(Settings.players.duplicate())
	await snap("g_pass_long_name")

	# Avertissement 18+
	Settings.age_accepted = false
	Game.go("home")
	await snap("g_home_warning")
	Settings.age_accepted = true
	Game.go("home")
	await snap("g_home")
	get_tree().quit(0)
