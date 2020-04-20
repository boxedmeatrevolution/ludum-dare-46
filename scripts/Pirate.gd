extends Node2D

# State 0 is arriving, state 1 is throwing, state 2 is leaving
var state := 0
var timer := 0
onready var _animation_player = $AnimationPlayer

func _ready() -> void:
	self._animation_player.play("Prepare")

func _process(delta : float) -> void:
	self.timer += delta
	if state == 0:
		if self.timer > 2:
			self._animation_player.play("Throw")
			self.state = 1
	elif state == 1:
		if !self._animation_player.is_playing():
			self._animation_player.play("Leave")
			self.state = 2
	elif state == 2:
		if self.timer > 2:
			self.queue_free()
	pass
