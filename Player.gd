extends KinematicBody

export var currentspeed = 0.0
export var maxspeed = 25.0
var speed_step = maxspeed / 5.0
export var rot_speed = 0.85

var velocity = Vector3.ZERO
var camera_spatial_reset

onready var universe_center = get_tree().get_root().get_node("/root/Main/Universe_Center")
onready var ui_soll  = get_tree().get_root().get_node("/root/Main/HUD/ui_soll")
onready var ui_ist  = get_tree().get_root().get_node("/root/Main/HUD/ui_ist")
onready var tp_speed  = get_tree().get_root().get_node("/root/Main/HUD/MarginContainer/tpSpeed")
onready var outer_camera = get_tree().get_root().get_node("/root/Main/Player/CameraSpatial/OuterCamera")
onready var camera_spatial = get_tree().get_root().get_node("/root/Main/Player/CameraSpatial")
onready var base_soll = get_tree().get_root().get_node("/root/Main/Player/BaseSoll")
onready var soll = get_tree().get_root().get_node("/root/Main/Player/BaseSoll/Soll")

#2D Vector between Ist and Soll
var move_2d
#2D Vector of Mouse Movement
var mouse_move

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera_spatial_reset = camera_spatial.transform.basis
	
func _input(event):
	if event.get_class() == "InputEventMouseMotion":
		mouse_move = (event.relative).normalized()

func _physics_process(delta):
	get_input(delta)
	velocity = move_and_slide(velocity, Vector3.UP)
		
	if camera_spatial:
		camera_spatial.global_transform.origin = $Plane.global_transform.origin
	if base_soll:
		base_soll.global_transform.origin = $Plane.global_transform.origin
		
	if mouse_move:
		base_soll.rotate_x(-mouse_move.y * delta)
		base_soll.rotate_y(-mouse_move.x * delta)
		mouse_move = Vector2(0,0)
	
	outer_camera.look_at(soll.global_transform.origin, Vector3.UP)
	
	ui_soll.rect_position.x = outer_camera.unproject_position(soll.global_transform.origin).x - ( ui_soll.rect_size.x / 2 ) 
	ui_soll.rect_position.y = outer_camera.unproject_position(soll.global_transform.origin).y - ( ui_soll.rect_size.y / 2 ) 
	
	ui_ist.rect_position.x =  outer_camera.unproject_position($BaseIst/Ist.global_transform.origin).x - ( ui_ist.rect_size.x / 2 ) 
	ui_ist.rect_position.y =  outer_camera.unproject_position($BaseIst/Ist.global_transform.origin).y - ( ui_ist.rect_size.y / 2 )
	
	move_2d = (ui_soll.rect_position - ui_ist.rect_position).normalized()
	
	#debug_geometry.clear()
	#debug_geometry.begin(PrimitiveMesh.PRIMITIVE_LINES)
	#debug_geometry.set_color(Color(1,1,1))
	#debug_geometry.add_vertex(self.transform.origin) 
	#debug_geometry.add_vertex(mousePosAim.origin) 		
	#debug_geometry.end())
	
	
var pitch_input = 0
var roll_input = 0	
var yaw_input = 0
export var input_response = 8.0
export var pitch_speed = 0.5
export var roll_speed = 0.9
export var yaw_speed = 0.5

func get_input(delta):
	
	if Input.is_action_pressed("camera_rotate"):
		var x_delta = get_viewport().size.x - get_viewport().get_mouse_position().x
		camera_spatial.transform.basis = transform.basis.rotated(transform.basis.y, x_delta * delta)
	else:
		camera_spatial.transform.basis = camera_spatial_reset
	if move_2d:
		pitch_input = lerp(pitch_input, move_2d.y * -1, input_response * delta)	
		yaw_input = lerp(yaw_input, move_2d.x * -1, input_response * delta)
		roll_input = lerp(roll_input,
			Input.get_action_strength("left") - Input.get_action_strength("right"),
			input_response * delta)
				
		transform.basis = transform.basis.rotated(transform.basis.z, roll_input * roll_speed * delta)
		transform.basis = transform.basis.rotated(transform.basis.x, pitch_input * pitch_speed * delta)
		transform.basis = transform.basis.rotated(transform.basis.y, yaw_input * yaw_speed * delta)
		transform.basis = transform.basis.orthonormalized()
	
	var vy = velocity.y
	velocity = Vector3.ZERO
	if Input.is_action_just_pressed("forward"):
		if currentspeed < maxspeed:
			currentspeed += speed_step
	if Input.is_action_just_pressed("back"):
		if currentspeed > 0:
			currentspeed -= speed_step
		
	velocity += -transform.basis.z * ((currentspeed / maxspeed) * maxspeed )
	velocity.y = vy
	
	tp_speed.value = (currentspeed / maxspeed)  * 100.0
