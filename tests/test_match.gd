extends TestCase
## Tests du déroulement complet d'une partie : tours, annonces, croire, accuser, mise, verdict.


func _new_match(count: int = 3, max_sips: int = 5) -> MatchState:
	var names: Array = []
	for i in count:
		names.append("J%d" % (i + 1))
	return MatchState.new(names, max_sips, 42)


func _roll(m: MatchState, a: int, b: int) -> void:
	m.set_dice(Vector2i(a, b))


func test_etat_initial() -> void:
	var m := _new_match()
	assert_eq(m.phase, MatchState.Phase.ANNOUNCING, "on commence par une annonce")
	assert_eq(m.current, 0, "le premier joueur commence")
	assert_eq(m.pot, 1, "mise de départ 1")
	assert_eq(m.announced, Dice.NONE, "aucune annonce")
	assert_eq(m.valid_announcements().size(), 21, "tout est permis pour la première annonce")
	assert_eq(m.round_number, 1, "manche 1")


func test_on_ne_peut_pas_annoncer_sans_avoir_lance() -> void:
	var m := _new_match()
	assert_false(m.announce(53), "pas de lancer = pas d'annonce")
	assert_eq(m.phase, MatchState.Phase.ANNOUNCING, "rien n'a changé")


func test_roll_dice_est_idempotent() -> void:
	var m := _new_match()
	var first := m.roll_dice()
	for i in 20:
		assert_eq(m.roll_dice(), first, "relancer l'écran ne change pas les dés")


func test_annonce_valide_passe_au_joueur_suivant() -> void:
	var m := _new_match()
	_roll(m, 5, 3)
	assert_true(m.announce(54), "annoncer plus fort que ses dés (bluff) est permis")
	assert_eq(m.phase, MatchState.Phase.DECIDING, "le suivant décide")
	assert_eq(m.current, 1, "au joueur 2")
	assert_eq(m.announced, 54, "annonce enregistrée")
	assert_eq(m.announcer, 0, "annonceur = joueur 1")
	assert_eq(m.pot, 1, "la mise n'a pas bougé")


func test_annonce_invalide_est_refusee() -> void:
	var m := _new_match()
	_roll(m, 6, 4)
	assert_true(m.announce(53), "première annonce libre")
	assert_true(m.believe() == null, "croire (cas normal) ne rend pas de verdict")
	_roll(m, 4, 1)
	assert_false(m.announce(53), "égalité refusée")
	assert_false(m.announce(41), "plus faible refusé")
	assert_false(m.announce(99), "valeur inexistante refusée")
	assert_false(m.announce(12), "12 n'existe pas")
	assert_eq(m.phase, MatchState.Phase.ANNOUNCING, "toujours en train d'annoncer")
	assert_true(m.announce(54), "54 est accepté")


func test_je_te_crois_augmente_la_mise_et_le_meme_joueur_relance() -> void:
	var m := _new_match()
	_roll(m, 5, 3)
	m.announce(53)
	assert_null(m.believe(), "pas de verdict")
	assert_eq(m.pot, 2, "mise 1 -> 2")
	assert_eq(m.phase, MatchState.Phase.ANNOUNCING, "il doit annoncer")
	assert_eq(m.current, 1, "c'est toujours le joueur 2")
	assert_false(m.has_rolled, "il doit relancer ses propres dés")
	assert_eq(m.valid_announcements()[0], 54, "il doit faire plus fort que 53")
	assert_false(m.valid_announcements().has(53), "pas d'égalité")


func test_accusation_d_un_bluff_fait_boire_le_menteur() -> void:
	var m := _new_match()
	_roll(m, 5, 2)          # vrais dés : 52
	m.announce(64)          # bluff
	var v := m.accuse()
	assert_not_null(v, "verdict rendu")
	assert_true(v.was_bluff, "c'était un bluff")
	assert_eq(v.loser, 0, "le menteur (J1) boit")
	assert_eq(v.accuser, 1, "J2 avait accusé")
	assert_eq(v.sips, 1, "mise de 1")
	assert_eq(v.real_value, 52, "dés révélés")
	assert_eq(v.winner(), 1, "J2 gagne")
	assert_eq(m.stats[0].sips, 1, "J1 a bu 1")
	assert_eq(m.stats[1].sips, 0, "J2 n'a rien bu")
	assert_eq(m.phase, MatchState.Phase.ROUND_OVER, "manche terminée")


func test_accusation_d_une_annonce_vraie_fait_boire_l_accusateur() -> void:
	var m := _new_match()
	_roll(m, 6, 4)
	m.announce(64)          # vrai
	var v := m.accuse()
	assert_false(v.was_bluff, "ce n'était pas un bluff")
	assert_eq(v.loser, 1, "l'accusateur boit")
	assert_eq(v.winner(), 0, "l'annonceur gagne")
	assert_eq(m.stats[1].sips, 1, "J2 a bu")


func test_des_egaux_a_l_annonce_donnent_raison_a_l_annonceur() -> void:
	var m := _new_match()
	_roll(m, 4, 3)
	m.announce(43)          # exactement ses dés
	var v := m.accuse()
	assert_false(v.was_bluff, "égalité = vrai")
	assert_eq(v.loser, 1, "l'accusateur boit")


func test_des_plus_forts_que_l_annonce_donnent_raison_a_l_annonceur() -> void:
	var m := _new_match()
	_roll(m, 6, 6)
	m.announce(31)          # modeste !
	var v := m.accuse()
	assert_false(v.was_bluff, "plus fort que l'annonce = pas un bluff")
	assert_eq(v.loser, 1, "l'accusateur boit")


func test_la_mise_accumulee_est_payee() -> void:
	var m := _new_match()
	_roll(m, 6, 5)
	m.announce(65)
	m.believe()                 # mise 2 (J2 relance)
	_roll(m, 2, 1)              # J2 a vraiment LA CAISSE... mais annonce 11 (mousse)
	m.announce(11)
	m.believe()                 # mise 3 (J3 relance)
	_roll(m, 3, 1)
	m.announce(22)              # J3 bluffe
	assert_eq(m.pot, 3, "mise à 3")
	var v := m.accuse()         # J1 accuse J3
	assert_eq(v.accuser, 0, "J1 accuse")
	assert_eq(v.announcer, 2, "J3 avait annoncé")
	assert_true(v.was_bluff, "31 < 22")
	assert_eq(v.sips, 3, "3 gorgées")
	assert_eq(v.loser, 2, "J3 boit")


func test_accuser_la_caisse_double_la_mise() -> void:
	var m := _new_match()
	_roll(m, 2, 1)
	m.announce(Dice.CAISSE)     # vraie CAISSE
	var v := m.accuse()
	assert_false(v.was_bluff, "vraie CAISSE")
	assert_true(v.doubled, "mise doublée")
	assert_eq(v.sips, 2, "1 x 2 = 2")
	assert_eq(v.loser, 1, "l'accusateur boit double")


func test_accuser_une_fausse_caisse_fait_boire_double_le_menteur() -> void:
	var m := _new_match()
	_roll(m, 6, 5)
	m.announce(65)
	m.believe()                 # mise 2
	_roll(m, 4, 2)
	m.announce(Dice.CAISSE)     # bluff sur LA CAISSE
	assert_true(m.must_believe_or_accuse(), "plus rien ne bat LA CAISSE")
	var v := m.accuse()
	assert_true(v.was_bluff, "42 < LA CAISSE")
	assert_eq(v.sips, 4, "2 x 2 = 4")
	assert_eq(v.loser, 1, "le menteur (J2) boit 4")


func test_croire_la_caisse_fait_boire_la_mise_immediatement() -> void:
	var m := _new_match()
	_roll(m, 2, 1)
	m.announce(Dice.CAISSE)
	assert_true(m.must_believe_or_accuse(), "règle spéciale")
	var v := m.believe()
	assert_not_null(v, "verdict immédiat")
	assert_eq(v.kind, Verdict.Kind.CAISSE_BELIEVED, "type : caisse crue")
	assert_eq(v.loser, 1, "le croyant boit")
	assert_eq(v.sips, 1, "la mise (pas de doublage)")
	assert_false(v.doubled, "pas doublé")
	assert_eq(m.phase, MatchState.Phase.ROUND_OVER, "la manche est finie")
	assert_eq(m.stats[1].sips, 1, "J2 a bu")
	assert_eq(v.winner(), -1, "pas de gagnant désigné")


func test_croire_une_fausse_caisse_fait_aussi_boire_et_compte_comme_bluff_reussi() -> void:
	var m := _new_match()
	_roll(m, 4, 3)
	m.announce(Dice.CAISSE)     # bluff
	var v := m.believe()
	assert_eq(v.loser, 1, "le croyant boit quand même")
	assert_eq(m.stats[0].bluffs, 1, "1 bluff")
	assert_eq(m.stats[0].bluffs_succeeded, 1, "bluff réussi")
	assert_eq(v.real_value, Dice.NONE, "les dés ne sont pas révélés")


func test_apres_la_caisse_avec_mise_haute() -> void:
	var m := _new_match(3, 5)
	_roll(m, 6, 5)
	m.announce(65)
	m.believe()                 # mise 2
	_roll(m, 6, 6)
	m.announce(66)
	m.believe()                 # mise 3 ; J3 doit annoncer plus fort que 66
	assert_eq(m.valid_announcements(), [21] as Array[int], "seule LA CAISSE bat 66")
	_roll(m, 2, 1)
	m.announce(Dice.CAISSE)
	var v := m.believe()
	assert_eq(v.sips, 3, "J1 croit LA CAISSE avec une mise de 3 : il boit 3")
	assert_eq(v.loser, 0, "J1 boit")


func test_le_perdant_commence_la_manche_suivante() -> void:
	var m := _new_match()
	_roll(m, 6, 5)
	m.announce(65)
	m.believe()                 # J2 relance, mise 2
	_roll(m, 3, 1)
	m.announce(66)              # J2 bluffe
	var v := m.accuse()         # J3 accuse J2
	assert_eq(v.loser, 1, "J2 boit")
	assert_true(m.next_round(), "manche suivante")
	assert_eq(m.current, 1, "le perdant (J2) commence")
	assert_eq(m.pot, 1, "mise remise à 1")
	assert_eq(m.announced, Dice.NONE, "annonces remises à zéro")
	assert_eq(m.announcer, -1, "plus d'annonceur")
	assert_eq(m.phase, MatchState.Phase.ANNOUNCING, "on annonce")
	assert_eq(m.round_number, 2, "manche 2")
	assert_eq(m.valid_announcements().size(), 21, "tout est permis de nouveau")
	assert_false(m.has_rolled, "il faut relancer")


func test_l_accusateur_perdant_commence_aussi() -> void:
	var m := _new_match()
	_roll(m, 6, 4)
	m.announce(53)              # vrai (64 > 53)
	var v := m.accuse()         # J2 accuse à tort
	assert_eq(v.loser, 1, "J2 boit")
	m.next_round()
	assert_eq(m.current, 1, "J2 commence la manche suivante")


func test_l_ordre_des_joueurs_boucle() -> void:
	var m := _new_match(3)
	m.set_dice(Vector2i(6, 5))
	m.announce(65)              # J1 -> current J2
	m.believe()
	m.set_dice(Vector2i(6, 6))
	m.announce(66)              # J2 -> current J3
	assert_eq(m.current, 2, "J3")
	m.believe()
	m.set_dice(Vector2i(2, 1))
	m.announce(Dice.CAISSE)     # J3 -> current J1 (boucle)
	assert_eq(m.current, 0, "retour au J1")


func test_deux_joueurs() -> void:
	var m := _new_match(2)
	m.set_dice(Vector2i(3, 1))
	m.announce(31)
	assert_eq(m.current, 1, "J2")
	m.believe()
	m.set_dice(Vector2i(4, 1))
	m.announce(41)
	assert_eq(m.current, 0, "retour à J1 avec 2 joueurs")
	var v := m.accuse()
	assert_false(v.was_bluff, "41 vrai")
	assert_eq(v.loser, 0, "J1 accuse à tort")
	assert_eq(v.sips, 2, "mise 2")


func test_dix_joueurs() -> void:
	var m := _new_match(10)
	assert_eq(m.player_count(), 10, "10 joueurs")
	m.set_dice(Vector2i(5, 5))
	m.announce(55)
	assert_eq(m.current, 1, "suivant")
	assert_eq(m.index_after(9), 0, "le 10e passe au 1er")


func test_les_actions_hors_phase_sont_ignorees() -> void:
	var m := _new_match()
	assert_null(m.believe(), "croire sans annonce")
	assert_null(m.accuse(), "accuser sans annonce")
	assert_false(m.next_round(), "pas de manche suivante sans verdict")
	m.set_dice(Vector2i(5, 3))
	m.announce(53)
	assert_false(m.announce(54), "J2 doit décider, pas annoncer")
	m.accuse()
	assert_null(m.accuse(), "double accusation impossible")
	assert_null(m.believe(), "croire après verdict impossible")
	assert_true(m.valid_announcements().is_empty(), "pas d'annonce après un verdict")


func test_limite_de_gorgees_plafonne_la_mise_et_la_punition() -> void:
	var m := _new_match(3, 2)   # limite = 2
	_roll(m, 6, 5)
	m.announce(31)
	m.believe()                 # mise 2
	_roll(m, 6, 5)
	m.announce(32)
	m.believe()                 # mise plafonnée à 2
	assert_eq(m.pot, 2, "mise plafonnée à la limite")
	_roll(m, 2, 1)
	m.announce(Dice.CAISSE)
	assert_eq(m.stake_if_accused(), 2, "doublage plafonné : 2 x 2 = 4 -> 2")
	var v := m.accuse()
	assert_eq(v.sips, 2, "punition plafonnée")


func test_la_limite_est_bornee_a_la_creation() -> void:
	assert_eq(MatchState.new(["a", "b"], 0, 1).max_sips, 1, "minimum 1")
	assert_eq(MatchState.new(["a", "b"], 99, 1).max_sips, 15, "maximum 15")


func test_les_des_restent_secrets_pour_le_joueur_suivant_jusqu_a_la_revelation() -> void:
	# Après « je te crois », les dés (et la valeur réelle) du précédent sont effacés :
	# le joueur suivant ne peut pas en hériter.
	var m := _new_match()
	m.set_dice(Vector2i(6, 6))
	m.announce(66)
	m.believe()
	assert_eq(m.real_value, Dice.NONE, "valeur réelle effacée")
	assert_eq(m.dice, Vector2i.ZERO, "dés effacés")
	assert_false(m.has_rolled, "pas encore lancé")
