extends Area2D

const BASE_SPEED = 800.0
var damage = 5
var piercing = false
var homing = false
var explosive = false
var chain_lightning = false
var explosion_radius = 80.0
var speed_mult = 1.0
var burn_damage = 0
var has_reaper = false
var knockback_force = 0.0
var has_freeze = false

func _ready():
	_setup_thrust_particles()
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(self):
		queue_free()

func _setup_thrust_particles():
	var p = CPUParticles2D.new()
	p.amount = 25
	p.lifetime = 0.2
	p.local_coords = false # Inertial Trails
	p.direction = Vector2(-1, 0)
	p.spread = 15.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 200.0
	p.initial_velocity_max = 400.0
	
	# Sovereign Visuals: White-Hot Fire
	p.scale_amount_min = 3.0
	p.scale_amount_max = 6.0
	var ramp = Gradient.new()
	ramp.set_color(0, Color.WHITE)
	ramp.set_color(1, Color(1.5, 0.4, 0.1, 0.0)) # Fading Orange Fire
	p.color_ramp = ramp
	
	add_child(p)
	p.emitting = true
	
	# Pure White Missile Body
	modulate = Color(2.0, 2.0, 2.0)

func _physics_process(delta: float) -> void:
	if homing:
		var closest: Node2D = null
		var closest_dist = 500.0
		for enemy in get_tree().get_nodes_in_group("Enemy"):
			if is_instance_valid(enemy):
				var d = global_position.distance_to(enemy.global_position)
				if d < closest_dist:
					closest_dist = d
					closest = enemy
		if closest:
			var desired_angle = (closest.global_position - global_position).angle()
			global_rotation = lerp_angle(global_rotation, desired_angle, 6.0 * delta)
	
	position += transform.x * BASE_SPEED * speed_mult * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		
		# Knockback
		if knockback_force > 0 and is_instance_valid(body):
			var kb_dir = global_position.direction_to(body.global_position)
			body.velocity += kb_dir * knockback_force * 50.0
		
		# Burn DOT
		if burn_damage > 0 and is_instance_valid(body) and body.has_method("apply_burn"):
			body.apply_burn(burn_damage)
		
		# Freeze Status
		if has_freeze and is_instance_valid(body) and body.has_method("apply_freeze"):
			body.apply_freeze(2.5)
		
		# Chain lightning
		if chain_lightning:
			var nearest: Node2D = null
			var nearest_dist = 200.0
			for enemy in get_tree().get_nodes_in_group("Enemy"):
				if is_instance_valid(enemy) and enemy != body:
					var d = body.global_position.distance_to(enemy.global_position)
					if d < nearest_dist:
						nearest_dist = d
						nearest = enemy
			if nearest and nearest.has_method("take_damage"):
				nearest.take_damage(int(damage * 0.5))
		
		# Explosive AOE
		if explosive:
			for enemy in get_tree().get_nodes_in_group("Enemy"):
				if is_instance_valid(enemy) and enemy != body:
					if body.global_position.distance_to(enemy.global_position) < explosion_radius:
						if enemy.has_method("take_damage"):
							enemy.take_damage(int(damage * 0.4))
		
		# Reaper - enemy explodes on death
		if has_reaper and is_instance_valid(body) and body.hp <= 0:
			for enemy in get_tree().get_nodes_in_group("Enemy"):
				if is_instance_valid(enemy) and enemy != body:
					if body.global_position.distance_to(enemy.global_position) < 100:
						if enemy.has_method("take_damage"):
							enemy.take_damage(3)
		
		# Lifesteal trigger
		if is_instance_valid(body) and body.hp <= 0:
			var player = get_tree().get_first_node_in_group("Player")
			if is_instance_valid(player) and player.has_method("on_enemy_killed"):
				player.on_enemy_killed()
		
		if not piercing:
			queue_free()
