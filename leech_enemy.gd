extends "res://enemy.gd"

var tether_damage = 2
var damage_timer = 0.0

func _ready():
	super._ready()
	SPEED = 160.0
	hp = 50
	$ProceduralEnemy.setup("leech", Color(0.1, 4.0, 0.5)) # Toxic Acid Green
	$CollisionPolygon2D.polygon = $ProceduralEnemy.get_hull_points()

func _physics_process(delta):
	if is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		look_at(player.global_position)
		
		# Process statuses
		_process_statuses(delta)
		
		var current_speed = SPEED
		if is_frozen: current_speed *= 0.4
		
		# Stay at tether range
		if dist > 150:
			velocity = global_position.direction_to(player.global_position) * current_speed
			$ProceduralEnemy.is_moving = true
		elif dist < 120:
			velocity = global_position.direction_to(player.global_position) * -current_speed
			$ProceduralEnemy.is_moving = true
		else:
			velocity = Vector2.ZERO
			$ProceduralEnemy.is_moving = false
			# Drain logic
			damage_timer += delta
			if damage_timer >= 0.8:
				if player.has_method("take_damage"):
					player.take_damage(tether_damage)
				damage_timer = 0.0
				
		move_and_slide()
