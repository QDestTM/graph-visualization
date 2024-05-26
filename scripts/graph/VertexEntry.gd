extends ColorRect

# SIGNALS ######################################################################

# MEMBERS ######################################################################

@export var _gui_mode: bool = false :
	set = _set_gui_mode

################################################################################
# VIRTUAL ######################################################################

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	if _gui_mode == false:
		return
	
	$AnimationPlayer.queue_free()
	print(name, " - Vertex State - freeing animation player.")


func _enter_tree() -> void:
	if _gui_mode == true:
		return
	
	$AnimationPlayer.play("circle_animation")


func _exit_tree() -> void:
	if _gui_mode == true:
		return
	
	$AnimationPlayer.stop()

################################################################################
# PUBLIC #######################################################################

################################################################################
# PRIVATE ######################################################################

func _set_gui_mode(value: bool) -> void:
	_gui_mode = value
	
	if _gui_mode == false:
		$AnimationPlayer.play("circle_animation")
	else:
		$AnimationPlayer.play("RESET")

################################################################################
# SIGNAL HANDLERS ##############################################################

################################################################################

