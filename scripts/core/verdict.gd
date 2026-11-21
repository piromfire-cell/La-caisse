class_name Verdict
extends RefCounted
## Le résultat d'une fin de manche : qui boit, combien, et pourquoi.

enum Kind {
	ACCUSATION,       ## Quelqu'un a crié « MENTEUR ! » : les vrais dés sont révélés.
	CAISSE_BELIEVED,  ## Quelqu'un a cru LA CAISSE : il boit la mise, rien n'est révélé.
}

var kind: Kind = Kind.ACCUSATION

## Joueur qui a accusé (ou qui a cru, dans le cas CAISSE_BELIEVED).
var accuser: int = -1
## Joueur qui avait fait l'annonce contestée.
var announcer: int = -1
## L'annonce contestée (ex. 64).
var announced: int = Dice.NONE
## Les vrais dés de l'annonceur (valeur lue et dés individuels).
var real_value: int = Dice.NONE
var dice: Vector2i = Vector2i.ZERO
## L'annonceur a-t-il menti ?
var was_bluff: bool = false
## Le joueur qui boit, et combien de gorgées.
var loser: int = -1
var sips: int = 0
## La mise avant doublage éventuel, et si LA CAISSE l'a doublée.
var pot: int = 1
var doubled: bool = false


## Le gagnant de l'échange (celui qui ne boit pas) — seulement pour une accusation.
func winner() -> int:
	if kind != Kind.ACCUSATION:
		return -1
	return announcer if loser == accuser else accuser
