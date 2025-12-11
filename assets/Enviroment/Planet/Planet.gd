extends Node3D

func _ready() -> void:
	_generate_colliders()

func _generate_colliders() -> void:
	for child in get_children():
		if child is MeshInstance3D:
			_add_collider_to_mesh(child)

func _add_collider_to_mesh(mesh_instance: MeshInstance3D) -> void:
	if mesh_instance.mesh == null:
		return

	# Skip if already has a StaticBody3D child
	for existing_child in mesh_instance.get_children():
		if existing_child is StaticBody3D:
			return

	var static_body := StaticBody3D.new()
	var collision_shape := CollisionShape3D.new()
	collision_shape.shape = mesh_instance.mesh.create_trimesh_shape()

	static_body.add_child(collision_shape)
	mesh_instance.add_child(static_body)
