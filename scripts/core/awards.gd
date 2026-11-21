class_name Awards
extends RefCounted
## Calcule les « prix » affichés dans le tableau de fin de partie.
##
## Chaque prix est un Dictionary :
##   id      : identifiant technique ("liar", "detector", "bluffer", "thirsty")
##   title   : titre affiché
##   players : Array[String] des gagnants (plusieurs en cas d'égalité)
##   detail  : phrase de détail (« 3 bluffs », « 4 accusations justes sur 5 »…)
## Un prix n'est pas attribué si personne ne le mérite (score de 0).


static func compute(names: Array, stats: Array) -> Array[Dictionary]:
	var awards: Array[Dictionary] = []

	# Plus gros menteur : le plus de bluffs (réussis ou non).
	var liar_scores: Array[int] = []
	for s: PlayerStats in stats:
		liar_scores.append(s.bluffs)
	var liar := _leaders(liar_scores)
	if not liar.is_empty():
		awards.append({
			"id": "liar",
			"title": "Plus gros menteur",
			"players": _names_at(names, liar),
			"detail": Fr.plural(liar_scores[liar[0]], "bluff", "bluffs"),
		})

	# Meilleur détecteur : le plus d'accusations justes ; à égalité, la meilleure précision.
	var det_scores: Array[int] = []
	for s: PlayerStats in stats:
		det_scores.append(s.accusations_correct * 1000 + _percent(s.accusations_correct, s.accusations))
	var det := _leaders(det_scores)
	if not det.is_empty():
		var d: PlayerStats = stats[det[0]]
		awards.append({
			"id": "detector",
			"title": "Meilleur détecteur",
			"players": _names_at(names, det),
			"detail": "%d sur %s" % [d.accusations_correct, Fr.plural(d.accusations, "accusation", "accusations")],
		})

	# Meilleur bluffeur : le plus de bluffs RÉUSSIS (crus par le joueur suivant).
	var bl_scores: Array[int] = []
	for s: PlayerStats in stats:
		bl_scores.append(s.bluffs_succeeded * 1000 + _percent(s.bluffs_succeeded, s.bluffs))
	var bl := _leaders(bl_scores)
	if not bl.is_empty():
		var b: PlayerStats = stats[bl[0]]
		awards.append({
			"id": "bluffer",
			"title": "Bluffs réussis",
			"players": _names_at(names, bl),
			"detail": "%d sur %s" % [b.bluffs_succeeded, Fr.plural(b.bluffs, "bluff", "bluffs")],
		})

	# Le plus assoiffé : le plus de gorgées bues.
	var thirst_scores: Array[int] = []
	for s: PlayerStats in stats:
		thirst_scores.append(s.sips)
	var thirst := _leaders(thirst_scores)
	if not thirst.is_empty():
		awards.append({
			"id": "thirsty",
			"title": "Le plus assoiffé",
			"players": _names_at(names, thirst),
			"detail": Fr.sips(thirst_scores[thirst[0]]),
		})

	return awards


## Indices des joueurs qui ont le meilleur score (et un score > 0). Vide si personne.
static func _leaders(scores: Array[int]) -> Array[int]:
	var best := 0
	for sc in scores:
		best = maxi(best, sc)
	var result: Array[int] = []
	if best <= 0:
		return result
	for i in scores.size():
		if scores[i] == best:
			result.append(i)
	return result


static func _names_at(names: Array, indices: Array[int]) -> Array[String]:
	var result: Array[String] = []
	for i in indices:
		result.append(str(names[i]))
	return result


static func _percent(part: int, total: int) -> int:
	if total <= 0:
		return 0
	return int(round(100.0 * part / total))
