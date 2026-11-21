class_name PlayersScreen
extends BaseScreen
## Entrée des joueurs : ajouter, retirer, réordonner (flèches) et mélanger. 2 à 10 joueurs.
## Les noms sont gardés d'une partie à l'autre.

const MIN_PLAYERS := 2
const MAX_PLAYERS := 10
const MAX_NAME_LENGTH := 12

var _names: Array[String] = []
var _rows: VBoxContainer = null
var _scroll: ScrollContainer = null
var _count_label: Label = null
var _add_button: Button = null
var _start_button: Button = null
var _keyboard_pad: Control = null
## Pendant ce délai (s), on garde le champ en cours de saisie visible malgré le clavier.
var _follow_focus: float = 0.0


func _build() -> void:
	for n in Settings.players:
		_names.append(n.left(MAX_NAME_LENGTH))
	while _names.size() < 3:
		_names.append("")
	_names.resize(mini(_names.size(), MAX_PLAYERS))

	content.add_theme_constant_override("separation", 14)

	var header := HBoxContainer.new()
	content.add_child(header)
	var back := UI.icon_button("left", "ghost", 84)
	back.pressed.connect(on_back)
	header.add_child(back)
	var title := UI.label("Qui joue ?", 66, UI.AMBER, true)
	header.add_child(title)
	var balance := Control.new()
	balance.custom_minimum_size = Vector2(84, 0)
	header.add_child(balance)

	_count_label = UI.label("", 30, UI.MUTED)
	content.add_child(_count_label)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(_scroll)
	var scroll_box := VBoxContainer.new()
	scroll_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_box.add_theme_constant_override("separation", 12)
	_scroll.add_child(scroll_box)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 12)
	scroll_box.add_child(_rows)

	_add_button = UI.button("+ AJOUTER UN JOUEUR", "ghost", 36, 92)
	_add_button.pressed.connect(_on_add)
	scroll_box.add_child(_add_button)

	var shuffle := UI.button("MÉLANGER L'ORDRE", "ghost", 32, 80)
	shuffle.pressed.connect(_on_shuffle)
	scroll_box.add_child(shuffle)

	# Espace réservé au clavier virtuel (téléphone) pour qu'il ne cache pas les champs.
	_keyboard_pad = Control.new()
	scroll_box.add_child(_keyboard_pad)

	_start_button = UI.button("C'EST PARTI !", "primary", 56, 130)
	_start_button.pressed.connect(_on_start)
	content.add_child(_start_button)

	_rebuild_rows()


func _process(delta: float) -> void:
	# Hauteur du clavier virtuel, convertie en unités du jeu.
	var kb := 0.0
	if DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		kb = float(DisplayServer.virtual_keyboard_get_height())
	var win_h := float(DisplayServer.window_get_size().y)
	var pad := 0.0
	if kb > 0.0 and win_h > 0.0:
		pad = kb * get_viewport_rect().size.y / win_h
	if absf(_keyboard_pad.custom_minimum_size.y - pad) > 1.0:
		_keyboard_pad.custom_minimum_size = Vector2(0, pad)
		_follow_focus = 0.6
	if _follow_focus > 0.0:
		_follow_focus -= delta
		var focused := get_viewport().gui_get_focus_owner()
		if focused is LineEdit:
			_scroll.ensure_control_visible(focused.get_parent())


func _rebuild_rows() -> void:
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()

	for i in _names.size():
		_rows.add_child(_make_row(i))

	_count_label.text = "%d / %d joueurs · autour de la table, dans l'ordre" % [_names.size(), MAX_PLAYERS]
	_add_button.disabled = _names.size() >= MAX_PLAYERS
	_start_button.disabled = _names.size() < MIN_PLAYERS


func _make_row(i: int) -> Control:
	var panel := UI.panel(Color(0, 0, 0, 0.3), 26, Color.TRANSPARENT, 0, 10)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)

	var badge := UI.inline_label(str(i + 1), 40, UI.WOOD_DARKEST, true)
	badge.custom_minimum_size = Vector2(60, 60)
	var badge_panel := UI.panel(UI.AMBER, 30, Color.TRANSPARENT, 0, 0)
	badge_panel.custom_minimum_size = Vector2(60, 60)
	badge_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge_panel.add_child(badge)
	row.add_child(badge_panel)

	var edit := LineEdit.new()
	edit.text = _names[i]
	edit.placeholder_text = "Joueur %d" % (i + 1)
	edit.max_length = MAX_NAME_LENGTH
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.custom_minimum_size = Vector2(0, 80)
	edit.add_theme_font_override("font", UI.body_font(600))
	edit.add_theme_font_size_override("font_size", 38)
	edit.add_theme_color_override("font_color", UI.WOOD_DARKEST)
	edit.add_theme_color_override("font_placeholder_color", UI.WOOD_LIGHT.lightened(0.25))
	edit.add_theme_color_override("caret_color", UI.AMBER_DARK)
	edit.add_theme_stylebox_override("normal", UI.panel_box(UI.FOAM, 20, Color.TRANSPARENT, 0, 14))
	edit.add_theme_stylebox_override("focus", UI.panel_box(UI.FOAM, 20, UI.AMBER, 4, 14))
	edit.text_changed.connect(func(t: String) -> void: _names[i] = t)
	edit.focus_entered.connect(func() -> void: _follow_focus = 0.8)
	row.add_child(edit)

	var up := UI.icon_button("up", "ghost", 70)
	up.disabled = i == 0
	up.pressed.connect(func() -> void: _move(i, -1))
	row.add_child(up)
	var down := UI.icon_button("down", "ghost", 70)
	down.disabled = i == _names.size() - 1
	down.pressed.connect(func() -> void: _move(i, 1))
	row.add_child(down)
	var remove := UI.icon_button("close", "danger", 70)
	remove.disabled = _names.size() <= MIN_PLAYERS
	remove.pressed.connect(func() -> void: _remove(i))
	row.add_child(remove)
	return panel


func _move(i: int, delta: int) -> void:
	var j := i + delta
	if j < 0 or j >= _names.size():
		return
	var tmp := _names[i]
	_names[i] = _names[j]
	_names[j] = tmp
	_rebuild_rows()


func _remove(i: int) -> void:
	if _names.size() <= MIN_PLAYERS:
		return
	_names.remove_at(i)
	_rebuild_rows()


func _on_add() -> void:
	if _names.size() >= MAX_PLAYERS:
		return
	_names.append("")
	_rebuild_rows()
	await get_tree().process_frame
	if is_inside_tree():
		_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)


func _on_shuffle() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(_names.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := _names[i]
		_names[i] = _names[j]
		_names[j] = tmp
	_rebuild_rows()


func _on_start() -> void:
	var final_names := PlayersScreen.clean_names(_names)
	Settings.players.clear()
	for n in _names:
		Settings.players.append(n.strip_edges())
	Settings.save_settings()
	Game.new_game(final_names)


## Nettoie les noms saisis : espaces enlevés, « Joueur N » pour les champs vides,
## et suffixe « 2 », « 3 »… pour les doublons (majuscules/minuscules ignorées).
static func clean_names(raw: Array) -> Array[String]:
	var result: Array[String] = []
	var used := {}
	for i in raw.size():
		var base := str(raw[i]).strip_edges()
		if base.is_empty():
			base = "Joueur %d" % (i + 1)
		var candidate := base
		var n := 2
		while used.has(candidate.to_lower()):
			candidate = "%s %d" % [base, n]
			n += 1
		used[candidate.to_lower()] = true
		result.append(candidate)
	return result
