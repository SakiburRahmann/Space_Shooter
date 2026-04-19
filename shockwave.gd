extends Node2D

func _ready():
	var tween = create_tween()
	scale = Vector2.ZERO
	modulate = Color(0, 1, 4, 1) # Extreme cyan glow
	tween.tween_property(self, "scale", Vector2(10, 10), 0.4).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)

func _draw():
	draw_circle(Vector2.ZERO, 50, Color(1,1,1,1))
