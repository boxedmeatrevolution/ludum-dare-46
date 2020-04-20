extends Node2D

var timer := 0.0

func _process(delta : float) -> void:
	self.timer += delta
	if self.timer > 1:
		self.queue_free()
