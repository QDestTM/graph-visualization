extends Node2D
class_name VertexNode

const EdgeScene := preload("res://scenes/graph/EdgeNode.tscn")

# MEMBERS ######################################################################

# { <VertexNode> : <EdgeNode> }
var _contiguity_map: Dictionary = {}
var _vertex_id: int = -1

var _distance: int = -1
var _defined_tag: String = ""

var _edln_tag: LineEdit = null

################################################################################
# VIRTUAL ######################################################################

func _ready() -> void:
	$TagEditLine/ReferenceRect.visible = Globals.is_debug_mode()
	$ReferenceArea.visible = Globals.is_debug_mode()
	
	_edln_tag = $TagEditLine
	
	if not Globals.is_graph_tags_placeholders_visible():
		tags_hide_placeholder()


func _notification(what: int) -> void:
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		_vertex_id = Globals.ID.use_next()
		GraphManager.invoke_graph_stats_changed()
		
		$ReferenceArea/IDLabel.text \
			= String.num_uint64(_vertex_id)
		
		name = "Vertex ID-%d" % _vertex_id

################################################################################
# PUBLIC #######################################################################

func anim_deletion(back: bool) -> void:
	if back == true:
		$AnimationPlayer.play_backwards("deletion")
	else:
		$AnimationPlayer.play("deletion")


func anim_special(back: bool) -> void:
	if back == true:
		$AnimationPlayer.play_backwards("special")
	else:
		$AnimationPlayer.play("special")


func anim_hover(back: bool) -> void:
	if back == true:
		$AnimationPlayer.play_backwards("hover")
	else:
		$AnimationPlayer.play("hover")


func anim_special_hover(back: bool) -> void:
	if back == true:
		$AnimationPlayer.play_backwards("special_hover")
	else:
		$AnimationPlayer.play("special_hover")


func anim_algo_select(back: bool) -> void:
	if back == true:
		$AnimationPlayer.play_backwards("algo_select")
	else:
		$AnimationPlayer.play("algo_select")


func anim_algo_processed(back: bool) -> void:
	if back == true:
		$AnimationPlayer.play_backwards("algo_processed")
	else:
		$AnimationPlayer.play("algo_processed")


func anim_algo_unused(back: bool) -> void:
	if back == true:
		$AnimationPlayer.play_backwards("algo_unused")
	else:
		$AnimationPlayer.play("algo_unused")


func anim_reset(back: bool) -> void:
	if back == true:
		$AnimationPlayer.play_backwards("reset")
	else:
		$AnimationPlayer.play("reset")

################################################################################

func edlns_make_readonly() -> void:
	_edln_tag.editable = false
	_edln_tag.selecting_enabled = false


func edlns_make_editable() -> void:
	_edln_tag.editable = true
	_edln_tag.selecting_enabled = true

################################################################################

func tags_hide_placeholder() -> void:
	_edln_tag.placeholder_text = ""


func tags_show_placeholder() -> void:
	_edln_tag.placeholder_text = "Tag"

################################################################################

func get_tag() -> String:
	return _defined_tag


func set_tag(new_tag: String) -> void:
	_defined_tag = new_tag; _edln_tag.text = new_tag


func remove_tag() -> void:
	assert( is_tag_defined(),
		"This vertex don't have a tag." )
	
	GraphManager.remove_tag(_defined_tag)
	set_tag("")

################################################################################

func get_id() -> int:
	return _vertex_id


func get_degree() -> int:
	return _contiguity_map.size()

################################################################################

func clamp_world_position() -> void:
	var old_pos: Vector2 = position
	var rect: Rect2 = $RectangleArea.get_global_rect()
	
	position = Globals.clamp_world_position(rect) + rect.size / 2.0
	
	if old_pos != position:
		update_edges_positions()


func update_position(pos: Vector2) -> void:
	position = pos; update_edges_positions()


func get_center_position() -> Vector2:
	return $Center.global_position

################################################################################

func get_distance() -> int:
	return _distance

func reset_distance() -> void:
	_distance = -1; update_distance_label()

func set_distance(distance: int) -> void:
	_distance = distance; update_distance_label()

func set_distance_thread(distance: int) -> void:
	update_distance_label.call_deferred()
	_distance = distance


func update_distance_label() -> void:
	var label: Label = $RectangleArea/DistanceLabel
	
	if _distance >= 0:
		label.text = String.num_int64(_distance)
	elif Globals.is_playmode_enabled():
		label.text = "-"
	else:
		label.text = "?"

################################################################################

func animate_and_free() -> void:
	anim_deletion(false)
	incidence_remove_all()
	
	GraphManager.invoke_graph_stats_changed()
	
	$RectangleArea.mouse_exited.disconnect(_on_mouse_exit)
	$RectangleArea.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	$AnimationPlayer.animation_finished.connect(
		func(_s: StringName) -> void: queue_free(),
		CONNECT_DEFERRED | CONNECT_ONE_SHOT
	)

################################################################################

func incidence_create(vertex: VertexNode, w: int = 0) -> void:
	assert( !is_same(vertex, self),
			"Can't connect to self." )
	assert( !_contiguity_map.has(vertex),
			"This vertices are connected." )
	
	var edge: EdgeNode = EdgeScene.instantiate()
	
	self._contiguity_map[vertex] = edge
	vertex._contiguity_map[self] = edge
	
	edge.incidence_setup(self, vertex)
	edge.set_weight(w)
	
	GraphManager.invoke_graph_stats_changed()
	GraphManager.get_root().add_child(edge)


func incidence_remove(vertex: VertexNode) -> void:
	assert( !is_same(vertex, self),
			"Can't disconnect from self." )
	assert( _contiguity_map.has(vertex),
			"This vertices are not connected." )
	
	var edge: EdgeNode = _contiguity_map[vertex]
	edge.animate_and_free(self)
	
	GraphManager.invoke_graph_stats_changed()
	self._contiguity_map.erase(vertex)
	vertex._contiguity_map.erase(self)


func incidence_remove_all() -> void:
	var vertices := _contiguity_map.keys()
	
	for vertex in vertices as Array[VertexNode]:
		incidence_remove(vertex)


func incidence_get_ids() -> Array:
	return _contiguity_map.keys().map(
		func(v: VertexNode) -> int: return v.get_id()
	)


func incidence_get_weights() -> Array:
	return _contiguity_map.values().map(
		func(e: EdgeNode) -> int: return e.get_weight()
	)


func incidence_get_edges() -> Array:
	return _contiguity_map.values()


func is_incident_with(vertex: VertexNode) -> bool:
	assert( !is_same(vertex, self), "Received self instance." )
	return _contiguity_map.has(vertex)

################################################################################

func update_edges_positions() -> void:
	var edges_array := _contiguity_map.values() 
	
	for edge in edges_array as Array[EdgeNode]:
		edge.update_line_point(self)

################################################################################

func get_edge(vertex: VertexNode) -> EdgeNode:
	assert( !is_same(vertex, self),
		"Can't have connections with self." )
	assert( _contiguity_map.has(vertex),
		"This vertices are not connected." )
	
	return _contiguity_map[vertex] as EdgeNode

################################################################################

func is_dragging() -> bool:
	return is_same(self, GraphManager.get_moving_vertex() )

func is_edge_begin() -> bool:
	return is_same(self, GraphManager.get_edge_begin() )

func is_graph_entry() -> bool:
	return is_same(self, GraphManager.get_graph_entry() )

func is_tag_defined() -> bool:
	return not _defined_tag.is_empty()

################################################################################
# PRIVATE ######################################################################

func _update_tag(new_tag: String) -> void:
	new_tag = new_tag.to_upper().replace(" ", "")
	_edln_tag.text = new_tag
	
	if new_tag == _defined_tag:
		return
	
	if GraphManager.is_tag_registered(new_tag):
		Globals.send_user_message("This tag already used!")
		return set_tag(_defined_tag)
	
	GraphManager.action.vertex_set_tag(self, new_tag)
	
	if is_tag_defined():
		GraphManager.remove_tag(_defined_tag)
		
		if not new_tag.is_empty():
			GraphManager.define_tag(self, new_tag)
			return set_tag(new_tag)
		else:
			return set_tag("")
	
	
	if not new_tag.is_empty():
		GraphManager.define_tag(self, new_tag)
		return set_tag(new_tag)

################################################################################
# SIGNAL HANDLERS ##############################################################

func _on_mouse_enter() -> void:
	GraphManager.vertex_mouse_enter(self)
	
	if is_dragging() or is_edge_begin() \
			or Globals.is_playmode_enabled():
		return
	
	GraphManager.begin_vertex_hover(self)
	if GraphManager.is_hovering_vertex_delete():
		return anim_special(false)
	
	anim_hover(false)


func _on_mouse_exit() -> void:
	GraphManager.vertex_mouse_exit(self)
	
	if is_dragging() or is_edge_begin() \
			or Globals.is_playmode_enabled():
		return
	
	GraphManager.end_vertex_hover(self)
	if GraphManager.is_hovering_vertex_delete():
		return anim_special(true)
	
	anim_hover(true)


func _on_area_input(event: InputEvent) -> void:
	if Globals.is_playmode_enabled() \
			or not event is InputEventMouseButton:
		return
	
	var button_index: int = \
		(event as InputEventMouseButton).button_index
	
	if button_index != MOUSE_BUTTON_LEFT:
		return
	
	match Globals.get_interaction_mode():
		Enums.InteractionMode.Select:
			if event.is_pressed():
				GraphManager.vertex_move_begin(self)
			else:
				GraphManager.vertex_move_end(self)
				
		Enums.InteractionMode.Edges when event.is_pressed():
			GraphManager.edges_incident_entry(self)

################################################################################

func _on_tag_edit_submit(text: String) -> void:
	_edln_tag.release_focus(); _update_tag(text)


func _on_tag_edit_mouse_exit() -> void:
	_edln_tag.release_focus()


func _on_tag_edit_focus_enter() -> void:
	if not Globals.is_playmode_camera_locked():
		Globals.get_camera().lock_movement()


func _on_tag_edit_focus_exit() -> void:
	if not Globals.is_playmode_camera_locked():
		Globals.get_camera().unlock_movement()
	
	_update_tag(_edln_tag.text)

################################################################################
