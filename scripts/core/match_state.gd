class_name MatchState
extends RefCounted
## L'état complet d'une partie de La Caisse + toutes les transitions de règles.
## Aucune interface ici : l'écran appelle ces fonctions et affiche ce qu'elles retournent.
##
## Cycle d'une manche :
##
##   ANNOUNCING ──announce()──▶ DECIDING ──believe()──▶ ANNOUNCING   (le joueur suivant relance)
##                                 │
##                                 ├──accuse()────────▶ ROUND_OVER   (dés révélés, quelqu'un boit)
##                                 └──believe() sur LA CAISSE ▶ ROUND_OVER (le croyant boit)
##
##   ROUND_OVER ──next_round()──▶ ANNOUNCING (le perdant commence ; mise = 1 ; plus d'annonce)

enum Phase {
	ANNOUNCING,  ## `current` lance ses dés (en secret) puis annonce un résultat.
	DECIDING,    ## `current` doit répondre à l'annonce : croire ou accuser.
	ROUND_OVER,  ## Un verdict a été rendu ; on attend la manche suivante.
}

var players: Array[String] = []
var max_sips: int = Rules.DEFAULT_MAX_SIPS
var rng := RandomNumberGenerator.new()

var phase: Phase = Phase.ANNOUNCING
## Indice du joueur à qui c'est le tour d'agir.
var current: int = 0
## Mise actuelle, en gorgées.
var pot: int = Rules.START_POT
## Dernière annonce de la manche (Dice.NONE s'il n'y en a pas encore) et son auteur.
var announced: int = Dice.NONE
var announcer: int = -1
## La dernière annonce était-elle un mensonge ? (secret : jamais affiché avant la révélation)
var announced_was_bluff: bool = false
## Les vrais dés du joueur qui vient de lancer (secret).
var dice: Vector2i = Vector2i.ZERO
var real_value: int = Dice.NONE
## Le joueur courant a-t-il déjà lancé ses dés pour ce tour ?
var has_rolled: bool = false
var round_number: int = 1
var last_verdict: Verdict = null
var stats: Array[PlayerStats] = []


## `player_names` : 2 à 10 noms. `seed_value` : graine du hasard (-1 = aléatoire ; utile aux tests).
func _init(player_names: Array, p_max_sips: int = Rules.DEFAULT_MAX_SIPS, seed_value: int = -1) -> void:
	for n in player_names:
		players.append(str(n))
		stats.append(PlayerStats.new())
	max_sips = clampi(p_max_sips, Rules.MIN_MAX_SIPS, Rules.MAX_MAX_SIPS)
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	start_round(0)


# ── Accès pratiques ────────────────────────────────────────────────────────────

func player_count() -> int:
	return players.size()


func current_name() -> String:
	return players[current]


func announcer_name() -> String:
	return players[announcer] if announcer >= 0 else ""


## Joueur assis après `index` autour de la table (le dernier repasse au premier).
func index_after(index: int) -> int:
	return (index + 1) % players.size()


## Y a-t-il déjà eu une annonce dans cette manche ?
func has_announcement() -> bool:
	return announced != Dice.NONE


## Quand l'annonce est LA CAISSE, personne ne peut faire mieux : le joueur suivant
## peut seulement « croire » (et boire la mise) ou accuser.
func must_believe_or_accuse() -> bool:
	return phase == Phase.DECIDING and Rules.is_unbeatable(announced)


## Gorgées que perdrait l'accusateur s'il avait tort, ou l'annonceur s'il avait menti.
func stake_if_accused() -> int:
	return Rules.penalty(pot, announced, max_sips)


## Mise après un « JE TE CROIS » ordinaire.
func pot_if_believed() -> int:
	return Rules.pot_after_belief(pot, max_sips)


## Gorgées bues par celui qui croit LA CAISSE.
func stake_if_believing_caisse() -> int:
	return Rules.believe_caisse_penalty(pot, max_sips)


# ── Début de manche ────────────────────────────────────────────────────────────

## Commence une nouvelle manche avec `starter` : mise remise à 1, annonces effacées.
func start_round(starter: int) -> void:
	phase = Phase.ANNOUNCING
	current = starter
	pot = Rules.START_POT
	announced = Dice.NONE
	announcer = -1
	announced_was_bluff = false
	dice = Vector2i.ZERO
	real_value = Dice.NONE
	has_rolled = false


## Passe à la manche suivante : le perdant de la manche qui vient de finir commence.
func next_round() -> bool:
	if phase != Phase.ROUND_OVER or last_verdict == null:
		return false
	round_number += 1
	start_round(last_verdict.loser)
	return true


# ── Tour du joueur courant : lancer puis annoncer ──────────────────────────────

## Le joueur courant lance ses 2 dés en secret. Appeler plusieurs fois ne relance PAS :
## on retourne les mêmes dés (impossible de tricher en rechargeant l'écran).
func roll_dice() -> Vector2i:
	if phase != Phase.ANNOUNCING:
		return dice
	if not has_rolled:
		set_dice(Dice.roll(rng))
	return dice


## Impose les dés (réservé aux tests).
func set_dice(value: Vector2i) -> void:
	dice = value
	real_value = Dice.value_from_dice(value.x, value.y)
	has_rolled = true


## Résultats que le joueur courant a le droit d'annoncer (strictement plus forts que
## la dernière annonce ; tout est permis s'il n'y en a pas). Vide hors de la phase d'annonce.
func valid_announcements() -> Array[int]:
	if phase != Phase.ANNOUNCING:
		return []
	return Dice.valid_announcements(announced)


## Le joueur courant annonce `value`. Retourne false (sans rien changer) si l'annonce est
## refusée : mauvaise phase, dés pas encore lancés, ou résultat pas assez fort.
## Sinon le téléphone passe au joueur suivant, qui doit décider.
func announce(value: int) -> bool:
	if phase != Phase.ANNOUNCING or not has_rolled:
		return false
	if not Dice.beats(value, announced):
		return false

	announced_was_bluff = Rules.is_bluff(value, real_value)
	if announced_was_bluff:
		stats[current].bluffs += 1
	announced = value
	announcer = current
	current = index_after(current)
	phase = Phase.DECIDING
	has_rolled = false  # le prochain à lancer (s'il croit) devra lancer ses propres dés
	return true


# ── Réponse du joueur suivant ──────────────────────────────────────────────────

## « JE TE CROIS ».
##  • Cas normal : la mise monte de 1, le même joueur relance ses dés puis doit annoncer plus
##    fort. Retourne null.
##  • Si l'annonce était LA CAISSE (imbattable) : il boit la mise tout de suite et la manche
##    est terminée. Retourne le Verdict.
func believe() -> Verdict:
	if phase != Phase.DECIDING:
		return null

	stats[current].believes += 1
	if announced_was_bluff:
		stats[announcer].bluffs_succeeded += 1

	if Rules.is_unbeatable(announced):
		var v := Verdict.new()
		v.kind = Verdict.Kind.CAISSE_BELIEVED
		v.accuser = current
		v.announcer = announcer
		v.announced = announced
		v.pot = pot
		v.doubled = false
		v.loser = current
		v.sips = Rules.believe_caisse_penalty(pot, max_sips)
		# Les vrais dés restent secrets : on ne remplit ni `dice` ni `was_bluff`.
		_finish_round(v)
		return v

	pot = Rules.pot_after_belief(pot, max_sips)
	phase = Phase.ANNOUNCING
	has_rolled = false
	dice = Vector2i.ZERO
	real_value = Dice.NONE
	return null


## « MENTEUR ! » : on révèle les vrais dés de l'annonceur.
##  • Bluff (dés plus faibles que l'annonce) : l'annonceur boit.
##  • Sinon (dés égaux ou plus forts) : l'accusateur boit.
## La mise est doublée si l'annonce contestée était LA CAISSE.
func accuse() -> Verdict:
	if phase != Phase.DECIDING:
		return null

	var v := Verdict.new()
	v.kind = Verdict.Kind.ACCUSATION
	v.accuser = current
	v.announcer = announcer
	v.announced = announced
	v.real_value = real_value
	v.dice = dice
	v.was_bluff = Rules.is_bluff(announced, real_value)
	v.pot = pot
	v.doubled = announced == Dice.CAISSE
	v.sips = Rules.penalty(pot, announced, max_sips)
	v.loser = announcer if v.was_bluff else current

	stats[current].accusations += 1
	if v.was_bluff:
		stats[current].accusations_correct += 1
		stats[announcer].bluffs_caught += 1

	_finish_round(v)
	return v


func _finish_round(v: Verdict) -> void:
	last_verdict = v
	stats[v.loser].sips += v.sips
	stats[v.loser].rounds_lost += 1
	phase = Phase.ROUND_OVER


# ── Statistiques ───────────────────────────────────────────────────────────────

## Total de gorgées bues par tout le monde.
func total_sips() -> int:
	var total := 0
	for s in stats:
		total += s.sips
	return total


## Les prix de fin de partie (voir Awards).
func awards() -> Array[Dictionary]:
	return Awards.compute(players, stats)
