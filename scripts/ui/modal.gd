class_name Modal
extends Control
## Fenêtre qui s'affiche par-dessus un écran : fond assombri + panneau centré.
## Les autres écrans de ce type (avertissement, pause) héritent de celui-ci et
## remplissent `box`.

## Colonne verticale du panneau, à remplir.
var box: VBoxContainer = null
var _panel: PanelContainer = null


func _init(panel_width: float = 620.0) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 20

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = UI.panel(UI.WOOD_DARK, 36, UI.AMBER, 4, 32)
	_panel.custom_minimum_size = Vector2(panel_width, 0)
	center.add_child(_panel)

	box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	_panel.add_child(box)


## Vide le panneau (pour afficher une autre « page » dans la même fenêtre).
func clear_box() -> void:
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()


func close() -> void:
	queue_free()
