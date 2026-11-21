extends TestCase
## Tests des statistiques de fin de partie et des « prix » (menteur, détecteur…).


func _new_match(count: int = 3) -> MatchState:
	var names: Array = []
	for i in count:
		names.append("J%d" % (i + 1))
	return MatchState.new(names, 5, 7)


## Joue une manche : `dice` = vrais dés de l'annonceur, `announce` = annonce, puis réponse.
func _play(m: MatchState, dice: Vector2i, announce: int, accuse: bool) -> Verdict:
	m.set_dice(dice)
	m.announce(announce)
	var v: Verdict = m.accuse() if accuse else m.believe()
	if v != null:
		m.next_round()
	return v


func test_gorgees_bues_par_joueur() -> void:
	var m := _new_match()
	# Manche 1 : J1 bluffe (64 avec 52), J2 accuse -> J1 boit 1.
	_play(m, Vector2i(5, 2), 64, true)
	assert_eq(m.stats[0].sips, 1, "J1 boit 1")
	# Manche 2 (J1 commence) : J1 dit vrai (65), J2 accuse à tort -> J2 boit 1.
	_play(m, Vector2i(6, 5), 65, true)
	assert_eq(m.stats[1].sips, 1, "J2 boit 1")
	assert_eq(m.total_sips(), 2, "2 gorgées au total")
	assert_eq(m.stats[0].rounds_lost, 1, "J1 a perdu 1 manche")


func test_bluffs_comptes_et_bluffs_reussis() -> void:
	var m := _new_match()
	m.set_dice(Vector2i(3, 1))
	m.announce(65)              # J1 bluffe
	m.believe()                 # J2 le croit -> bluff réussi
	assert_eq(m.stats[0].bluffs, 1, "1 bluff tenté")
	assert_eq(m.stats[0].bluffs_succeeded, 1, "1 bluff réussi")
	assert_eq(m.stats[1].believes, 1, "J2 a cru une fois")
	m.set_dice(Vector2i(4, 2))
	m.announce(66)              # J2 bluffe aussi
	var v := m.accuse()         # J3 le démasque
	assert_eq(m.stats[1].bluffs, 1, "1 bluff pour J2")
	assert_eq(m.stats[1].bluffs_succeeded, 0, "pas réussi")
	assert_eq(m.stats[1].bluffs_caught, 1, "démasqué")
	assert_true(v.was_bluff, "verdict : bluff")


func test_une_annonce_honnete_n_est_pas_un_bluff() -> void:
	var m := _new_match()
	m.set_dice(Vector2i(6, 5))
	m.announce(65)
	assert_eq(m.stats[0].bluffs, 0, "dire la vérité n'est pas bluffer")
	m.believe()
	assert_eq(m.stats[0].bluffs_succeeded, 0, "croire une vérité n'est pas un bluff réussi")


func test_accusations_et_precision() -> void:
	var m := _new_match()
	_play(m, Vector2i(5, 2), 64, true)     # J2 accuse juste
	assert_eq(m.stats[1].accusations, 1, "1 accusation")
	assert_eq(m.stats[1].accusations_correct, 1, "juste")
	_play(m, Vector2i(6, 5), 65, true)     # J2 accuse à tort (J1 commence la manche 2)
	assert_eq(m.stats[1].accusations, 2, "2 accusations")
	assert_eq(m.stats[1].accusations_correct, 1, "toujours 1 juste")


func test_prix_plus_gros_menteur_et_meilleur_detecteur() -> void:
	var m := _new_match()
	# J1 bluffe 2 fois, J2 accuse juste 2 fois.
	_play(m, Vector2i(3, 1), 54, true)     # J1 bluffe, J2 accuse -> J1 boit ; J1 commence
	_play(m, Vector2i(3, 1), 55, true)     # J1 bluffe encore, J2 accuse -> J1 boit
	var awards := m.awards()
	var by_id := {}
	for a in awards:
		by_id[a["id"]] = a
	assert_eq(by_id["liar"]["players"], ["J1"], "J1 = plus gros menteur")
	assert_eq(by_id["liar"]["detail"], "2 bluffs", "2 bluffs")
	assert_eq(by_id["detector"]["players"], ["J2"], "J2 = meilleur détecteur")
	assert_eq(by_id["detector"]["detail"], "2 sur 2 accusations", "2 sur 2")
	assert_eq(by_id["thirsty"]["players"], ["J1"], "J1 a le plus bu")
	assert_eq(by_id["thirsty"]["detail"], "2 gorgées", "2 gorgées")
	assert_false(by_id.has("bluffer"), "aucun bluff réussi -> pas de prix")


func test_prix_bluffs_reussis() -> void:
	var m := _new_match()
	m.set_dice(Vector2i(3, 1))
	m.announce(65)              # bluff
	m.believe()                 # cru
	var by_id := {}
	for a in m.awards():
		by_id[a["id"]] = a
	assert_true(by_id.has("bluffer"), "prix des bluffs réussis")
	assert_eq(by_id["bluffer"]["players"], ["J1"], "J1")
	assert_eq(by_id["bluffer"]["detail"], "1 sur 1 bluff", "1 sur 1")


func test_egalite_les_deux_joueurs_gagnent_le_prix() -> void:
	var m := _new_match(4)
	# J1 bluffe (manche 1), puis J2 (manche 2) : chacun 1 bluff, tous deux démasqués.
	_play(m, Vector2i(3, 1), 54, true)     # J1 bluffe, J2 accuse ; J1 boit et commence
	m.set_dice(Vector2i(3, 1))
	m.announce(54)                          # J1 dit 54 (vrai ? 31 < 54 -> bluff)
	m.believe()                             # J2 le croit : mise 2, J2 relance
	m.set_dice(Vector2i(3, 1))
	m.announce(55)                          # J2 bluffe
	m.accuse()                              # J3 accuse
	var by_id := {}
	for a in m.awards():
		by_id[a["id"]] = a
	# J1: 2 bluffs ; J2: 1 bluff -> J1 seul.
	assert_eq(by_id["liar"]["players"], ["J1"], "J1 a le plus de bluffs")
	# Égalité parfaite : on modifie directement les stats.
	m.stats[1].bluffs = 2
	var tie: Dictionary = {}
	for a in m.awards():
		if a["id"] == "liar":
			tie = a
	assert_eq(tie["players"], ["J1", "J2"], "égalité : les deux apparaissent")


func test_aucun_prix_sans_evenement() -> void:
	var m := _new_match()
	assert_true(m.awards().is_empty(), "partie vierge : aucun prix")


func test_precision_departage_les_detecteurs() -> void:
	var names := ["A", "B"]
	var stats: Array[PlayerStats] = [PlayerStats.new(), PlayerStats.new()]
	stats[0].accusations = 4
	stats[0].accusations_correct = 2     # 50 %
	stats[1].accusations = 2
	stats[1].accusations_correct = 2     # 100 % -> même nombre de bonnes accusations
	var detector := {}
	for a in Awards.compute(names, stats):
		if a["id"] == "detector":
			detector = a
	assert_eq(detector["players"], ["B"], "à égalité de bonnes accusations, la précision départage")


func test_total_des_gorgees_egal_la_somme_des_verdicts() -> void:
	var m := _new_match()
	var expected := 0
	expected += _play(m, Vector2i(5, 2), 64, true).sips
	expected += _play(m, Vector2i(6, 5), 65, true).sips
	m.set_dice(Vector2i(2, 1))
	m.announce(Dice.CAISSE)
	var v := m.believe()
	expected += v.sips
	assert_eq(m.total_sips(), expected, "somme des gorgées cohérente")
