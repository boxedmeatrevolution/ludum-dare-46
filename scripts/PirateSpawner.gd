extends Node2D

const PirateScene := preload("res://entities/Pirate.tscn")

export var pirate_spawn_frequency = 10
var _next_pirate_spawn_time : float = 15
var _pirate_spawn_timer : float = 0
var _prev_pirate_spawn_choice : int = 2

func _process(delta : float) -> void:
	self._pirate_spawn_timer += delta
	if self._pirate_spawn_timer > self._next_pirate_spawn_time:
		self._pirate_spawn_timer = 0
		self._next_pirate_spawn_time = self.pirate_spawn_frequency * (1 + 0.2 * randf() - 0.1)
		var pirate := PirateScene.instance()
		var size := get_viewport().get_size_override()
		var spawn_choice := randi() % 2
		if spawn_choice == 0:
			spawn_choice = (self._prev_pirate_spawn_choice + 1) % 3
		else:
			spawn_choice = (self._prev_pirate_spawn_choice + 2) % 3
		self._prev_pirate_spawn_choice = spawn_choice
		if spawn_choice == 0:
			pirate.position = Vector2(-260, (0.4 * randf() + 0.2) * size.y)
			pirate.rotation = 0
		elif spawn_choice == 1:
			pirate.position = Vector2(size.x + 260, 0.6 * randf() * size.y)
			pirate.rotation = PI
		elif spawn_choice == 2:
			pirate.position = Vector2(randf() * size.x, -260)
			pirate.rotation = 0.5 * PI
		self.add_child(pirate)
