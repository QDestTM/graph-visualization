extends Control

# SIGNALS ######################################################################


# MEMBERS ######################################################################

var _state_visible: bool = false

var _anim_skip_mark: CheckBox = null
var _graph_restore: CheckBox = null

var _anim_speed_scale_1x: Button = null
var _anim_speed_scale_2x: Button = null
var _anim_speed_scale_3x: Button = null
var _anim_speed_scale_4x: Button = null
var _anim_speed_scale_5x: Button = null

var _anim_speed_scale_buttons: Array

################################################################################
# VIRTUAL ######################################################################

func _ready() -> void:
	var state_changer := func(state: bool) -> void:
		_anim_skip_mark.disabled = state
	
	Globals.disable_playmode_request \
		.connect(state_changer.bind(false))
	Globals.enable_playmode_request \
		.connect(state_changer.bind(true))
	
	_anim_skip_mark = %AnimationSkip
	_graph_restore = %GraphRestore
	
	_anim_speed_scale_1x = %"Scale-1x"
	_anim_speed_scale_2x = %"Scale-2x"
	_anim_speed_scale_3x = %"Scale-3x"
	_anim_speed_scale_4x = %"Scale-4x"
	_anim_speed_scale_5x = %"Scale-5x"
	
	_anim_speed_scale_buttons = [
		_anim_speed_scale_1x,
		_anim_speed_scale_2x,
		_anim_speed_scale_3x,
		_anim_speed_scale_4x,
		_anim_speed_scale_5x,
	]
	
	_on_popup_panel_hide.call_deferred( get_instance_id() )
	
	# Just for receiving values from settings
	var deffered_tasks := func() -> void:
		_anim_skip_mark.button_pressed \
			= Globals.is_playmode_skip_animation()
		_graph_restore.button_pressed \
			= Globals.is_graph_restore()
		
		var speed_scale: float \
			= Globals.get_playmode_speed_scale()
		var button: Button \
			= _anim_speed_scale_buttons[int(speed_scale) - 1]
	
		_anim_speed_scale_button_disable(button)
	
	deffered_tasks.call_deferred()

################################################################################
# PUBLIC #######################################################################

################################################################################
# PRIVATE ######################################################################

func _anim_speed_scale_button_disable(button: Button) -> void:
	for _button in _anim_speed_scale_buttons as Array[Button]:
		_button.disabled = is_same(button, _button)

################################################################################
# SIGNAL HANDLERS ##############################################################

func _on_popup_panel_hide(id: int) -> void:
	if get_instance_id() != id:
		return
	
	_state_visible = false
	# Most properties will change in animation finish handler
	$AnimationPlayer.play_backwards("show_ui")


func _on_popup_panel_show(id: int) -> void:
	if get_instance_id() != id:
		return
	
	_state_visible = true
	visible = _state_visible
	
	set_process_mode(PROCESS_MODE_INHERIT)
	Globals.get_camera().lock_movement()
	
	$AnimationPlayer.play("show_ui")

################################################################################

func _on_animation_finish(animation: StringName) -> void:
	if animation == "show_ui" and !_state_visible:
		set_process_mode(PROCESS_MODE_DISABLED)
		
		# This check need because settings can be
		# opened while playmode active
		if not Globals.is_playmode_enabled():
			Globals.get_camera().unlock_movement()
		
		visible = _state_visible


func _on_content_rect_resize() -> void:
	%ContentPanel.set_deferred("size", $ContentRect.size)

################################################################################

func _on_anim_speed_scale_1x_pressed() -> void:
	_anim_speed_scale_button_disable(_anim_speed_scale_1x)
	Globals.set_playmode_speed_scale(1.0)

func _on_anim_speed_scale_2x_pressed() -> void:
	_anim_speed_scale_button_disable(_anim_speed_scale_2x)
	Globals.set_playmode_speed_scale(2.0)

func _on_anim_speed_scale_3x_pressed() -> void:
	_anim_speed_scale_button_disable(_anim_speed_scale_3x)
	Globals.set_playmode_speed_scale(3.0)

func _on_anim_speed_scale_4x_pressed() -> void:
	_anim_speed_scale_button_disable(_anim_speed_scale_4x)
	Globals.set_playmode_speed_scale(4.0)

func _on_anim_speed_scale_5x_pressed() -> void:
	_anim_speed_scale_button_disable(_anim_speed_scale_5x)
	Globals.set_playmode_speed_scale(5.0)

################################################################################

func _on_animation_skip_toggled(toggled_on: bool) -> void:
	Globals.set_playmode_animation_skip(toggled_on)


func _on_graph_restore_toggled(toggled_on: bool) -> void:
	Globals.set_graph_restore(toggled_on)

################################################################################
