extends Node2D

# State 0 is arriving, state 1 is throwing, state 2 is leaving
var _state := 0
var _timer : float = 0
var _initial_position : Vector2
onready var _animation_player = $AnimationPlayer
export var popup_distance = 150
export var throw_speed = 1000
export var popup_time = 1
export var wait_time = 2

onready var _hand = $Hand

func _ready() -> void:
	self._animation_player.play("Prepare")
	self._initial_position = self.position

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
		if self._timer > self.wait_time:
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
	item.enabled = true
	item.rotation = rot
	item.position = pos
	item.velocity = self.throw_speed * Vector2.RIGHT.rotated(rot)
	get_tree().get_root().add_child(item)
