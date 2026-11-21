extends TestCase
## Tests de la mise, du plafond de gorgées et du verdict (bluff ou pas).


func test_mise_de_depart() -> void:
	assert_eq(Rules.START_POT, 1, "la mise de départ est de 1 gorgée")


func test_chaque_je_te_crois_ajoute_une_gorgee() -> void:
	assert_eq(Rules.pot_after_belief(1, 5), 2, "1 -> 2")
	assert_eq(Rules.pot_after_belief(2, 5), 3, "2 -> 3")
	assert_eq(Rules.pot_after_belief(4, 5), 5, "4 -> 5")


func test_la_mise_ne_depasse_jamais_la_limite() -> void:
	assert_eq(Rules.pot_after_belief(5, 5), 5, "plafonnée à 5")
	assert_eq(Rules.pot_after_belief(3, 3), 3, "plafonnée à 3")
	assert_eq(Rules.pot_after_belief(1, 1), 1, "limite de 1 : la mise reste à 1")


func test_penalite_normale_egale_la_mise() -> void:
	assert_eq(Rules.penalty(1, 53, 5), 1, "mise 1")
	assert_eq(Rules.penalty(3, 44, 5), 3, "mise 3 sur une mousse")
	assert_eq(Rules.penalty(2, 66, 5), 2, "mise 2 sur 66")


func test_la_caisse_double_la_mise() -> void:
	assert_eq(Rules.penalty(1, Dice.CAISSE, 5), 2, "1 x 2")
	assert_eq(Rules.penalty(2, Dice.CAISSE, 5), 4, "2 x 2")


func test_la_penalite_est_plafonnee_meme_apres_doublage() -> void:
	assert_eq(Rules.penalty(3, Dice.CAISSE, 5), 5, "3 x 2 = 6 -> plafonné à 5")
	assert_eq(Rules.penalty(5, Dice.CAISSE, 5), 5, "5 x 2 = 10 -> plafonné à 5")
	assert_eq(Rules.penalty(1, Dice.CAISSE, 1), 1, "limite 1 : toujours 1")
	assert_eq(Rules.penalty(9, 53, 15), 9, "limite haute 15 : pas de plafonnement à 9")


func test_croire_la_caisse_fait_boire_la_mise_sans_doublage() -> void:
	assert_eq(Rules.believe_caisse_penalty(1, 5), 1, "mise 1")
	assert_eq(Rules.believe_caisse_penalty(3, 5), 3, "mise 3")
	assert_eq(Rules.believe_caisse_penalty(9, 5), 5, "plafonné")


func test_bluff_si_les_vrais_des_sont_plus_faibles() -> void:
	assert_true(Rules.is_bluff(64, 52), "annonce 64 avec 52 = bluff")
	assert_true(Rules.is_bluff(Dice.CAISSE, 66), "annonce LA CAISSE avec 66 = bluff")
	assert_true(Rules.is_bluff(11, 65), "annonce 11 avec 65 = bluff (la mousse est plus forte)")


func test_pas_bluff_si_des_egaux_ou_plus_forts() -> void:
	assert_false(Rules.is_bluff(64, 64), "dés égaux = vrai")
	assert_false(Rules.is_bluff(52, 64), "dés plus forts = vrai")
	assert_false(Rules.is_bluff(65, 11), "une mousse bat 65 : pas un bluff")
	assert_false(Rules.is_bluff(Dice.CAISSE, Dice.CAISSE), "vraie CAISSE")
	assert_false(Rules.is_bluff(31, Dice.CAISSE), "annoncer moins que sa CAISSE n'est pas un bluff")


func test_seule_la_caisse_est_imbattable() -> void:
	assert_true(Rules.is_unbeatable(Dice.CAISSE), "LA CAISSE")
	for v in Dice.RANKED:
		if v != Dice.CAISSE:
			assert_false(Rules.is_unbeatable(v), "%d peut être battu" % v)
