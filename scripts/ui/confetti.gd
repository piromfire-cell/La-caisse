class_name Confetti
extends RefCounted
## Petite explosion de confettis (couleurs bière/fête). Usage : Confetti.burst(parent, position).


## Lance un jet de confettis depuis `position` (dans le repère de `parent`).
static func burst(parent: Node, position: Vector2, amount: int = 90) -> void:
	var p := CPUParticles2D.new()
	p.position = position
	p.amount = amount
	p.lifetime = 2.4
	p.one_shot = true
	p.explosiveness = 0.96
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(200, 8)
	p.direction = Vector2(0, -1)
	p.spread = 62.0
	p.initial_velocity_min = 480.0
	p.initial_velocity_max = 980.0
	p.gravity = Vector2(0, 1500)
	p.angular_velocity_min = -420.0
	p.angular_velocity_max = 420.0
	p.scale_amount_min = 10.0
	p.scale_amount_max = 22.0
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([UI.AMBER, UI.AMBER_LIGHT, UI.FOAM, UI.RED, UI.GREEN])
	ramp.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
	ramp.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	p.color_initial_ramp = ramp
	p.z_index = 50
	parent.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)
