extends Node3D

# Node references
@onready var ship: CharacterBody3D = $Ship
@onready var target_pivot: Node3D = $TargetPivot
@onready var target_aim_point: Node3D = $TargetPivot/TargetAimPoint
@onready var actual_aim_point: Node3D = $Ship/ActualAimPoint
@onready var camera: Camera3D = $TargetPivot/SpringArm3D/Camera3D
@onready var impact_particles: GPUParticles3D = $Ship/ImpactParticles

# UI references
@onready var ui_target = get_node("/root/Main/HUD/ui_soll")
@onready var ui_actual = get_node("/root/Main/HUD/ui_ist")
@onready var tp_speed = get_node("/root/Main/HUD/MarginContainer/tpSpeed")
@onready var speed_label: Label = get_node("/root/Main/HUD/MarginContainer/SpeedLabel")
@onready var hull_label: Label = get_node("/root/Main/HUD/HullLabel")

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

# Hull
@export var max_hull: float = 100.0
@export var damage_multiplier: float = 0.5
@export var pushback_strength: float = 1.3
var hull: float = 100.0
var pushback_velocity: Vector3 = Vector3.ZERO
var was_colliding: bool = false


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

	# Decay pushback velocity
	pushback_velocity = pushback_velocity.move_toward(Vector3.ZERO, 20.0 * delta)

	# Set velocity based on current speed + pushback
	var move_direction: Vector3 = -ship.global_transform.basis.z.normalized()
	ship.velocity = move_direction * current_speed + pushback_velocity

	var velocity_before_collision := ship.velocity
	ship.move_and_slide()

	handle_collisions(velocity_before_collision)


func handle_collisions(velocity_before: Vector3) -> void:
	var is_colliding := ship.get_slide_collision_count() > 0

	if not is_colliding:
		was_colliding = false
		return

	# Only process damage on initial impact, not continuous contact
	var is_new_collision := not was_colliding
	was_colliding = true

	for i in ship.get_slide_collision_count():
		var collision := ship.get_slide_collision(i)
		var normal := collision.get_normal()

		# Calculate impact strength based on velocity into the surface
		var impact_velocity := -velocity_before.dot(normal)
		if impact_velocity <= 0.5:
			continue

		# Only apply damage and effects on initial impact
		if is_new_collision:
			# Apply damage proportional to impact
			var damage := impact_velocity * damage_multiplier
			hull -= damage
			hull = maxf(hull, 0.0)

			# Apply pushback away from collision (scales quadratically with impact)
			var impact_ratio := impact_velocity / max_speed
			pushback_velocity = normal * impact_ratio * impact_ratio * pushback_strength * max_speed

			# Reduce forward speed proportional to impact
			current_speed *= 1.0 - clampf(impact_ratio, 0.3, 0.9)

			# Spawn impact particles at collision point
			if impact_particles:
				impact_particles.global_position = collision.get_position()
				impact_particles.restart()


func update_ui() -> void:
	# Update speed indicator (forward: 0-100%, reverse: 0 to -50%)
	var max_reverse: float = max_speed * 0.5
	if current_speed >= 0:
		tp_speed.value = (current_speed / max_speed) * 100.0
	else:
		tp_speed.value = (current_speed / max_reverse) * 50.0

	# Update speed label
	speed_label.text = "%.1f" % current_speed

	# Update hull display
	if hull_label:
		var hull_percent := (hull / max_hull) * 100.0
		hull_label.text = "Hull: %d%%" % hull_percent

		# Color based on hull status
		if hull_percent > 60:
			hull_label.add_theme_color_override("font_color", Color(0.3, 1, 0.3))
		elif hull_percent > 30:
			hull_label.add_theme_color_override("font_color", Color(1, 1, 0.3))
		else:
			hull_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))

	# Project aim points to screen and position crosshairs
	if camera and ui_target and ui_actual:
		# Target crosshair (where player is aiming)
		var target_screen_pos := camera.unproject_position(target_aim_point.global_position)
		ui_target.position = target_screen_pos - ui_target.size / 2.0

		# Actual crosshair (where ship is pointing)
		var actual_screen_pos := camera.unproject_position(actual_aim_point.global_position)
		ui_actual.position = actual_screen_pos - ui_actual.size / 2.0
