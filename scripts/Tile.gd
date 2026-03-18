extends RigidBody3D
class_name TileObject

@onready var label      := $NumberLabel
@onready var hover_mesh := $HoverHighlight
@onready var collision  := $CollisionShape3D

var data: OkeyTileData
var is_face_down: bool = false   # Yüzü kapalı mı (diğer oyuncular / deste)

signal drag_started(tile: TileObject)
signal drag_ended(tile: TileObject)
signal tile_clicked(tile: TileObject)

var is_hovered   := false
var is_dragging  := false
var is_selected  := false
var drag_plane_y := 0.0   # Sürüklerken bağlı kalınan Y düzlemi

const DRAG_THRESHOLD_PX := 8.0
var _press_screen_pos := Vector2.ZERO
var _moved_enough     := false

func _ready() -> void:
	if data:
		update_visuals()

func setup(_data: OkeyTileData, face_down: bool = false) -> void:
	data         = _data
	is_face_down = face_down
	if is_inside_tree():
		update_visuals()

func update_visuals() -> void:
	if not label: return
	if is_face_down:
		# Taşın yüzünü gizle — arka yüzü göster
		label.visible = false
		if hover_mesh:
			# Vurgu yok, etkileşim yok
			hover_mesh.visible = false
	else:
		label.visible = true
		label.text    = data.get_display_text()
		label.modulate = data.get_display_color()

func set_selected(v: bool) -> void:
	is_selected = v
	if hover_mesh and not is_face_down:
		hover_mesh.visible = v

# ─── Input ────────────────────────────────────────────────────────────────────
func _on_input_event(_camera: Node, event: InputEvent, _pos: Vector3, _norm: Vector3, _shape: int) -> void:
	# Yüzü kapalı taşlara tıklanamaz (sadece atılan yığın taşı tıklanabilmeli)
	if is_face_down and not get_meta("is_discard_top", false): return
	if not (event is InputEventMouseButton): return
	if event.button_index != MOUSE_BUTTON_LEFT: return

	if event.pressed:
		_press_screen_pos = get_viewport().get_mouse_position()
		_moved_enough     = false
		is_dragging       = true
		drag_plane_y      = global_position.y
		freeze            = true
		emit_signal("drag_started", self)
	else:
		if is_dragging:
			is_dragging = false
			if not _moved_enough:
				emit_signal("tile_clicked", self)
			else:
				emit_signal("drag_ended", self)

func _input(event: InputEvent) -> void:
	if not is_dragging: return
	if not (event is InputEventMouseButton): return
	if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		is_dragging = false
		if not _moved_enough:
			emit_signal("tile_clicked", self)
		else:
			emit_signal("drag_ended", self)

func _process(delta: float) -> void:
	if not is_dragging: return
	var mouse_now = get_viewport().get_mouse_position()

	if not _moved_enough and _press_screen_pos.distance_to(mouse_now) > DRAG_THRESHOLD_PX:
		_moved_enough = true

	if _moved_enough and not is_face_down:
		var camera = get_viewport().get_camera_3d()
		if not camera: return
		var ray_origin = camera.project_ray_origin(mouse_now)
		var ray_dir    = camera.project_ray_normal(mouse_now)
		# Y düzleminde sürükle
		if abs(ray_dir.y) > 0.001:
			var t = (drag_plane_y + 1.5 - ray_origin.y) / ray_dir.y
			var target_pos = ray_origin + ray_dir * t
			global_position = global_position.lerp(target_pos, 20.0 * delta)

func _on_mouse_entered() -> void:
	is_hovered = true
	if hover_mesh and not is_selected and not is_face_down:
		hover_mesh.show()

func _on_mouse_exited() -> void:
	is_hovered = false
	if hover_mesh and not is_selected:
		hover_mesh.hide()
