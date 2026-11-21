extends TestCase
## Simulation : des milliers de parties jouées au hasard, avec vérification des invariants.
## Si une règle est cassée quelque part, cette suite la trouve presque à coup sûr.


func _random_game(seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var players := rng.randi_range(2, 10)
	var max_sips := rng.randi_range(1, 15)
	var names: Array = []
	for i in players:
		names.append("P%d" % i)
	var m := MatchState.new(names, max_sips, seed_value)

	var sum_of_verdict_sips := 0
	var rounds_finished := 0

	for step in 120:
		assert_true(m.pot >= 1 and m.pot <= max_sips, "mise dans [1, limite] (pot=%d, max=%d)" % [m.pot, max_sips])
		assert_true(m.current >= 0 and m.current < players, "joueur courant valide")

		match m.phase:
			MatchState.Phase.ANNOUNCING:
				var options := m.valid_announcements()
				assert_false(options.is_empty(), "un joueur doit toujours pouvoir annoncer quelque chose")
				if options.is_empty():
					return
				m.roll_dice()
				assert_true(m.has_rolled, "dés lancés")
				# Joue honnêtement 50 % du temps quand c'est possible.
				var choice: int = options[rng.randi_range(0, options.size() - 1)]
				if rng.randf() < 0.5:
					var honest: Array[int] = []
					for o in options:
						if Dice.rank(o) <= Dice.rank(m.real_value):
							honest.append(o)
					if not honest.is_empty():
						choice = honest[rng.randi_range(0, honest.size() - 1)]
				var before_announced := m.announced
				assert_true(m.announce(choice), "annonce proposée = annonce acceptée")
				assert_true(Dice.beats(m.announced, before_announced), "les annonces montent toujours")

			MatchState.Phase.DECIDING:
				if m.announced == Dice.CAISSE:
					assert_true(m.must_believe_or_accuse(), "après LA CAISSE : croire ou accuser seulement")
				else:
					assert_false(m.must_believe_or_accuse(), "sinon, on peut surenchérir")
				var verdict: Verdict
				if rng.randf() < 0.5:
					verdict = m.accuse()
					assert_not_null(verdict, "accuser rend un verdict")
					assert_eq(verdict.kind, Verdict.Kind.ACCUSATION, "type accusation")
					assert_eq(verdict.was_bluff, Dice.rank(verdict.announced) > Dice.rank(verdict.real_value), "bluff = annonce > dés")
					assert_eq(verdict.loser, verdict.announcer if verdict.was_bluff else verdict.accuser, "bon perdant")
					assert_eq(verdict.doubled, verdict.announced == Dice.CAISSE, "doublage seulement sur LA CAISSE")
				else:
					verdict = m.believe()
					if m.announced == Dice.CAISSE:
						assert_not_null(verdict, "croire LA CAISSE termine la manche")
						assert_eq(verdict.kind, Verdict.Kind.CAISSE_BELIEVED, "type caisse crue")
						assert_eq(verdict.loser, verdict.accuser, "le croyant boit")
					else:
						assert_null(verdict, "croire autre chose continue la manche")
				if verdict != null:
					assert_true(verdict.sips >= 1 and verdict.sips <= max_sips, "punition dans [1, limite]")
					assert_true(verdict.loser >= 0 and verdict.loser < players, "perdant valide")
					sum_of_verdict_sips += verdict.sips
					rounds_finished += 1

			MatchState.Phase.ROUND_OVER:
				var loser := m.last_verdict.loser
				assert_true(m.next_round(), "manche suivante possible")
				assert_eq(m.current, loser, "le perdant commence")
				assert_eq(m.pot, 1, "mise remise à 1")
				assert_eq(m.announced, Dice.NONE, "annonces effacées")

	# Cohérence finale des statistiques.
	assert_eq(m.total_sips(), sum_of_verdict_sips, "gorgées bues = somme des verdicts")
	var lost := 0
	for s in m.stats:
		assert_true(s.bluffs_succeeded + s.bluffs_caught <= s.bluffs, "bluffs réussis + démasqués <= bluffs")
		assert_true(s.accusations_correct <= s.accusations, "accusations justes <= accusations")
		assert_true(s.sips >= 0, "gorgées positives")
		lost += s.rounds_lost
	assert_eq(lost, rounds_finished, "manches perdues = manches terminées")


func test_3000_parties_aleatoires() -> void:
	for seed_value in 3000:
		_random_game(seed_value)
		if failures.size() > 20:
			break  # inutile d'inonder la sortie
