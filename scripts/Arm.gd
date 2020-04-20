extends Node2D

const ArmSegmentScene := preload("res://entities/ArmSegment.tscn")

export var texture : StreamTexture

export var initial_length : float = 200
export var initial_angle : float = 0
export var segment_count : int = 20
export var vertices_per_segment : int = 5
export var target_position : Vector2 = Vector2.ZERO
export var target_approach_time : float = 0.1
export var thickness_start : float = 20
export var thickness_end : float = 28
export var relax_time : float = 0.05
export var curvature : float = 0
export var relax_time_tangent : float = 0.5
export var relax_time_normal : float = 3

export var retract_time : float = 2

var _idle_phase : float = 0

var retract : bool = true

onready var _arm_draw := $ArmDraw

var _initial_position : Vector2
var _segments : Array = []
var _curve : Curve2D

func _create_segment() -> Node:
	return ArmSegmentScene.instance()

func _ready() -> void:
	self._initial_position = self.initial_length * Vector2.RIGHT.rotated(self.initial_angle)
	self.target_position = self._initial_position
	
	# Children are transferred from this node to a segment
	# node.
	var children := []
	for child_idx in range(0, self.get_child_count()):
		var child := self.get_child(child_idx)
		if child != self._arm_draw:
			self.remove_child(child)
			children.push_back(child)
	
	# Create the segments.
	self._segments = []
	for segment_idx in range(0, segment_count):
		var segment := self._create_segment()
		segment.segment_index = segment_idx
		segment.arm = self
		self._segments.push_back(segment)
		self.add_child(segment)
		if segment_idx == segment_count - 1:
			segment.scale.x = 2
			segment.scale.y = 2
	
	# Add the children back to the last segment.
	for child in children:
		self._segments[-2].add_child(child)
	
	# Create the curve.
	self._curve = Curve2D.new()
	for segment in self._segments.size():
		self._curve.add_point(Vector2.ZERO)
	
	# Do updates before first frame.
	self._update_segments(0)
	self._update_curve()
	
	remove_child(self._arm_draw)
	add_child_below_node(self._segments[-1], self._arm_draw)

func _process(delta : float) -> void:
	self._update_curve()
	self._arm_draw.update()

func _physics_process(delta : float) -> void:
	self._update_segments(delta)

func _get_force(segment : Vector2, target : Vector2, tangent : Vector2, delta : float) -> Vector2:
	tangent = tangent.normalized()
	# The current segment experiences a "force"
	# directed towards the midpoint of its neighbours.
	var displacement := segment - target
	var displacement_tangent := displacement.dot(tangent) * tangent
	var displacement_normal := displacement - displacement_tangent
	var time_factor_tangent := exp(-self.segment_count * delta / self.relax_time_tangent) - 1
	var time_factor_normal := exp(-self.segment_count * delta / self.relax_time_normal) - 1
	var force := displacement_tangent * time_factor_tangent + displacement_normal * time_factor_normal
	return force

func _update_segments(delta : float) -> void:
	# Find displacements on each segment.
	for segment_idx in range(1, self._segments.size() - 1):
		var segment : Node = self._segments[segment_idx]
		var segment_prev : Node = self._segments[segment_idx - 1]
		var segment_next : Node = self._segments[segment_idx + 1]
		var midpoint : Vector2 = 0.5 * (segment_next.position + segment_prev.position)
		var force := self._get_force(segment.position, midpoint, segment_next.position - segment_prev.position, delta)
		segment.position += force
	
	# Update the end of the arm to get closer to the target.
	var time_factor : float
	self._idle_phase += delta * 2
	if self.retract:
		self.target_position = self._initial_position + 16 * Vector2.RIGHT.rotated(self._idle_phase)
		time_factor = exp(-delta / self.retract_time) - 1
	else:
		time_factor = exp(-delta / self.target_approach_time) - 1
	var displacement : Vector2 = self._segments[-1].position - self.target_position
	self._segments[-1].position += time_factor * displacement
	
	var tangent_start : Vector2 = (self._segments[1].position - self._segments[0].position).normalized()
	var tangent_end : Vector2 = (self._segments[-1].position - self._segments[-2].position).normalized()
	
	self._segments[0].position = Vector2.ZERO
	
	# Rotate all segments so they face the tangent direction.
	self._segments[0].rotation = atan2(tangent_start.y, tangent_start.x)
	self._segments[-1].rotation = atan2(tangent_end.y, tangent_end.x)
	for segment_idx in range(1, self._segments.size() - 1):
		var tangent : Vector2 = self._segments[segment_idx + 1].position - self._segments[segment_idx - 1].position
		self._segments[segment_idx].rotation = atan2(tangent.y, tangent.x)

func _update_curve() -> void:
	for segment_idx in range(0, self._segments.size()):
		var prev = self._segments[0].position
		if segment_idx > 0:
			prev = self._segments[segment_idx - 1].position
		var current = self._segments[segment_idx].position
		var next = self._segments[-1].position
		if segment_idx < self._segments.size() - 1:
			next = self._segments[segment_idx + 1].position
		self._curve.set_point_position(segment_idx, current)
		self._curve.set_point_in(segment_idx, curvature * (current - prev))
		self._curve.set_point_out(segment_idx, curvature * (next - current))
