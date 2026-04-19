extends CharacterBody2D

var target_player = null
var SPEED = 300.0
var fire_rate = 0.5
var fire_timer = 0.0
var bullet_scene = preload("res://bullet.tscn")
var orbit_angle = 0.0
var orbit_radius = 80.0
var orbit_speed = 2.0

func _physics_process(delta):
	if is_instance_valid(target_player):
		orbit_angle += delta * orbit_speed
		var target_pos = target_player.global_position + Vector2(cos(orbit_angle), sin(orbit_angle)) * orbit_radius
		global_position = global_position.lerp(target_pos, 5.0 * delta)
		
		# Targeting
		var closest = null
		var dist = 400.0
		for enemy in get_tree().get_nodes_in_group("Enemy"):
			if is_instance_valid(enemy):
				var d = global_position.distance_to(enemy.global_position)
				if d < dist:
					dist = d
					closest = enemy
		
		if closest:
			look_at(closest.global_position)
			fire_timer -= delta
			if fire_timer <= 0:
				_fire()
				fire_timer = fire_rate
	else:
		queue_free()

func _fire():
	var b = bullet_scene.instantiate()
	b.global_position = global_position
	b.global_rotation = global_rotation
	b.damage = int(target_player.damage * 0.5)
	get_parent().add_child(b)
