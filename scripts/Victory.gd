extends Node2D

func _ready() -> void:
	var flavour = int(Globals.has_butter) + int(Globals.has_sour_cream) + int(Globals.has_salt) + int(Globals.has_pepper)
	var flavour_text = "D"
	if flavour == 0:
		flavour_text = "Your potato was... bland. Maybe you should have smashed some condiments into it."
	elif flavour == 1:
		flavour_text = "Your potato was okay. Maybe you should have smashed more condiments into it"
	elif flavour == 2:
		flavour_text = "That was a tasty potato, as far as potatoes go."
	elif flavour == 3:
		flavour_text = "That was a delicious potato. You'll remember this meal.'"
	elif flavour == 4:
		flavour_text = "You made the Perfect Potato. You never need to eat again."
	$FlavourText.text = flavour_text


func _on_Button_pressed():
	get_tree().change_scene("res://levels/Level.tscn")
