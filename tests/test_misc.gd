extends TestCase
## Tests des petits utilitaires : français (accords) et défis du mode Soft.


func test_gorgees_au_singulier_et_au_pluriel() -> void:
	assert_eq(Fr.sips(1), "1 gorgée", "singulier")
	assert_eq(Fr.sips(2), "2 gorgées", "pluriel")
	assert_eq(Fr.sips(5), "5 gorgées", "pluriel")
	assert_eq(Fr.sips(0), "0 gorgée", "zéro prend le singulier en français")


func test_pluriel_francais() -> void:
	assert_eq(Fr.plural(0, "bluff", "bluffs"), "0 bluff", "0")
	assert_eq(Fr.plural(1, "bluff", "bluffs"), "1 bluff", "1")
	assert_eq(Fr.plural(3, "bluff", "bluffs"), "3 bluffs", "3")


func test_liste_de_noms() -> void:
	assert_eq(Fr.join_names([]), "", "vide")
	assert_eq(Fr.join_names(["Alice"]), "Alice", "un nom")
	assert_eq(Fr.join_names(["Alice", "Bob"]), "Alice et Bob", "deux noms")
	assert_eq(Fr.join_names(["Alice", "Bob", "Chloé"]), "Alice, Bob et Chloé", "trois noms")


func test_mode_soft_eau() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var d := Challenges.describe(3, Challenges.KIND_WATER, rng)
	assert_eq(d["type"], "water", "type eau")
	assert_eq(d["sips"], 3, "3 gorgées")
	assert_eq(d["text"], "3 gorgées d'EAU", "texte")
	assert_eq(Challenges.describe(1, Challenges.KIND_WATER, rng)["text"], "1 gorgée d'EAU", "singulier")


func test_mode_soft_defis() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	for sips in [1, 2, 3, 4, 5, 10]:
		var d := Challenges.describe(sips, Challenges.KIND_CHALLENGE, rng)
		assert_eq(d["type"], "challenge", "type défi")
		assert_true(str(d["text"]).length() > 5, "texte de défi non vide")


func test_mode_soft_melange_donne_les_deux_types() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var types := {}
	for i in 60:
		types[Challenges.describe(2, Challenges.KIND_MIX, rng)["type"]] = true
	assert_true(types.has("water") and types.has("challenge"), "le mélange alterne eau et défis")


func test_les_defis_ne_se_repetent_pas_immediatement() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var previous := ""
	for i in 40:
		var c := Challenges.pick(1, rng)
		assert_ne(c, previous, "pas deux fois le même défi de suite")
		previous = c


func test_les_defis_sont_ranges_par_intensite() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	assert_true(Challenges.LIGHT.has(Challenges.pick(1, rng)), "1-2 gorgées : défi léger")
	assert_true(Challenges.MEDIUM.has(Challenges.pick(3, rng)), "3-4 gorgées : défi moyen")
	assert_true(Challenges.SPICY.has(Challenges.pick(5, rng)), "5+ gorgées : défi corsé")
	assert_true(Challenges.LIGHT.size() >= 10 and Challenges.MEDIUM.size() >= 10 and Challenges.SPICY.size() >= 10, "assez de défis")
