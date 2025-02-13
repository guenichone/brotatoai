class_name TargetRandPosAroundPlayerMovementBehavior
extends MovementBehavior

export (int) var range_around_player = 300
export (int) var range_randomization = 100

var _actual:int
var _current_target:Vector2 = Vector2.ZERO

var player_ref:Node2D = null


func init(parent:Node)->Node:
	var _init = .init(parent)
	player_ref = (_parent as Unit).player_ref
	_actual = range_around_player + rand_range( - range_randomization, range_randomization)
	return self


func get_movement()->Vector2:
	if _current_target == Vector2.ZERO or Utils.vectors_approx_equal(_current_target, _parent.global_position, EQUALITY_PRECISION):
		_current_target = get_new_target()

	return _current_target - _parent.global_position


func get_target_position():
	return _current_target


func get_new_target()->Vector2:
	var new_target = player_ref.global_position + Vector2(rand_range( - _actual, _actual), rand_range( - _actual, _actual))

	new_target.x = clamp(new_target.x, _parent._min_pos.x, _parent._max_pos.x)
	new_target.y = clamp(new_target.y, _parent._min_pos.y, _parent._max_pos.y)

	return new_target
