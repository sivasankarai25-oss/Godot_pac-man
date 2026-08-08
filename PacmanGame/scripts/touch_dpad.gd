extends Control
class_name TouchDPad
## Optional on-screen D-pad (spec section 6: "Optionally provide an
## on-screen directional control"). Works alongside swipe controls without
## conflicting -- both write into InputManager's pending-direction state.
## Buttons use `button_down` (not `pressed`) so holding registers
## continuously, matching how held arrow keys behave in Pacman._read_input_direction.

@onready var up_button: Button = $Up
@onready var down_button: Button = $Down
@onready var left_button: Button = $Left
@onready var right_button: Button = $Right

func _ready() -> void:
	up_button.button_down.connect(func(): InputManager.set_direction_from_dpad(Vector2i(0, -1)))
	down_button.button_down.connect(func(): InputManager.set_direction_from_dpad(Vector2i(0, 1)))
	left_button.button_down.connect(func(): InputManager.set_direction_from_dpad(Vector2i(-1, 0)))
	right_button.button_down.connect(func(): InputManager.set_direction_from_dpad(Vector2i(1, 0)))
