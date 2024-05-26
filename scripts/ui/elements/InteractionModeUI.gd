extends Control

################################################################################
# VIRTUAL ######################################################################

func _ready() -> void:
	Globals.interaction_mode_changed \
		.connect(_on_interaction_mode_change)

################################################################################
# PUBLIC #######################################################################

func set_mode_select() -> void:
	Globals.set_interaction_mode(Enums.InteractionMode.Select)

func set_mode_vertices() -> void:
	Globals.set_interaction_mode(Enums.InteractionMode.Vertices)

func set_mode_edges() -> void:
	Globals.set_interaction_mode(Enums.InteractionMode.Edges)

################################################################################
# SIGNAL HANDLERS ##############################################################

func _on_interaction_mode_change() -> void:
	match Globals.get_interaction_mode():
		Enums.InteractionMode.Select:
			%ModeTexture.texture = preload("res://resources/icons/cursor.png")
		Enums.InteractionMode.Vertices:
			%ModeTexture.texture = preload("res://resources/icons/vertex.png")
		Enums.InteractionMode.Edges:
			%ModeTexture.texture = preload("res://resources/icons/edge.png")

################################################################################
