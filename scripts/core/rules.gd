class_name Rules
extends RefCounted
## Les règles de MISE et de VERDICT, sans aucune interface.
##
##   • La mise de départ est de 1 gorgée.
##   • Chaque « JE TE CROIS » ajoute 1 gorgée à la mise.
##   • Si l'annonce contestée est LA CAISSE, la mise est DOUBLÉE.
##   • Une punition ne dépasse jamais la limite choisie dans les réglages (5 par défaut).
##   • Un bluff = une annonce plus forte que les vrais dés.
##     Des dés égaux ou plus forts que l'annonce = annonce honnête.

const START_POT: int = 1
const CAISSE_MULTIPLIER: int = 2
const DEFAULT_MAX_SIPS: int = 5
const MIN_MAX_SIPS: int = 1
const MAX_MAX_SIPS: int = 15


## Mise après un « JE TE CROIS » : +1, sans jamais dépasser la limite.
static func pot_after_belief(pot: int, max_sips: int) -> int:
	return mini(pot + 1, max_sips)


## Nombre de gorgées de la punition quand `announced` est contestée avec une mise de `pot`.
## LA CAISSE double la mise ; le résultat est plafonné à `max_sips`.
static func penalty(pot: int, announced: int, max_sips: int) -> int:
	var amount := pot * (CAISSE_MULTIPLIER if announced == Dice.CAISSE else 1)
	return mini(amount, max_sips)


## Gorgées à boire quand on « croit » LA CAISSE (impossible de faire mieux) :
## on boit la mise telle quelle, tout de suite — sans doublage, sans révéler les dés.
static func believe_caisse_penalty(pot: int, max_sips: int) -> int:
	return mini(pot, max_sips)


## Les vrais dés étaient-ils plus faibles que l'annonce (= bluff) ?
static func is_bluff(announced: int, real_value: int) -> bool:
	return Dice.rank(announced) > Dice.rank(real_value)


## Plus aucune annonce ne peut battre celle-ci (= LA CAISSE) ?
## Le joueur suivant ne peut alors que « croire » (et boire) ou accuser.
static func is_unbeatable(announced: int) -> bool:
	return Dice.valid_announcements(announced).is_empty()
