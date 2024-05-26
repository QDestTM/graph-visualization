extends Control

# SIGNALS ######################################################################

# MEMBERS ######################################################################

var _restore_path: String = "user://_restore.jsog"

var _last_opened_path: String = "user://"
var _last_opened_file: String = "graph.json"

var _last_file: String = "graph.json"
var _filters := PackedStringArray(["*.json"])
var _acting: bool = false

################################################################################
# VIRTUAL ######################################################################

func _ready() -> void:
	Globals.userdata_loading \
		.connect(_on_userdata_loading)
	Globals.userdata_saving \
		.connect(_on_userdata_saving)
	
	$ButtonConfirm.disabled = true

################################################################################
# PUBLIC #######################################################################

################################################################################
# PRIVATE ######################################################################

func _update_last_data(path: String) -> void:
	var split_path := path.rsplit("\\", true, 1)
	
	_last_opened_path = split_path[0]
	_last_opened_file = split_path[1]

################################################################################

func _restore_load() -> void:
	if !Globals.is_graph_restore():
		return
	
	var exists: bool = FileAccess \
		.file_exists(_restore_path)
	
	if exists == false:
		return
	
	_graph_load(_restore_path)
	print("Graph Control - Graph Restored.")


func _restore_save() -> void:
	_save_graph(_restore_path)
	print("Graph Control - Graph Backuped.")

################################################################################

func _save_graph(path: String) -> void:
	var data: Dictionary = {
		"vertices" : {},
		"edges"    : [],
		"entry"    : -1,
		"camera"   : [
			Globals.get_camera().position.x,
			Globals.get_camera().position.y
		]
	}
	
	var vertices_data: Dictionary = data["vertices"]
	var edges_data   : Array      = data["edges"]
	var nodes: Array
	
	# Writing vertices data
	nodes = Globals.get_all_vertices()
	for vertex in nodes as Array[VertexNode]:
		vertices_data[vertex.get_id()] = [
			vertex.global_position.x,
			vertex.global_position.y
		]
	
	# Writing edges data
	nodes = Globals.get_all_edges()
	for edge in nodes as Array[EdgeNode]:
		edges_data.append([
			edge.get_beg_vertex().get_id(),
			edge.get_end_vertex().get_id(),
			edge.get_weight()
		])
	
	# Writing entry data
	if GraphManager.is_graph_entry_defined():
		data["entry"] = GraphManager.get_graph_entry().get_id()
	
	# Finishing
	var file := FileAccess.open(path, FileAccess.WRITE)
	
	file.store_string(
		JSON.stringify(data, "\t", false, false))
	
	file.close()
	
	if path != _restore_path:
		Globals.send_user_message("Graph Saved!")
		_update_last_data(path)


func _graph_load(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	var data: Dictionary = JSON.parse_string(
			file.get_as_text(false))
	
	file.close()
	
	if _validate_json_data(data) == false:
		return Globals.send_user_message("Invalid data format!")
	
	# Building graph from data
	GraphManager.destroy_graph()
	
	# Reading vertices data
	var data_vertices: Dictionary = data["vertices"]
	
	for key in data_vertices.keys() as Array[String]:
		var pos_data: Array = data_vertices[key]
		Globals.ID.set_temporary( key.to_int() )
		
		GraphManager.vertex_create(
			Vector2(pos_data[0], pos_data[1]))
	
	# Reading edges data
	var data_edges: Array = data["edges"]
	
	for edge in data_edges as Array[Array]:
		var beg_vertex: VertexNode \
			= GraphManager.vertex_from_id(edge[0])
		var end_vertex: VertexNode \
			= GraphManager.vertex_from_id(edge[1])
		
		beg_vertex.incidence_create(end_vertex, edge[2])
	
	# Reding entry data
	var entry_id: int = data["entry"]
	if entry_id >= 0:
		GraphManager.graph_entry_define(
			GraphManager.vertex_from_id(entry_id))
	
	# Reding camera position data
	var data_camera: Array = data["camera"]
	Globals.get_camera().position = Vector2(
		data_camera[0],
		data_camera[1]
	)
	
	if path != _restore_path:
		_update_last_data(path)
		Globals.send_user_message("Graph Loaded!")


################################################################################

func _validate_json_data(data: Dictionary) -> bool:
	if data == null:
		return false
	
	if not data.has("vertices"):
		return false
	if not data.has("edges"):
		return false
	if not data.has("entry"):
		return false
	if not data.has("camera"):
		return false
	
	if not data["vertices"] is Dictionary:
		return false
	if not data["edges"] is Array:
		return false
	if not data["entry"] is float:
		return false
	if not data["camera"] is Array:
		return false
	
	# Validating vertices data
	var data_vertices: Dictionary = data["vertices"]
	
	for key in data_vertices.keys() as Array[String]:
		if not key.is_valid_int():
			return false
		
		var _position = data_vertices[key]
		
		if not _position is Array:
			return false
		if (_position as Array).size() != 2:
			return false
		
		for x in _position as Array:
			if not x is float:
				return false
	
	# Validating edges data
	var data_edges: Array = data["edges"]
	
	for value in data_edges as Array:
		if not value is Array:
			return false
		if (value as Array).size() != 3:
			return false
		
		for x in value as Array:
			if not x is float:
				return false
		
		# Edge weight must be in range
		if value[2] < 0 or value[2] > EdgeNode.WEIGHT_MAX:
			return false
		
		# Vertices ids can't be equal
		if value[0] == value[1]:
			return false
		
		# Vertices ids must exists
		var id_beg := String.num_uint64( value[0] )
		var id_end := String.num_uint64( value[1] )
		
		if not data_vertices.has(id_beg):
			return false
		if not data_vertices.has(id_end):
			return false
	
	# Validating camera position
	var data_camera: Array = data["camera"]
	
	if data_camera.size() != 2:
		return false
	
	for value in data_camera:
		if not value is float:
			return false
	
	return true

################################################################################

func _graph_save_action_callback(
	state: bool, paths: PackedStringArray, _i: int
) -> void:
	if state == false:
		_acting = false; return
	
	_save_graph(paths[0])
	_acting = false


func _graph_load_action_callback(
	state: bool, paths: PackedStringArray, _i: int
) -> void:
	if state == false:
		_acting = false; return
	
	_graph_load(paths[0])
	_acting = false

################################################################################
# SIGNAL HANDLERS ##############################################################

func _on_userdata_loading(data: Dictionary) -> void:
	_last_opened_path = data.get("last_opened_path", "user://")
	_last_opened_file = data.get("last_opened_file", "graph.json")
	
	_restore_load()


func _on_userdata_saving(data: Dictionary) -> void:
	data["last_opened_path"] = _last_opened_path
	data["last_opened_file"] = _last_opened_file
	
	_restore_save()

################################################################################

func _on_button_save_pressed() -> void:
	if _acting == true:
		return
	
	_acting = true
	DisplayServer.file_dialog_show(
		"Save Graph", _last_opened_path, _last_opened_file, false,
		DisplayServer.FILE_DIALOG_MODE_SAVE_FILE, _filters,
		_graph_save_action_callback
	)


func _on_button_load_pressed() -> void:
	if _acting == true:
		return
	
	_acting = true
	DisplayServer.file_dialog_show(
		"Load Graph", _last_opened_path, _last_opened_file, false,
		DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, _filters,
		_graph_load_action_callback
	)

################################################################################

func _on_timer_timeout() -> void:
	$AnimationPlayer.play_backwards("show_confirm")
	$ButtonConfirm.disabled = true


func _on_button_confirm_pressed() -> void:
	$AnimationPlayer.play_backwards("show_confirm")
	$ButtonConfirm.disabled = true
	
	$ConfirmTimer.stop()
	
	GraphManager.destroy_graph()
	Globals.send_user_message("Graph Cleared!")


func _on_button_clean_pressed() -> void:
	$AnimationPlayer.play("show_confirm")
	$ConfirmTimer.start()
	
	$ButtonConfirm.disabled = false

################################################################################
