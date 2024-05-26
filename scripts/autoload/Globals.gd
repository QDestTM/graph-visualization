extends Node

# SIGNALS ######################################################################

signal interaction_mode_changed()

signal disable_gui_request()
signal enable_gui_request()

signal hide_gui_request()
signal show_gui_request()

signal disable_playmode_request()
signal enable_playmode_request()

signal animation_finished()

signal userdata_loading(data: Dictionary)
signal userdata_saving(data: Dictionary)

signal user_message_sending(message: String)

# MEMBERS ######################################################################

var ID: IDGenerator = IDGenerator.new()

var _playmode_speed_scale: float = 1.0
var _playmode_skip_animation: bool = false

var _graph_restore: bool = true

var _interaction_mode: Enums.InteractionMode

var _gui_disabled: bool = false
var _gui_visible: bool = true

var _playmode_disabled: bool = true
var _debug_mode: bool = false

var _world_camera: WorldCamera = null

################################################################################
# VIRTUAL ######################################################################

func _ready() -> void:
	userdata_loading \
		.connect(_on_userdata_loading)
	userdata_saving \
		.connect(_on_userdata_saving)
	
	_interaction_mode = Enums.InteractionMode.Select
	_debug_nodes_update_visibility.call_deferred()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("swith_debug_mode"):
		_debug_mode = !_debug_mode
		_debug_nodes_update_visibility()

################################################################################
# PUBLIC #######################################################################

func init_world_camera(camera: WorldCamera) -> void:
	assert(_world_camera == null, "World camera already initialized.")
	
	_world_camera = camera
	print("Received node - World Camera")

################################################################################

func userdata_load() -> void:
	var path: String = "user://_userdata.jsog"
	
	if not FileAccess.file_exists(path):
		return
	
	var file := FileAccess.open(path, FileAccess.READ)
	var data: Dictionary = JSON.parse_string(
		file.get_as_text(false))
	
	if data != null:
		userdata_loading.emit(data)
	
	file.close()


func userdata_save() -> void:
	var path: String = "user://_userdata.jsog"
	var data: Dictionary = {}
	
	userdata_saving.emit(data)
	var file := FileAccess.open(path, FileAccess.WRITE)
	
	file.store_string(
		JSON.stringify(data, "\t", false, false)
	)
	file.close()

################################################################################

func disable_gui() -> void:
	assert(_gui_disabled == false,
		"GUI already disabled!")
	
	_gui_disabled = true
	disable_gui_request.emit()


func enable_gui() -> void:
	assert(_gui_disabled == true,
		"GUI already active!")
	
	_gui_disabled = false
	enable_gui_request.emit()

################################################################################

func hide_gui() -> void:
	assert(_gui_visible == true,
		"GUI already hidden.")
	
	_gui_visible = false
	hide_gui_request.emit()


func show_gui() -> void:
	assert(_gui_visible == false,
		"GUI already visible.")
	
	_gui_visible = true
	show_gui_request.emit()

################################################################################

func disable_playmode() -> void:
	assert(_playmode_disabled == false,
		"Play mode already disabled.")
	
	_playmode_disabled = true
	disable_playmode_request.emit()
	
	for edge in get_all_edges() as Array[EdgeNode]:
		edge.weight_make_editable()
	
	_world_camera.clamp_position()


func enable_playmode() -> void:
	assert(_playmode_disabled == true,
		"Play mode already enabled.")
	
	_playmode_disabled = false
	enable_playmode_request.emit()
	
	for edge in get_all_edges() as Array[EdgeNode]:
		edge.weight_make_readonly()

################################################################################

func set_playmode_speed_scale(scale: float) -> void:
	assert(scale > 0, "Speed scale can't be 0 or less!")
	
	_playmode_speed_scale = scale
	update_playmode_speed_scale()


func update_playmode_speed_scale() -> void:
	if is_playmode_enabled():
		Engine.time_scale = _playmode_speed_scale
	else:
		Engine.time_scale = 1.0


func get_playmode_speed_scale() -> float:
	return _playmode_speed_scale

func set_playmode_animation_skip(state: bool) -> void:
	_playmode_skip_animation = state

################################################################################

func set_graph_restore(state: bool) -> void:
	_graph_restore = state

################################################################################

func invoke_animation_finished() -> void:
	animation_finished.emit()

func focus_vertex(vertex: VertexNode) -> void:
	_world_camera.focus_on(vertex.position)

func send_user_message(message: String) -> void:
	user_message_sending.emit(message)

################################################################################

func clamp_world_position(rect: Rect2) -> Vector2:
	var position: Vector2 = Vector2.ZERO
	
	position.x = clampf(
		rect.position.x,
		_world_camera.LIM_LEFT,
		_world_camera.LIM_RIGHT - rect.size.x
	)
	
	position.y = clampf(
		rect.position.y,
		_world_camera.LIM_TOP,
		_world_camera.LIM_BOTTOM - rect.size.y
	)
	
	return position

################################################################################

func set_interaction_mode(mode: Enums.InteractionMode) -> void:
	if _interaction_mode == mode:
		return
	
	_interaction_mode = mode
	interaction_mode_changed.emit()

################################################################################

func get_interaction_mode() -> Enums.InteractionMode:
	return _interaction_mode

func get_all_vertices() -> Array:
	return get_tree().get_nodes_in_group("vertices")

func get_all_edges() -> Array:
	return get_tree().get_nodes_in_group("edges")

func get_camera() -> WorldCamera:
	return _world_camera

################################################################################

func is_playmode_skip_animation() -> bool:
	return _playmode_skip_animation

func is_graph_restore() -> bool:
	return _graph_restore

func is_gui_visible() -> bool:
	return _gui_visible

func is_gui_enabled() -> bool:
	return !_gui_disabled

func is_playmode_enabled() -> bool:
	return !_playmode_disabled

func is_debug_mode() -> bool:
	return _debug_mode

################################################################################

func is_interaction_select() -> bool:
	return _interaction_mode == Enums.InteractionMode.Select

func is_interaction_vertices() -> bool:
	return _interaction_mode == Enums.InteractionMode.Vertices

func is_interaction_edges() -> bool:
	return _interaction_mode == Enums.InteractionMode.Edges

################################################################################
# PRIVATE ######################################################################

func _get_all_debug_nodes() -> Array:
	return get_tree().get_nodes_in_group("debug_node")

################################################################################

func _debug_nodes_update_visibility() -> void:
	var nodes: Array = _get_all_debug_nodes()
	
	for node in nodes as Array[CanvasItem]:
		node.visible = _debug_mode

################################################################################
# SIGNAL HANDLERS ##############################################################

func _on_userdata_loading(data: Dictionary) -> void:
	var settings: Dictionary = data.get("settings", {})
	_playmode_speed_scale = settings.get("playmode_speed_scale", 1.0)
	_playmode_skip_animation = settings.get("playmode_skip_animation", false)
	
	_graph_restore = settings.get("graph_restore", true)


func _on_userdata_saving(data: Dictionary) -> void:
	data["settings"] = {
		"playmode_speed_scale"    : _playmode_speed_scale,
		"playmode_skip_animation" : _playmode_skip_animation,
		"graph_restore"           : _graph_restore
	}

################################################################################
