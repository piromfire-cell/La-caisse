class_name PlayerStats
extends RefCounted
## Les statistiques d'un joueur pendant la partie.

## Gorgées bues au total.
var sips: int = 0
## Annonces mensongères (annonce plus forte que les vrais dés).
var bluffs: int = 0
## Bluffs « crus » par le joueur suivant (= bluffs réussis).
var bluffs_succeeded: int = 0
## Bluffs démasqués par une accusation.
var bluffs_caught: int = 0
## Fois où ce joueur a crié « MENTEUR ! », et fois où il avait raison.
var accusations: int = 0
var accusations_correct: int = 0
## Fois où ce joueur a dit « JE TE CROIS ».
var believes: int = 0
## Manches perdues (= fois où il a bu).
var rounds_lost: int = 0
