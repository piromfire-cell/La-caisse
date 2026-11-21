extends TestCase
## Tests du classement des dés et des annonces valides.


func test_lecture_du_plus_gros_chiffre_en_premier() -> void:
	assert_eq(Dice.value_from_dice(3, 5), 53, "3 et 5 -> 53")
	assert_eq(Dice.value_from_dice(5, 3), 53, "5 et 3 -> 53 (ordre indifférent)")
	assert_eq(Dice.value_from_dice(1, 2), 21, "1 et 2 -> 21 (LA CAISSE)")
	assert_eq(Dice.value_from_dice(2, 1), 21, "2 et 1 -> 21")
	assert_eq(Dice.value_from_dice(4, 4), 44, "double 4")
	assert_eq(Dice.value_from_dice(6, 1), 61, "6 et 1 -> 61")
	assert_eq(Dice.value_from_dice(1, 1), 11, "double 1")


func test_il_y_a_21_resultats_distincts() -> void:
	assert_eq(Dice.RANKED.size(), 21, "21 résultats possibles")
	var seen := {}
	for v in Dice.RANKED:
		seen[v] = true
	assert_eq(seen.size(), 21, "aucun doublon dans le classement")


func test_chaque_jet_possible_donne_un_resultat_valide() -> void:
	for a in range(1, 7):
		for b in range(1, 7):
			assert_true(Dice.is_valid_value(Dice.value_from_dice(a, b)), "jet %d-%d valide" % [a, b])


func test_distribution_des_36_combinaisons() -> void:
	var counts := {}
	for a in range(1, 7):
		for b in range(1, 7):
			var v := Dice.value_from_dice(a, b)
			counts[v] = counts.get(v, 0) + 1
	var total := 0
	for v in Dice.RANKED:
		assert_eq(counts.get(v, 0), Dice.combos(v), "combinaisons pour %d" % v)
		total += counts.get(v, 0)
	assert_eq(total, 36, "36 combinaisons au total")
	assert_eq(Dice.combos(99), 0, "résultat invalide -> 0 combinaison")


func test_classement_complet_du_plus_faible_au_plus_fort() -> void:
	var expected: Array[int] = [31, 32, 41, 42, 43, 51, 52, 53, 54, 61, 62, 63, 64, 65, 11, 22, 33, 44, 55, 66, 21]
	assert_eq(Dice.RANKED, expected, "ordre exact du classement")


func test_les_normaux_sont_plus_faibles_que_les_mousses() -> void:
	for n in [31, 42, 54, 65]:
		for m in [11, 22, 33, 44, 55, 66]:
			assert_true(Dice.beats(m, n), "mousse %d bat %d" % [m, n])
			assert_false(Dice.beats(n, m), "%d ne bat pas la mousse %d" % [n, m])


func test_les_mousses_sont_ordonnees() -> void:
	assert_true(Dice.beats(22, 11), "22 > 11")
	assert_true(Dice.beats(66, 55), "66 > 55")
	assert_false(Dice.beats(11, 22), "11 < 22")


func test_la_caisse_bat_tout() -> void:
	for v in Dice.RANKED:
		if v != Dice.CAISSE:
			assert_true(Dice.beats(Dice.CAISSE, v), "LA CAISSE bat %d" % v)
			assert_false(Dice.beats(v, Dice.CAISSE), "%d ne bat pas LA CAISSE" % v)


func test_egalite_ne_bat_pas() -> void:
	for v in Dice.RANKED:
		assert_false(Dice.beats(v, v), "%d ne bat pas lui-même" % v)


func test_les_normaux_sont_ordonnes_par_gros_chiffre_puis_petit() -> void:
	assert_true(Dice.beats(32, 31), "32 > 31")
	assert_true(Dice.beats(41, 32), "41 > 32")
	assert_true(Dice.beats(43, 42), "43 > 42")
	assert_true(Dice.beats(51, 43), "51 > 43")
	assert_true(Dice.beats(65, 64), "65 > 64")
	assert_true(Dice.beats(61, 54), "61 > 54")


func test_beats_avec_aucune_annonce_et_valeurs_invalides() -> void:
	assert_true(Dice.beats(31, Dice.NONE), "tout valide bat « aucune annonce »")
	assert_true(Dice.beats(Dice.CAISSE, Dice.NONE), "même LA CAISSE")
	assert_false(Dice.beats(99, Dice.NONE), "une valeur invalide ne bat rien")
	assert_false(Dice.beats(12, 31), "12 n'existe pas (le plus gros chiffre se lit en premier)")
	assert_eq(Dice.rank(99), -1, "rang invalide = -1")


func test_annonces_valides_sans_annonce_precedente() -> void:
	var all := Dice.valid_announcements(Dice.NONE)
	assert_eq(all.size(), 21, "tout est permis")
	assert_eq(all[0], 31, "le plus faible en premier")
	assert_eq(all[20], 21, "LA CAISSE en dernier")


func test_annonces_valides_apres_un_resultat_normal() -> void:
	var after_53 := Dice.valid_announcements(53)
	assert_false(after_53.has(53), "pas d'égalité")
	assert_false(after_53.has(52), "pas plus faible")
	assert_false(after_53.has(31), "pas plus faible")
	assert_eq(after_53[0], 54, "le premier choix est 54")
	assert_true(after_53.has(65) and after_53.has(11) and after_53.has(21), "65, mousses et caisse permis")
	assert_eq(after_53.size(), 21 - (Dice.rank(53) + 1), "taille attendue")


func test_annonces_valides_apres_65_et_66_et_la_caisse() -> void:
	var after_65 := Dice.valid_announcements(65)
	assert_eq(after_65.size(), 7, "6 mousses + LA CAISSE")
	assert_eq(after_65[0], 11, "la plus petite mousse")
	assert_eq(Dice.valid_announcements(66), [21] as Array[int], "après 66 : seulement LA CAISSE")
	assert_true(Dice.valid_announcements(Dice.CAISSE).is_empty(), "après LA CAISSE : plus rien")


func test_chaque_annonce_proposee_bat_la_precedente() -> void:
	for prev in Dice.RANKED:
		for v in Dice.valid_announcements(prev):
			assert_true(Dice.beats(v, prev), "%d doit battre %d" % [v, prev])
		# Et tout ce qui n'est pas proposé ne la bat pas.
		var offered := Dice.valid_announcements(prev)
		for v in Dice.RANKED:
			if not offered.has(v):
				assert_false(Dice.beats(v, prev), "%d ne doit pas battre %d" % [v, prev])


func test_categories() -> void:
	assert_eq(Dice.category(53), Dice.Category.NORMAL, "53 normal")
	assert_eq(Dice.category(31), Dice.Category.NORMAL, "31 normal")
	assert_eq(Dice.category(44), Dice.Category.MOUSSE, "44 mousse")
	assert_eq(Dice.category(11), Dice.Category.MOUSSE, "11 mousse")
	assert_eq(Dice.category(21), Dice.Category.CAISSE, "21 caisse")
	assert_true(Dice.is_mousse(66), "66 est une mousse")
	assert_false(Dice.is_mousse(21), "21 n'est pas une mousse")
	assert_false(Dice.is_mousse(53), "53 n'est pas une mousse")
	assert_true(Dice.is_caisse(21), "21 est LA CAISSE")


func test_des_individuels_et_libelles() -> void:
	assert_eq(Dice.high_die(53), 5, "gros dé")
	assert_eq(Dice.low_die(53), 3, "petit dé")
	assert_eq(Dice.high_die(21), 2, "gros dé de 21")
	assert_eq(Dice.low_die(21), 1, "petit dé de 21")
	assert_eq(Dice.long_label(53), "53", "libellé normal")
	assert_eq(Dice.long_label(44), "Mousse de 4 (44)", "libellé mousse")
	assert_eq(Dice.long_label(21), "LA CAISSE (21)", "libellé caisse")


func test_lancer_donne_toujours_deux_des_entre_1_et_6() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var seen_caisse := false
	for i in 2000:
		var r := Dice.roll(rng)
		assert_true(r.x >= 1 and r.x <= 6 and r.y >= 1 and r.y <= 6, "dés dans 1..6")
		if Dice.value_from_dice(r.x, r.y) == Dice.CAISSE:
			seen_caisse = true
	assert_true(seen_caisse, "LA CAISSE finit par sortir (2/36 des jets)")
