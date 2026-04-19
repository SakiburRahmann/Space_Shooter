extends Area2D

var value = 1
var node_color = ""
var speed = 0.0
var max_speed = 800.0
var acceleration = 2500.0
var tracking_player: Node2D = null
var magnet_radius = 125.0

@onready var poly = $Polygon2D

func _ready():
	add_to_group("Gems")
	_setup_shimmer()

var shimmer_emitter: CPUParticles2D

func _setup_shimmer():
	var p = CPUParticles2D.new()
	p.amount = 10
	p.lifetime = 0.5
	p.local_coords = false
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.gravity = Vector2(0, -20)
	p.initial_velocity_min = 15.0
	p.initial_velocity_max = 40.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.0
	var s_curve = Curve.new()
	s_curve.add_point(Vector2(0, 1.0))
	s_curve.add_point(Vector2(1, 0.0))
	p.scale_amount_curve = s_curve
	add_child(p)
	p.emitting = true
	p.color = Color(2.5, 2.5, 3.0)
	shimmer_emitter = p

func setup(msg_color: String):
	node_color = msg_color
	if node_color == "RED":
		poly.color = Color(8.0, 0.4, 0.4)
		if shimmer_emitter: shimmer_emitter.color = Color(6.0, 0.5, 0.5)
	elif node_color == "BLUE":
		poly.color = Color(0.4, 0.8, 10.0)
		if shimmer_emitter: shimmer_emitter.color = Color(0.5, 1.0, 8.0)
	else:
		poly.color = Color(0.4, 8.0, 0.4)
		if shimmer_emitter: shimmer_emitter.color = Color(0.5, 6.0, 0.5)
	poly.modulate = Color(2.0, 2.0, 2.0)

func _physics_process(delta: float) -> void:
	# Sin-Wave Pulse: Loot feels alive
	var pulse = (sin(Time.get_ticks_msec() * 0.008) * 0.5 + 1.2)
	poly.scale = Vector2(pulse, pulse)
	poly.modulate.a = clamp(pulse, 0.8, 1.0)
	
	if not is_instance_valid(tracking_player):
		var player = get_tree().get_first_node_in_group("Player")
		if is_instance_valid(player):
			var radius = magnet_radius
			if "magnet_radius" in player:
				radius = player.magnet_radius
			var dist = global_position.distance_to(player.global_position)
			if dist < radius:
				tracking_player = player
	else:
		var direction = global_position.direction_to(tracking_player.global_position)
		speed = min(speed + acceleration * delta, max_speed)
		global_position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		GameManager.collect_node(node_color)
		queue_free()
