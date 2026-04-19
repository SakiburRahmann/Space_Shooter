extends CharacterBody2D

var SPEED = 130.0
var hp = 20
var contact_damage = 10
@onready var player = get_tree().get_first_node_in_group("Player")
var bullet_scene = preload("res://enemy_bullet.tscn")
var death_particles_scene = preload("res://death_particles.tscn")
var xp_gem_scene = preload("res://xp_gem.tscn")
var credit_scene = preload("res://void_credit_pickup.tscn")
var fire_timer = 2.0
var fire_rate = 2.5

func _ready():
	add_to_group("Enemy")
	var mult = 1.0
	if "GameManager" in self and GameManager.get("enemy_hp_mult"): mult = GameManager.enemy_hp_mult
	hp = int(hp * mult)
	$ProceduralEnemy.setup("sniper", Color(1.0, 3.5, 8.0)) # Ice Blue Sniper
	$CollisionPolygon2D.polygon = $ProceduralEnemy.get_hull_points()

func _physics_process(delta: float):
	if is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		look_at(player.global_position)
		
		var separation = _get_separation_vector()
		
		if dist > 450:
			var move_dir = global_position.direction_to(player.global_position)
			velocity = (move_dir + separation * 1.5).normalized() * SPEED
			$ProceduralEnemy.is_moving = true
		elif dist < 300:
			var move_dir = global_position.direction_to(player.global_position) * -1
			velocity = (move_dir + separation * 1.5).normalized() * SPEED
			$ProceduralEnemy.is_moving = true
		else:
			velocity = separation * SPEED * 0.5
			$ProceduralEnemy.is_moving = false
			
		move_and_slide()
		
		# Shooting logic
		fire_timer -= delta
		if fire_timer <= 0 and dist < 750:
			if bullet_scene != null:
				var b = bullet_scene.instantiate()
				var muzzle = $ProceduralEnemy.muzzle_port if has_node("ProceduralEnemy") else Vector2(40, 0)
				b.global_position = global_position + muzzle.rotated(global_rotation)
				b.global_rotation = global_rotation
				if b.has_method("setup_color"):
					b.setup_color($ProceduralEnemy.accent_color)
				get_parent().add_child(b)
				fire_timer = fire_rate

func take_damage(amount: int):
	hp -= amount
	if hp <= 0: die()

func die():
	GameManager.register_kill()
	if death_particles_scene != null:
		var explosion = death_particles_scene.instantiate()
		explosion.global_position = global_position
		get_parent().call_deferred("add_child", explosion)
	var drop_chance = 0.40 * max(0.2, 2.5 * pow(0.85, GameManager.current_wave - 1))
	if randf() < drop_chance: _spawn_random_drop()
	queue_free()

func _spawn_random_drop():
	var roll = randf()
	if roll < 0.8:
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

func _get_separation_vector() -> Vector2:
	var sep = Vector2.ZERO
	var count = 0
	for n in get_tree().get_nodes_in_group("Enemy"):
		if is_instance_valid(n) and n != self:
			var d = global_position.distance_to(n.global_position)
			if d < 50.0 and d > 0.1:
				sep += (global_position - n.global_position).normalized() / (d / 50.0)
				count += 1
				if count > 6: break
	return sep.limit_length(1.0)
