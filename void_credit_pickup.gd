extends Area2D

@onready var poly = $Polygon2D

func _ready():
	_setup_shimmer()
	# Spinning animation
	var t = create_tween().set_loops()
	t.tween_property(poly, "scale:x", -1.1, 0.5)
	t.tween_property(poly, "scale:x", 1.1, 0.5)
	
	# Floating
	var ft = create_tween().set_loops()
	ft.tween_property(self, "position:y", position.y - 10, 0.8).set_trans(Tween.TRANS_SINE)
	ft.tween_property(self, "position:y", position.y + 10, 0.8).set_trans(Tween.TRANS_SINE)
	
	# Sovereign Golden Radiance
	poly.color = Color(10.0, 8.0, 0.5)
	poly.modulate = Color(2.5, 2.5, 2.0, 1.0)

func _setup_shimmer():
	var p = CPUParticles2D.new()
	p.amount = 10
	p.lifetime = 0.6
	p.local_coords = false
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 8.0
	p.direction = Vector2(0, -1)
	p.gravity = Vector2(0, -60)
	p.initial_velocity_min = 15.0
	p.initial_velocity_max = 40.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.0
	var s_curve = Curve.new()
	s_curve.add_point(Vector2(0, 1.0))
	s_curve.add_point(Vector2(1, 0.0))
	p.scale_amount_curve = s_curve
	p.color = Color(8.0, 6.0, 0.5, 0.9)
	add_child(p)
	p.emitting = true

var speed = 0.0
var max_speed = 800.0
var acceleration = 2500.0
var tracking_player: Node2D = null

func _physics_process(delta: float) -> void:
	# High-Intensity Gold Pulse
	var pulse = (sin(Time.get_ticks_msec() * 0.01) * 0.2 + 1.1)
	scale = Vector2(pulse, pulse)
	
	if not is_instance_valid(tracking_player):
		var player = get_tree().get_first_node_in_group("Player")
		if is_instance_valid(player):
			var radius = 125.0
			if "magnet_radius" in player:
				radius = player.magnet_radius
			if global_position.distance_to(player.global_position) < radius:
				tracking_player = player
	else:
		var direction = global_position.direction_to(tracking_player.global_position)
		speed = min(speed + acceleration * delta, max_speed)
		global_position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("Player"):
		SaveManager.void_credits += 1
		SaveManager.save_data()
		# Visual feedback
		ShakeManager.add_trauma(0.1)
		queue_free()
