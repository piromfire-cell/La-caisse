extends Control
## Écran-hôte : dessine le fond de bois et affiche un écran à la fois dans une colonne
## centrale (sur un grand écran ou dans un navigateur de bureau, le jeu garde des
## proportions de téléphone).

const SCREENS := {
	"home": preload("res://scripts/screens/home_screen.gd"),
	"players": preload("res://scripts/screens/players_screen.gd"),
	"pass": preload("res://scripts/screens/pass_screen.gd"),
	"dice": preload("res://scripts/screens/dice_screen.gd"),
	"announce": preload("res://scripts/screens/announce_screen.gd"),
	"decide": preload("res://scripts/screens/decide_screen.gd"),
	"reveal": preload("res://scripts/screens/reveal_screen.gd"),
	"stats": preload("res://scripts/screens/stats_screen.gd"),
	"rules": preload("res://scripts/screens/rules_screen.gd"),
	"settings": preload("res://scripts/screens/settings_screen.gd"),
}

## Largeur maximale de la colonne de jeu, en proportion de la hauteur de l'écran.
const MAX_WIDTH_RATIO := 0.62
## Après un changement d'écran, on ignore les touches pendant ce délai (évite les doubles taps
## qui feraient sauter un écran « passe le téléphone »).
const INPUT_LOCK_SECONDS := 0.45

var _stage: Control = null
var _blocker: Control = null
var _current: BaseScreen = null
var _lock_timer: SceneTreeTimer = null


func _ready() -> void:
	Game.host = self
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(WoodBackground.new())

	_stage = Control.new()
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)

	# Voile invisible qui bloque les touches juste après un changement d'écran.
	_blocker = Control.new()
	_blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	_blocker.visible = false
	_blocker.z_index = 100
	add_child(_blocker)

	get_viewport().size_changed.connect(_layout)
	_layout()
	DisplayServer.screen_set_keep_on(true)  # l'écran ne s'éteint pas pendant la partie
	show_screen("home")


## Remplace l'écran affiché par `id`.
func show_screen(id: String, args: Dictionary = {}) -> void:
	if not SCREENS.has(id):
		push_error("Écran inconnu : %s" % id)
		return
	if _current != null:
		_current.queue_free()
		_current = null
	var screen: BaseScreen = SCREENS[id].new()
	screen.name = id
	_stage.add_child(screen)
	screen.build(args)
	_current = screen
	screen.modulate.a = 0.0
	screen.create_tween().tween_property(screen, "modulate:a", 1.0, 0.18)
	_lock_input()


func current_screen() -> BaseScreen:
	return _current


func _lock_input() -> void:
	_blocker.visible = true
	_lock_timer = get_tree().create_timer(INPUT_LOCK_SECONDS)
	_lock_timer.timeout.connect(func() -> void: _blocker.visible = false)


## Centre la colonne de jeu et limite sa largeur sur les grands écrans.
func _layout() -> void:
	var vp := get_viewport_rect().size
	var w := minf(vp.x, vp.y * MAX_WIDTH_RATIO)
	_stage.position = Vector2((vp.x - w) / 2.0, 0.0)
	_stage.size = Vector2(w, vp.y)


func _notification(what: int) -> void:
	# Bouton « retour » d'Android.
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and _current != null:
		_current.on_back()


func _unhandled_input(event: InputEvent) -> void:
	# Échap sur ordinateur / navigateur = retour.
	if event.is_action_pressed("ui_cancel") and _current != null:
		_current.on_back()
		get_viewport().set_input_as_handled()
