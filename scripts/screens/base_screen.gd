class_name BaseScreen
extends Control
## Squelette commun à tous les écrans : une colonne verticale (`content`) avec des marges
## qui évitent l'encoche et les bords. Chaque écran remplit `content` dans `_build()`.

## Les paramètres reçus de `Game.go(...)`.
var args: Dictionary = {}
## Colonne dans laquelle l'écran empile ses éléments.
var content: VBoxContainer = null


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS


## Appelé par Main une fois l'écran ajouté à l'arbre.
func build(p_args: Dictionary) -> void:
	args = p_args
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", int(UI.safe_top()))
	margin.add_theme_constant_override("margin_bottom", int(UI.safe_bottom()))
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 20)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(content)
	_build()


## À redéfinir : remplit `content`.
func _build() -> void:
	pass


## Bouton « retour » du téléphone (ou Échap) : par défaut, retour à l'accueil.
func on_back() -> void:
	Game.go_home()


## Ouvre le menu de pause par-dessus l'écran (écrans de partie en cours).
func open_pause() -> void:
	if get_node_or_null("PauseMenu") != null:
		return
	var menu := PauseMenu.new({ "screen": String(name), "args": resume_args() })
	menu.name = "PauseMenu"
	add_child(menu)


## Paramètres à redonner à cet écran quand on y revient depuis les stats ou les règles.
func resume_args() -> Dictionary:
	return args
