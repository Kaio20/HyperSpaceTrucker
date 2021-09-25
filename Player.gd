extends KinematicBody

export var currentspeed = 0.0
export var maxspeed = 25.0
var speed_step = maxspeed / 5.0
export var rot_speed = 0.85

var velocity = Vector3.ZERO
onready var universe_center = get_tree().get_root().get_node("/root/Main/Universe_Center")
onready var ui_mousePosAim  = get_tree().get_root().get_node("/root/Main/HUD/mousePosAim")
onready var ui_mouseShouldAim  = get_tree().get_root().get_node("/root/Main/HUD/mouseShouldAim")
onready var tp_speed  = get_tree().get_root().get_node("/root/Main/HUD/MarginContainer/tpSpeed")

#Position where the Player moves towards
var mousePosAim
#Position where the Player should move towards
var mouseShouldAim
#2D Vector between mousePosAim and mouseShouldAim
var move_2d

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _physics_process(delta):
	get_input(delta)
	velocity = move_and_slide(velocity, Vector3.UP)
		
	mousePosAim = $MoveTowards.global_transform
	
	ui_mousePosAim.rect_position.x =  $Camera.unproject_position(mousePosAim.origin).x - ( ui_mousePosAim.rect_size.x / 2 ) 
	ui_mousePosAim.rect_position.y =  $Camera.unproject_position(mousePosAim.origin).y - ( ui_mousePosAim.rect_size.y / 2 )
	
	ui_mouseShouldAim.rect_position.x = get_viewport().get_mouse_position().x - ( ui_mouseShouldAim.rect_size.x / 2 ) 
	ui_mouseShouldAim.rect_position.y = get_viewport().get_mouse_position().y - ( ui_mouseShouldAim.rect_size.y / 2 )
	
	move_2d = (ui_mouseShouldAim.rect_position - ui_mousePosAim.rect_position).normalized()
	
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
