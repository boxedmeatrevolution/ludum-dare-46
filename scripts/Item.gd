extends Node2D

var _velocity := Vector2.ZERO
var _angular_velocity : float = 0
var _radius : float = 0
var grav : float = 700
var drag : float = 0.002
var min_bounce_velocity : float = 300
onready var circle_shape : CircleShape2D = $Area2D/CollisionShape2D.shape

const ButterSprite := preload("res://sprites/items/Butter.png")
const SaltSprite := preload("res://sprites/items/Salt.png")
const SourCreamSprite := preload("res://sprites/items/SourCream.png")
const PepperSprite := preload("res://sprites/items/Pepper.png")

onready var _sprite := $Sprite
var type : int = 0

func _ready() -> void:
	self._radius = circle_shape.radius
	if self.type == 0:
		self._sprite.texture = ButterSprite
	elif self.type == 1:
		self._sprite.texture = SourCreamSprite
	elif self.type == 2:
		self._sprite.texture = PepperSprite
	elif self.type == 3:
		self._sprite.texture = SaltSprite

func _physics_process(delta : float) -> void:
	self._velocity += self.grav * Vector2.DOWN * delta
	self._velocity -= self.drag * self._velocity.length_squared() * self._velocity.normalized() * delta
	if self.position.x < self._radius:
		self._velocity.x = abs(self._velocity.x)
	if self.position.x > get_viewport_rect().size.x - self._radius:
		self._velocity.x = -abs(self._velocity.x)
	self.position += self._velocity * delta
	self.rotation += self._angular_velocity

func _on_knife_collision(area : Area2D) -> void:
	pass

func _on_arm_collision(area : Area2D) -> void:
	if !area.get_collision_layer_bit(0) && !area.get_collision_layer_bit(1) && !area.get_collision_layer_bit(2) && !area.get_collision_layer_bit(4) && !area.get_collision_layer_bit(5):
		return
	var velocity_old := self._velocity
	var area_position := area.global_position
	var normal : Vector2 = (self.position - area_position).normalized()
	var surface_velocity : Vector2 = Vector2.ZERO
	if "velocity" in area:
		surface_velocity = area.velocity
	if "_velocity" in area:
		surface_velocity = area._velocity
	var velocity_normal := self._velocity.dot(normal)
	var velocity_tangent := self._velocity.slide(normal)
	var surface_velocity_normal := surface_velocity.dot(normal)
	var surface_velocity_tangent := surface_velocity.slide(normal)
	if surface_velocity_normal >= velocity_normal:
		var bounce_velocity := surface_velocity_normal * normal + velocity_tangent
		var elasticity := 0.5
		bounce_velocity += (-elasticity * (velocity_normal - surface_velocity_normal) + self.min_bounce_velocity) * normal
		self._velocity = bounce_velocity
	var shape_radius : float = area.get_node("CollisionShape2D").shape.radius
	if (area_position - self.position).length() < shape_radius + self._radius:
		self.position = area_position + normal * (shape_radius + self._radius)
	self._angular_velocity = 0.1 * tanh((self._velocity.x + 40 * randf() - 20) / 200)
