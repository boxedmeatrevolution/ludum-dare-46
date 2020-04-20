extends Node2D

# State 0 is arriving, state 1 is throwing, state 2 is leaving
var _state := 0
var _timer : float = 0
var _initial_position : Vector2
onready var _animation_player = $AnimationPlayer
export var popup_distance = 150
export var throw_speed = 1000
export var popup_time = 1
export var wait_time = 2.0

onready var potato : Node2D = get_tree().get_root().get_node("Level/Potato")

onready var _audio_player_arrive := $AudioPlayerArrive
onready var _audio_player_hit := $AudioPlayerHit

const _sound_arrive := [
	preload("res://sounds/PirateNeedAHand.wav"),
	preload("res://sounds/PirateHereYaGo.wav"),
	preload("res://sounds/PirateAhoy.wav"),
	preload("res://sounds/PirateYarr.wav")
]

const _sound_hit := [
	preload("res://sounds/PirateTeehee.wav")
]

onready var _hand = $Hand

func _ready() -> void:
	self._animation_player.play("Prepare")
	self._initial_position = self.position
	self._audio_player_arrive.stream = self._sound_arrive[randi() % self._sound_arrive.size()]
	self._audio_player_arrive.play()

func _process(delta : float) -> void:
	var target_position = self._initial_position + self.popup_distance * Vector2.RIGHT.rotated(self.rotation)
	self._timer += delta
	if self._state == 0:
		var t := 0.5 * (1 - cos(PI * self._timer / self.popup_time))
		self.position = lerp(self._initial_position, target_position, t)
		if self._timer > self.popup_time:
			self._state = 1
			self._timer = 0
			self.position = target_position
	elif self._state == 1:
		var throw : bool = (self._timer > self.wait_time)
		if self._timer > 0.5 * self.wait_time && (self.position - self.potato.position).slide(Vector2.RIGHT.rotated(self.rotation)).length() < 80 && (self.potato.position - self.position).dot(Vector2.RIGHT.rotated(self.rotation)) > 0:
			throw = true
		if throw:
			self._animation_player.play("Throw")
			self._state = 2
			self._timer = 0
	elif self._state == 2:
		if !self._animation_player.is_playing():
			self._animation_player.play("Leave")
			self._state = 3
			self._timer = 0
			self._throw()
	elif self._state == 3:
		if self._timer > self.wait_time:
			self._state = 4
			self._timer = 0
	elif self._state == 4:
		var t := 0.5 * (1 - cos(PI * self._timer / self.popup_time))
		self.position = lerp(target_position, self._initial_position, t)
		if self._timer > self.popup_time:
			self.queue_free()

func _throw() -> void:
	var item : Node2D = self._hand.get_child(0)
	var rot := self.global_rotation
	var pos := item.global_position
	self._hand.remove_child(item)
	item.state = 1
	item.rotation = rot
	item.position = pos
	item.velocity = self.throw_speed * Vector2.RIGHT.rotated(rot)
	var knives_parent := get_tree().get_root().get_node("Level/Knives")
	knives_parent.add_child(item)


func _on_collision(area : Area2D) -> void:
	if self._state != 4 && self._state != 0:
		self._state = 4
		self._timer = 0
		if self._animation_player.current_animation == "Throw":
			self._animation_player.play("Prepare")
		self._audio_player_hit.stream = self._sound_hit[randi() % self._sound_hit.size()]
		self._audio_player_hit.play()
