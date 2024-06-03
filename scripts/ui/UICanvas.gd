extends CanvasLayer

# SIGNALS ######################################################################

signal popup_panel_show(id: int)
signal popup_panel_hide(id: int)

# MEMBERS ######################################################################

var _ui_interaction_mode: Control = null
var _ui_algorithm_player: Control = null
var _ui_graph_control   : Control = null

var _btn_open_guide   : Button = null
var _btn_open_settings: Button = null
var _btn_open_search  : Button = null

var _popup_background: ColorRect = null
var _current_popup_id: int = -1

var _popup_id_guide   : int
var _popup_id_settings: int
var _popup_id_search  : int

################################################################################
# VIRTUAL ######################################################################

func _ready() -> void:
	Globals.interaction_mode_changed \
		.connect(_on_interaction_mode_change)
	
	Globals.disable_gui_request \
		.connect(_on_disable_gui_request)
	Globals.enable_gui_request \
		.connect(_on_enable_gui_request)
	
	var player: AnimationPlayer = $AnimationPlayer
	Globals.hide_gui_request \
		.connect(player.play.bind("gui_fading") )
	Globals.show_gui_request \
		.connect(player.play_backwards.bind("gui_fading") )
	
	
	Globals.disable_playmode_request \
		.connect(_on_disable_playmode_request)
	Globals.enable_playmode_request \
		.connect(_on_enable_playmode_request)
	
	_ui_interaction_mode = $"UI-ElementContainer-1/InteractionModeUI"
	_ui_algorithm_player = $"UI-ElementContainer-2/AlgorithmPlayerUI"
	_ui_graph_control    = $"UI-ElementContainer-4/GraphControlUI"
	
	_btn_open_guide    = $"UI-ElementContainer-3/GuideOpenButton"
	_btn_open_settings = $"UI-ElementContainer-6/SettingsOpenButton"
	_btn_open_search   = $"UI-ElementContainer-6/SearchOpenButton"
	
	_popup_background  = $OverlayContent/Background
	
	_popup_id_guide    = $OverlayContent/GuidePanel.get_instance_id()
	_popup_id_settings = $OverlayContent/SettingsPanel.get_instance_id()
	_popup_id_search   = $OverlayContent/SearchPanel.get_instance_id()

################################################################################
# PUBLIC #######################################################################

################################################################################
# PRIVATE ######################################################################

func _popup_panel_hide(id: int) -> void:
	assert(_current_popup_id != -1,
		"Popup need's to be opened!")
	
	_current_popup_id = -1
	popup_panel_hide.emit(id)
	
	Globals.unlock_keybinds()
	
	_popup_background.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
	$AnimationPlayer.play_backwards("popup_show")
	
	# Enabling specified interface parts
	match id:
		_popup_id_guide:
			_on_enable_gui_request()
		_popup_id_settings:
			_on_enable_gui_request()
		_popup_id_search:
			_on_enable_gui_request()


func _popup_panel_show(id: int) -> void:
	assert(_current_popup_id == -1,
		"Popup need's to be closed!")
	
	_current_popup_id = id
	popup_panel_show.emit(id)
	
	Globals.lock_keybinds()
	
	_popup_background.set_mouse_filter(Control.MOUSE_FILTER_STOP)
	$AnimationPlayer.play("popup_show")
	
	# Disabling specified interface parts
	match id:
		_popup_id_guide:
			_ui_interaction_mode.set_process_mode(PROCESS_MODE_DISABLED)
			_ui_algorithm_player.set_process_mode(PROCESS_MODE_DISABLED)
			_ui_graph_control.set_process_mode(PROCESS_MODE_DISABLED)
			
			_btn_open_settings.set_process_mode(PROCESS_MODE_DISABLED)
			_btn_open_search.set_process_mode(PROCESS_MODE_DISABLED)
		
		_popup_id_settings:
			_on_disable_gui_request()
		
		_popup_id_search:
			_ui_interaction_mode.set_process_mode(PROCESS_MODE_DISABLED)
			_ui_algorithm_player.set_process_mode(PROCESS_MODE_DISABLED)
			_ui_graph_control.set_process_mode(PROCESS_MODE_DISABLED)
			
			_btn_open_guide.set_process_mode(PROCESS_MODE_DISABLED)
			_btn_open_settings.set_process_mode(PROCESS_MODE_DISABLED)

################################################################################
# SIGNAL HANDLERS ##############################################################

func _on_interaction_mode_change() -> void:
	# Set input area mouse filter to IGNORE
	# because in normal mode it blocks interaction with vertices.
	match Globals.get_interaction_mode():
		Enums.InteractionMode.Select, Enums.InteractionMode.Edges:
			$InputArea.mouse_filter = Control.MOUSE_FILTER_IGNORE
		Enums.InteractionMode.Vertices:
			$InputArea.mouse_filter = Control.MOUSE_FILTER_STOP

################################################################################

func _on_disable_gui_request() -> void:
	_ui_interaction_mode.set_process_mode(PROCESS_MODE_DISABLED)
	_ui_algorithm_player.set_process_mode(PROCESS_MODE_DISABLED)
	_ui_graph_control.set_process_mode(PROCESS_MODE_DISABLED)
	
	_btn_open_guide.set_process_mode(PROCESS_MODE_DISABLED)
	_btn_open_settings.set_process_mode(PROCESS_MODE_DISABLED)
	_btn_open_search.set_process_mode(PROCESS_MODE_DISABLED)


func _on_enable_gui_request() -> void:
	_ui_interaction_mode.set_process_mode(PROCESS_MODE_INHERIT)
	_ui_algorithm_player.set_process_mode(PROCESS_MODE_INHERIT)
	_ui_graph_control.set_process_mode(PROCESS_MODE_INHERIT)
	
	_btn_open_guide.set_process_mode(PROCESS_MODE_INHERIT)
	_btn_open_settings.set_process_mode(PROCESS_MODE_INHERIT)
	_btn_open_search.set_process_mode(PROCESS_MODE_INHERIT)

################################################################################

func _on_disable_playmode_request() -> void:
	_on_interaction_mode_change()
	
	_ui_interaction_mode.set_process_mode(PROCESS_MODE_INHERIT)
	# Algorithm player contains own logic
	_ui_graph_control.set_process_mode(PROCESS_MODE_INHERIT)
	
	_btn_open_guide.set_process_mode(PROCESS_MODE_INHERIT)
	$AnimationPlayer.play_backwards("playmode_gui_fading")

func _on_enable_playmode_request() -> void:
	$InputArea.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
	
	_ui_interaction_mode.set_process_mode(PROCESS_MODE_DISABLED)
	# Algorithm player contains own logic
	_ui_graph_control.set_process_mode(PROCESS_MODE_DISABLED)
	
	_btn_open_guide.set_process_mode(PROCESS_MODE_DISABLED)
	$AnimationPlayer.play("playmode_gui_fading")

################################################################################

func _on_guide_open_pressed() -> void:
	if _current_popup_id == _popup_id_guide:
		return _popup_panel_hide(_popup_id_guide)
	
	_popup_panel_show(_popup_id_guide)


func _on_settings_open_pressed() -> void:
	if _current_popup_id == _popup_id_settings:
		return _popup_panel_hide(_popup_id_settings)
	
	_popup_panel_show(_popup_id_settings)


func _on_search_open_pressed() -> void:
	if _current_popup_id == _popup_id_search:
		return _popup_panel_hide(_popup_id_search)
	
	_popup_panel_show(_popup_id_search)

################################################################################

func _on_area_input(event: InputEvent) -> void:
	if Globals.is_interaction_vertices() == false \
			or not event is InputEventMouseButton:
		return
	
	var mouse := event as InputEventMouseButton
	
	if mouse.is_pressed() or \
			event.button_index != MOUSE_BUTTON_LEFT:
		return
	
	GraphManager.action.vertex_create(
		event.global_position + Globals.get_camera().position
	)


func _on_popup_background_input(event: InputEvent) -> void:
	if event.is_pressed() \
			or not event is InputEventMouseButton \
			or _current_popup_id == -1:
		return
	
	var mouse := event as InputEventMouseButton
	
	if mouse.button_index == MOUSE_BUTTON_LEFT:
		_popup_panel_hide(_current_popup_id)

################################################################################
