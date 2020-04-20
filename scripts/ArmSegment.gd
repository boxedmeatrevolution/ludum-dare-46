extends Area2D

var velocity : Vector2 = Vector2.ZERO
var angular_velocity : float = 0
var arm : Node2D = null
var segment_index : int = 0
onready var shape : CircleShape2D = $CollisionShape2D.shape as CircleShape2D

onready var _prev_position : Vector2 = self.position
onready var _prev_rotation : float = self.rotation

func _physics_process(delta : float) -> void:
	self.velocity = (self.position - self._prev_position) / delta
	self.angular_velocity = (self.rotation - self._prev_rotation) / delta
	self._prev_position = self.position
	self._prev_rotation = self.rotation
