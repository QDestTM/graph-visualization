extends Control

# MEMBERS ######################################################################

var _state_visible: bool = false

################################################################################
# VIRTUAL ######################################################################

func _ready() -> void:
	_on_popup_panel_hide \
		.call_deferred( get_instance_id() )

################################################################################
# PUBLIC #######################################################################

################################################################################
# PRIVATE ######################################################################

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
		
		Globals.get_camera().unlock_movement()
		visible = _state_visible

################################################################################

func _on_content_rect_resize() -> void:
	%ContentPanel.set_deferred("size", $ContentRect.size)

################################################################################
