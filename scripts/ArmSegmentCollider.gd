extends Area2D

onready var _prev_position : Vector2 = self.position
var velocity : Vector2 = Vector2.ZERO
onready var shape : CircleShape2D = $CollisionShape2D.shape as CircleShape2D

func _physics_process(delta : float) -> void:
	self.velocity = (self.get_parent().position - self._prev_position) / delta
	self._prev_position = self.get_parent().position
