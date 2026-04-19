extends "res://enemy.gd"

# Vanguard specialization: Frontal Shielding
func _ready():
	add_to_group("Enemy")
	var mult = 1.0
	if Engine.has_singleton("GameManager") or get_node_or_null("/root/GameManager") != null:
		mult = GameManager.enemy_hp_mult
	hp = int(hp * mult)
	$ProceduralEnemy.setup("vanguard", Color(4.5, 1.2, 0.4)) # Amber Vanguard
	$CollisionPolygon2D.polygon = $ProceduralEnemy.get_hull_points()

func take_damage(amount: int):
	if is_frozen: # Frozen ships lose their shielding advantage
		super.take_damage(amount)
		return
		
	# Shielded logic: Reduced damage from front
	var to_player = global_position.direction_to(player.global_position)
	var forward = transform.x
	if forward.dot(to_player) > 0.5: # Facing player
		super.take_damage(int(amount * 0.2)) # 80% reduction
	else:
		super.take_damage(amount)
