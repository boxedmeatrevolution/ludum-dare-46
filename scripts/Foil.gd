extends Node2D

var grav := 200 * Vector2.DOWN
var velocity := Vector2.ZERO
var angular_velocity := randf() * 2 - 1

func _physics_process(delta : float) -> void:
	self.velocity += self.grav * delta
	self.position += self.velocity * delta
	self.rotation += self.angular_velocity * delta
