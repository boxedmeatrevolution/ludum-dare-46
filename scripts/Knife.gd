extends Area2D

export var enabled := false
export var velocity : Vector2
export var grav : float = 400

func _physics_process(delta : float) -> void:
	if self.enabled:
		self.velocity += Vector2.DOWN * grav * delta
		self.position += velocity * delta
		self.rotation = -self.velocity.angle_to(Vector2.RIGHT)
