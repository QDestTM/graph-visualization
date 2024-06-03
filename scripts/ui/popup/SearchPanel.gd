extends Control

# SIGNALS ######################################################################

# MEMBERS ######################################################################

var _state_visible: bool = false

var _last_search: String = ""

var _search_line: LineEdit = null
var _items_grid: GridContainer = null

var _items_left: int = 0
var _items: Array[Button] = []

################################################################################
# VIRTUAL ######################################################################

func _ready() -> void:
	_search_line = %SearchLine
	_items_grid = %GridContainer

################################################################################
# PUBLIC #######################################################################

################################################################################
# PRIVATE ######################################################################

func _get_free_item() -> Button:
	if _items_left == 0:
		var scene: PackedScene = preload(
			"res://scenes/ui/components/SearchPanelItem.tscn")
		
		var item: Button = scene.instantiate() as Button
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		_items.append(item)
		_items_grid.add_child(item)
	
	var item: Button = _items[
			_items.size() - (_items_left + 1) ]
	
	if _items_left > 0:
		_items_left -= 1
	
	return item


func _append_item(vertex: VertexNode) -> void:
	var item: Button = _get_free_item()
	
	var callable := _on_item_click.bind(vertex.get_id())
	item.pressed.connect(callable)
	
	var label: Label = item.get_node("%Label")
	label.text = vertex.get_tag()
	item.show()


func _remove_items() -> void:
	for item in _items as Array[Button]:
		var connections := item.pressed.get_connections()
		
		for connection in connections:
			item.pressed.disconnect(connection["callable"])
		
		item.hide()
	
	_items_left = _items.size()

################################################################################

func _search_from_input(popup: bool) -> void:
	_search(_search_line.text, popup)


func _search(search: String, popup: bool) -> void:
	search = search.to_upper().replace(" ", "")
	_search_line.text = search
	
	if search == _last_search and not popup:
		return
	
	var vertices: Array = Globals.get_all_vertices()
	_remove_items()
	
	if search.is_empty():
		return
	
	for vertex in vertices as Array[VertexNode]:
		var tag: String = vertex.get_tag()
		
		if tag.contains(search) or search.contains(tag):
			_append_item(vertex)
	
	_last_search = search

################################################################################
# SIGNAL HANDLERS ##############################################################

func _on_popup_panel_hide(id: int) -> void:
	if get_instance_id() != id:
		return
	
	_search_line.release_focus()
	
	_state_visible = false
	# Most properties will change in animation finish handler
	$AnimationPlayer.play_backwards("show_ui")


func _on_popup_panel_show(id: int) -> void:
	if get_instance_id() != id:
		return
	
	_state_visible = true
	visible = _state_visible
	
	_search_from_input(true)
	_search_line.grab_focus()
	
	set_process_mode(PROCESS_MODE_INHERIT)
	if not Globals.is_playmode_camera_locked():
		Globals.get_camera().lock_movement()
	
	$AnimationPlayer.play("show_ui")

################################################################################

func _on_animation_finish(animation: StringName) -> void:
	if animation == "show_ui" and !_state_visible:
		set_process_mode(PROCESS_MODE_DISABLED)
		
		if not Globals.is_playmode_camera_locked():
			Globals.get_camera().unlock_movement()
		
		visible = _state_visible


func _on_content_rect_resize() -> void:
	%ContentPanel.set_deferred("size", $ContentRect.size)

################################################################################

func _on_item_click(id: int) -> void:
	var vertex: VertexNode \
		= GraphManager.vertex_from_id(id)
	
	Globals.focus_vertex(vertex)

################################################################################

func _on_search_button_pressed() -> void:
	_search_line.release_focus()
	_search_from_input(false)


func _on_search_line_submit(text: String) -> void:
	_search_line.release_focus()
	_search(text, false)

################################################################################
