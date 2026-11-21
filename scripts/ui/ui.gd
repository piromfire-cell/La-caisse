class_name UI
extends RefCounted
## « Boîte à outils » visuelle : palette de couleurs, polices, fabriques de boutons/étiquettes
## et petites icônes dessinées en code (aucun emoji : ils ne s'affichent pas partout).
##
## Pour changer le look du jeu, c'est ici (couleurs, polices, style des boutons).

# ── Palette « bar / bière » ───────────────────────────────────────────────────
const WOOD_DARKEST := Color("1d0f06")
const WOOD_DARK := Color("2a160a")
const WOOD := Color("4a2c17")
const WOOD_LIGHT := Color("6e4325")
const AMBER := Color("f5a623")
const AMBER_DARK := Color("b8730a")
const AMBER_LIGHT := Color("ffd36b")
const FOAM := Color("fff8e1")
const FOAM_SHADE := Color("e6d9b4")
const RED := Color("d9453b")
const RED_DARK := Color("8f2620")
const GREEN := Color("5bb04a")
const GREEN_DARK := Color("367a2b")
const MUTED := Color("cbb68d")

## Styles de boutons : [couleur de fond, couleur du « rebord » 3D, couleur du texte].
const BUTTON_KINDS := {
	"primary": [AMBER, AMBER_DARK, WOOD_DARKEST],
	"danger": [RED, RED_DARK, FOAM],
	"good": [GREEN, GREEN_DARK, FOAM],
	"ghost": [WOOD_LIGHT, WOOD_DARK, FOAM],
	"foam": [FOAM, FOAM_SHADE, WOOD_DARKEST],
	"gold": [AMBER_LIGHT, AMBER_DARK, WOOD_DARKEST],
}

const FONT_DISPLAY_PATH := "res://assets/fonts/LilitaOne-Regular.ttf"
const FONT_BODY_PATH := "res://assets/fonts/Fredoka.ttf"
## Étiquette OpenType de l'axe « wght » (poids) d'une police variable.
const AXIS_WEIGHT := 2003265652

static var _display_font: Font = null
static var _body_fonts: Dictionary = {}


## Police des titres et des boutons (grasse, ronde, festive).
static func display_font() -> Font:
	if _display_font == null:
		_display_font = load(FONT_DISPLAY_PATH)
	return _display_font


## Police du texte courant ; `weight` de 300 (léger) à 700 (gras).
static func body_font(weight: int = 500) -> Font:
	if not _body_fonts.has(weight):
		var variation := FontVariation.new()
		variation.base_font = load(FONT_BODY_PATH)
		variation.variation_opentype = { AXIS_WEIGHT: weight }
		_body_fonts[weight] = variation
	return _body_fonts[weight]


# ── Étiquettes ────────────────────────────────────────────────────────────────

## Crée une étiquette de texte (retour à la ligne automatique, centrée par défaut).
static func label(text: String, size: int = 34, color: Color = FOAM, display: bool = false,
		align: int = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align as HorizontalAlignment
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", display_font() if display else body_font(500))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


## Étiquette qui garde sa taille naturelle (pas de retour à la ligne, centrée dans son parent).
## À utiliser pour les textes courts placés dans une rangée (HBoxContainer).
static func inline_label(text: String, size: int = 34, color: Color = FOAM, display: bool = false) -> Label:
	var l := label(text, size, color, display)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return l


## Ajoute un contour (et une ombre) à une étiquette pour la rendre lisible de loin.
static func outline(l: Label, color: Color, width: int = 10, shadow: bool = true) -> void:
	l.add_theme_constant_override("outline_size", width)
	l.add_theme_color_override("font_outline_color", color)
	if shadow:
		l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.4))
		l.add_theme_constant_override("shadow_offset_x", 0)
		l.add_theme_constant_override("shadow_offset_y", 6)


## Réduit la taille de police pour que `text` tienne dans `max_width`.
static func fit_font_size(text: String, font: Font, base_size: int, max_width: float, min_size: int = 36) -> int:
	var s := base_size
	while s > min_size and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x > max_width:
		s -= 4
	return s


# ── Boutons ───────────────────────────────────────────────────────────────────

## Gros bouton 3D. `kind` : "primary", "danger", "good", "ghost", "foam" ou "gold".
static func button(text: String, kind: String = "primary", font_size: int = 46, min_height: int = 112) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, min_height)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_override("font", display_font())
	b.add_theme_font_size_override("font_size", font_size)
	apply_button_style(b, kind)
	b.pressed.connect(func() -> void: Sfx.play("click"))
	return b


## (Re)applique l'apparence d'un type de bouton — sert aussi à marquer un choix « sélectionné ».
static func apply_button_style(b: Button, kind: String) -> void:
	var c: Array = BUTTON_KINDS[kind]
	var fill: Color = c[0]
	var edge: Color = c[1]
	var text_color: Color = c[2]
	b.add_theme_stylebox_override("normal", _button_box(fill, edge, 10))
	b.add_theme_stylebox_override("hover", _button_box(fill.lightened(0.05), edge, 10))
	b.add_theme_stylebox_override("pressed", _button_box(fill.darkened(0.08), edge, 3))
	b.add_theme_stylebox_override("disabled", _button_box(fill.lerp(WOOD, 0.7), edge.lerp(WOOD_DARK, 0.7), 10))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", text_color)
	b.add_theme_color_override("font_hover_color", text_color)
	b.add_theme_color_override("font_pressed_color", text_color)
	b.add_theme_color_override("font_focus_color", text_color)
	b.add_theme_color_override("font_disabled_color", text_color.lerp(WOOD, 0.55))


static func _button_box(fill: Color, edge: Color, depth: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(30)
	sb.border_width_bottom = depth
	sb.border_color = edge
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 8 + (10 - depth)
	sb.content_margin_bottom = 8 + depth
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 8 if depth > 3 else 3
	sb.shadow_offset = Vector2(0, 6 if depth > 3 else 2)
	sb.anti_aliasing = true
	return sb


## Petit bouton carré avec une icône dessinée (flèches, croix, menu…).
static func icon_button(icon_name: String, kind: String = "ghost", size: int = 76) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(size, size)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	apply_button_style(b, kind)
	var color: Color = BUTTON_KINDS[kind][2]
	var pad := size * 0.2
	b.draw.connect(func() -> void:
		var tint := color if not b.disabled else color.lerp(WOOD, 0.6)
		draw_icon(b, icon_name, Rect2(Vector2(pad, pad * 0.8), b.size - Vector2(pad, pad) * 2.0), tint))
	b.pressed.connect(func() -> void: Sfx.play("click"))
	return b


# ── Panneaux ──────────────────────────────────────────────────────────────────

static func panel_box(fill: Color = Color(0, 0, 0, 0.28), radius: int = 28, border: Color = Color.TRANSPARENT,
		border_width: int = 0, margin: int = 22) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(border_width)
	sb.border_color = border
	sb.set_content_margin_all(margin)
	sb.anti_aliasing = true
	return sb


static func panel(fill: Color = Color(0, 0, 0, 0.28), radius: int = 28, border: Color = Color.TRANSPARENT,
		border_width: int = 0, margin: int = 22) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", panel_box(fill, radius, border, border_width, margin))
	return p


## Espace vide qui s'étire (pousse le reste vers le haut/bas). `weight` règle la part d'espace.
static func spacer(weight: float = 1.0) -> Control:
	var c := Control.new()
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.size_flags_stretch_ratio = weight
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


## Espace vide de hauteur fixe.
static func gap(height: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


# ── Zones sûres (encoche, barre de navigation) ────────────────────────────────

## Marge haute à respecter (en unités du jeu) pour ne pas passer sous l'encoche.
static func safe_top() -> float:
	return maxf(40.0, _safe_inset(true))


static func safe_bottom() -> float:
	return maxf(36.0, _safe_inset(false))


static func _safe_inset(top: bool) -> float:
	var win := DisplayServer.window_get_size()
	if win.y <= 0:
		return 0.0
	var safe := DisplayServer.get_display_safe_area()
	var screen := DisplayServer.screen_get_size()
	if safe.size.y <= 0 or screen.y <= 0:
		return 0.0
	var px := float(safe.position.y) if top else float(screen.y - safe.end.y)
	var vp_h := 1280.0
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		vp_h = tree.root.get_visible_rect().size.y
	return maxf(0.0, px * vp_h / float(win.y))


# ── Icônes dessinées en code ──────────────────────────────────────────────────

## Dessine l'icône `icon_name` dans `rect` sur le CanvasItem `ci` (à appeler depuis un _draw).
## Icônes : up, down, left, close, plus, minus, menu, check, play, gear, book, eye, phone,
## magnifier, bubble, crown, mug.
static func draw_icon(ci: CanvasItem, icon_name: String, rect: Rect2, color: Color) -> void:
	var w := maxf(3.0, rect.size.x * 0.11)
	var p := func(x: float, y: float) -> Vector2:
		return rect.position + Vector2(x * rect.size.x, y * rect.size.y)
	match icon_name:
		"up":
			ci.draw_polyline(PackedVector2Array([p.call(0.15, 0.7), p.call(0.5, 0.3), p.call(0.85, 0.7)]), color, w, true)
		"down":
			ci.draw_polyline(PackedVector2Array([p.call(0.15, 0.3), p.call(0.5, 0.7), p.call(0.85, 0.3)]), color, w, true)
		"left":
			ci.draw_polyline(PackedVector2Array([p.call(0.65, 0.12), p.call(0.3, 0.5), p.call(0.65, 0.88)]), color, w, true)
		"close":
			ci.draw_line(p.call(0.2, 0.2), p.call(0.8, 0.8), color, w, true)
			ci.draw_line(p.call(0.8, 0.2), p.call(0.2, 0.8), color, w, true)
		"plus":
			ci.draw_line(p.call(0.5, 0.15), p.call(0.5, 0.85), color, w, true)
			ci.draw_line(p.call(0.15, 0.5), p.call(0.85, 0.5), color, w, true)
		"minus":
			ci.draw_line(p.call(0.15, 0.5), p.call(0.85, 0.5), color, w, true)
		"menu":
			for y in [0.25, 0.5, 0.75]:
				ci.draw_line(p.call(0.12, y), p.call(0.88, y), color, w, true)
		"check":
			ci.draw_polyline(PackedVector2Array([p.call(0.12, 0.55), p.call(0.4, 0.82), p.call(0.88, 0.22)]), color, w * 1.2, true)
		"play":
			ci.draw_colored_polygon(PackedVector2Array([p.call(0.25, 0.1), p.call(0.25, 0.9), p.call(0.88, 0.5)]), color)
		"gear":
			var c: Vector2 = p.call(0.5, 0.5)
			var r := rect.size.x * 0.24
			ci.draw_arc(c, r, 0.0, TAU, 32, color, w * 1.1, true)
			for i in 8:
				var a := TAU * i / 8.0
				ci.draw_line(c + Vector2.from_angle(a) * r * 1.3, c + Vector2.from_angle(a) * r * 1.85, color, w * 1.3, true)
		"book":
			var left := PackedVector2Array([p.call(0.08, 0.22), p.call(0.48, 0.3), p.call(0.48, 0.85), p.call(0.08, 0.77)])
			var right := PackedVector2Array([p.call(0.92, 0.22), p.call(0.52, 0.3), p.call(0.52, 0.85), p.call(0.92, 0.77)])
			ci.draw_colored_polygon(left, color)
			ci.draw_colored_polygon(right, color)
		"eye":
			var pts := PackedVector2Array()
			for i in 17:
				var t := i / 16.0
				pts.append(p.call(0.05 + 0.9 * t, 0.5 - 0.3 * sin(PI * t)))
			for i in 17:
				var t := i / 16.0
				pts.append(p.call(0.95 - 0.9 * t, 0.5 + 0.3 * sin(PI * t)))
			ci.draw_polyline(pts, color, w, true)
			ci.draw_circle(p.call(0.5, 0.5), rect.size.x * 0.13, color)
		"phone":
			var body := Rect2(p.call(0.28, 0.05), rect.size * Vector2(0.44, 0.9))
			ci.draw_rect(body, color, false, w)
			ci.draw_line(p.call(0.42, 0.15), p.call(0.58, 0.15), color, w * 0.7, true)
			ci.draw_circle(p.call(0.5, 0.82), rect.size.x * 0.045, color)
		"magnifier":
			ci.draw_arc(p.call(0.42, 0.42), rect.size.x * 0.28, 0.0, TAU, 32, color, w * 1.1, true)
			ci.draw_line(p.call(0.63, 0.63), p.call(0.9, 0.9), color, w * 1.5, true)
		"bubble":
			var bub := PackedVector2Array([p.call(0.1, 0.15), p.call(0.9, 0.15), p.call(0.9, 0.65), p.call(0.55, 0.65),
				p.call(0.3, 0.9), p.call(0.34, 0.65), p.call(0.1, 0.65)])
			ci.draw_colored_polygon(bub, color)
		"crown":
			var crown := PackedVector2Array([p.call(0.1, 0.78), p.call(0.05, 0.28), p.call(0.3, 0.5), p.call(0.5, 0.15),
				p.call(0.7, 0.5), p.call(0.95, 0.28), p.call(0.9, 0.78)])
			ci.draw_colored_polygon(crown, color)
		"mug":
			var body := PackedVector2Array([p.call(0.12, 0.3), p.call(0.64, 0.3), p.call(0.6, 0.92), p.call(0.16, 0.92)])
			ci.draw_colored_polygon(body, color)
			ci.draw_arc(p.call(0.72, 0.6), rect.size.x * 0.15, -PI / 2.0, PI / 2.0, 16, color, w * 0.9, true)
			# mousse : trois bulles au-dessus du verre
			ci.draw_circle(p.call(0.22, 0.24), rect.size.x * 0.12, color)
			ci.draw_circle(p.call(0.38, 0.17), rect.size.x * 0.14, color)
			ci.draw_circle(p.call(0.54, 0.24), rect.size.x * 0.12, color)
		_:
			push_warning("Icône inconnue : %s" % icon_name)
