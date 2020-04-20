extends Node2D

func _ready() -> void:
	var flavour = int(Globals.has_butter) + int(Globals.has_sour_cream) + int(Globals.has_salt) + int(Globals.has_pepper)
	var flavour_text = "D"
	if flavour == 0:
		flavour_text = "edible."
	elif flavour == 1:
		flavour_text = "okay."
	elif flavour == 2:
		flavour_text = "nice."
	elif flavour == 3:
		flavour_text = "good."
	elif flavour == 4:
		flavour_text = "amazing!"
	$FlavourText.text += flavour_text
