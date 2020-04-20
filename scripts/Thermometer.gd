extends Node2D

onready var potato := get_tree().get_root().get_node("Level/Potato")

func _process(delta : float) -> void:
	update()

func _draw() -> void:
	var thermometer_width : float = 330
	var thermometer_fraction : float = self.potato._temperature
	var thermometer_height : float = 20
	draw_rect(Rect2(0, -0.5 * thermometer_height, thermometer_width, thermometer_height), Color.gray)
	draw_circle(Vector2(thermometer_width, 0), 0.5 * thermometer_height, Color.gray)
	draw_rect(Rect2(0, -0.5 * thermometer_height, thermometer_fraction * thermometer_width, thermometer_height), Color.red)
	draw_circle(Vector2(thermometer_fraction * thermometer_width, 0), 0.5 * thermometer_height, Color.red)
	draw_circle(Vector2(0, 0), 32, Color.red)
	draw_circle(Vector2(10, -10), 10, Color.pink)
