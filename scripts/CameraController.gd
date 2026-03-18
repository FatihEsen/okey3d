extends Camera3D

## Orbital camera that looks at a target point.
## Middle-mouse drag = orbit, scroll wheel = zoom, right-mouse drag = pan.

@export var target: Vector3 = Vector3(0, 0, 8)   # centre of player-0 rack area
@export var distance: float = 22.0
@export var pitch_deg: float = 45.0               # 0 = horizon, 90 = top-down
@export var yaw_deg: float = 0.0                  # 0 = looking from +Z toward origin

@export var zoom_speed: float = 2.0
@export var orbit_speed: float = 0.4
@export var pan_speed: float = 0.02
@export var min_distance: float = 4.0
@export var max_distance: float = 60.0
@export var min_pitch: float = 10.0
@export var max_pitch: float = 80.0

var _orbiting := false
var _panning  := false

func _ready() -> void:
	_apply_transform()

func _apply_transform() -> void:
	var pitch_rad = deg_to_rad(pitch_deg)
	var yaw_rad   = deg_to_rad(yaw_deg)
	# Spherical coords → cartesian offset from target
	var offset = Vector3(
		distance * cos(pitch_rad) * sin(yaw_rad),
		distance * sin(pitch_rad),
		distance * cos(pitch_rad) * cos(yaw_rad)
	)
	global_position = target + offset
	look_at(target, Vector3.UP)

func _input(event: InputEvent) -> void:
	# ── Scroll to zoom ────────────────────────────────────────────────────────
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				distance = max(min_distance, distance - zoom_speed)
				_apply_transform()
			MOUSE_BUTTON_WHEEL_DOWN:
				distance = min(max_distance, distance + zoom_speed)
				_apply_transform()
			MOUSE_BUTTON_MIDDLE:
				_orbiting = event.pressed
			MOUSE_BUTTON_RIGHT:
				_panning = event.pressed

	# ── Drag to orbit / pan ───────────────────────────────────────────────────
	if event is InputEventMouseMotion:
		if _orbiting:
			yaw_deg   -= event.relative.x * orbit_speed
			pitch_deg  = clamp(pitch_deg + event.relative.y * orbit_speed,
			                   min_pitch, max_pitch)
			_apply_transform()
		elif _panning:
			var right  = global_basis.x * (-event.relative.x * pan_speed * distance * 0.1)
			var up_vec = global_basis.y * ( event.relative.y * pan_speed * distance * 0.1)
			target += right + up_vec
			_apply_transform()

	# ── Keyboard shortcuts (F = frame rack, R = reset) ────────────────────────
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F:   # focus on rack
				target = Vector3(0, 1, 8)
				distance = 22.0
				pitch_deg = 45.0
				yaw_deg = 0.0
				_apply_transform()
			KEY_R:   # reset to export defaults
				target = Vector3(0, 0, 8)
				distance = 22.0
				pitch_deg = 45.0
				yaw_deg = 0.0
				_apply_transform()
