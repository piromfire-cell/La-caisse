extends Node
## Le « chef d'orchestre » : garde la partie en cours (`session`) et décide quel écran
## afficher ensuite. Les écrans ne se connaissent pas entre eux : ils appellent seulement
## les fonctions ci-dessous. Disponible partout sous le nom `Game`.
##
## Déroulement d'un tour :
##   pass (roll) → dice → announce → pass (decide) → decide ─┬─ croire → dice (même joueur) …
##                                                           └─ accuser → reveal → pass (roll) …

## La partie en cours (null quand on est sur l'accueil).
var session: MatchState = null
## L'écran-hôte (Main) ; il sait changer d'écran.
var host: Node = null
## Hasard « d'ambiance » (choix des défis du mode Soft).
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()


## Affiche l'écran `screen` ("home", "players", "pass", "dice", "announce", "decide",
## "reveal", "stats", "rules", "settings") avec des paramètres optionnels.
func go(screen: String, args: Dictionary = {}) -> void:
	if host != null:
		host.show_screen(screen, args)


func go_home() -> void:
	session = null
	go("home")


## Démarre une nouvelle partie avec ces joueurs (dans cet ordre autour de la table).
func new_game(names: Array) -> void:
	session = MatchState.new(names, Settings.max_sips)
	go("pass", { "kind": "roll" })


## Rejoue avec les mêmes joueurs (statistiques remises à zéro).
func restart_same_players() -> void:
	if session != null:
		new_game(session.players.duplicate())


## L'écran « Passe le téléphone » est confirmé par le bon joueur.
func pass_done(kind: String) -> void:
	go("decide" if kind == "decide" else "dice")


## Le joueur a vu ses dés et veut annoncer.
func dice_done() -> void:
	go("announce")


## Le joueur annonce `value` ; le téléphone passe au joueur suivant.
func announce(value: int) -> bool:
	if session == null or not session.announce(value):
		return false
	go("pass", { "kind": "decide" })
	return true


## « JE TE CROIS » : si ce n'est pas LA CAISSE, le même joueur relance ses dés.
func believe() -> void:
	var verdict := session.believe()
	go("dice" if verdict == null else "reveal")


## « MENTEUR ! »
func accuse() -> void:
	session.accuse()
	go("reveal")


## Après la révélation : le perdant commence la manche suivante.
func next_round() -> void:
	session.next_round()
	go("pass", { "kind": "roll" })


## Affiche les stats. `final` = fin de partie ; sinon un bouton « Reprendre » ramène à
## l'écran décrit dans `back` (ex. { "screen": "pass", "args": {...} }).
func show_stats(final: bool, back: Dictionary = {}) -> void:
	go("stats", { "final": final, "back": back })


## Texte pour une quantité de gorgées.
func sips_text(n: int) -> String:
	return Fr.sips(n)


## Décrit la punition de `sips` gorgées : alcool, eau ou défi selon le mode Soft.
## Retourne { "type": "sips"|"water"|"challenge", "sips": int, "text": String }.
func describe_penalty(sips: int) -> Dictionary:
	if Settings.soft_mode:
		return Challenges.describe(sips, Settings.soft_kind, rng)
	return { "type": "sips", "sips": sips, "text": Fr.sips(sips) }
