extends "res://enemy.gd"

var is_phasing = false
var phase_timer = 2.0

func _ready():
	super._ready()
	SPEED = 220.0
	hp = 40
	$ProceduralEnemy.setup("wraith", Color(4.0, 0.5, 4.0)) # Neon Ultraviolet
	$CollisionPolygon2D.polygon = $ProceduralEnemy.get_hull_points()

func _physics_process(delta):
	if is_instance_valid(player):
		phase_timer -= delta
		if phase_timer <= 0:
			_toggle_phase()
			phase_timer = 1.5 if is_phasing else 3.0
			
		look_at(player.global_position)
		var current_speed = SPEED * 2.5 if is_phasing else SPEED
		if is_frozen: current_speed *= 0.4
		
		velocity = global_position.direction_to(player.global_position) * current_speed
		move_and_slide()
		if has_node("ProceduralEnemy"):
			$ProceduralEnemy.is_moving = velocity.length() > 0.1
		
		_process_statuses(delta)

func _toggle_phase():
	is_phasing = !is_phasing
	if is_phasing:
		modulate.a = 0.3
		collision_layer = 0
		collision_mask = 0
	else:
		modulate.a = 1.0
		collision_layer = 4
		collision_mask = 3

func take_damage(amount: int):
	if is_phasing: return
	super.take_damage(amount)
