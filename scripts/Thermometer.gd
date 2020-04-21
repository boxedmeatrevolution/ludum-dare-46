extends Node2D

onready var potato := get_tree().get_root().get_node("Level/Potato")
var _color := Color(0.776, 0.235, 0.235)

func _process(delta : float) -> void:
	update()

func _draw() -> void:
	var thermometer_width : float = 235
	var thermometer_fraction : float = self.potato._temperature
	var thermometer_height : float = 10
	draw_rect(Rect2(0, -0.5 * thermometer_height, thermometer_fraction * thermometer_width, thermometer_height), self._color)
	draw_circle(Vector2(thermometer_fraction * thermometer_width, 0), 0.5 * thermometer_height, self._color)
