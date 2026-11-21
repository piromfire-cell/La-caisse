class_name Dice
extends RefCounted
## Tout ce qui concerne les DÉS : lecture d'un jet, classement des résultats et
## liste des annonces permises. Aucune dépendance à l'interface : c'est de la logique
## pure, donc facile à tester.
##
## Un jet de deux dés se lit « le plus gros chiffre en premier » : un 3 et un 5 donnent 53.
##
## Classement, du plus faible au plus fort :
##   1. les résultats normaux : 31, 32, 41, 42, 43, 51 … 65  (14 résultats)
##   2. les doubles, appelés « Mousses » : 11, 22, 33, 44, 55, 66
##   3. le plus fort de tous : 21 = « LA CAISSE »

## Valeur spéciale : « aucune annonce encore faite ».
const NONE: int = 0

## Le jet 2 + 1.
const CAISSE: int = 21

enum Category { NORMAL, MOUSSE, CAISSE }

## Les 21 résultats possibles, du plus faible (index 0) au plus fort (index 20).
const RANKED: Array[int] = [
	31, 32, 41, 42, 43, 51, 52, 53, 54, 61, 62, 63, 64, 65,  # normaux
	11, 22, 33, 44, 55, 66,                                    # mousses
	21,                                                        # LA CAISSE
]


## Transforme deux dés en résultat lisible : (3, 5) -> 53, (1, 2) -> 21, (4, 4) -> 44.
static func value_from_dice(a: int, b: int) -> int:
	return maxi(a, b) * 10 + mini(a, b)


## Le résultat est-il un des 21 résultats possibles ?
static func is_valid_value(value: int) -> bool:
	return RANKED.has(value)


## Position dans le classement (0 = le plus faible, 20 = LA CAISSE). -1 si invalide.
static func rank(value: int) -> int:
	return RANKED.find(value)


## `a` bat-il strictement `b` ? Si `b` est NONE (aucune annonce), tout résultat valide gagne.
static func beats(a: int, b: int) -> bool:
	if not is_valid_value(a):
		return false
	if b == NONE:
		return true
	return rank(a) > rank(b)


static func category(value: int) -> Category:
	if value == CAISSE:
		return Category.CAISSE
	if is_mousse(value):
		return Category.MOUSSE
	return Category.NORMAL


## Double (11, 22 … 66) ?
static func is_mousse(value: int) -> bool:
	return value != CAISSE and is_valid_value(value) and high_die(value) == low_die(value)


static func is_caisse(value: int) -> bool:
	return value == CAISSE


## Le plus gros dé du résultat (53 -> 5).
static func high_die(value: int) -> int:
	return floori(value / 10.0)


## Le plus petit dé du résultat (53 -> 3).
static func low_die(value: int) -> int:
	return value % 10


## Toutes les annonces permises après `previous` : uniquement des résultats STRICTEMENT plus
## forts, du plus faible au plus fort. Si `previous` est NONE, tout est permis.
## Retourne un tableau vide quand plus rien ne bat l'annonce (c'est le cas après LA CAISSE).
static func valid_announcements(previous: int) -> Array[int]:
	var result: Array[int] = []
	var start := 0 if previous == NONE else rank(previous) + 1
	if start < 0:
		return result  # `previous` n'est pas un résultat connu
	for i in range(start, RANKED.size()):
		result.append(RANKED[i])
	return result


## Combien de combinaisons de deux dés (sur 36) donnent ce résultat ?
## Les doubles : 1 façon. Tous les autres : 2 façons (ex. 3-5 et 5-3).
static func combos(value: int) -> int:
	if not is_valid_value(value):
		return 0
	return 1 if is_mousse(value) else 2


## Lance deux dés. Retourne Vector2i(dé1, dé2). Le générateur est passé en paramètre
## pour pouvoir faire des tests reproductibles.
static func roll(rng: RandomNumberGenerator) -> Vector2i:
	return Vector2i(rng.randi_range(1, 6), rng.randi_range(1, 6))


## Texte court : « 53 », « 44 », « 21 ».
static func label(value: int) -> String:
	return str(value)


## Texte complet : « 53 », « Mousse de 4 (44) », « LA CAISSE (21) ».
static func long_label(value: int) -> String:
	match category(value):
		Category.CAISSE:
			return "LA CAISSE (21)"
		Category.MOUSSE:
			return "Mousse de %d (%d)" % [high_die(value), value]
		_:
			return str(value)
