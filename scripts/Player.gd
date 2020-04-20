extends Node2D

export var arm_target_swap_zone : float = 150

onready var _head := $Body/Head
onready var _body := $Body
onready var _arm_right := $Body/ArmRight
onready var _arm_left := $Body/ArmLeft
onready var _pupil_right := $Body/Head/EyeRight/Pupil
onready var _pupil_left := $Body/Head/EyeLeft/Pupil

var _bonk_timer : float = 0
var _head_bonk : float = 0
var _active_arm : int = 1
var _idle_phase : float = 0

func _ready() -> void:
	pass

func _process(delta : float) -> void:
	var arm_target := get_global_mouse_position()
	if self._active_arm == 1 && arm_target.x < self.position.x - self.arm_target_swap_zone:
		self._active_arm = -1
	elif self._active_arm == -1 && arm_target.x > self.position.x + self.arm_target_swap_zone:
		self._active_arm = 1

	if self._active_arm == 1:
		self._arm_right.retract = false
		self._arm_left.retract = true
		self._arm_right.target_position = self._arm_right.to_local(arm_target)
	else:
		self._arm_right.retract = true
		self._arm_left.retract = false
		self._arm_left.target_position = self._arm_left.to_local(arm_target)
	
	# Move eyes:
	var eye_target := arm_target / get_viewport().get_size_override() - Vector2(0.5, 0.5)
	eye_target.y = 3 * eye_target.y
	eye_target.x = 8 * eye_target.x
	self._pupil_right.position = eye_target
	self._pupil_left.position = eye_target
	
	# Tilt body.
	self._idle_phase += delta * 2
	var weighted_hand_position : float = 0.5 * (self._arm_left._segments[-1].global_position.x + self._arm_right._segments[-1].global_position.x) - self.global_position.x
	self._body.rotation = 0.008 * weighted_hand_position * PI / 180 + 0.015 * sin(self._idle_phase)
	self._head.rotation = self._head_bonk
	
	if self._bonk_timer > 0:
		self._bonk_timer -= delta
		if self._bonk_timer < 0:
			self._bonk_timer = 0
			self._head_bonk = 0
		self._head_bonk *= exp(-delta / 0.25)

func _on_head_collision(area):
	if self._bonk_timer == 0:
		if area.position.x > self._head.global_position.x:
			self._head_bonk = -0.3
		else:
			self._head_bonk = 0.3
		self._bonk_timer = 1
