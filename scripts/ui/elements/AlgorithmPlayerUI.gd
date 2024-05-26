extends Control

# SIGNALS ######################################################################

# MEMBERS ######################################################################

var _btn_stop       : Button = null
var _btn_step_front : Button = null
var _btn_step_back  : Button = null
var _btn_auto_play  : Button = null
var _btn_play       : Button = null
var _btn_reset_entry: Button = null

var _auto_play_mode: bool = false
var _timer: Timer = null

################################################################################
# VIRTUAL ######################################################################

func _ready() -> void:
	var set_button_state := func(disabled: bool) -> void:
		_btn_reset_entry.disabled = disabled
	
	Globals.disable_playmode_request \
		.connect(_on_disable_playmode_request)
	Globals.enable_playmode_request \
		.connect(_on_enable_playmode_request)
	
	Globals.animation_finished \
		.connect(_update_button_states)
	
	GraphManager.graph_entry_defined.connect(
		set_button_state.bind(false))
	GraphManager.graph_entry_removed.connect(
		set_button_state.bind(true))
	
	_btn_stop       = $ButtonsContainer/ButtonStop
	_btn_step_front = $ButtonsContainer/ButtonStepFront
	_btn_step_back  = $ButtonsContainer/ButtonStepBack
	_btn_auto_play  = $ButtonsContainer/ButtonAutoPlay
	_btn_play       = $ButtonsContainer/ButtonPlay
	_btn_reset_entry= $ButtonResetEntry
	
	_timer = $AutoPlayTimer

################################################################################
# PUBLIC #######################################################################

func anim_no_entry() -> void:
	$AnimationPlayer.play("no_entry")

################################################################################
# PRIVATE ######################################################################

func _on_auto_play_timer_timeout() -> void:
	GraphManager.player.step_front()

	if !GraphManager.player.can_step_front():
		_auto_play_disable()

################################################################################

func _auto_play_enable() -> void:
	_auto_play_mode = true
	_timer.start(1.2)
	
	_btn_stop.disabled = true
	_btn_step_back.disabled = true
	_btn_step_front.disabled = true


func _auto_play_disable() -> void:
	_auto_play_mode = false
	_timer.stop()
	
	_btn_stop.disabled = false
	_update_button_states()

################################################################################

func _update_button_states() -> void:
	_btn_step_back.disabled \
		= !GraphManager.player.can_step_back()
	_btn_step_front.disabled \
		= !GraphManager.player.can_step_front()
	
	if !GraphManager.player.can_step_front():
		Globals.get_camera().unlock_movement()
	else:
		Globals.get_camera().lock_movement()

################################################################################
# SIGNAL HANDLERS ##############################################################

func _on_play_press() -> void:
	if !GraphManager.is_graph_entry_defined():
		Globals.send_user_message("Entry point not defined!")
		return anim_no_entry()
	
	GraphManager.player.play(
		GraphManager.get_graph_entry())


func _on_step_back_press() -> void:
	GraphManager.player.step_back()
	_update_button_states()


func _on_step_front_press() -> void:
	GraphManager.player.step_front()
	_update_button_states()


func _on_auto_play_press() -> void:
	if _auto_play_mode == true:
		_auto_play_disable()
	else:
		_auto_play_enable()


func _on_stop_press() -> void:
	GraphManager.player.stop()

################################################################################

func _on_disable_playmode_request() -> void:
	_btn_stop.disabled = true
	_btn_step_back.disabled = true
	_btn_step_front.disabled = true
	_btn_auto_play.disabled = true
	_btn_play.disabled = false
	
	Globals.get_camera().unlock_movement()
	_btn_reset_entry.disabled = false


func _on_enable_playmode_request() -> void:
	_btn_stop.disabled = false
	#_btn_step_back.disabled = false
	_btn_step_front.disabled = false
	_btn_auto_play.disabled = false
	_btn_play.disabled = true
	
	Globals.get_camera().lock_movement()
	_btn_reset_entry.disabled = true

################################################################################

func _on_reset_entry_press() -> void:
	GraphManager.action.graph_entry_remove()

################################################################################
