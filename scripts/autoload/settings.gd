extends Node
## Réglages du jeu, sauvegardés sur l'appareil (fichier « user://la_caisse.cfg »).
## Disponible partout sous le nom `Settings`.

signal changed

const PATH := "user://la_caisse.cfg"

## Limite de gorgées par punition.
var max_sips: int = Rules.DEFAULT_MAX_SIPS
## Mode Soft : eau / défis au lieu de l'alcool.
var soft_mode: bool = false
## En mode Soft : "eau", "defis" ou "mix".
var soft_kind: String = Challenges.KIND_MIX
var sound_on: bool = true
## Voix qui crie « Menteur ! » (synthèse vocale de l'appareil, si disponible).
var voice_on: bool = true
var vibration_on: bool = true
## Petit point discret sur la grille d'annonce qui indique le vrai résultat du joueur.
var show_hint: bool = true
## Derniers noms de joueurs utilisés (pour ne pas les retaper).
var players: Array[String] = []
## Avertissement 18+ accepté pour cette session (volontairement non sauvegardé :
## l'avertissement revient à chaque lancement de l'application).
var age_accepted: bool = false


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		return
	max_sips = clampi(int(cf.get_value("game", "max_sips", max_sips)), Rules.MIN_MAX_SIPS, Rules.MAX_MAX_SIPS)
	soft_mode = bool(cf.get_value("game", "soft_mode", soft_mode))
	var kind := str(cf.get_value("game", "soft_kind", soft_kind))
	soft_kind = kind if kind in [Challenges.KIND_WATER, Challenges.KIND_CHALLENGE, Challenges.KIND_MIX] else Challenges.KIND_MIX
	sound_on = bool(cf.get_value("device", "sound_on", sound_on))
	voice_on = bool(cf.get_value("device", "voice_on", voice_on))
	vibration_on = bool(cf.get_value("device", "vibration_on", vibration_on))
	show_hint = bool(cf.get_value("game", "show_hint", show_hint))
	players.clear()
	for n in cf.get_value("game", "players", []):
		players.append(str(n))


func save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("game", "max_sips", max_sips)
	cf.set_value("game", "soft_mode", soft_mode)
	cf.set_value("game", "soft_kind", soft_kind)
	cf.set_value("device", "sound_on", sound_on)
	cf.set_value("device", "voice_on", voice_on)
	cf.set_value("device", "vibration_on", vibration_on)
	cf.set_value("game", "show_hint", show_hint)
	cf.set_value("game", "players", players)
	cf.save(PATH)
	changed.emit()
