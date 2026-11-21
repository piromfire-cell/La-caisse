class_name IconView
extends Control
## Affiche une icône dessinée en code (voir UI.draw_icon pour la liste des noms).

var icon: String = "play":
	set(v):
		icon = v
		queue_redraw()

var color: Color = UI.FOAM:
	set(v):
		color = v
		queue_redraw()


func _init(p_icon: String = "play", p_size: float = 96.0, p_color: Color = UI.FOAM) -> void:
	icon = p_icon
	color = p_color
	custom_minimum_size = Vector2(p_size, p_size)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(func() -> void: pivot_offset = size / 2.0)


func _draw() -> void:
	UI.draw_icon(self, icon, Rect2(Vector2.ZERO, size), color)
