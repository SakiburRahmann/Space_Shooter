extends CharacterBody2D

var SPEED = 230.0
var hp = 10
var contact_damage = 15
var zigzag_dir = 1
var zigzag_timer = 0.0
@onready var player = get_tree().get_first_node_in_group("Player")
var death_particles_scene = preload("res://death_particles.tscn")
var xp_gem_scene = preload("res://xp_gem.tscn")
var credit_scene = preload("res://void_credit_pickup.tscn")

func _ready():
	add_to_group("Enemy")
	var mult = 1.0
	if "GameManager" in self and GameManager.get("enemy_hp_mult"): mult = GameManager.enemy_hp_mult
	hp = int(hp * mult)
	$ProceduralEnemy.setup("zigzag", Color(6.0, 5.0, 0.2)) # Electric Yellow ZigZag
	$CollisionPolygon2D.polygon = $ProceduralEnemy.get_hull_points()

func _physics_process(delta: float):
	if is_instance_valid(player):
		var dir = global_position.direction_to(player.global_position)
		var separation = _get_separation_vector()
		zigzag_timer += delta
		if zigzag_timer > 0.4:
			zigzag_timer = 0.0
			zigzag_dir *= -1
		var side_dir = dir.rotated(PI/2) * zigzag_dir * 150.0
		velocity = (dir + separation * 1.5).normalized() * SPEED + side_dir
		look_at(player.global_position)
		move_and_slide()
		if has_node("ProceduralEnemy"):
			$ProceduralEnemy.is_moving = velocity.length() > 0.1

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

func apply_stun(duration: float):
	pass
