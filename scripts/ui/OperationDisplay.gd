extends Control
class_name OperationDisplay

const MOVE_DURATION := 0.7

const L_OPD_POS := Vector2(20, 0)
const R_OPD_POS := Vector2(80, 0)
const OP_POS := Vector2.ZERO

const _TEST_ANIMATIONS := false

# SIGNALS ######################################################################


# MEMBERS ######################################################################

var _tween: Tween = null
var _move_duration: float = 0.4

var _lbl_operator_plus: Label = null
var _lbl_operand_l: Label = null
var _lbl_operand_r: Label = null
var _lbl_operator: Label = null

var _point: Marker2D = null

################################################################################
# VIRTUAL ######################################################################

func _ready() -> void:
	print("Operation Display - Animations Testing - ", _TEST_ANIMATIONS)
	
	_lbl_operator_plus = $"Operator-Plus"
	_lbl_operand_l = $"Operand-L"
	_lbl_operand_r = $"Operand-R"
	_lbl_operator = $"Operator"
	_point = $Point
	
	labels_make_transparent()
	
	_move_duration = $AnimationPlayer.get_animation("move").length
	_test_animations()

################################################################################
# PUBLIC #######################################################################

func show_move(
	val_l: int, from_l: Vector2,
	val_r: int, from_r: Vector2,
	reverse: bool
) -> void:
	_respawn_tween()
	
	set_operand_l(val_l)
	set_operand_r(val_r)
	set_operator("?")
	
	from_l -= _lbl_operand_l.pivot_offset
	from_r -= _lbl_operand_r.pivot_offset
	
	if reverse == false:
		$AnimationPlayer.play("move")
		
		_tween.parallel().tween_property(_lbl_operand_l, "position",
			L_OPD_POS, _move_duration).set_trans(Tween.TRANS_SINE) \
				.set_ease(Tween.EASE_IN_OUT).from(from_l)
		
		_tween.parallel().tween_property(_lbl_operand_r, "position",
			R_OPD_POS, _move_duration).set_trans(Tween.TRANS_SINE) \
				.set_ease(Tween.EASE_IN_OUT).from(from_r)
	
	else:
		$AnimationPlayer.play_backwards("move")
		
		_tween.parallel().tween_property(_lbl_operand_l, "position",
			from_l, _move_duration).set_trans(Tween.TRANS_SINE) \
				.set_ease(Tween.EASE_IN_OUT).from(L_OPD_POS)
		
		_tween.parallel().tween_property(_lbl_operand_r, "position",
			from_r, _move_duration).set_trans(Tween.TRANS_SINE) \
				.set_ease(Tween.EASE_IN_OUT).from(R_OPD_POS)


func show_operation(
	val_l: int, val_r: int,
	result: int, reverse: bool
) -> void:
	_kill_tween()
	
	if reverse == false:
		$AnimationPlayer.play("operation")
		set_operand_l(result)
		set_operand_r(val_r)
		
	else:
		$AnimationPlayer.play_backwards("operation_reverse")
		set_operand_l(val_l)
		set_operand_r(val_r)


func show_compare(value: int, assign: bool, reverse: bool) -> void:
	_kill_tween()
	
	set_operand_l(value)
	
	_lbl_operand_l.position = L_OPD_POS
	_lbl_operator.position = OP_POS
	
	if reverse == false:
		
		if assign == false:
			$AnimationPlayer.play("compare_discard")
			set_operator("<")
		else:
			$AnimationPlayer.play("compare_assign")
			set_operator(">")
		
	else:
		$AnimationPlayer.play("compare_reset")
		set_operator("?")


func show_assign(value: int, reverse: bool) -> void:
	_kill_tween()
	
	set_operand_l(value)
	
	if reverse == false:
		$AnimationPlayer.play("assign")
	else:
		$AnimationPlayer.play_backwards("assign_reverse")


func show_discard(value: int, reverse: bool) -> void:
	_kill_tween()
	
	set_operand_l(value)
	
	if reverse == false:
		$AnimationPlayer.play("discard")
	else:
		$AnimationPlayer.play_backwards("discard")

################################################################################

func set_operand_l(value: int) -> void:
	_lbl_operand_l.text = String.num_uint64(value)

func set_operand_r(value: int) -> void:
	_lbl_operand_r.text = String.num_uint64(value)


func set_operator(value: String) -> void:
	_lbl_operator.text = value

################################################################################

func clean_all() -> void:
	_kill_tween()
	
	$AnimationPlayer.stop()
	labels_make_transparent()

################################################################################

func labels_make_transparent() -> void:
	_lbl_operator_plus.self_modulate = Color.TRANSPARENT
	_lbl_operator.self_modulate = Color.TRANSPARENT
	
	_lbl_operand_l.self_modulate = Color.TRANSPARENT
	_lbl_operand_r.self_modulate = Color.TRANSPARENT

################################################################################

func connect_to_vertex(vertex: VertexNode) -> void:
	position = vertex.position - _point.position
	labels_make_transparent()

################################################################################
# PRIVATE ######################################################################

func _kill_tween() -> void:
	if _tween == null:
		return
	
	_tween.kill()


func _respawn_tween() -> void:
	if _tween == null:
		_tween = create_tween(); return
	
	_tween.kill(); _tween = create_tween()

################################################################################

func _test_animations() -> void:
	if _TEST_ANIMATIONS == false:
		return
	
	var callable1 := show_move \
		.bind(10, Vector2(100, 100), 20, Vector2(200, 100), false)
	
	var callable2 := show_operation.bind(10, 20, 30, false)
	var callable3 := show_compare.bind(true, false)
	
	var callable4 := show_assign.bind(30, false)
	var callable5 := show_assign.bind(30, true)
	
	var callable6 := show_compare.bind(true, true)
	var callable7 := show_compare.bind(false, false)
	
	var callable8 := show_discard.bind(30, false)
	var callable9 := show_discard.bind(30, true)
	
	var callable10 := show_compare.bind(false, true)
	
	var callable11 := show_operation.bind(10, 20, 30, true)
	var callable12 := show_move \
		.bind(10, Vector2(100, 100), 20, Vector2(200, 100), true)
	
	get_tree().create_timer(2).timeout.connect(callable1)
	get_tree().create_timer(4).timeout.connect(callable2)
	get_tree().create_timer(6).timeout.connect(callable3)
	get_tree().create_timer(8).timeout.connect(callable4)
	get_tree().create_timer(10).timeout.connect(callable5)
	get_tree().create_timer(12).timeout.connect(callable6)
	get_tree().create_timer(14).timeout.connect(callable7)
	get_tree().create_timer(16).timeout.connect(callable8)
	get_tree().create_timer(18).timeout.connect(callable9)
	get_tree().create_timer(20).timeout.connect(callable10)
	get_tree().create_timer(22).timeout.connect(callable11)
	get_tree().create_timer(24).timeout.connect(callable12)

################################################################################
# SIGNAL HANDLERS ##############################################################

################################################################################
