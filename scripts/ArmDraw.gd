extends Node2D

func _draw() -> void:
	var parent := get_parent()
	var pool_vertices := PoolVector2Array()
	var pool_colors := PoolColorArray([Color.white, Color.white, Color.white, Color.white])
	var pool_uvs := PoolVector2Array()
	pool_vertices.resize(4)
	pool_uvs.resize(4)
	
	var center_start : Vector2 = parent._curve.get_point_position(0)
	var tangent_start : Vector2 = parent._curve.interpolatef(0.01) - center_start
	var normal_start := tangent_start.rotated(PI / 2)
	if normal_start.length() != 0:
		normal_start = 0.5 * normal_start.normalized() * parent.thickness_start
	var prev_center := center_start
	var prev_vertex_upper := center_start + normal_start
	var prev_vertex_lower := center_start - normal_start
	var prev_u := 0.0
	
	var vertex_count : int = parent.vertices_per_segment * parent._segments.size()
	var render_vertex_count : int = parent.vertices_per_segment * (parent._segments.size() - 1)
	for vertex_idx in range(1, render_vertex_count):
		var t := vertex_idx / float(vertex_count - 1)
		var center : Vector2 = parent._curve.interpolatef(t * (parent._segments.size() - 1))
		var tangent := center - prev_center
		var normal := tangent.rotated(PI / 2)
		normal = 0.5 * normal.normalized() * lerp(parent.thickness_start, parent.thickness_end, t)
		var vertex_upper := center + normal
		var vertex_lower := center - normal
		var side_a = vertex_upper - prev_vertex_upper
		var side_b = vertex_lower - prev_vertex_lower
		if tangent.dot(side_a) > 0:
			pool_vertices[0] = prev_vertex_upper
			pool_vertices[1] = vertex_upper
		else:
			pool_vertices[0] = vertex_upper
			pool_vertices[1] = prev_vertex_upper
		if tangent.dot(side_b) > 0:
			pool_vertices[2] = vertex_lower
			pool_vertices[3] = prev_vertex_lower
		else:
			pool_vertices[2] = prev_vertex_lower
			pool_vertices[3] = vertex_lower
		var u := vertex_idx / float(render_vertex_count - 1)
		pool_uvs[0] = Vector2(prev_u, 0)
		pool_uvs[1] = Vector2(u, 0)
		pool_uvs[2] = Vector2(u, 1)
		pool_uvs[3] = Vector2(prev_u, 1)
		draw_primitive(pool_vertices, pool_colors, pool_uvs, parent.texture)
		prev_center = center
		prev_vertex_upper = vertex_upper
		prev_vertex_lower = vertex_lower
		prev_u = u
