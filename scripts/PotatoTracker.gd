extends Node2D

onready var potato := get_tree().get_root().get_node("Level/Potato")

func _ready() -> void:
	self.visible = false

func _process(delta : float) -> void:
	if potato.position.y < self.position.y - 120 && self.potato._eaten_timer == 0:
		self.position.x = potato.position.x
		self.visible = true
	else:
		self.visible = false
