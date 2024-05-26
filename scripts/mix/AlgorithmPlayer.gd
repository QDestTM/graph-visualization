extends Object
class_name AlgorithmPlayer

const EXIT_THREAD := true

# MEMBERS ######################################################################

var _actions: UndoRedo = UndoRedo.new()
var _display: OperationDisplay = null

var _thread_exit: bool = false
var _thread: Thread = Thread.new()
var _semaphore: Semaphore = Semaphore.new()

var _entry: VertexNode = null

################################################################################
# VIRTUAL ######################################################################

################################################################################
# PUBLIC #######################################################################

func play(entry: VertexNode) -> void:
	assert( entry != null, "Entry point can't be null." )
	assert( Globals.is_playmode_enabled() == false,
		"Algorithm Player already active." )
	
	Globals.enable_playmode()
	
	_thread.start(_dijkstra_process)
	_thread_exit = false
	_entry = entry


func stop() -> void:
	assert( Globals.is_playmode_enabled() == true,
		"Algorithm Player don't active." )
	
	Globals.disable_playmode()
	
	_actions.clear_history(false)
	_thread_exit = true
	
	_semaphore.post()
	_thread.wait_to_finish \
		.call_deferred()
	
	_clean_all(false)
	_entry = null
	
	Globals.update_playmode_speed_scale()


################################################################################

func setup_operation_display() -> void:
	assert(_display == null, "Operation Display already initialized.")
	var scene := preload("res://scenes/ui/OperationDisplay.tscn")
	
	_display = scene.instantiate()
	assert(_display != null, "Failed to intantiate Operation Display.")
	
	GraphManager.get_root().add_child(_display)


################################################################################

func step_back() -> void:
	if !_actions.has_undo():
		return
	
	_actions.undo()


func step_front() -> void:
	if _actions.has_redo():
		_actions.redo()
	else:
		_semaphore.post()


func can_step_back() -> bool:
	return _actions.has_undo()


func can_step_front() -> bool:
	return _actions.has_redo() or _thread.is_alive()

################################################################################
# PRIVATE ######################################################################

# Use only in other thread.
func _dijkstra_process() -> void:
	# Remove all posts from semaphore
	while _semaphore.try_wait() != false:
		pass
	
	# Basic initializations
	var vertices := Globals.get_all_vertices()
	
	for vertex in vertices as Array[VertexNode]:
		vertex.set_distance.call_deferred(-1)
	
	_entry.set_distance.call_deferred(0)
	
	# Algorithm work
	var processed: Dictionary = {}
	var next_queue: Dictionary = {}
	
	var queue: Array = [_entry]
	_semaphore.wait()
	
	Globals.update_playmode_speed_scale.call_deferred()
	
	while queue.size() > 0:
		if _thread_exit == EXIT_THREAD:
			return _clean_all(true)
		
		for vertex in queue as Array[VertexNode]:
			if _thread_exit == EXIT_THREAD:
				return _clean_all(true)
			
			var distance := vertex.get_distance()
			var edges := vertex.incidence_get_edges()
			
			if not Globals.is_playmode_skip_animation():
				Globals.focus_vertex.call_deferred(vertex)
			
			#########################################################
			if _action_vertex_select(vertex) == EXIT_THREAD:
				return _clean_all(true)
			#########################################################
			
			for edge in edges as Array[EdgeNode]:
				if _thread_exit == EXIT_THREAD:
					return _clean_all(true)
				
				var p_vertex := edge.get_vertex_relative(vertex)
				if processed.has(p_vertex):
					continue
				
				#########################################################
				if _action_edge_select(edge, vertex) == EXIT_THREAD:
					return _clean_all(true)
				
				if _action_vertex_select(p_vertex) == EXIT_THREAD:
					return _clean_all(true)
				#########################################################
				
				var p_distance := p_vertex.get_distance()
				
				var weight := edge.get_weight()
				var new_dist := distance + weight
				
				#########################################################
				if _action_show_move(vertex, p_vertex, edge) == EXIT_THREAD:
					return _clean_all(true)
				
				if _action_show_operation(vertex, edge) == EXIT_THREAD:
					return _clean_all(true)
				#########################################################
				
				# Updating distance of the processing vertex
				# only if new distance lower than current
				# or distance is "INF" (-1)
				if p_distance == -1 or new_dist < p_distance:
					#########################################################
					if _action_show_compare(new_dist, true) == EXIT_THREAD:
						return _clean_all(true)
					
					if _action_show_assign(p_vertex, new_dist) == EXIT_THREAD:
						return _clean_all(true)
					#########################################################
				
				else:
				#########################################################
					if _action_show_compare(new_dist, false) == EXIT_THREAD:
						return _clean_all(true)
					
					if _action_show_discard(p_vertex, new_dist) == EXIT_THREAD:
						return _clean_all(true)
				#########################################################
				
				
				
				if _action_vertex_deselect(p_vertex) == EXIT_THREAD:
					return _clean_all(true)
				
				if _action_edge_diselect(edge, vertex) == EXIT_THREAD:
					return _clean_all(true)
				#########################################################
				
				# Next vertices for processing
				next_queue[p_vertex] = null
			# EDGES LOOP END
			
			# Preparing to process next vertices
			processed[vertex] = null
			
			#########################################################
			var unprocs = edges.filter(
				func(edge: EdgeNode) -> bool:
					return !processed.has(
						edge.get_vertex_relative(vertex)
					)
			)
			
			if _action_vertex_processed(vertex, unprocs) == EXIT_THREAD:
				return _clean_all(true)
			#########################################################
			
		queue = next_queue.keys().filter(
			func(vertex: VertexNode) -> bool:
				return !processed.has(vertex)
		)
		queue.sort_custom(
			func(v1: VertexNode, v2: VertexNode) -> bool:
				return v1.get_distance() < v2.get_distance()
		)
		
		next_queue.clear()
		# END VERICES LOOP
	# END WHILE
	
	# Searching unused vertices and edges
	var unused_vertices: Dictionary = {}
	var unused_edges: Dictionary = {}
	
	for vertex in vertices as Array[VertexNode]:
		if processed.has(vertex):
			continue
		
		unused_vertices[vertex] = null
		var edges := vertex.incidence_get_edges()
		
		for edge in edges as Array[EdgeNode]:
			unused_edges[edge] = null
	
	if ( unused_vertices.size() + unused_edges.size() ) != 0 \
		and _action_unused(unused_vertices.keys(),
			unused_edges.keys() ) == EXIT_THREAD:
		return _clean_all(true)
	
	# Animation finish action
	var procd_vertices: Array = processed.keys()
	var procd_edges: Dictionary = {}
	
	for vertex in procd_vertices as Array[VertexNode]:
		var edges := vertex.incidence_get_edges()
		
		for edge in edges as Array[EdgeNode]:
			procd_edges[edge] = null
	
	if _action_finish(procd_vertices, procd_edges.keys()) == EXIT_THREAD:
		return _clean_all(true)
	
	Globals.invoke_animation_finished.call_deferred()

################################################################################

func _wait_for_next_step() -> bool:
	_semaphore.wait(); return _thread_exit


func _clean_all(is_thread: bool = false) -> void:
	var clean_vertices := Globals.get_all_vertices()
	var clean_edges := Globals.get_all_edges()
	
	var vertex_cleaner: Callable
	var edge_cleaner: Callable
	
	if is_thread == true:
		_display.clean_all.call_deferred()
		
		vertex_cleaner = \
			func(v: VertexNode) -> void:
				v.reset_distance.call_deferred()
				v.anim_reset.call_deferred(false)
			
		edge_cleaner = \
			func(e: EdgeNode) -> void:
				e.anim_reset.call_deferred(false)
	else:
		_display.clean_all()
		
		vertex_cleaner = \
			func(v: VertexNode) -> void:
				v.reset_distance()
				v.anim_reset(false)
			
		edge_cleaner = \
			func(e: EdgeNode) -> void:
				e.anim_reset(false)
	
	#######################################################
	for v in clean_vertices as Array[VertexNode]:
		vertex_cleaner.call(v)
	
	for e in clean_edges as Array[EdgeNode]:
		edge_cleaner.call(e)

################################################################################

# select - True for select animation and false for deselect.
func _action_vertex(vertex: VertexNode, select: bool) -> bool:
	_actions.create_action("Vertex Action")
	
	var do_action := func(back: bool) -> void:
		Globals.focus_vertex(vertex)
		vertex.anim_algo_select(back)
	
	_actions.add_do_method(
		do_action.bind(!select)
	)
	_actions.add_undo_method(
		do_action.bind(select)
	)
	_actions.commit_action(false)
	
	if Globals.is_playmode_skip_animation():
		return !EXIT_THREAD
	
	do_action.call_deferred(!select)
	return _wait_for_next_step()


func _action_vertex_select(vertex: VertexNode) -> bool:
	return _action_vertex(vertex, true)

func _action_vertex_deselect(vertex: VertexNode) -> bool:
	return _action_vertex(vertex, false)

################################################################################

func _action_edge(
	edge: EdgeNode, from: VertexNode, select: bool
) -> bool:
	_actions.create_action("Edge Action")
	
	var animation_method: Callable
	
	var focus_begin: VertexNode
	var focus_end: VertexNode
	
	if select == true:
		focus_end = edge.get_vertex_relative(from)
		focus_begin = from
	else:
		focus_begin = edge.get_vertex_relative(from)
		focus_end = from
	
	if edge.is_base_vertex(from):
		animation_method = edge.anim_algo_select
	else:
		animation_method = edge.anim_algo_select_flip
	
	_actions.add_do_method(
		func() -> void:
			Globals.focus_vertex(focus_end)
			animation_method.call(!select)
	)
	_actions.add_undo_method(
		func() -> void:
			Globals.focus_vertex(focus_begin)
			animation_method.call(select)
	)
	_actions.commit_action(false)
	
	if Globals.is_playmode_skip_animation():
		return !EXIT_THREAD
	
	animation_method.call_deferred(!select)
	Globals.focus_vertex.call_deferred(focus_end)
	
	return _wait_for_next_step()


func _action_edge_select(edge: EdgeNode, from: VertexNode) -> bool:
	return _action_edge(edge, from, true)

func _action_edge_diselect(edge: EdgeNode, from: VertexNode) -> bool:
	return _action_edge(edge, from, false)

################################################################################

func _action_vertex_processed(
	vertex: VertexNode, edges: Array
) -> bool:
	_actions.create_action("Mark Processed")
	
	var do_action := func(back: bool) -> void:
		Globals.focus_vertex(vertex)
		vertex.anim_algo_processed(back)
		
		for edge in edges as Array[EdgeNode]:
			if edge.is_base_vertex(vertex):
				edge.anim_algo_processed(back)
			else:
				edge.anim_algo_processed_flip(back)
	
	_actions.add_do_method(
		do_action.bind(false)
	)
	_actions.add_undo_method(
		do_action.bind(true)
	)
	_actions.commit_action(false)
	
	if Globals.is_playmode_skip_animation():
		return !EXIT_THREAD
	
	do_action.call_deferred(false)
	return _wait_for_next_step()

################################################################################

func _action_unused(vertices: Array, edges: Array) -> bool:
	if ( vertices.size() + edges.size() ) == 0:
		return false
	
	_actions.create_action("Mark Unused")
	
	var do_action := func(back: bool) -> void:
		for vertex in vertices as Array[VertexNode]:
			vertex.anim_algo_unused(back)
	
		for edge in edges as Array[EdgeNode]:
			edge.anim_algo_unused(back)
	
	_actions.add_do_method(
		do_action.bind(false)
	)
	_actions.add_undo_method(
		do_action.bind(true)
	)
	_actions.commit_action(false)
	
	if Globals.is_playmode_skip_animation():
		do_action.call_deferred(false)
		return !EXIT_THREAD
	
	do_action.call_deferred(false)
	return _wait_for_next_step()


func _action_finish(vertices: Array, edges: Array) -> bool:
	_actions.create_action("Finish Animation")
	
	var do_action := func(back: bool) -> void:
		for vertex in vertices as Array[VertexNode]:
			vertex.anim_algo_unused(!back)
		
		for edge in edges as Array[EdgeNode]:
			edge.anim_algo_unused(!back)
	
	_actions.add_do_method(
		do_action.bind(false)
	)
	_actions.add_undo_method(
		do_action.bind(true)
	)
	_actions.commit_action(false)
	
	if Globals.is_playmode_skip_animation():
		return !EXIT_THREAD
	
	do_action.call_deferred(false)
	return _wait_for_next_step()

################################################################################

func _action_show_move(
	vertex: VertexNode, v_connect: VertexNode, edge: EdgeNode,
) -> bool:
	_actions.create_action("Show Operation Move")
	
	var do_action := func(back: bool) -> void:
		_display.connect_to_vertex(v_connect)
		
		var w_pos: Vector2 = edge.get_center_position()
		var v_pos: Vector2 = vertex.get_center_position()
		
		var w_value: int = edge.get_weight()
		var v_value: int = vertex.get_distance()
		
		w_pos -= _display.position
		v_pos -= _display.position
		
		_display.show_move(v_value, v_pos, w_value, w_pos, back)
	
	_actions.add_do_method(
		do_action.bind(false)
	)
	_actions.add_undo_method(
		do_action.bind(true)
	)
	_actions.commit_action(false)
	
	if Globals.is_playmode_skip_animation():
		return !EXIT_THREAD
	
	do_action.call_deferred(false)
	return _wait_for_next_step()


func _action_show_operation(
	vertex: VertexNode, edge: EdgeNode
) -> bool:
	_actions.create_action("Show Operation Operation")
	
	var do_action := func(back: bool) -> void:
		var w_value: int = edge.get_weight()
		var v_value: int = vertex.get_distance()
		
		var sum: int = v_value + w_value
		
		_display.show_operation(v_value, w_value, sum, back)
	
	_actions.add_do_method(
		do_action.bind(false)
	)
	_actions.add_undo_method(
		do_action.bind(true)
	)
	_actions.commit_action(false)
	
	if Globals.is_playmode_skip_animation():
		return !EXIT_THREAD
	
	do_action.call_deferred(false)
	return _wait_for_next_step()


func _action_show_compare(
	value: int, assign: bool
) -> bool:
	_actions.create_action("Show Operation Compare")
	
	var do_action := func(back: bool) -> void:
		_display.show_compare(value, assign, back)
	
	_actions.add_do_method(
		do_action.bind(false)
	)
	_actions.add_undo_method(
		do_action.bind(true)
	)
	_actions.commit_action(false)
	
	if Globals.is_playmode_skip_animation():
		return !EXIT_THREAD
	
	do_action.call_deferred(false)
	return _wait_for_next_step()

################################################################################

func _action_show_assign(
	vertex: VertexNode, distance: int
) -> bool:
	_actions.create_action("Show Operation Assign")
	
	var old_distance: int = vertex.get_distance()
	
	var do_action := func(back: bool) -> void:
		if back == true:
			vertex.set_distance(old_distance)
		else:
			vertex.set_distance(distance)
		
		_display.connect_to_vertex(vertex)
		_display.show_assign(distance, back)
	
	_actions.add_do_method(
		do_action.bind(false)
	)
	_actions.add_undo_method(
		do_action.bind(true)
	)
	_actions.commit_action(false)
	
	if Globals.is_playmode_skip_animation():
		vertex.set_distance_thread(distance)
		return !EXIT_THREAD
	
	do_action.call_deferred(false)
	return _wait_for_next_step()


func _action_show_discard(
	vertex: VertexNode, distance: int
) -> bool:
	_actions.create_action("Show Operation Assign")
	
	var do_action := func(back: bool) -> void:
		_display.connect_to_vertex(vertex)
		_display.show_discard(distance, back)
	
	_actions.add_do_method(
		do_action.bind(false)
	)
	_actions.add_undo_method(
		do_action.bind(true)
	)
	_actions.commit_action(false)
	
	if Globals.is_playmode_skip_animation():
		return !EXIT_THREAD
	
	do_action.call_deferred(false)
	return _wait_for_next_step()

################################################################################
