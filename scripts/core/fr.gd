class_name Fr
extends RefCounted
## Petits utilitaires de français (accords, pluriels).
## Tout le texte « dynamique » du jeu passe par ici pour que les « s » soient justes.


## « 1 gorgée » / « 3 gorgées ».
static func sips(n: int) -> String:
	return "%d %s" % [n, "gorgée" if n <= 1 else "gorgées"]


## Accorde un nom commun : plural(2, "bluff", "bluffs") -> « 2 bluffs ».
## En français, 0 et 1 prennent le singulier.
static func plural(n: int, singular: String, plural_form: String) -> String:
	return "%d %s" % [n, singular if n <= 1 else plural_form]


## Joint des noms avec des virgules et « et » : ["A","B","C"] -> « A, B et C ».
static func join_names(names: Array) -> String:
	if names.is_empty():
		return ""
	if names.size() == 1:
		return str(names[0])
	var head: Array = names.slice(0, names.size() - 1)
	var parts := PackedStringArray()
	for n in head:
		parts.append(str(n))
	return "%s et %s" % [", ".join(parts), str(names[names.size() - 1])]
