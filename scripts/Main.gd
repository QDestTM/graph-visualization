extends Node

# MEMBERS ######################################################################

################################################################################
# VIRTUAL ######################################################################

func _ready() -> void:
	#Thread.set_thread_safety_checks_enabled(false)
	#print("Main - Thread safety checks disabled.")
	
	var version: String = ProjectSettings \
		.get_setting("application/config/version")
	DisplayServer.window_set_title(
		"Graph Visualization v%s" % version)
	
	PhysicsServer2D.set_active(false)
	DisplayServer.window_set_min_size(Vector2i(800, 600))
	
	Globals.init_world_camera($GraphRoot/WorldCamera)
	Globals.get_camera().init_border_rect($BorderRect)
	
	GraphManager.init_graph_root($GraphRoot)
	Globals.userdata_load()
	
	Globals.send_user_message \
		.call_deferred("Press (F1) for Guide >")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Globals.userdata_save()

################################################################################
# PUBLIC #######################################################################

################################################################################
# PRIVATE ######################################################################

################################################################################
# SIGNAL HANDLERS ##############################################################

func _on_background_rect_resize() -> void:
	Globals.get_camera().clamp_position()

################################################################################
