extends KinematicBody

export var speed = 15
export var rot_speed = 0.85

var velocity = Vector3.ZERO


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.


func _physics_process(delta):
	get_input(delta)
	velocity = move_and_slide(velocity, Vector3.UP)
	
	$gravity.look_at(Vector3(0,0,0),Vector3.UP)
	
	
	#self.global_transform.basis.slerp($gravity.global_transform.basis,delta*89)
#	print(Quat($gravity.global_transform.basis))
#	rotate_z(0.005) 
#	self.global_transform = self.global_transform.interpolate_with($gravity.global_transform, delta)
	#le(self.global_transform.basis,$gravity.global_transform.basis,delta)
	#$Plane.global_transform.basis.x = $Plane.global_transform.basis.x.linear_interpolate($gravity.global_transform.basis.x, delta)
	#$Plane.transform.rotated($Plane.transform.basis.z,delta*90)
	#self.global_transform.basis = Vector3(0,0,$gravity.global_transform.basis.z)
	
	
	#https://godotengine.org/qa/57911/how-to-lerp-rotation-in-godot-smooth-rotate-back-to-zero
	#Matrizen dreh matrix
	
func get_input(delta):
	var vy = velocity.y
	velocity = Vector3.ZERO
	if Input.is_action_pressed("forward"):
		velocity += -transform.basis.z * speed
	if Input.is_action_pressed("back"):
		velocity += transform.basis.z * speed
	if Input.is_action_pressed("right"):
		rotate_y(-rot_speed * delta)
	if Input.is_action_pressed("left"):
		rotate_y(rot_speed * delta)
	velocity.y = vy
