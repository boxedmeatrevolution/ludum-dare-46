extends Node2D

func _process(delta : float) -> void:
	$Butter.modulate = Color(1, 1, 1, 1 if Globals.has_butter else 0.3)
	$SourCream.modulate = Color(1, 1, 1, 1 if Globals.has_sour_cream else 0.3)
	$Pepper.modulate = Color(1, 1, 1, 1 if Globals.has_pepper else 0.3)
	$Salt.modulate = Color(1, 1, 1, 1 if Globals.has_salt else 0.3)
