extends Node

var trauma = 0.0
var max_x = 25.0
var max_y = 25.0
var max_r = 0.1

func add_trauma(amount: float):
	trauma = min(trauma + amount, 1.0)
