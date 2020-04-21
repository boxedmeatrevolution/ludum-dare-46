extends Node2D

var timer := 0.0

func _process(delta : float) -> void:
	self.timer += delta
	if self.timer > 0.05:
		self.timer = 0
		if $Sprite.frame >= 7:
			self.queue_free()
		$Sprite.frame += 1
