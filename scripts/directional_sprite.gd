class_name DirectionalSprite
extends Sprite3D
## 8-direction billboard sprite.
## Picks a spritesheet column based on the facing direction *relative to the camera*.
##
## Spritesheet column order (hframes = 8):
##   0 = N  (walking away from camera / back view, "up" on screen)
##   1 = NE, 2 = E, 3 = SE,
##   4 = S  (walking toward camera / front view)
##   5 = SW, 6 = W, 7 = NW
##
## Later, for animations, use one row per animation frame (vframes) and keep
## the 8 directions as columns. `direction_index()` stays the same.

const DIRECTIONS := 8

## When no texture is assigned, generate a placeholder sheet (pill + arrow).
@export var generate_placeholder := true
@export var body_color := Color(0.55, 0.6, 0.66)
@export var accent_color := Color(0.3, 0.9, 1.0)

## World-space facing direction (Y ignored).
var facing := Vector3.BACK


func _ready() -> void:
	if texture == null and generate_placeholder:
		texture = _make_placeholder_sheet(64)
	hframes = DIRECTIONS


func set_facing(dir: Vector3) -> void:
	dir.y = 0.0
	if dir.length_squared() > 0.0001:
		facing = dir.normalized()


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam:
		frame = direction_index(facing, cam)


## Returns 0..7, clockwise on screen, 0 = away from camera.
static func direction_index(dir: Vector3, cam: Camera3D) -> int:
	var cam_basis := cam.global_transform.basis
	var fwd := -cam_basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var right := cam_basis.x
	right.y = 0.0
	right = right.normalized()
	var angle := atan2(dir.dot(right), dir.dot(fwd))
	return wrapi(roundi(angle / (TAU / DIRECTIONS)), 0, DIRECTIONS)


# --- Placeholder art -------------------------------------------------------

func _make_placeholder_sheet(size: int) -> ImageTexture:
	var img := Image.create(size * DIRECTIONS, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var s := float(size)
	for i in DIRECTIONS:
		var ox := i * s
		# Body: a vertical "pill" whose bottom touches the frame bottom (feet).
		var r := s * 0.16
		var y := s * 0.2
		while y <= s * 0.82:
			_disc(img, Vector2(ox + s * 0.5, y), r, body_color)
			y += 1.0
		# Arrow showing the screen direction this frame represents.
		var a := i * TAU / DIRECTIONS
		var d := Vector2(sin(a), -cos(a))
		var c := Vector2(ox + s * 0.5, s * 0.5)
		for t in range(0, int(s * 0.34)):
			_disc(img, c + d * t, 2.5, Color.WHITE)
		_disc(img, c + d * s * 0.36, 5.0, accent_color)
	return ImageTexture.create_from_image(img)


func _disc(img: Image, center: Vector2, r: float, col: Color) -> void:
	for py in range(int(center.y - r), int(center.y + r) + 1):
		for px in range(int(center.x - r), int(center.x + r) + 1):
			if px < 0 or py < 0 or px >= img.get_width() or py >= img.get_height():
				continue
			if Vector2(px, py).distance_to(center) <= r:
				img.set_pixel(px, py, col)
