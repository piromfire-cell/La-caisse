class_name Challenges
extends RefCounted
## Mode « Soft » : à la place des gorgées d'alcool, le perdant boit de l'EAU ou relève un DÉFI.
## Plus la punition est grosse (nombre de gorgées), plus le défi est corsé.
##
## Pour ajouter/modifier des défis : change simplement les listes ci-dessous.

const KIND_WATER := "eau"
const KIND_CHALLENGE := "defis"
const KIND_MIX := "mix"

const LIGHT: Array[String] = [
	"Fais ton meilleur cri de chat.",
	"Fais un compliment sincère à la personne à ta gauche.",
	"Fais 5 squats, bien creux.",
	"Parle comme un pirate jusqu'à ta prochaine manche.",
	"Imite un joueur de la table : les autres doivent deviner qui.",
	"Chante le refrain de ta toune préférée.",
	"Dis le mot « bière » dans trois langues différentes (ou invente-les).",
	"Raconte ta pire gaffe en 15 secondes.",
	"Fais le tour de la table en marchant comme un canard.",
	"Fais deviner un film en le mimant, sans parler.",
	"Dis ton nom à l'envers, vite et sans te tromper.",
	"Fais un high five à tout le monde, en silence, avec le plus grand sérieux.",
]

const MEDIUM: Array[String] = [
	"Fais un toast ridicule à la table.",
	"Garde l'accent de Français jusqu'à ta prochaine manche.",
	"Montre la dernière photo de ta galerie (pas de triche!).",
	"Fais 10 jumping jacks pendant que la table compte à voix haute.",
	"Raconte ton souvenir le plus gênant.",
	"Imite un animal au choix du joueur à ta droite.",
	"Fais une déclaration d'amour à ton verre.",
	"Parle en rimes pendant les deux prochains tours.",
	"Fais une grimace de 10 secondes sans rire, pendant que les autres essaient de te faire craquer.",
	"Danse sans musique pendant 15 secondes.",
	"Fais applaudir la table pour toi et salue comme une vedette de cinéma.",
	"Raconte un secret inoffensif que personne ici ne connaît.",
]

const SPICY: Array[String] = [
	"Fais un discours de 20 secondes : « Pourquoi la bière est la plus grande invention de l'humanité ».",
	"Laisse la table te trouver un surnom pour le reste de la partie.",
	"Fais le robot jusqu'à ta prochaine manche.",
	"Fais 15 pompes (ou 25 squats). On te regarde.",
	"Échange ta place avec quelqu'un de ton choix et change d'accent jusqu'à la fin de la manche.",
	"Rappe ta journée en 20 secondes, avec les bruits de bouche.",
	"Laisse le joueur à ta gauche te donner un gage inoffensif (les autres approuvent).",
	"Fais une pub télé pour ton objet le plus proche, avec l'enthousiasme d'un vendeur de chars usagés.",
	"Fais le tour de la table en dansant sur une chanson que tu chantes toi-même.",
	"Tiens la position de la chaise (dos au mur) pendant que la table compte jusqu'à 20.",
	"Raconte ta plus grosse folie de jeunesse (version familiale).",
	"Fais ton meilleur cri de Tarzan et reste dans le personnage jusqu'à ta prochaine manche.",
]

## Défis déjà tirés récemment (pour éviter les répétitions immédiates).
static var _recent: Array[String] = []


## Décrit la punition pour `sips` gorgées en mode Soft.
## `kind` : KIND_WATER, KIND_CHALLENGE ou KIND_MIX (au hasard entre les deux).
## Retourne { "type": "water"|"challenge", "sips": int, "text": String }.
static func describe(sips: int, kind: String, rng: RandomNumberGenerator) -> Dictionary:
	var use_challenge := false
	match kind:
		KIND_CHALLENGE:
			use_challenge = true
		KIND_WATER:
			use_challenge = false
		_:
			use_challenge = rng.randf() < 0.5

	if use_challenge:
		return { "type": "challenge", "sips": sips, "text": pick(sips, rng) }
	return { "type": "water", "sips": sips, "text": "%s d'EAU" % Fr.sips(sips) }


## Choisit un défi adapté à la taille de la punition, en évitant les derniers tirés.
static func pick(sips: int, rng: RandomNumberGenerator) -> String:
	var pool: Array[String] = LIGHT
	if sips >= 5:
		pool = SPICY
	elif sips >= 3:
		pool = MEDIUM

	var choices: Array[String] = []
	for c in pool:
		if not _recent.has(c):
			choices.append(c)
	if choices.is_empty():
		_recent.clear()
		choices = pool.duplicate()

	var chosen: String = choices[rng.randi_range(0, choices.size() - 1)]
	_recent.append(chosen)
	if _recent.size() > 8:
		_recent.pop_front()
	return chosen
