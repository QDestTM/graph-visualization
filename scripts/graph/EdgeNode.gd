extends Line2D
class_name EdgeNode

const WEIGHT_MAX := 1000

# MEMBERS ######################################################################

var _weight: int = 0

var _beg: VertexNode = null
var _end: VertexNode = null

var _edln_weight: LineEdit = null

################################################################################
# VIRTUAL ######################################################################

func _ready() -> void:
	$WeightEdit/ReferenceRect.visible = Globals.is_debug_mode()
	$WeightEdit/ConnectionsLabel.visible = Globals.is_debug_mode()
	
	_edln_weight = $WeightEdit

################################################################################
# PUBLIC #######################################################################

func anim_connect(back: bool) -> void:
	if back == true:
		$AnimationPlayer.play_backwards("connect")
	else:
		$AnimationPlayer.play("connect")


func anim_connect_flip(back: bool) -> void:
	if back == true:
		$AnimationPlayer.play_backwards("connect_flip")
	else:
		$AnimationPlayer.play("connect_flip")


func anim_algo_select(back: bool) -> void:
	if back == true:
		$AnimationPlayer.play_backwards("algo_select")
	else:
		$AnimationPlayer.play("algo_select")


func anim_algo_select_flip(back: bool) -> void:
	if back == true:
		$AnimationPlayer.play_backwards("algo_select_flip")
	else:
		$AnimationPlayer.play("algo_select_flip")


func anim_algo_processed(back: bool) -> void:
	if back == true:
		$AnimationPlayer.play_backwards("algo_processed")
	else:
		$AnimationPlayer.play("algo_processed")


func anim_algo_processed_flip(back: bool) -> void:
	if back == true:
		$AnimationPlayer.play_backwards("algo_processed_flip")
	else:
		$AnimationPlayer.play("algo_processed_flip")


func anim_algo_unused(back: bool) -> void:
	if back == true:
		$AnimationPlayer.play_backwards("algo_unused")
	else:
		$AnimationPlayer.play("algo_unused")


func anim_reset(back: bool = false) -> void:
	if back == true:
		$AnimationPlayer.play_backwards("reset")
	else:
		$AnimationPlayer.play("reset")

################################################################################

func get_beg_vertex() -> VertexNode:
	return _beg


func get_end_vertex() -> VertexNode:
	return _end


func get_vertex_relative(vertex: VertexNode) -> VertexNode:
	assert( is_same(vertex, _beg) or is_same(vertex, _end),
		"Vertex must be an instance of begin or end of this edge." )
	
	if is_same(vertex, _beg):
		return _end
	
	return _beg


func is_base_vertex(vertex: VertexNode) -> bool:
	assert( is_same(vertex, _beg) or is_same(vertex, _end),
		"Vertex must be an instance of begin or end of this edge." )
		
	return is_same(vertex, _beg)

################################################################################

func incidence_setup(beg: VertexNode, end: VertexNode) -> void:
	assert(_beg == null, "Beg-Vertex already set.")
	assert(_end == null, "End-Vertex already set.")
	
	$WeightEdit/ConnectionsLabel.text \
		= "%d > %d" % [ beg.get_id(), end.get_id() ]
	
	_beg = beg; _end = end
	anim_connect(false)
	update_line()

################################################################################

func update_line() -> void:
	set_point_position(0, _beg.position)
	set_point_position(1, _end.position)
	update_line_edit()


func update_line_point(vertex: VertexNode) -> void:
	if is_same(_beg, vertex):
		set_point_position(0, _beg.position)
	elif is_same(_end, vertex):
		set_point_position(1, _end.position)
	else:
		assert(false,
			"Vertex must be a begin/end of this edge.")
	
	update_line_edit()


func update_line_edit() -> void:
	var edit: LineEdit = $WeightEdit
	var pos_a := _beg.position
	var pos_b := _end.position
	
	$Center.position = pos_b + ( (pos_a - pos_b) / 2.0 )
	edit.position = $Center.position - edit.pivot_offset


func get_center_position() -> Vector2:
	return $Center.global_position

################################################################################

func animate_and_free(vertex: VertexNode) -> void:
	if is_same(vertex, _beg):
		anim_connect_flip(true)
	else:
		anim_connect(true)
	
	_beg = null; _end = null
	$AnimationPlayer.animation_finished.connect(
		func(_s: StringName) -> void: queue_free(),
		CONNECT_DEFERRED | CONNECT_ONE_SHOT
	)

################################################################################

func edlns_make_readonly() -> void:
	_edln_weight.editable = false
	_edln_weight.selecting_enabled = false


func edlns_make_editable() -> void:
	_edln_weight.editable = true
	_edln_weight.selecting_enabled = true

################################################################################

func get_weight() -> int:
	return _weight


func set_weight(x: int) -> void:
	_weight = max(x, 0)
	$WeightEdit.set_text(
		String.num_uint64(_weight)
	)

################################################################################
# PRIVATE ######################################################################

func _parse_weight_and_set(text: String) -> void:
	if text.is_valid_int() == false:
		return set_weight(0)
	
	var w_old: int = _weight
	var w_new: int = clampi(text.to_int(), 0, WEIGHT_MAX)
	
	if w_old == w_new:
		return set_weight(w_new)
	
	set_weight(w_new)
	
	GraphManager.action \
		.edge_set_weight(_beg, _end, w_old, w_new)

################################################################################
# SIGNAL HANDLERS ##############################################################

func _on_weight_edit_submit(text: String) -> void:
	_edln_weight.release_focus()
	_parse_weight_and_set(text)

################################################################################

func _on_weight_edit_mouse_exit() -> void:
	_edln_weight.release_focus()


func _on_weight_edit_focus_enter() -> void:
	if not Globals.is_playmode_camera_locked():
		Globals.get_camera().lock_movement()
	
	_parse_weight_and_set(_edln_weight.text)


func _on_weight_edit_focus_exit() -> void:
	if not Globals.is_playmode_camera_locked():
		Globals.get_camera().unlock_movement()
	
	_parse_weight_and_set(_edln_weight.text)

################################################################################
