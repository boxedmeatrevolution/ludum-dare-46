extends Node2D

const ArmSegment := preload("res://scripts/ArmSegment.gd")

const HappySprite := preload("res://sprites/potato/Happy.png")
const JoySprite := preload("res://sprites/potato/Joy.png")
const SurpriseSprite := preload("res://sprites/potato/Surprise.png")
const ScaredSprite := preload("res://sprites/potato/Scared.png")
const DeadSprite := preload("res://sprites/potato/Eaten.png")
const ItemScene := preload("res://entities/Item.tscn")

const FoilScene := preload("res://entities/Foil.tscn")
const PoofScene := preload("res://entities/Poof.tscn")

onready var _audio_player_hit := $AudioPlayerHit
onready var _audio_player_joy := $AudioPlayerJoy
onready var _audio_player_splat := $AudioPlayerSplat
onready var _audio_player_impact := $AudioPlayerImpact

onready var player := get_tree().get_root().get_node("Level/Player")

var _temperature : float = 1
var _time_to_win : float = 90

const _sound_impact := [
	preload("res://sounds/Impact5.wav"),
	preload("res://sounds/Impact6.wav"),
	preload("res://sounds/Impact7.wav")
]

const _sound_hit := [
	preload("res://sounds/PotatoOw.wav")
]

const _sound_joy := [
	preload("res://sounds/PotatoWee.wav"),
	preload("res://sounds/PotatoYay.wav"),
	preload("res://sounds/PotatoTeehee.wav")
]

const _sound_little_joy := [
	preload("res://sounds/PotatoAh.wav"),
	preload("res://sounds/PotatoEh.wav"),
	preload("res://sounds/PotatoOh.wav"),
]

const _sound_splat := [
	preload("res://sounds/Splat2.wav"),
	preload("res://sounds/Splat3.wav")
]

var _sound_joy_index := 0
var _sound_joy_timer : float = 0
var _sound_impact_timer : float = 0

export var grav : float = 700
export var drag : float = 0.002
export var min_bounce_velocity : float = 300
var _velocity : Vector2 = Vector2.ZERO
var _angular_velocity : float = 0
var _radius : float = 0
var _surprise_timer : float = 0
var _joy_timer : float = 0
var _death_timer : float = 0
var _eaten_timer : float = 0
onready var _sprite := $Sprite
onready var _death_sprite := $DeathSprite
onready var _flames_sprite := $FlamesSprite
var _flames_animation_timer : float = 0

var created_butter := false
var created_sour_create := false
var created_salt := false
var created_pepper := false

func _ready() -> void:
	Globals.has_butter = false
	Globals.has_salt = false
	Globals.has_pepper = false
	Globals.has_sour_cream = false
	var circle_shape : CircleShape2D = $Area2D/CollisionShape2D.shape
	self._radius = circle_shape.radius

func _process(delta : float) -> void:
	self._temperature -= delta / self._time_to_win
	if self._temperature <= 0:
		self._temperature = 0
		self._flames_sprite.visible = false
	if self._temperature <= 0.75 && !self.created_butter && abs(self.position.x - 512) > 300:
		var butter := ItemScene.instance()
		self.created_butter = true
		butter.type = 0
		butter.position = Vector2(512, -50)
		get_tree().get_root().get_node("Level/Items").add_child(butter)
	elif self._temperature <= 0.45 && !self.created_sour_create && abs(self.position.x - 512) > 300:
		var sour_cream := ItemScene.instance()
		self.created_sour_create = true
		sour_cream.type = 1
		sour_cream.position = Vector2(512, -50)
		get_tree().get_root().get_node("Level/Items").add_child(sour_cream)
	elif self._temperature <= 0.2 && !self.created_pepper && abs(self.position.x - 512) > 300:
		var pepper := ItemScene.instance()
		self.created_pepper = true
		pepper.type = 2
		pepper.position = Vector2(452, -50)
		get_tree().get_root().get_node("Level/Items").add_child(pepper)
	elif self._temperature <= 0.15 && !self.created_salt && abs(self.position.x - 512) > 300:
		var salt := ItemScene.instance()
		self.created_salt = true
		salt.type = 3
		salt.position = Vector2(572, -50)
		get_tree().get_root().get_node("Level/Items").add_child(salt)
	if self._sound_joy_timer > 0:
		self._sound_joy_timer -= delta
	if self._sound_impact_timer > 0:
		self._sound_impact_timer -= delta
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
	if player._head_anim == 1:
		self._sprite.texture = ScaredSprite
	if self._death_timer > 0:
		self._sprite.texture = DeadSprite
		self._death_timer -= delta
		if self._death_timer < 3 - 1:
			self._death_sprite.frame = 3
		elif self._death_timer < 3 - 0.5:
			self._death_sprite.frame = 2
		elif self._death_timer < 3 - 0.25:
			self._death_sprite.frame = 1
		else:
			self._death_sprite.frame = 0
		if self._death_timer <= 0:
			get_tree().change_scene("res://levels/GameOver.tscn")
	if self._eaten_timer > 0:
		self._eaten_timer -= delta
		if self._eaten_timer <= 0:
			get_tree().change_scene("res://levels/Victory.tscn")
	if self.position.y > 800:
		self._die()

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
	self._die()
	var foil := FoilScene.instance()
	foil.position = self.position
	foil.velocity = self._velocity + 400 * Vector2.RIGHT.rotated(2 * PI * randf())
	get_tree().get_root().get_node("Level/Effect").add_child(foil)
	self._sprite.visible = false
	self._death_sprite.visible = true
	self._flames_sprite.visible = false
	self._audio_player_splat.stream = self._sound_splat[randi() % self._sound_splat.size()]
	self._audio_player_splat.play()

func _die() -> void:
	if self._death_timer == 0:
		self._audio_player_hit.stream = self._sound_hit[randi() % self._sound_hit.size()]
		self._audio_player_hit.play()
		self.min_bounce_velocity = 200
		self._death_timer = 3

func _eat() -> void:
	if self._eaten_timer == 0:
		self._eaten_timer = 3
		self._audio_player_splat.stream = self._sound_splat[randi() % self._sound_splat.size()]
		self._audio_player_splat.play()
		self.position = Vector2(0, -1000000)
		self.grav = 0

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
		if self._death_timer > 0:
			elasticity = 0.1
		bounce_velocity += (-elasticity * (velocity_normal - surface_velocity_normal) + self.min_bounce_velocity) * normal
		self._velocity = bounce_velocity
	var shape_radius : float = area.get_node("CollisionShape2D").shape.radius
	if (area_position - self.position).length() < shape_radius + self._radius:
		self.position = area_position + normal * (shape_radius + self._radius)
	self._angular_velocity = 0.1 * tanh((self._velocity.x + 40 * randf() - 20) / 200)
	if area.get_collision_layer_bit(5):
		var item := area.get_parent()
		# If its an item
		var merge_speed := 300.0
		if item.type == 0:
			merge_speed = 150
		if abs(surface_velocity_normal - velocity_normal) > merge_speed:
			if self.position.y > 0 && item.position.y > 0:
				self._audio_player_splat.stream = self._sound_splat[randi() % self._sound_splat.size()]
				self._audio_player_splat.play()
				if item.type == 0:
					Globals.has_butter = true
					$Decor/Butter.visible = true
				elif item.type == 1:
					Globals.has_sour_cream = true
					$Decor/SourCream.visible = true
				elif item.type == 2:
					Globals.has_pepper = true
					$Decor/Pepper.visible = true
				elif item.type == 3:
					Globals.has_salt = true
					$Decor/Salt.visible = true
				item.queue_free()
				var poof := PoofScene.instance()
				poof.global_position = self.global_position
				get_tree().get_root().get_node("Level/Effect").add_child(poof)
	
	if self._sound_impact_timer <= 0:
		self._sound_impact_timer = 0.25
		self._audio_player_impact.stream = self._sound_impact[randi() % self._sound_impact.size()]
		self._audio_player_impact.play()
	var impulse = self._velocity - velocity_old
	if self._surprise_timer <= 0 && self._death_timer <= 0:
		if area.get_collision_layer_bit(2) || area.get_collision_layer_bit(4):
			self._joy_timer = 1
		if impulse.length() > 1500:
			self._joy_timer = 1
			if self._sound_joy_timer <= 0:
				self._audio_player_joy.stream = self._sound_joy[self._sound_joy_index]
				self._audio_player_joy.play()
				self._sound_joy_index = (self._sound_joy_index + 1) % self._sound_joy.size()
				self._sound_joy_timer = 1
		elif impulse.length() > 600:
			if self._sound_joy_timer <= 0:
				self._audio_player_joy.stream = self._sound_little_joy[self._sound_joy_index]
				self._audio_player_joy.play()
				self._sound_joy_index = (self._sound_joy_index + 1) % self._sound_joy.size()
				self._sound_joy_timer = 1

