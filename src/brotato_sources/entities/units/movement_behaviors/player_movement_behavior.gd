class_name PlayerMovementBehavior
extends MovementBehavior

const MIN_MOVE_DIST = 20

var last_movement = Vector2.ZERO

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)

# ANCHOR : Player movement
func get_movement()->Vector2:
	var movement:Vector2 = Vector2.ZERO
	
	if ProgressData.settings.mouse_only:
		var mouse_pos = get_global_mouse_position()
		movement = Vector2(mouse_pos.x - _parent.global_position.x, mouse_pos.y - _parent.global_position.y)

		if (abs(movement.x) < MIN_MOVE_DIST and abs(movement.y) < MIN_MOVE_DIST) or Input.is_mouse_button_pressed(BUTTON_LEFT):
			movement = Vector2.ZERO
	else :
		if GodotRLClient.manual_input:
			if InputService.using_gamepad:
				movement = Input.get_vector("move_left", "move_right", "move_up", "move_down")
			else :
				movement = Input.get_vector("move_left_keyboard_only", "move_right_keyboard_only", "move_up_keyboard_only", "move_down_keyboard_only")
		else:
			var controller = $"/root/Main/BrotatoAI"
		
			movement = controller.move_action

	if RunData.effects["cant_stop_moving"] and movement == Vector2.ZERO:
		if last_movement == Vector2.ZERO:
			movement = Vector2(rand_range( - PI, PI), rand_range( - PI, PI))
		else :
			movement = last_movement

	last_movement = movement

	return movement
