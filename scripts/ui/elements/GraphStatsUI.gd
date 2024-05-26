extends Control

const FRAMES_BEFORE_UPDATE = 4

# SIGNALS ######################################################################

# MEMBERS ######################################################################

var _update_counters_quequed: bool = false
var _frame_counter: int = FRAMES_BEFORE_UPDATE

var _counter_lbl_vertices: Label = null
var _counter_lbl_edges: Label = null
var _display_lbl_degree: Label = null

################################################################################
# VIRTUAL ######################################################################

func _ready() -> void:
	GraphManager.graph_stats_changed \
		.connect(_on_graph_stats_chaged)
	
	GraphManager.vertex_mouse_entered \
		.connect(_on_vertex_mouse_entered)
	GraphManager.vertex_mouse_exited \
		.connect(_on_vertex_mouse_exited)
	
	_counter_lbl_vertices = $CounterVertices/CounterLabel
	_counter_lbl_edges = $CounterEdges/CounterLabel
	_display_lbl_degree = $DisplayDegree/DisplayLabel


func _process(_delta: float) -> void:
	if _update_counters_quequed == false:
		return
	
	if _frame_counter != 0:
		_frame_counter -= 1; return
	
	_counter_lbl_vertices.text = String.num_uint64(
		Globals.get_all_vertices().size())
	
	_counter_lbl_edges.text = String.num_uint64(
		Globals.get_all_edges().size())
	
	_update_counters_quequed == true

################################################################################
# PUBLIC #######################################################################

################################################################################
# PRIVATE ######################################################################

################################################################################
# SIGNAL HANDLERS ##############################################################

func _on_vertex_mouse_entered(vertex: VertexNode) -> void:
	_display_lbl_degree.text = String.num_uint64( vertex.get_degree() )


func _on_vertex_mouse_exited(vertex: VertexNode) -> void:
	_display_lbl_degree.text = "?"

################################################################################

func _on_graph_stats_chaged() -> void:
	_frame_counter = FRAMES_BEFORE_UPDATE
	_update_counters_quequed = true

################################################################################

