extends CharacterBody2D

var SPEED = 150.0
var hp = 10
var contact_damage = 10
@onready var player = get_tree().get_first_node_in_group("Player")
var death_particles_scene = preload("res://death_particles.tscn")
var xp_gem_scene = preload("res://xp_gem.tscn")
var credit_scene = preload("res://void_credit_pickup.tscn")

# === SOVEREIGN STATUS ENGINE ===
var is_frozen = false
var freeze_timer = 0.0
var is_burning = false
var burn_timer = 0.0
var burn_tick_timer = 0.0
var is_linked = false

func _ready():
	add_to_group("Enemy")
	var mult = 1.0
	if Engine.has_singleton("GameManager") or get_node_or_null("/root/GameManager") != null:
		mult = GameManager.enemy_hp_mult
	hp = int(hp * mult)
	if has_node("ProceduralEnemy"):
		$ProceduralEnemy.setup("basic", Color(3.5, 0.2, 0.2)) # Crimson Grunt

func _physics_process(delta: float):
	if is_instance_valid(player):
		var current_speed = SPEED
		if is_frozen: current_speed *= 0.4
		
		var move_dir = global_position.direction_to(player.global_position)
		var separation = _get_separation_vector()
		
		# Sovereign Steering: Blend target tracking with tactical separation
		velocity = (move_dir + separation * 1.5).normalized() * current_speed
		look_at(player.global_position)
		move_and_slide()
		
		if has_node("ProceduralEnemy"):
			$ProceduralEnemy.is_moving = velocity.length() > 0.1
		
		_process_statuses(delta)
		
		for i in get_slide_collision_count():
			var col = get_slide_collision(i)
			if col.get_collider() == player:
				if player.has_method("take_damage"):
					player.take_damage(contact_damage)

func _get_separation_vector() -> Vector2:
	var separation = Vector2.ZERO
	var neighbors = get_tree().get_nodes_in_group("Enemy")
	var neighbor_count = 0
	var separation_radius = 50.0
	
	for neighbor in neighbors:
		if is_instance_valid(neighbor) and neighbor != self:
			var dist = global_position.distance_to(neighbor.global_position)
			if dist < separation_radius and dist > 0.1:
				# Repulse with inverse square law for smooth tactical spacing
				var diff = global_position - neighbor.global_position
				separation += diff.normalized() / (dist / separation_radius)
				neighbor_count += 1
				if neighbor_count > 6: break # Performance cap
				
	return separation.limit_length(1.0)

func apply_burn(_dmg: int):
	is_burning = true
	burn_timer = 3.0
	
func apply_freeze(dur: float):
	is_frozen = true
	freeze_timer = dur

func apply_stun(duration: float):
	apply_freeze(duration)

func _process_statuses(delta):
	if is_frozen:
		modulate.b = 2.0
		freeze_timer -= delta
		if freeze_timer <= 0:
			is_frozen = false
			modulate.b = 1.0
			
	if is_burning:
		modulate.r = 2.0
		burn_timer -= delta
		burn_tick_timer += delta
		if burn_tick_timer >= 0.5:
			take_damage(2) # DOT
			burn_tick_timer = 0.0
			if player and player.get("has_nitro"):
				_trigger_nitro_pulse()
		if burn_timer <= 0:
			is_burning = false
			modulate.r = 1.0

func _trigger_nitro_pulse():
	var blast_radius = 80.0
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if is_instance_valid(enemy) and enemy != self:
			if global_position.distance_to(enemy.global_position) < blast_radius:
				enemy.take_damage(5)
	ShakeManager.add_trauma(0.2)

func take_damage(amount: int):
	hp -= amount
	if hp <= 0:
		die()

func die():
	GameManager.register_kill()
	
	if is_frozen and player and player.get("has_shatter_frost"):
		_trigger_shatter_explosion()
		
	if death_particles_scene != null:
		var explosion = death_particles_scene.instantiate()
		explosion.global_position = global_position
		get_parent().call_deferred("add_child", explosion)
	
	var drop_chance = 0.40 * max(0.2, 2.5 * pow(0.85, GameManager.current_wave - 1))
	if randf() < drop_chance and not GameManager.is_wave_clearing:
		_spawn_random_drop()
		
	queue_free()

func _trigger_shatter_explosion():
	var blast_radius = 200.0
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if is_instance_valid(enemy) and enemy != self:
			if global_position.distance_to(enemy.global_position) < blast_radius:
				enemy.take_damage(20)
	ShakeManager.add_trauma(0.5)

func _spawn_random_drop():
	var roll = randf()
	if roll < 0.75:
		if xp_gem_scene != null:
			var gem = xp_gem_scene.instantiate()
			gem.global_position = global_position
			get_parent().call_deferred("add_child", gem)
			var colors = ["RED", "BLUE", "GREEN"]
			gem.call_deferred("setup", colors[randi() % 3])
	else:
		if credit_scene != null:
			var c = credit_scene.instantiate()
			c.global_position = global_position
			get_parent().call_deferred("add_child", c)
