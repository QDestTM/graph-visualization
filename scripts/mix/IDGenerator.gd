extends Object
class_name IDGenerator

# MEMBERS ######################################################################

var _id_next_temp: int = -1
var _id: int = -1

################################################################################
# PUBLIC #######################################################################

func set_temporary(id: int) -> void:
	_id_next_temp = id


func use_next() -> int:
	if _id_next_temp != -1:
		return _use_next_temp()
	
	_id += 1; return _id


func reset_id() -> void:
	_id = -1; _id_next_temp = -1

func get_next() -> int:
	return _id + 1

################################################################################
# PRIVATE ######################################################################

func _use_next_temp() -> int:
	if _id_next_temp == get_next():
		_id += 1
	
	var id: int = _id_next_temp
	_id_next_temp = -1; return id

################################################################################

