extends Node

const GraphEntryRender := preload("res://scripts/graph/VertexEntry.gd")
const VertexScene := preload("res://scenes/graph/VertexNode.tscn")

# SIGNALS ######################################################################

signal vertex_move_begined()
signal vertex_move_ended()

signal vertex_hover_begined()
signal vertex_hover_ended()

signal vertex_mouse_entered(vertex: VertexNode)
signal vertex_mouse_exited(vertex: VertexNode)

signal edge_connection_begined()
signal edge_connection_canceled()
signal edge_connection_ended()

signal graph_stats_changed()

signal graph_entry_defined()
signal graph_entry_removed()

signal graph_save_started()
signal graph_save_finished()

# MEMBERS ######################################################################

var action: ActionController = ActionController.new()
var player: AlgorithmPlayer = AlgorithmPlayer.new()

var _vertex_map: Dictionary = {}
var _graph_root: Node2D = null

var _hovering_vertex_delete: bool = false
var _hovering_vertex: VertexNode = null

var _edge_begin: VertexNode = null

var _moving_vertex_last_pos: Vector2 = Vector2.ZERO
var _moving_vertex: VertexNode = null
var _moving_offset: Vector2 = Vector2.ZERO

var _graph_entry_render: GraphEntryRender = null
var _graph_entry: VertexNode = null

################################################################################
# VIRTUAL ######################################################################

func _ready() -> void:
	var scene := preload("res://scenes/graph/VertexEntry.tscn")
	
	_graph_entry_render = scene.instantiate()
	assert(_graph_entry_render != null,
		"Failed to instantiate graph entry render.")
	
	print("Graph Manager - Entry state render intantiated.")


func _process(_delta: float) -> void:
	if is_vertex_moving() == false:
		return
	
	_moving_vertex.update_position(
		_graph_root.get_local_mouse_position() \
			+ _moving_offset
	)


func _input(event: InputEvent) -> void:
	var pressed: bool = event.is_pressed()
	
	if event.is_action("ui_redo") and pressed:
		return action.redo()
	
	elif event.is_action("ui_undo") and pressed:
		return action.undo()
	
	# Hover vertices input handling
	if !Globals.is_interaction_select():
			return
	
	if is_vertex_hovering() == false:
			return
	
	if event.is_action("remove_hovered_vertex"):
		if _update_hovering_vertex_delete(pressed) == false:
			return
		
		if _hovering_vertex_delete:
			_hovering_vertex.anim_special(false)
		else:
			action.vertex_delete(_hovering_vertex)
	
	elif event.is_action("set_graph_entry") and !pressed:
		action.graph_entry_define(_graph_entry, _hovering_vertex)

################################################################################
# PUBLIC #######################################################################

func init_graph_root(node: Node2D) -> void:
	assert(_graph_root == null, "Node Root already initialized.")

	_graph_root = node
	print("Received node - Graph Root")
	
	player.setup_operation_display()

################################################################################

func invoke_graph_stats_changed() -> void:
	graph_stats_changed.emit()

################################################################################

func is_vertex_moving() -> bool:
	return _moving_vertex != null

func is_vertex_hovering() -> bool:
	return _hovering_vertex != null

func is_hovering_vertex_delete() -> bool:
	return _hovering_vertex_delete

func is_graph_entry_defined() -> bool:
	return _graph_entry != null

func is_vertex_id_valid(id: int) -> bool:
	return _vertex_map.has(id)

################################################################################

func get_root() -> Node2D:
	return _graph_root

func get_moving_vertex() -> VertexNode:
	return _moving_vertex

func get_hovering_vertex() -> VertexNode:
	return _hovering_vertex

func get_graph_entry() -> VertexNode:
	return _graph_entry

func get_edge_begin() -> VertexNode:
	return _edge_begin

func vertex_from_id(id: int) -> VertexNode:
	return _vertex_map[id]

################################################################################

func vertex_move_begin(vertex: VertexNode) -> void:
	assert(_moving_vertex == null,
		"Already moving other vertice.")
	
	_moving_vertex_last_pos = vertex.global_position
	
	_moving_offset = vertex.global_position \
		- vertex.get_global_mouse_position()
	action.vertex_move_begin(vertex)

	_moving_vertex = vertex
	vertex_move_begined.emit()


func vertex_move_end(vertex: VertexNode) -> void:
	assert( is_same(vertex, _moving_vertex),
		"This vertex doesn't moving now.")
	
	_moving_vertex.clamp_world_position()
	
	if _moving_vertex_last_pos != vertex.global_position:
		action.vertex_move_end(vertex)
	
	vertex_move_ended.emit()
	_moving_vertex = null

################################################################################

func begin_vertex_hover(vertex: VertexNode) -> void:
	_hovering_vertex = vertex
	vertex_hover_begined.emit()


func end_vertex_hover(_vertex: VertexNode) -> void:
	set_deferred("_hovering_vertex_delete", false)
	vertex_hover_ended.emit()
	_hovering_vertex = null

################################################################################

func vertex_create(position: Vector2) -> void:
	var vertex: VertexNode = VertexScene.instantiate()
	
	_vertex_map_append(vertex)
	_graph_root.add_child(vertex)
	
	vertex.global_position = position
	vertex.clamp_world_position()


func vertex_delete(vertex: VertexNode) -> void:
	if is_same(vertex, _moving_vertex):
		_moving_vertex = null
	
	if is_same(vertex, _hovering_vertex):
		_hovering_vertex = null
	
	if vertex.is_graph_entry():
		_graph_entry_remove()
	
	_vertex_map_remove(vertex)
	vertex.animate_and_free()


func vertex_delete_by_id(id: int) -> void:
	vertex_delete( _vertex_map[id] )

################################################################################

func vertex_mouse_enter(vertex: VertexNode) -> void:
	vertex_mouse_entered.emit(vertex)


func vertex_mouse_exit(vertex: VertexNode) -> void:
	vertex_mouse_exited.emit(vertex)

################################################################################

func edges_incident_entry(vertex: VertexNode) -> void:
	_edges_incident_entry(vertex)

################################################################################

func graph_entry_define(vertex: VertexNode) -> void:
	if vertex.is_graph_entry(): # Entry remove
		return _graph_entry_remove()
	
	if is_graph_entry_defined():
		_graph_entry_remove()
	
	_graph_entry = vertex
	graph_entry_defined.emit()
	vertex.add_child(_graph_entry_render)


func graph_entry_remove() -> void:
	assert( is_graph_entry_defined(),
		"Graph entry must be defined." )
	
	_graph_entry_remove()

################################################################################

func destroy_graph() -> void:
	action.clean_actions()
	var nodes: Array
	
	nodes = Globals.get_all_vertices()
	for vertex in nodes as Array[VertexNode]:
		vertex_delete(vertex)
	

################################################################################
# PRIVATE ######################################################################

# Returns TRUE only if field was updated.
func _update_hovering_vertex_delete(state: bool) -> bool:
	if state == _hovering_vertex_delete:
		return false
	
	_hovering_vertex_delete = state
	return true

################################################################################

func _vertex_map_append(vertex: VertexNode) -> void:
	_vertex_map[vertex.get_id()] = vertex


func _vertex_map_remove(vertex: VertexNode) -> void:
	_vertex_map.erase(vertex.get_id())

################################################################################

func _edges_incident_entry(vertex: VertexNode) -> void:
	if _edge_begin == null:
		_edges_incident_step_1(vertex)
	else:
		_edges_incident_step_2(vertex)


func _edges_incident_step_1(vertex: VertexNode) -> void:
	Globals.hide_gui()
	Globals.disable_gui()
	
	_edge_begin = vertex
	_edge_begin.anim_special(false)
	
	edge_connection_begined.emit()


func _edges_incident_step_2(vertex: VertexNode) -> void:
	Globals.show_gui()
	Globals.enable_gui()
	
	if is_same(_edge_begin, vertex):
		_edge_begin.anim_special_hover(false)
		_edge_begin = null
		
		return edge_connection_canceled.emit()
	
	if _edge_begin.is_incident_with(vertex):
		action.edges_disconnect(_edge_begin, vertex)
		
		_edge_begin.incidence_remove(vertex)
		_edge_begin.anim_special(true)
		
		_edge_begin = null
		
		return edge_connection_ended.emit()
	
	_edge_begin.incidence_create(vertex)
	action.edges_connect(_edge_begin, vertex)
	_edge_begin.anim_special(true)
	
	_edge_begin = null
	edge_connection_ended.emit()

################################################################################

func _graph_entry_remove() -> void:
	_graph_entry.remove_child(_graph_entry_render)
	_graph_entry = null; graph_entry_removed.emit()

################################################################################
