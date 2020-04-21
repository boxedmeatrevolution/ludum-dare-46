extends Area2D

# 0: held by pirate.
# 1: thrown by pirate
# 2: slowing down in arm
# 3: stuck in arm
# 4: falling to ground
var state := 0

var fall_timer : float = 0

var stuck_target : Node2D = null
var stuck_setup := false
export var velocity : Vector2
export var grav : float = 400

onready var _shape := $CollisionShape2D
onready var _audio_player := $AudioPlayerHit

const _sound_hit := [
	preload("res://sounds/KnifeHit1.wav"),
	preload("res://sounds/KnifeHit2.wav")
]

func _process(delta : float) -> void:
	if self.state == 2 && !self.stuck_setup:
		var pos := self.global_position
		var rot := self.global_rotation
		var sc := self.global_scale
		self.get_parent().remove_child(self)
		var stuck_target_child := self.stuck_target.get_parent().get_child(0)
		self.stuck_target.get_parent().add_child_below_node(stuck_target_child, self)
		self.global_position = pos
		self.global_rotation = rot
		self.global_scale = sc
		self.velocity = self.velocity.rotated(-self.stuck_target.get_parent().global_rotation)
		self.stuck_setup = true
		self._audio_player.stream = self._sound_hit[randi() % self._sound_hit.size()]
		self._audio_player.play()
	if self.state == 3:
		self.fall_timer += delta
		if self.fall_timer > 5:
			var pos := self.global_position
			var rot := self.global_rotation
			var sc := self.global_scale
			var new_parent := get_tree().get_root().get_node("Level/Knives")
			get_parent().remove_child(self)
			new_parent.add_child(self)
			self.global_position = pos
			self.global_rotation = rot
			self.global_scale = sc
			self.velocity = Vector2.ZERO
			self.state = 4

func _physics_process(delta : float) -> void:
	if self.state == 1 || self.state == 2 || self.state == 4:
		self.position += velocity * delta
		if self.state == 1:
			self.velocity += Vector2.DOWN * grav * delta
			self.rotation = -self.velocity.angle_to(Vector2.RIGHT)
		elif self.state == 4:
			self.velocity += Vector2.DOWN * 2 * grav * delta
			self.rotation += 5 * delta
			if self.position.y > 1200:
				self.queue_free()
		elif self.state == 2 && self.stuck_setup:
			self.velocity *= exp(-delta / 0.05)
			if self.velocity.length() < 10:
				self.velocity = Vector2.ZERO
				var overlaps = overlaps_area(self.stuck_target)
				self.state = 3
				if !overlaps || self.stuck_target.scale.x > 1.5:
					self.fall_timer = 10000

func _on_collision_enter(area : Area2D):
	if self.state == 1:
		if area.get_collision_layer_bit(0) || area.get_collision_layer_bit(5):
			self.stuck_target = area
			self.state = 2
			area.get_parent()._velocity += self.velocity
			area.get_parent()._on_knife_collision(self)
		elif area.get_collision_layer_bit(1) || area.get_collision_layer_bit(2):
			# Arm or head
			self.stuck_target = area
			self.state = 2
