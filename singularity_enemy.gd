extends "res://enemy.gd"

var pull_force = 150.0

func _ready():
	super._ready()
	SPEED = 80.0
	hp = 150
	$ProceduralEnemy.setup("singularity", Color(2.5, 0.2, 4.0)) # Neon Violet
	$CollisionPolygon2D.polygon = $ProceduralEnemy.get_hull_points()

func _physics_process(delta):
	if is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		look_at(player.global_position)
		
		# Process statuses
		_process_statuses(delta)
		
		var current_speed = SPEED
		if is_frozen: current_speed *= 0.4
		
		# Slow constant approach
		velocity = global_position.direction_to(player.global_position) * current_speed
		$ProceduralEnemy.is_moving = true
		move_and_slide()
		
		# Gravity Pull Logic
		if dist < 600:
			var pull_dir = player.global_position.direction_to(global_position)
			# Pull is weaker if core is frozen
			var actual_pull = pull_force
			if is_frozen: actual_pull *= 0.2
			player.velocity += pull_dir * actual_pull * delta * 60.0
