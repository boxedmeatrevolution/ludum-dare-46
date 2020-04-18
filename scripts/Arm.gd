extends Node2D

export var texture : StreamTexture

export var segment_count : int = 10
export var vertices_per_segment : int = 5
export var target_position : Vector2 = Vector2.ZERO
export var thickness_start : float = 20
export var thickness_end : float = 28
export var relax_time : float = 0.05
export var curvature : float = 0
export var relax_time_tangent : float = 0.5
export var relax_time_normal : float = 3

var _segments : Array = []
var _curve : Curve2D

func _create_segment() -> Node2D:
	return Node2D.new()

func _ready() -> void:
	# Children are transferred from this node to a segment
	# node.
	var children := []
	for child_idx in range(0, self.get_child_count()):
		var child := self.get_child(child_idx)
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
	
	# Create the curve.
	self._curve = Curve2D.new()
	for segment in self._segments.size():
		self._curve.add_point(Vector2.ZERO)
	
	# Do updates before first frame.
	self._update_segments(0)
	self._update_curve()

func _process(delta : float) -> void:
	self._update_segments(delta)
	self._update_curve()
	update()

func _draw() -> void:
	var pool_vertices := PoolVector2Array()
	var pool_colors := PoolColorArray([Color.white, Color.white, Color.white, Color.white])
	var pool_uvs := PoolVector2Array()
	pool_vertices.resize(4)
	pool_uvs.resize(4)
	
	var center_start := self._curve.get_point_position(0)
	var tangent_start := self._curve.interpolatef(0.01) - center_start
	var normal_start := tangent_start.rotated(PI / 2)
	if normal_start.length() != 0:
		normal_start = 0.5 * normal_start.normalized() * self.thickness_start
	var prev_center := center_start
	var prev_vertex_upper := center_start + normal_start
	var prev_vertex_lower := center_start - normal_start
	var prev_t := 0.0
	
	var vertex_count := self.vertices_per_segment * self._segments.size()
	for vertex_idx in range(1, vertex_count):
		var t := vertex_idx / float(vertex_count - 1)
		var center := self._curve.interpolatef(t * (self._segments.size() - 1))
		var tangent := center - prev_center
		var normal := tangent.rotated(PI / 2)
		if normal.length() != 0:
			normal = 0.5 * normal.normalized() * lerp(self.thickness_start, self.thickness_end, t)
		var vertex_upper := center + normal
		var vertex_lower := center - normal
		var order := 1
		var side_a = vertex_upper - prev_vertex_upper
		var side_b = vertex_lower - prev_vertex_lower
		if tangent.dot(side_a) > 0:
			pool_vertices.set(0, prev_vertex_upper)
			pool_vertices.set(1, vertex_upper)
		else:
			pool_vertices.set(0, vertex_upper)
			pool_vertices.set(1, prev_vertex_upper)
		if tangent.dot(side_b) > 0:
			pool_vertices.set(2, vertex_lower)
			pool_vertices.set(3, prev_vertex_lower)
		else:
			pool_vertices.set(2, prev_vertex_lower)
			pool_vertices.set(3, vertex_lower)
		pool_uvs.set(0, Vector2(prev_t, 0))
		pool_uvs.set(1, Vector2(t, 0))
		pool_uvs.set(2, Vector2(t, 1))
		pool_uvs.set(3, Vector2(prev_t, 1))
		draw_primitive(pool_vertices, pool_colors, pool_uvs, self.texture)
		prev_center = center
		prev_vertex_upper = vertex_upper
		prev_vertex_lower = vertex_lower
		prev_t = t

func _update_segments(delta : float) -> void:
	self._segments[0].position = Vector2.ZERO
	self._segments[-1].position = self.target_position
	for segment_idx in range(1, self._segments.size() - 1):
		var segment : Node2D = self._segments[segment_idx]
		var segment_prev : Node2D = self._segments[segment_idx - 1]
		var segment_next : Node2D = self._segments[segment_idx + 1]
		var tangent := segment_next.position - segment_prev.position
		if tangent.length() != 0:
			tangent = tangent.normalized()
		# The current segment experiences a "force"
		# directed towards the midpoint of its neighbours.
		var midpoint := 0.5 * (segment_next.position + segment_prev.position)
		var displacement := segment.position - midpoint
		var displacement_tangent := displacement.dot(tangent) * tangent
		var displacement_normal := displacement - displacement_tangent
		var time_factor_tangent := exp(-self.segment_count * delta / self.relax_time_tangent)
		var time_factor_normal := exp(-self.segment_count * delta / self.relax_time_normal)
		segment.position = midpoint + displacement_tangent * time_factor_tangent
		segment.position = midpoint + displacement_normal * time_factor_normal

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
