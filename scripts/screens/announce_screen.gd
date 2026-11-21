extends BaseScreen
## Choix de l'annonce : une grille avec UNIQUEMENT les résultats permis (plus forts que la
## dernière annonce). Un petit point discret marque le vrai résultat du joueur (réglable).
## On touche un résultat, puis on confirme avec le gros bouton du bas.

var _selected: int = Dice.NONE
var _tiles: Dictionary = {}
var _tile_kinds: Dictionary = {}
var _confirm: Button = null


func _build() -> void:
	var s := Game.session
	var options := s.valid_announcements()

	content.add_theme_constant_override("separation", 14)
	var player := s.current_name()
	var title := UI.label("%s, annonce !" % player, 58, UI.AMBER, true)
	title.add_theme_font_size_override("font_size", UI.fit_font_size("%s, annonce !" % player, UI.display_font(), 58, 640.0, 36))
	content.add_child(title)

	if s.has_announcement():
		content.add_child(UI.label("Tu dois faire plus fort que %s" % Dice.long_label(s.announced), 32, UI.AMBER_LIGHT))
	else:
		content.add_child(UI.label("Tu ouvres la manche : tout est permis !", 32, UI.AMBER_LIGHT))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)

	var normals: Array[int] = []
	var mousses: Array[int] = []
	var has_caisse := false
	for v in options:
		match Dice.category(v):
			Dice.Category.NORMAL: normals.append(v)
			Dice.Category.MOUSSE: mousses.append(v)
			_: has_caisse = true

	if not normals.is_empty():
		_add_section(list, "RÉSULTATS NORMAUX", normals, 4, "ghost")
	if not mousses.is_empty():
		_add_section(list, "MOUSSES (DOUBLES)", mousses, 3, "foam")
	if has_caisse:
		_add_section(list, "LE PLUS FORT DE TOUS", [Dice.CAISSE] as Array[int], 1, "gold")

	_confirm = UI.button("CHOISIS UN RÉSULTAT", "primary", 46, 124)
	_confirm.disabled = true
	_confirm.pressed.connect(func() -> void: Game.announce(_selected))
	content.add_child(_confirm)

	# S'il n'y a qu'un seul choix possible (ex. LA CAISSE après un 66), on le présélectionne.
	if options.size() == 1:
		_select(options[0])


func _add_section(parent: Control, heading: String, values: Array[int], columns: int, kind: String) -> void:
	parent.add_child(UI.label(heading, 26, UI.MUTED))
	var grid := GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(grid)
	for v in values:
		var text := "LA CAISSE  (21)" if v == Dice.CAISSE else str(v)
		var tile := UI.button(text, kind, 58 if v != Dice.CAISSE else 52, 116)
		tile.pressed.connect(func() -> void: _select(v))
		# Point discret = le vrai résultat de CE joueur.
		if Settings.show_hint:
			tile.draw.connect(func() -> void:
				if v == Game.session.real_value:
					tile.draw_circle(Vector2(tile.size.x - 20.0, 20.0), 9.0, UI.WOOD_DARKEST)
					tile.draw_circle(Vector2(tile.size.x - 20.0, 20.0), 6.0, UI.AMBER_LIGHT))
		grid.add_child(tile)
		_tiles[v] = tile
		_tile_kinds[v] = kind


func _select(value: int) -> void:
	if _selected != Dice.NONE and _tiles.has(_selected):
		UI.apply_button_style(_tiles[_selected], _tile_kinds[_selected])
	_selected = value
	UI.apply_button_style(_tiles[value], "primary")
	Sfx.play("tick")
	_confirm.disabled = false
	_confirm.text = "ANNONCER LA CAISSE" if value == Dice.CAISSE else "ANNONCER %d" % value


func on_back() -> void:
	open_pause()
