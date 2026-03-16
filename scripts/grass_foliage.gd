extends Node3D

@export var count_per_variant: int = 300
@export var ground_half_size: float = 24.5

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for child in get_children():
		if not child is MultiMeshInstance3D:
			continue
		var mm: MultiMesh = child.multimesh
		mm.instance_count = count_per_variant
		for i in count_per_variant:
			var x := rng.randf_range(-ground_half_size, ground_half_size)
			var z := rng.randf_range(-ground_half_size, ground_half_size)
			var s := rng.randf_range(0.8, 1.4)
			var t := Transform3D(Basis().scaled(Vector3(s, s, s)), Vector3(x, 0.0, z))
			mm.set_instance_transform(i, t)
