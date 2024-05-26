extends Control

var _delete_vertex: bool = false

################################################################################
# VIRTUAL ######################################################################

func _ready() -> void:
	GraphManager.vertex_move_begined \
		.connect(_on_vertex_move_begined)
	GraphManager.vertex_move_ended \
		.connect(_on_vertex_move_ended)


func _process(_delta: float) -> void:
	if GraphManager.is_vertex_moving() == false:
		return
	
	if _is_mouse_in_area() == _delete_vertex:
		return
	
	_delete_vertex = !_delete_vertex
	
	if _delete_vertex == true:
		GraphManager.get_moving_vertex().anim_special(false)
	else:
		GraphManager.get_moving_vertex().anim_special(true)
	

################################################################################
# PRIVATE ######################################################################

func _is_mouse_in_area() -> bool:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	return rect.has_point( get_local_mouse_position() )

################################################################################
# SIGNAL HANDLERS ##############################################################

func _on_vertex_move_begined() -> void:
	$AnimationPlayer.play("fade_panel")


func _on_vertex_move_ended() -> void:
	$AnimationPlayer.play_backwards("fade_panel")
	if _delete_vertex == false:
		return
	
	_delete_vertex = false
	GraphManager.action.vertex_delete_area()

################################################################################
