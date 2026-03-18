extends RigidBody3D
class_name TileObject

@onready var label := $NumberLabel
@onready var hover_mesh := $HoverHighlight
@onready var collision := $CollisionShape3D

var data: OkeyTileData

signal drag_started(tile: TileObject)
signal drag_ended(tile: TileObject)

var is_hovered := false
var is_dragging := false
var drag_plane_z := 0.0

func _ready() -> void:
	if data:
		update_visuals()

func setup(_data: OkeyTileData) -> void:
	data = _data
	if is_inside_tree():
		update_visuals()

func update_visuals() -> void:
	if not label: return
	label.text = data.get_display_text()
	label.modulate = data.get_display_color()

func _on_input_event(camera: Node, event: InputEvent, position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			drag_plane_z = global_position.z
			freeze = true # Ensure it doesn't fall
			emit_signal("drag_started", self)
		else:
			if is_dragging:
				_end_drag()

func _input(event: InputEvent) -> void:
	if is_dragging and event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_end_drag()

func _end_drag() -> void:
	is_dragging = false
	emit_signal("drag_ended", self)

func _process(delta: float) -> void:
	if is_dragging:
		var camera = get_viewport().get_camera_3d()
		if not camera: return
		var mouse_pos = get_viewport().get_mouse_position()
		var ray_origin = camera.project_ray_origin(mouse_pos)
		var ray_dir = camera.project_ray_normal(mouse_pos)
		
		# Intersect with the Z-plane of where the tile was when clicked
		if abs(ray_dir.z) > 0.001:
			var t = (drag_plane_z - ray_origin.z) / ray_dir.z
			var target_pos = ray_origin + ray_dir * t
			# Lift slightly while dragging
			target_pos.y += 1.0
			global_position = global_position.lerp(target_pos, 20.0 * delta)

func _on_mouse_entered() -> void:
	is_hovered = true
	if hover_mesh and not is_dragging: hover_mesh.show()

func _on_mouse_exited() -> void:
	is_hovered = false
	if hover_mesh: hover_mesh.hide()
