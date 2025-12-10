extends Node3D

# Node references
@onready var ship: CharacterBody3D = $Ship
@onready var target_pivot: Node3D = $TargetPivot
@onready var target_aim_point: Node3D = $TargetPivot/TargetAimPoint
@onready var actual_aim_point: Node3D = $Ship/ActualAimPoint
@onready var camera: Camera3D = $TargetPivot/SpringArm3D/Camera3D

# UI references
@onready var ui_target = get_node("/root/Main/HUD/ui_soll")
@onready var ui_actual = get_node("/root/Main/HUD/ui_ist")
@onready var tp_speed = get_node("/root/Main/HUD/MarginContainer/tpSpeed")
@onready var speed_label: Label = get_node("/root/Main/HUD/MarginContainer/SpeedLabel")

# Mouse input
var mouse_delta: Vector2 = Vector2.ZERO

# Target control (player-controlled, 360° free movement)
@export var mouse_sensitivity: float = 0.3

# Ship rotation (follows target at fixed speed)
@export var ship_rotation_speed: float = 2.0

# Movement
@export var max_speed: float = 30.0
@export var acceleration: float = 15.2
@export var deceleration: float = 10.5
var current_speed: float = 0.0


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Sync target pivot rotation with ship's initial rotation
	target_pivot.global_transform.basis = ship.global_transform.basis


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_delta = event.relative

	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _physics_process(delta: float) -> void:
	handle_target_input(delta)
	rotate_ship_toward_target(delta)
	handle_movement(delta)

	# Sync positions AFTER movement is complete
	target_pivot.global_position = ship.global_position

	update_ui()


func handle_target_input(delta: float) -> void:
	# Rotate target pivot based on mouse input (full 360° freedom)
	if mouse_delta:
		target_pivot.rotate_y(-mouse_delta.x * mouse_sensitivity * delta)
		target_pivot.rotate_object_local(Vector3.RIGHT, -mouse_delta.y * mouse_sensitivity * delta)
		mouse_delta = Vector2.ZERO


func rotate_ship_toward_target(delta: float) -> void:
	# Get direction from ship to target aim point
	var target_direction: Vector3 = (target_aim_point.global_position - ship.global_position).normalized()

	# Current forward direction of the ship
	var current_forward: Vector3 = -ship.global_transform.basis.z.normalized()

	# Only rotate if we're not already aligned
	if current_forward.dot(target_direction) < 0.9999:
		# Create a basis that looks at the target
		var target_basis := Basis.looking_at(target_direction, Vector3.UP)

		# Spherically interpolate the ship's rotation toward target
		var current_quat := ship.global_transform.basis.get_rotation_quaternion()
		var target_quat := target_basis.get_rotation_quaternion()
		var new_quat := current_quat.slerp(target_quat, ship_rotation_speed * delta)

		ship.global_transform.basis = Basis(new_quat)


func handle_movement(delta: float) -> void:
	# Player input
	var input_thrust: float = 0.0
	var fwd = Input.is_action_pressed("forward")
	var back = Input.is_action_pressed("back")

	if fwd:
		input_thrust = acceleration
	elif back:
		input_thrust = -acceleration

	# Apply thrust or drag
	if input_thrust != 0.0:
		current_speed += input_thrust * delta
		current_speed = clampf(current_speed, -max_speed * 0.5, max_speed)
	else:
		# No input - apply drag to slow down
		current_speed = move_toward(current_speed, 0.0, deceleration * delta)

	# Set velocity based on current speed
	if current_speed != 0.0:
		var move_direction: Vector3 = -ship.global_transform.basis.z.normalized()
		ship.velocity = move_direction * current_speed
		ship.move_and_slide()
	else:
		ship.velocity = Vector3.ZERO


func update_ui() -> void:
	# Update speed indicator (forward: 0-100%, reverse: 0 to -50%)
	var max_reverse: float = max_speed * 0.5
	if current_speed >= 0:
		tp_speed.value = (current_speed / max_speed) * 100.0
	else:
		tp_speed.value = (current_speed / max_reverse) * 50.0

	# Update speed label
	speed_label.text = "%.1f" % current_speed

	# Project aim points to screen and position crosshairs
	if camera and ui_target and ui_actual:
		# Target crosshair (where player is aiming)
		var target_screen_pos := camera.unproject_position(target_aim_point.global_position)
		ui_target.position = target_screen_pos - ui_target.size / 2.0

		# Actual crosshair (where ship is pointing)
		var actual_screen_pos := camera.unproject_position(actual_aim_point.global_position)
		ui_actual.position = actual_screen_pos - ui_actual.size / 2.0
