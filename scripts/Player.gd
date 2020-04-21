extends Node2D

export var arm_target_swap_zone : float = 150

onready var _head := $Body/Head
onready var _body := $Body
onready var _arm_right := $Body/ArmRight
onready var _arm_left := $Body/ArmLeft
onready var _eye_right := $Body/Head/EyeRight
onready var _eye_left := $Body/Head/EyeLeft
onready var _pupil_right := $Body/Head/EyeRight/Pupil
onready var _pupil_left := $Body/Head/EyeLeft/Pupil
onready var _mouth := $Body/Head/Mouth

onready var _audio_player_hit := $Body/Head/AudioPlayerHit
onready var _audio_player_munch := $Body/Head/AudioPlayerMunch
onready var _audio_player_ooh := $Body/Head/AudioPlayerOoh
onready var _head_sprite := $Body/Head/Sprite
onready var _mouth_sprite := $Body/Head/Mouth/Sprite
onready var _potato : Node2D = get_tree().get_root().get_node("Level/Potato")

var _sprite_head_chomp_timer : float = 0
const _sprite_head_normal := preload("res://sprites/player/Head.png")
const _sprite_head_hit := preload("res://sprites/player/HeadHit.png")
const _sprite_head_chomp := [
	preload("res://sprites/player/HeadChomp1.png"),
	preload("res://sprites/player/HeadChomp2.png")
]
const _sprite_mouth_normal := preload("res://sprites/player/MouthClose.png")
const _sprite_mouth_open := preload("res://sprites/player/MouthOpen.png")

var _sound_munch_timer := 0.0

# 0: normal
# 1: mouth open to eat potat
# 2: hurt by potat
# 3: successfully eaten potat
var _prev_head_anim := 0
var _head_anim := 0

const _sound_hit_by_potato := [
	preload("res://sounds/MainHot.wav"),
	preload("res://sounds/MainOff.wav"),
	preload("res://sounds/MainOw.wav")
]
var _current_potato_sound := 0

var _bonk_timer : float = 0
var _head_bonk : float = 0
var _active_arm : int = 1
var _idle_phase : float = 0

func _ready() -> void:
	pass

func _process(delta : float) -> void:
	if self._prev_head_anim != self._head_anim:
		if self._head_anim == 0 || self._head_anim == 1:
			self._eye_left.visible = true
			self._eye_right.visible = true
			self._mouth.visible = true
			self._head_sprite.texture = self._sprite_head_normal
			if self._head_anim == 0:
				self._mouth_sprite.texture = self._sprite_mouth_normal
			else:
				if self._sound_munch_timer <= 0:
					self._sound_munch_timer = 2
					self._audio_player_ooh.play()
				self._mouth_sprite.texture = self._sprite_mouth_open
		else:
			self._eye_left.visible = false
			self._eye_right.visible = false
			self._mouth.visible = false
			if self._head_anim == 2:
				self._head_sprite.texture = self._sprite_head_hit
			elif self._head_anim == 3:
				self._head_sprite.texture = self._sprite_head_chomp[0]
	if self._head_anim == 3:
		self._sprite_head_chomp_timer += delta
		if self._sprite_head_chomp_timer > 0.3:
			self._head_sprite.texture = self._sprite_head_chomp[1]
		if self._sprite_head_chomp_timer > 0.6:
			self._head_sprite.texture = self._sprite_head_chomp[0]
			self._sprite_head_chomp_timer = 0
	
	if self._sound_munch_timer >= 0:
		self._sound_munch_timer -= delta
	self._prev_head_anim = self._head_anim
	var arm_target := get_global_mouse_position()
	if arm_target.y < 50:
		arm_target.y = 50
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
	var eye_target : Vector2 = self._potato.position / get_viewport().get_size_override() - Vector2(0.5, 0.5)
	eye_target.y = 3 * clamp(eye_target.y, -0.5, 0.5)
	eye_target.x = 8 * clamp(eye_target.x, -0.5, 0.5)
	self._pupil_right.position = eye_target
	self._pupil_left.position = eye_target
	
	# Tilt body.
	self._idle_phase += delta * 2
	var weighted_hand_position : float = 0.5 * (self._arm_left._segments[-1].global_position.x + self._arm_right._segments[-1].global_position.x) - self.global_position.x
	self._body.rotation = 0.008 * weighted_hand_position * PI / 180 + 0.015 * sin(self._idle_phase)
	self._head.rotation = self._head_bonk
	
	if self._head_anim != 3:
		if self._bonk_timer > 0:
			self._head_anim = 2
			self._bonk_timer -= delta
			if self._bonk_timer < 0:
				self._bonk_timer = 0
				self._head_bonk = 0
			self._head_bonk *= exp(-delta / 0.25)
		elif self._potato._temperature <= 0 && self._potato._death_timer <= 0:
			if (self._potato.position - self.position).length() < 500:
				self._head_anim = 1
			else:
				self._head_anim = 0
		else:
			self._head_anim = 0

func _on_head_collision(area : Area2D):
	if area.get_collision_layer_bit(0):
		var potato := area.get_parent()
		if potato._temperature > 0:
			if self._bonk_timer == 0:
				self._audio_player_hit.stream = self._sound_hit_by_potato[self._current_potato_sound]
				self._audio_player_hit.play()
				self._current_potato_sound = (self._current_potato_sound + 1) % self._sound_hit_by_potato.size()
				if potato.position.x > self._head.global_position.x:
					self._head_bonk = -0.3
				else:
					self._head_bonk = 0.3
				self._bonk_timer = 1
		elif potato._death_timer <= 0:
			potato._eat()
			self._head_anim = 3
			self._audio_player_munch.play()
