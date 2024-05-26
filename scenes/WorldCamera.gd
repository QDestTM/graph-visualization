extends Camera2D
class_name WorldCamera

const LIM_LEFT := 0
const LIM_RIGHT := 4000
const LIM_TOP := 0
const LIM_BOTTOM := 4000

# SIGNALS ######################################################################


# MEMBERS ######################################################################

@export_range(400.0, 800.0, 1.0)
var camera_speed: float = 500.0 # For movement by keys

var _border_rect: ReferenceRect = null
var _lock_movement: bool = false
var _dragging: bool = false

################################################################################
# VIRTUAL ######################################################################

func _ready() -> void:
	var b_rect: Rect2 = Rect2(0, 0, LIM_RIGHT, LIM_BOTTOM)
	var v_rect: Rect2 = get_viewport_rect()
	
	position = (b_rect.size / 2.0) - (v_rect.size / 2.0)


func _process(delta: float) -> void:
	if _lock_movement == true:
		return
	
	var moved: bool = false
	
	if Input.is_action_pressed("camera_move_l"):
		position.x -= camera_speed * delta
		moved = true
	elif Input.is_action_pressed("camera_move_r"):
		position.x += camera_speed * delta
		moved = true
	
	if Input.is_action_pressed("camera_move_u"):
		position.y -= camera_speed * delta
		moved = true
	elif Input.is_action_pressed("camera_move_d"):
		position.y += camera_speed * delta
		moved = true
	
	if moved == true:
		clamp_position()


func _input(event: InputEvent) -> void:
	if _lock_movement == true:
		return
	
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
	
		if mouse.button_index != MOUSE_BUTTON_RIGHT:
			return
	
		_dragging = mouse.is_pressed()
		
	elif event is InputEventMouseMotion and _dragging:
		var motion := event as InputEventMouseMotion
	
		position -= motion.relative
		clamp_position()

################################################################################
# PUBLIC #######################################################################

func init_border_rect(rect: ReferenceRect) -> void:
	assert(_border_rect == null,
		"Camera border rect already initialized!")
	
	_border_rect = rect
	print("World Camera - Border Rect initialized!")

################################################################################

func lock_movement() -> void:
	_lock_movement = true
	_border_rect.hide()


func unlock_movement() -> void:
	_lock_movement = false
	_border_rect.show()
	
	clamp_position()


func focus_on(pos: Vector2) -> void:
	var rect: Rect2 = get_viewport_rect()
	
	position = Vector2(
		pos.x - (rect.size.x / 2.0),
		pos.y - (rect.size.y / 2.0)
	)

################################################################################

func clamp_position() -> void:
	var camera_size: Vector2 = get_viewport_rect().size
	
	position.x = clampf(position.x,
		LIM_LEFT, LIM_RIGHT - camera_size.x)
	position.y = clampf(position.y,
		LIM_TOP, LIM_BOTTOM - camera_size.y)

################################################################################
# PRIVATE ######################################################################

################################################################################
# SIGNAL HANDLERS ##############################################################

################################################################################

