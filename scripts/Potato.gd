extends Area2D

const ArmSegment := preload("res://scripts/ArmSegment.gd")

const HappySprite := preload("res://sprites/potato/Happy.png")
const JoySprite := preload("res://sprites/potato/Joy.png")
const SurpriseSprite := preload("res://sprites/potato/Surprise.png")

export var grav : float = 700
export var drag : float = 0.002
export var min_bounce_velocity : float = 300
var _velocity : Vector2 = Vector2.ZERO
var _angular_velocity : float = 0
var _radius : float = 0
var _surprise_timer : float = 0
var _joy_timer : float = 0
onready var _collision_shape := $CollisionShape2D
onready var _sprite := $Sprite
onready var _flames_sprite := $FlamesSprite
var _flames_animation_timer : float = 0

func _ready() -> void:
	var circle_shape : CircleShape2D = self._collision_shape.shape
	self._radius = circle_shape.radius

func _process(delta : float) -> void:
	self._flames_animation_timer += delta
	if self._flames_animation_timer > 0.125:
		self._flames_sprite.frame = (self._flames_sprite.frame + 1) % 5
		self._flames_animation_timer = 0
	self._sprite.texture = HappySprite
	if self._joy_timer > 0:
		self._sprite.texture = JoySprite
		self._joy_timer -= delta
	if self._surprise_timer > 0:
		self._sprite.texture = SurpriseSprite
		self._surprise_timer -= delta
	if self.position.y > 800:
		self._velocity = Vector2.ZERO
		self.position = Vector2(400, 50)

func _physics_process(delta : float) -> void:
	self._velocity += self.grav * Vector2.DOWN * delta
	self._velocity -= self.drag * self._velocity.length_squared() * self._velocity.normalized() * delta
	if self.position.x < self._radius:
		self._velocity.x = abs(self._velocity.x)
	if self.position.x > get_viewport_rect().size.x - self._radius:
		self._velocity.x = -abs(self._velocity.x)
	self.position += self._velocity * delta
	self.rotation += self._angular_velocity
	for area in self.get_overlapping_areas():
		if area.get_collision_layer_bit(1) || area.get_collision_layer_bit(2):
			self._on_arm_collision(area)

func _on_arm_collision(area : Area2D) -> void:
	var velocity_old := self._velocity
	var area_position := area.global_position
	var normal : Vector2 = (self.position - area_position).normalized()
	var surface_velocity : Vector2 = Vector2.ZERO
	if "velocity" in area:
		surface_velocity = area.velocity
#		var arm := segment.arm
#		var segment_idx := segment.segment_index
#		if segment_idx > 0:
#			var segment_prev : ArmSegment = arm._segments[segment_idx - 1]
#			var tangent := area_position - segment_prev.position
#			if (self.position - area_position).dot(tangent) < 0:
#				normal = -(self.position - area_position).slide(tangent).normalized()
#		elif segment_idx < arm._segments.size() - 1:
#			var segment_next : ArmSegment = arm._segments[segment_idx + 1]
#			var tangent := segment_next.position - area_position
#			if (self.position - area_position).dot(tangent) > 0:
#				normal = -(self.position - area_position).slide(tangent).normalized()
	var velocity_normal := self._velocity.dot(normal)
	var velocity_tangent := self._velocity.slide(normal)
	var surface_velocity_normal := surface_velocity.dot(normal)
	var surface_velocity_tangent := surface_velocity.slide(normal)
	if surface_velocity_normal >= velocity_normal:
		var bounce_velocity := surface_velocity_normal * normal + velocity_tangent
		bounce_velocity += (-0.5 * (velocity_normal - surface_velocity_normal) + self.min_bounce_velocity) * normal
		self._velocity = bounce_velocity
	var shape_radius : float = area.get_node("CollisionShape2D").shape.radius
	if (area_position - self.position).length() < shape_radius + self._radius:
		self.position = area_position + normal * (shape_radius + self._radius)
	self._angular_velocity = 0.1 * tanh((self._velocity.x + 40 * randf() - 20) / 200)
	
	var impulse = self._velocity - velocity_old
	if area.get_collision_layer_bit(2):
		self._joy_timer = 1
	elif impulse.length() > 1000:
		self._surprise_timer = 1
