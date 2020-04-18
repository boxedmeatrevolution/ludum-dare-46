extends Node2D

export var segment_count : int = 10
export var target_position : Vector2 = Vector2.ZERO
export var vertices_per_segment : int = 4
export var thickness_start : float = 32
export var thickness_end : float = 24
export var curvature : float = 0.01
export var relax_time : float = 0.05
export var relax_time_tangent : float = 4

var _segments : Array = []
var _curve : Curve2D
var _vertices : PoolVector3Array
var _uvs : PoolVector2Array

onready var _mesh_instance := $MeshInstance2D
var _mesh : ArrayMesh

func _create_segment() -> Node2D:
	return Node2D.new()

func _ready() -> void:
	# Children are transferred from this node to a segment
	# node.
	var children := []
	for child_idx in range(0, self.get_child_count()):
		var child := self.get_child(child_idx)
		if child != self._mesh_instance:
			self.remove_child(child)
			children.push_back(child)
	
	# Create the segments.
	self._segments = []
	for _segment_idx in range(0, segment_count):
		var segment := self._create_segment()
		self._segments.push_back(segment)
		self.add_child(segment)
	
	# Add the children back to the last segment.
	for child in children:
		self._segments[-1].add_child(child)
	
	# Create the mesh vertices.
	self._curve = Curve2D.new()
	self._vertices = PoolVector3Array()
	self._uvs = PoolVector2Array()
	self._mesh = ArrayMesh.new()
	for segment in self._segments.size():
		self._curve.add_point(Vector2.ZERO)
	self._mesh_instance.mesh = self._mesh
	
	# Do updates before first frame.
	self._update_segments(100)
	self._update_mesh()

func _process(delta : float) -> void:
	self._update_segments(delta)
	self._update_mesh()

func _update_segments(delta : float) -> void:
	self._segments[0].position = Vector2.ZERO
	self._segments[-1].position = self.target_position
	for segment_idx in range(1, self._segments.size() - 1):
		var segment : Node2D = self._segments[segment_idx]
		var segment_prev : Node2D = self._segments[segment_idx - 1]
		var segment_next : Node2D = self._segments[segment_idx + 1]
		# The current segment experiences a "force"
		# directed towards the midpoint of its neighbours.
		var midpoint := 0.5 * (segment_next.position + segment_prev.position)
		var displacement := segment.position - midpoint
		segment.position -= displacement * delta / self.relax_time

func _update_mesh() -> void:
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
	var center_vertices = self._curve.tessellate()
	self._vertices.resize(2 * center_vertices.size())
	self._uvs.resize(2 * center_vertices.size())
	for vertex_idx in range(0, center_vertices.size()):
		var t := vertex_idx / float(center_vertices.size() - 1)
		var center_vertex : Vector2 = center_vertices[vertex_idx]
		var tangent := Vector2.ZERO
		if vertex_idx == 0:
			tangent = center_vertices[vertex_idx + 1] - center_vertices[vertex_idx]
		elif vertex_idx == center_vertices.size() - 1:
			tangent = center_vertices[vertex_idx] - center_vertices[vertex_idx - 1]
		else:
			tangent = 0.5 * (center_vertices[vertex_idx + 1] - center_vertices[vertex_idx - 1])
		var normal := tangent.rotated(PI / 2)
		if normal.length() != 0:
			normal = normal.normalized() * lerp(self.thickness_start, self.thickness_end, t)
		var pos_upper := center_vertex + normal
		var pos_lower := center_vertex - normal
		self._vertices.set(2 * vertex_idx, Vector3(pos_upper.x, pos_upper.y, 0))
		self._vertices.set(2 * vertex_idx + 1, Vector3(pos_lower.x, pos_lower.y, 0))
		self._uvs.set(2 * vertex_idx, Vector2(t, 1))
		self._uvs.set(2 * vertex_idx + 1, Vector2(t, 0))
	var arrays = []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	arrays[ArrayMesh.ARRAY_VERTEX] = self._vertices
	arrays[ArrayMesh.ARRAY_TEX_UV] = self._uvs
	self._mesh.surface_remove(0)
	self._mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, arrays)
