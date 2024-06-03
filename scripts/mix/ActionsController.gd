extends Object
class_name ActionController

# MEMBERS ######################################################################

var _undo_redo: UndoRedo = UndoRedo.new()
var _vertex_move_from: Vector2 = Vector2.ZERO

################################################################################
# VIRTUAL ######################################################################

################################################################################
# PUBLIC #######################################################################

func undo() -> void:
	if !_undo_redo.has_undo():
		return
	
	_undo_redo.undo()


func redo() -> void:
	if !_undo_redo.has_redo():
		return
	
	_undo_redo.redo()


func clean_actions() -> void:
	_undo_redo.clear_history(false)

################################################################################

func vertex_move_begin(vertex: VertexNode) -> void:
	_vertex_move_from = vertex.position


func vertex_move_end(vertex: VertexNode) -> void:
	_undo_redo.create_action("Move Vertex")
	
	var from: Vector2 = _vertex_move_from
	var dest: Vector2 = vertex.position
	var id: int = vertex.get_id()
	
	_undo_redo.add_do_method(
		func() -> void: vfid(id).update_position(dest)
	)
	_undo_redo.add_undo_method(
		func() -> void: vfid(id).update_position(from)
	)
	
	_undo_redo.commit_action(false)

################################################################################

func vertex_create(position: Vector2) -> void:
	_undo_redo.create_action("Append Vertex")
	
	var id: int = Globals.ID.get_next()
	
	_undo_redo.add_do_method(
		func() -> void:
			Globals.ID.set_temporary(id)
			GraphManager.vertex_create(position)
	)
	_undo_redo.add_undo_method(
		func() -> void:
			GraphManager.vertex_delete_by_id(id)
	)
	
	_undo_redo.commit_action()


func vertex_delete(vertex: VertexNode) -> void:
	_undo_redo.create_action("Remove Vertex")
	
	var position: Vector2 = vertex.position
	var tag: String = vertex.get_tag()
	var id: int = vertex.get_id()
	
	var is_entry: bool = vertex.is_graph_entry()
	
	var vertices: Array \
		= vertex.incidence_get_ids()
	var weights: Array \
		= vertex.incidence_get_weights()
	
	_undo_redo.add_do_method(
		func() -> void:
			GraphManager.vertex_delete_by_id(id)
	)
	_undo_redo.add_undo_method(
		func() -> void:
			Globals.ID.set_temporary(id)
			GraphManager.vertex_create(position)
			
			var _vertex: VertexNode = vfid(id)
			
			if is_entry == true:
				GraphManager.graph_entry_define(_vertex)
			
			if not tag.is_empty():
				GraphManager.define_tag(_vertex, tag)
				_vertex.set_tag(tag)
			
			_reconnect_edges(vertices, weights, id)
	)
	
	_undo_redo.commit_action()


func vertex_delete_area() -> void:
	_undo_redo.create_action("Remove Vertex (Area)")
	
	var vertex: VertexNode = GraphManager.get_moving_vertex()
	
	var position: Vector2 = _vertex_move_from
	var tag: String = vertex.get_tag()
	var id: int = vertex.get_id()
	
	var is_entry: bool = vertex.is_graph_entry()
	
	var vertices: Array \
		= vertex.incidence_get_ids()
	var weights: Array \
		= vertex.incidence_get_weights()
	
	_undo_redo.add_do_method(
		func() -> void:
			GraphManager.vertex_delete_by_id(id)
	)
	_undo_redo.add_undo_method(
		func() -> void:
			Globals.ID.set_temporary(id)
			GraphManager.vertex_create(position)
			
			var _vertex: VertexNode = vfid(id)
			
			if is_entry == true:
				GraphManager.graph_entry_define(_vertex)
			
			if not tag.is_empty():
				GraphManager.define_tag(_vertex, tag)
				_vertex.set_tag(tag)
			
			_reconnect_edges(vertices, weights, id)
	)
	
	_undo_redo.commit_action()

################################################################################

func vertex_set_tag(vertex: VertexNode, new_tag: String) -> void:
	_undo_redo.create_action("Vertex Set Tag")
	
	var old_tag: String = vertex.get_tag()
	var id: int = vertex.get_id()
	
	_undo_redo.add_do_method(
		func() -> void:
			var _vertex: VertexNode = vfid(id)
			
			if _vertex.is_tag_defined():
				_vertex.remove_tag()
			
			GraphManager.define_tag(_vertex, new_tag)
			_vertex.set_tag(new_tag)
	)
	_undo_redo.add_undo_method(
		func() -> void:
			var _vertex: VertexNode = vfid(id)
			
			if _vertex.is_tag_defined():
				_vertex.remove_tag()
			
			if not old_tag.is_empty():
				GraphManager.define_tag(_vertex, old_tag)
			
			_vertex.set_tag(old_tag)
	)
	
	_undo_redo.commit_action(false)

################################################################################

func graph_entry_define(old: VertexNode, new: VertexNode) -> void:
	_undo_redo.create_action("Graph Entry Change")
	
	var is_old_null: bool = (old == null)
	
	var id_new: int = new.get_id()
	var id_old: int = -1
	
	if is_old_null == false:
		id_old = old.get_id()
	
	_undo_redo.add_do_method(
		func() -> void:
			GraphManager.graph_entry_define( vfid(id_new) )
	)
	_undo_redo.add_undo_method(
		func() -> void:
			if is_old_null == true:
				GraphManager.graph_entry_remove()
			else:
				GraphManager.graph_entry_define( vfid(id_old) )
	)
	
	_undo_redo.commit_action()


func graph_entry_remove() -> void:
	_undo_redo.create_action("Graph Entry Remove")
	
	var id: int = GraphManager.get_graph_entry().get_id()
	
	_undo_redo.add_do_method(
		func() -> void:
			GraphManager.graph_entry_remove()
	)
	_undo_redo.add_undo_method(
		func() -> void:
			GraphManager.graph_entry_define( vfid(id) )
	)
	
	_undo_redo.commit_action()

################################################################################

func edges_connect(beg: VertexNode, end: VertexNode) -> void:
	_undo_redo.create_action("Edges Connect")
	
	var id1: int = beg.get_id()
	var id2: int = end.get_id()
	
	var weight: int = beg.get_edge(end) \
		.get_weight()
	
	_undo_redo.add_do_method(
		func() -> void:
			vfid(id1).incidence_create( vfid(id2), weight )
	)
	_undo_redo.add_undo_method(
		func() -> void:
			vfid(id1).incidence_remove( vfid(id2) )
	)
	
	_undo_redo.commit_action(false)


func edges_disconnect(beg: VertexNode, end: VertexNode) -> void:
	_undo_redo.create_action("Edges Disconnect")
	
	var id1: int = beg.get_id()
	var id2: int = end.get_id()
	
	var weight: int = beg.get_edge(end) \
		.get_weight()
	
	_undo_redo.add_do_method(
		func() -> void:
			vfid(id1).incidence_remove( vfid(id2) )
	)
	_undo_redo.add_undo_method(
		func() -> void:
			vfid(id1).incidence_create( vfid(id2), weight )
	)
	
	_undo_redo.commit_action(false)

################################################################################

func edge_set_weight(
	beg: VertexNode, end: VertexNode, w_old: int, w_new: int
) -> void:
	_undo_redo.create_action("Set Edge Weight")
	
	var id1: int = beg.get_id()
	var id2: int = end.get_id()
	
	_undo_redo.add_do_method(
		func() -> void:
			vfid(id1).get_edge( vfid(id2) ).set_weight(w_new)
	)
	_undo_redo.add_undo_method(
		func() -> void:
			vfid(id1).get_edge( vfid(id2) ).set_weight(w_old)
	)
	
	_undo_redo.commit_action(false)

################################################################################
# PRIVATE ######################################################################

# Vertex from id shortcut.
func vfid(id: int) -> VertexNode:
	return GraphManager.vertex_from_id(id)

# Vertex validate id shortcut.
func vvid(id: int) -> bool:
	return GraphManager.is_vertex_id_valid(id)


func _reconnect_edges(vertices: Array, weights: Array, id: int) -> void:
	var vertex: VertexNode = vfid(id)
	
	for i in vertices.size():
		var v_id: int = vertices[i]
		
		if !vvid(v_id):
			return
		
		vertex.incidence_create(
			vfid(v_id), weights[i] )

################################################################################
