extends Node3D

const ROOM_HALF_X := 5.8
const ROOM_MIN_Z := -7.4
const ROOM_MAX_Z := 3.6
const GRAB_DISTANCE := 0.38
const RAY_LENGTH := 8.0

var font_regular: FontFile
var font_bold: FontFile

var left_controller: XRController3D
var right_controller: XRController3D
var xr_origin: XROrigin3D
var xr_camera: XRCamera3D
var left_ray: MeshInstance3D
var right_ray: MeshInstance3D

var hud_root: Node3D
var step_label: Label3D
var desc_label: Label3D
var hint_label: Label3D

var trigger_target: StaticBody3D
var teleport_marker: StaticBody3D
var skip_button: StaticBody3D
var headset_confirm: StaticBody3D
var gate_center: Vector3 = Vector3(0.0, 1.1, -6.2)
var gate_nodes: Array[Node3D] = []

var screwdriver_tool: StaticBody3D
var cutter_tool: StaticBody3D
var movable_object: StaticBody3D
var bolt_target: MeshInstance3D
var wire_target: MeshInstance3D
var drop_zone: MeshInstance3D

var grabbables: Array = []
var held_object: Node3D = null
var held_by_controller: XRController3D = null
var held_local_xform: Transform3D = Transform3D.IDENTITY
var bolt_progress: float = 0.0

var current_step: int = 0
var stick_directions_done := {"up": false, "down": false, "left": false, "right": false}
var face_buttons_done := {"right_ax": false, "right_by": false, "left_ax": false, "left_by": false}

var locomotion_enabled: bool = false
var teleport_enabled: bool = false
var move_speed: float = 1.5
var turn_cooldown: float = 0.0

var steps_data := [
	{
		"title": "خوش‌آمدید",
		"desc": "مرکز منابع یادگیری\nاداره آموزش و تعالی منابع انسانی شرکت پالایش نفت اصفهان\n\nبند مچی دسته‌ها را ببندید. دکمه ماشه (Trigger) را روی یکی از دسته‌ها فشار دهید."
	},
	{
		"title": "ماشه — Trigger",
		"desc": "انگشت اشاره را روی ماشه جلوی دسته بگذارید. به کره نارنجی نشانه بگیرید و ماشه را فشار دهید."
	},
	{
		"title": "گریپ — Grip",
		"desc": "دکمه کناری دسته، زیر انگشت میانی، Grip است. برای گرفتن اشیا از آن استفاده می‌شود. Grip چپ یا راست را فشار دهید."
	},
	{
		"title": "گرفتن ابزار",
		"desc": "دسته را نزدیک پیچ‌گوشتی، انبردست یا قطعه آبی روی میز ببرید و Grip را نگه دارید تا ابزار در دست بماند. سپس Grip را رها کنید."
	},
	{
		"title": "آنالوگ — Thumbstick",
		"desc": "اهرم گرد دسته چپ را به چهار جهت بالا، پایین، چپ و راست تا انتها فشار دهید."
	},
	{
		"title": "کلیک آنالوگ",
		"desc": "اهرم آنالوگ راست یا چپ را مثل دکمه به پایین فشار دهید (Thumbstick Click)."
	},
	{
		"title": "دکمه‌های A B X Y",
		"desc": "راست: A پایین و B بالا. چپ: X پایین و Y بالا. هر چهار دکمه را یکی‌یکی بزنید."
	},
	{
		"title": "منو — Menu",
		"desc": "دکمه منو روی دسته چپ، بالای دکمه Y است. آن را فشار دهید.\nدکمه Meta روی دسته راست برای سیستم هدست است و داخل این برنامه خوانده نمی‌شود."
	},
	{
		"title": "دکمه‌های خود هدست",
		"desc": "کنار هدست: دکمه صدا (+) و (−) و دکمه روشن/خاموش.\nروشن/خاموش را در آموزش فشار ندهید. به تابلوی تأیید روی دیوار نشانه بگیرید و ماشه را بزنید."
	},
	{
		"title": "جابه‌جایی با تله‌پورت",
		"desc": "به حلقه سبز روی زمین نشانه بگیرید و ماشه را بزنید تا به آنجا بروید."
	},
	{
		"title": "حرکت نرم",
		"desc": "اهرم دسته چپ را به جلو فشار دهید و از دروازه آبی عبور کنید. اهرم راست چپ/راست، چرخش است."
	},
	{
		"title": "پیچ‌گوشتی",
		"desc": "پیچ‌گوشتی زرد را با Grip بردارید، نوک را نزدیک پیچ ببرید و ماشه را نگه دارید تا پیچ سفت شود."
	},
	{
		"title": "قطع سیم",
		"desc": "انبردست قرمز را با Grip بردارید، نزدیک سیم سبز ببرید و ماشه را بزنید."
	},
	{
		"title": "جاگذاری قطعه",
		"desc": "مکعب آبی را با Grip بردارید و روی مربع سبز میز رها کنید."
	},
	{
		"title": "پایان آموزش",
		"desc": "آفرین. اکنون می‌توانید در مرکز منابع یادگیری آزادانه حرکت کنید و ابزارها را بردارید.\nاداره آموزش و تعالی منابع انسانی شرکت پالایش نفت اصفهان"
	},
]


func _ready() -> void:
	font_regular = load("res://assets/fonts/Vazirmatn-Regular.ttf")
	font_bold = load("res://assets/fonts/Vazirmatn-Bold.ttf")

	xr_origin = $XROrigin
	xr_camera = $XROrigin/XRCamera
	left_controller = $XROrigin/LeftController
	right_controller = $XROrigin/RightController

	_attach_controller_model(left_controller, Color(0.2, 0.45, 0.85))
	_attach_controller_model(right_controller, Color(0.85, 0.25, 0.22))
	_build_room()
	_build_table_and_tools()
	_build_controller_rays()
	_build_training_props()
	_build_hud()
	_refresh_hud()

	left_controller.button_pressed.connect(_on_button_pressed.bind(left_controller, "left"))
	right_controller.button_pressed.connect(_on_button_pressed.bind(right_controller, "right"))
	left_controller.button_released.connect(_on_button_released.bind(left_controller, "left"))
	right_controller.button_released.connect(_on_button_released.bind(right_controller, "right"))


func _process(delta: float) -> void:
	_update_hud_follow()
	_update_rays()
	_update_held_object()

	if current_step == 4:
		_check_stick_directions()
	if current_step == 11:
		_check_screwdriver_task(delta)
	if current_step == 10:
		if xr_origin.global_position.distance_to(Vector3(gate_center.x, xr_origin.global_position.y, gate_center.z)) < 1.15:
			_advance_step()
	if locomotion_enabled:
		_handle_smooth_locomotion(delta)
	if turn_cooldown > 0.0:
		turn_cooldown -= delta


func _make_label(text: String, font_size: int, color: Color, width: float = 0.0, bold: bool = false) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font = font_bold if bold and font_bold else font_regular
	label.font_size = font_size
	label.outline_size = maxi(int(font_size / 6.0), 4)
	label.modulate = color
	label.pixel_size = 0.0024
	if width > 0.0:
		label.width = width
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _box(size: Vector3, color: Color, pos: Vector3, parent: Node = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.7
	mi.material_override = mat
	mi.position = pos
	(parent if parent else self).add_child(mi)
	return mi


func _cyl(top_r: float, bot_r: float, height: float, color: Color, pos: Vector3, rot: Vector3 = Vector3.ZERO, metallic: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_r
	mesh.bottom_radius = bot_r
	mesh.height = height
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = 0.35 if metallic > 0.0 else 0.7
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	add_child(mi)
	return mi


func _attach_controller_model(controller: XRController3D, accent: Color) -> void:
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.045, 0.035, 0.11)
	body.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.13, 0.15)
	body.material_override = mat
	body.position = Vector3(0, 0, 0.02)
	controller.add_child(body)

	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.018
	ring_mesh.outer_radius = 0.028
	ring.mesh = ring_mesh
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = accent
	ring_mat.emission_enabled = true
	ring_mat.emission = accent
	ring_mat.emission_energy_multiplier = 0.35
	ring.material_override = ring_mat
	ring.rotation_degrees = Vector3(90, 0, 0)
	ring.position = Vector3(0, 0.02, -0.02)
	controller.add_child(ring)


func _build_room() -> void:
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.82, 0.84, 0.86)
	floor_mat.roughness = 0.35
	var floor_mi := MeshInstance3D.new()
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(16, 16)
	floor_mi.mesh = floor_mesh
	floor_mi.material_override = floor_mat
	add_child(floor_mi)

	var grout := StandardMaterial3D.new()
	grout.albedo_color = Color(0.62, 0.65, 0.68)
	var g := -7.0
	while g <= 7.0:
		var lx := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = Vector3(16, 0.004, 0.018)
		lx.mesh = lm
		lx.material_override = grout
		lx.position = Vector3(0, 0.003, g)
		add_child(lx)
		var lz := MeshInstance3D.new()
		var lm2 := BoxMesh.new()
		lm2.size = Vector3(0.018, 0.004, 16)
		lz.mesh = lm2
		lz.material_override = grout
		lz.position = Vector3(g, 0.003, 0)
		add_child(lz)
		g += 1.5

	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.93, 0.94, 0.95)
	wall_mat.roughness = 0.85
	_box(Vector3(12.2, 3.4, 0.12), wall_mat.albedo_color, Vector3(0, 1.7, -7.6))
	_box(Vector3(0.12, 3.4, 12.0), wall_mat.albedo_color, Vector3(-6.1, 1.7, -1.6))
	_box(Vector3(0.12, 3.4, 12.0), wall_mat.albedo_color, Vector3(6.1, 1.7, -1.6))
	_box(Vector3(12.2, 3.4, 0.12), Color(0.88, 0.90, 0.92), Vector3(0, 1.7, 4.2))

	var accent := Color(0.05, 0.18, 0.55)
	_box(Vector3(12.2, 0.12, 0.14), accent, Vector3(0, 3.28, -7.54))
	_box(Vector3(12.2, 0.08, 0.14), Color(0.82, 0.08, 0.12), Vector3(0, 3.16, -7.54))

	var ceiling := StandardMaterial3D.new()
	ceiling.albedo_color = Color(0.96, 0.97, 0.98)
	_box(Vector3(12.4, 0.08, 12.2), ceiling.albedo_color, Vector3(0, 3.44, -1.7))

	var title := _make_label("مرکز منابع یادگیری", 56, Color(0.05, 0.18, 0.55), 0.0, true)
	title.position = Vector3(0, 2.85, -7.48)
	title.pixel_size = 0.004
	add_child(title)

	var org := _make_label("اداره آموزش و تعالی منابع انسانی شرکت پالایش نفت اصفهان", 28, Color(0.15, 0.18, 0.22), 900.0)
	org.position = Vector3(0, 2.52, -7.48)
	org.pixel_size = 0.0022
	add_child(org)

	var logo_texture: Texture2D = load("res://assets/logo.png")
	if logo_texture:
		var logo := Sprite3D.new()
		logo.texture = logo_texture
		logo.pixel_size = 0.0028
		logo.position = Vector3(0, 2.05, -7.48)
		logo.shaded = false
		add_child(logo)

	_build_posters()
	_build_headset_diagram()
	_plant(Vector3(-5.5, 0, -6.8))
	_plant(Vector3(5.5, 0, -6.8))
	_plant(Vector3(-5.5, 0, 3.2))
	_plant(Vector3(5.5, 0, 3.2))


func _build_posters() -> void:
	var texts := [
		"واقعیت مجازی\nمحیط سه‌بعدی که با هدست دیده می‌شود.",
		"ایمنی\nفضای واقعی اطرافتان را خالی نگه دارید.",
		"بند مچی\nقبل از شروع، بند دسته را به مچ ببندید.",
		"دکمه Meta\nبرای خروج از برنامه و منوی سیستم هدست است.",
	]
	var spots := [
		{"pos": Vector3(-5.98, 1.85, -2.2), "yaw": 90.0},
		{"pos": Vector3(-5.98, 1.85, 0.6), "yaw": 90.0},
		{"pos": Vector3(5.98, 1.85, -2.2), "yaw": -90.0},
		{"pos": Vector3(5.98, 1.85, 0.6), "yaw": -90.0},
	]
	for i in spots.size():
		var info: Dictionary = spots[i]
		_box(Vector3(0.04, 0.72, 1.05), Color(0.97, 0.97, 0.95), info["pos"])
		var caption := _make_label(texts[i], 26, Color(0.12, 0.14, 0.18), 420.0)
		caption.position = info["pos"] + Vector3(0.03 if info["yaw"] > 0.0 else -0.03, 0.05, 0)
		caption.rotation_degrees = Vector3(0, info["yaw"], 0)
		caption.pixel_size = 0.0015
		add_child(caption)


func _build_headset_diagram() -> void:
	var board_pos := Vector3(-3.6, 1.55, -7.48)
	_box(Vector3(1.5, 1.1, 0.05), Color(0.12, 0.16, 0.28), board_pos)
	var hset := _box(Vector3(0.55, 0.28, 0.22), Color(0.1, 0.11, 0.13), board_pos + Vector3(0, 0.12, 0.14))
	hset.rotation_degrees = Vector3(-8, 0, 0)
	_box(Vector3(0.06, 0.12, 0.04), Color(0.85, 0.85, 0.9), board_pos + Vector3(0.32, 0.18, 0.16))
	_box(Vector3(0.06, 0.08, 0.04), Color(0.75, 0.2, 0.2), board_pos + Vector3(0.32, 0.02, 0.16))
	var cap := _make_label("هدست: صدا  +  /  −\nپایین سمت راست: روشن/خاموش\nاین دکمه‌ها مال خود هدست‌اند نه دسته", 22, Color(0.95, 0.95, 0.97), 520.0)
	cap.position = board_pos + Vector3(0, -0.32, 0.04)
	cap.pixel_size = 0.0014
	add_child(cap)


func _plant(pos: Vector3) -> void:
	_cyl(0.16, 0.13, 0.28, Color(0.45, 0.48, 0.52), pos + Vector3(0, 0.14, 0))
	for i in 5:
		var ang := i * TAU / 5.0
		_box(Vector3(0.04, 0.55 + (i % 2) * 0.1, 0.01), Color(0.18, 0.42, 0.22), pos + Vector3(cos(ang) * 0.07, 0.55, sin(ang) * 0.07))


func _build_table_and_tools() -> void:
	var wood := Color(0.42, 0.30, 0.18)
	var table_pos := Vector3(0, 0.74, -1.85)
	_box(Vector3(1.7, 0.07, 0.85), wood, table_pos)
	for x_off in [-0.72, 0.72]:
		for z_off in [-0.32, 0.32]:
			_box(Vector3(0.07, 0.74, 0.07), wood, Vector3(table_pos.x + x_off, 0.37, table_pos.z + z_off))

	var top_y := 0.80
	var table_label := _make_label("میز کار آموزشی", 30, Color(0.95, 0.9, 0.7), 0.0, true)
	table_label.position = Vector3(0, 1.12, -2.22)
	table_label.pixel_size = 0.002
	add_child(table_label)

	screwdriver_tool = _build_screwdriver(Vector3(-0.45, top_y + 0.02, -2.05))
	grabbables.append(screwdriver_tool)
	cutter_tool = _build_cutter(Vector3(0.05, top_y + 0.02, -2.05))
	grabbables.append(cutter_tool)
	movable_object = _make_grabbable(Vector3(-0.22, top_y + 0.04, -1.62), Color(0.2, 0.45, 0.9), Vector3(0.08, 0.08, 0.08))
	grabbables.append(movable_object)

	bolt_target = _cyl(0.025, 0.025, 0.045, Color(0.62, 0.64, 0.68), Vector3(-0.12, top_y + 0.02, -2.05), Vector3.ZERO, 0.55)
	wire_target = _cyl(0.01, 0.01, 0.36, Color(0.12, 0.62, 0.22), Vector3(0.42, top_y + 0.02, -1.62), Vector3(0, 0, 90))

	drop_zone = MeshInstance3D.new()
	var zone_mesh := BoxMesh.new()
	zone_mesh.size = Vector3(0.2, 0.01, 0.2)
	drop_zone.mesh = zone_mesh
	var zone_mat := StandardMaterial3D.new()
	zone_mat.albedo_color = Color(0.25, 0.85, 0.45, 0.55)
	zone_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	zone_mat.emission_enabled = true
	zone_mat.emission = Color(0.25, 0.85, 0.45)
	zone_mat.emission_energy_multiplier = 0.45
	drop_zone.material_override = zone_mat
	drop_zone.position = Vector3(0.22, top_y + 0.005, -1.62)
	add_child(drop_zone)

	var wrench := _build_wrench(Vector3(0.48, top_y + 0.02, -2.05))
	grabbables.append(wrench)
	var cup := _build_cup(Vector3(0.55, top_y + 0.04, -1.62))
	grabbables.append(cup)


func _make_grabbable(pos: Vector3, color: Color, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mi.material_override = mat
	body.add_child(mi)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	body.position = pos
	add_child(body)
	return body


func _build_screwdriver(pos: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var handle := MeshInstance3D.new()
	var handle_mesh := CylinderMesh.new()
	handle_mesh.top_radius = 0.02
	handle_mesh.bottom_radius = 0.02
	handle_mesh.height = 0.11
	handle.mesh = handle_mesh
	var handle_mat := StandardMaterial3D.new()
	handle_mat.albedo_color = Color(0.95, 0.72, 0.08)
	handle.material_override = handle_mat
	handle.rotation_degrees = Vector3(0, 0, 90)
	handle.position = Vector3(-0.06, 0, 0)
	body.add_child(handle)
	var shaft := MeshInstance3D.new()
	var shaft_mesh := CylinderMesh.new()
	shaft_mesh.top_radius = 0.006
	shaft_mesh.bottom_radius = 0.006
	shaft_mesh.height = 0.12
	shaft.mesh = shaft_mesh
	var shaft_mat := StandardMaterial3D.new()
	shaft_mat.albedo_color = Color(0.75, 0.76, 0.78)
	shaft_mat.metallic = 0.65
	shaft.material_override = shaft_mat
	shaft.rotation_degrees = Vector3(0, 0, 90)
	shaft.position = Vector3(0.055, 0, 0)
	body.add_child(shaft)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.24, 0.05, 0.05)
	col.shape = shape
	body.add_child(col)
	body.position = pos
	add_child(body)
	return body


func _build_cutter(pos: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var red := StandardMaterial3D.new()
	red.albedo_color = Color(0.78, 0.14, 0.14)
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.8, 0.82, 0.85)
	metal.metallic = 0.7
	for s in [-1.0, 1.0]:
		var arm := MeshInstance3D.new()
		var arm_mesh := BoxMesh.new()
		arm_mesh.size = Vector3(0.14, 0.012, 0.016)
		arm.mesh = arm_mesh
		arm.material_override = red
		arm.rotation_degrees = Vector3(0, 0, s * 8.0)
		arm.position = Vector3(-0.04, s * 0.01, 0)
		body.add_child(arm)
		var blade := MeshInstance3D.new()
		var blade_mesh := BoxMesh.new()
		blade_mesh.size = Vector3(0.05, 0.01, 0.012)
		blade.mesh = blade_mesh
		blade.material_override = metal
		blade.position = Vector3(0.08, s * 0.006, 0)
		body.add_child(blade)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.22, 0.05, 0.04)
	col.shape = shape
	body.add_child(col)
	body.position = pos
	add_child(body)
	return body


func _build_wrench(pos: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.7, 0.72, 0.75)
	metal.metallic = 0.7
	var bar := MeshInstance3D.new()
	var bar_mesh := BoxMesh.new()
	bar_mesh.size = Vector3(0.18, 0.018, 0.012)
	bar.mesh = bar_mesh
	bar.material_override = metal
	body.add_child(bar)
	var head := MeshInstance3D.new()
	var head_mesh := TorusMesh.new()
	head_mesh.inner_radius = 0.012
	head_mesh.outer_radius = 0.028
	head.mesh = head_mesh
	head.material_override = metal
	head.rotation_degrees = Vector3(90, 0, 0)
	head.position = Vector3(0.1, 0, 0)
	body.add_child(head)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.24, 0.05, 0.05)
	col.shape = shape
	body.add_child(col)
	body.position = pos
	add_child(body)
	return body


func _build_cup(pos: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var cup := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.035
	mesh.bottom_radius = 0.028
	mesh.height = 0.08
	cup.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.92, 0.95)
	cup.material_override = mat
	body.add_child(cup)
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.04
	shape.height = 0.08
	col.shape = shape
	body.add_child(col)
	body.position = pos
	add_child(body)
	return body


func _build_controller_rays() -> void:
	left_ray = _make_ray()
	left_controller.add_child(left_ray)
	right_ray = _make_ray()
	right_controller.add_child(right_ray)


func _make_ray() -> MeshInstance3D:
	var ray := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.003
	cyl.bottom_radius = 0.0035
	cyl.height = 1.2
	ray.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.75, 1.0, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.35, 0.75, 1.0)
	mat.emission_energy_multiplier = 0.8
	ray.material_override = mat
	ray.rotation_degrees = Vector3(-90, 0, 0)
	ray.position = Vector3(0, 0, -0.6)
	return ray


func _build_training_props() -> void:
	trigger_target = StaticBody3D.new()
	var sphere_mi := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.11
	sphere.height = 0.22
	sphere_mi.mesh = sphere
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.95, 0.45, 0.12)
	smat.emission_enabled = true
	smat.emission = Color(0.95, 0.45, 0.12)
	smat.emission_energy_multiplier = 0.9
	sphere_mi.material_override = smat
	trigger_target.add_child(sphere_mi)
	var scol := CollisionShape3D.new()
	var sshape := SphereShape3D.new()
	sshape.radius = 0.12
	scol.shape = sshape
	trigger_target.add_child(scol)
	trigger_target.position = Vector3(0.55, 1.35, -1.15)
	add_child(trigger_target)

	teleport_marker = StaticBody3D.new()
	var torus_mi := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.32
	torus.outer_radius = 0.46
	torus_mi.mesh = torus
	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = Color(0.2, 0.85, 0.45)
	tmat.emission_enabled = true
	tmat.emission = Color(0.2, 0.85, 0.45)
	tmat.emission_energy_multiplier = 0.8
	torus_mi.material_override = tmat
	teleport_marker.add_child(torus_mi)
	var tcol := CollisionShape3D.new()
	var tshape := CylinderShape3D.new()
	tshape.radius = 0.5
	tshape.height = 0.08
	tcol.shape = tshape
	teleport_marker.add_child(tcol)
	teleport_marker.position = Vector3(2.2, 0.04, -4.2)
	add_child(teleport_marker)

	var pillar_mat := StandardMaterial3D.new()
	pillar_mat.albedo_color = Color(0.2, 0.5, 0.95)
	pillar_mat.emission_enabled = true
	pillar_mat.emission = Color(0.2, 0.5, 0.95)
	pillar_mat.emission_energy_multiplier = 0.55
	for x in [-0.85, 0.85]:
		var pillar := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(0.1, 2.1, 0.1)
		pillar.mesh = pm
		pillar.material_override = pillar_mat
		pillar.position = Vector3(x, 1.05, gate_center.z)
		add_child(pillar)
		gate_nodes.append(pillar)

	headset_confirm = _make_button_panel(Vector3(-3.6, 0.95, -7.42), "متوجه شدم", Color(0.1, 0.45, 0.28))
	skip_button = _make_button_panel(Vector3(0.95, 1.38, -1.15), "مرحله بعد", Color(0.35, 0.38, 0.42))


func _make_button_panel(pos: Vector3, text: String, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.42, 0.12, 0.03)
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mi.material_override = mat
	body.add_child(mi)
	var label := _make_label(text, 26, Color(1, 1, 1), 0.0, true)
	label.position = Vector3(0, 0, 0.025)
	label.pixel_size = 0.0013
	body.add_child(label)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.42, 0.12, 0.04)
	col.shape = shape
	body.add_child(col)
	body.position = pos
	add_child(body)
	return body


func _build_hud() -> void:
	hud_root = Node3D.new()
	add_child(hud_root)
	step_label = _make_label("", 40, Color(0.05, 0.18, 0.55), 780.0, true)
	step_label.pixel_size = 0.0026
	step_label.position = Vector3(0, 0.16, 0)
	hud_root.add_child(step_label)
	desc_label = _make_label("", 28, Color(0.12, 0.14, 0.18), 900.0)
	desc_label.pixel_size = 0.002
	desc_label.position = Vector3(0, -0.02, 0)
	hud_root.add_child(desc_label)
	hint_label = _make_label("", 24, Color(0.05, 0.45, 0.55), 700.0)
	hint_label.pixel_size = 0.0018
	hint_label.position = Vector3(0, -0.22, 0)
	hud_root.add_child(hint_label)


func _update_hud_follow() -> void:
	if xr_camera == null:
		return
	var cam := xr_camera.global_transform
	var forward := -cam.basis.z
	forward.y = 0.0
	if forward.length() < 0.05:
		forward = Vector3(0, 0, -1)
	forward = forward.normalized()
	hud_root.global_position = cam.origin + forward * 1.35 + Vector3(0, 0.18, 0)
	hud_root.look_at(cam.origin, Vector3.UP)
	hud_root.rotate_y(PI)


func _update_rays() -> void:
	var left_on := left_controller.is_button_pressed("trigger") or left_controller.is_button_pressed("ax_button")
	var right_on := right_controller.is_button_pressed("trigger") or right_controller.is_button_pressed("ax_button")
	left_ray.scale = Vector3(1, 1.15 if left_on else 0.55, 1)
	right_ray.scale = Vector3(1, 1.15 if right_on else 0.55, 1)


func _update_held_object() -> void:
	if held_object == null or held_by_controller == null:
		return
	held_object.global_transform = held_by_controller.global_transform * held_local_xform


func _refresh_hud() -> void:
	var s: Dictionary = steps_data[current_step]
	step_label.text = "مرحله %d از %d  —  %s" % [current_step + 1, steps_data.size(), s["title"]]
	desc_label.text = s["desc"]

	trigger_target.visible = current_step == 1
	teleport_marker.visible = current_step == 9 or teleport_enabled
	headset_confirm.visible = current_step == 8
	skip_button.visible = current_step < steps_data.size() - 1
	for n in gate_nodes:
		n.visible = current_step == 10 or locomotion_enabled

	if current_step == 4:
		hint_label.text = "جهت‌های انجام‌شده: %d از ۴" % _count_done(stick_directions_done)
	elif current_step == 6:
		hint_label.text = "دکمه‌های زده‌شده: %d از ۴" % _count_done(face_buttons_done)
	elif current_step == 3:
		hint_label.text = "ابزار را نزدیک دسته کنید و Grip را نگه دارید"
	else:
		hint_label.text = "برای رد شدن: به دکمه «مرحله بعد» نشانه بگیرید و ماشه بزنید"

	if current_step >= 9:
		teleport_enabled = true
	if current_step >= 10:
		locomotion_enabled = true


func _count_done(d: Dictionary) -> int:
	var c := 0
	for k in d:
		if d[k]:
			c += 1
	return c


func _advance_step() -> void:
	current_step += 1
	if current_step >= steps_data.size():
		current_step = steps_data.size() - 1
	bolt_progress = 0.0
	_refresh_hud()


func _points_at(controller: XRController3D, target: Node3D) -> bool:
	if target == null or not target.visible:
		return false
	var origin: Vector3 = controller.global_transform.origin
	var direction: Vector3 = -controller.global_transform.basis.z
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction.normalized() * RAY_LENGTH)
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	return not result.is_empty() and result["collider"] == target


func _is_trigger(button_name: String) -> bool:
	return button_name == "trigger" or button_name == "trigger_click"


func _is_grip(button_name: String) -> bool:
	return button_name == "grip" or button_name == "grip_click"


func _on_button_pressed(button_name: String, controller: XRController3D, side: String) -> void:
	if _is_trigger(button_name) and skip_button.visible and _points_at(controller, skip_button):
		_advance_step()
		return

	if _is_grip(button_name):
		_try_grab(controller)
		if current_step == 2:
			_advance_step()
			return
		if current_step == 3 and held_object != null:
			_advance_step()
			return

	match current_step:
		0:
			if _is_trigger(button_name):
				_advance_step()
		1:
			if _is_trigger(button_name) and _points_at(controller, trigger_target):
				_advance_step()
		5:
			if button_name == "primary_click":
				_advance_step()
		6:
			if button_name == "ax_button" or button_name == "by_button":
				var key := "%s_%s" % [side, "ax" if button_name == "ax_button" else "by"]
				if face_buttons_done.has(key):
					face_buttons_done[key] = true
					_refresh_hud()
				if _count_done(face_buttons_done) >= 4:
					_advance_step()
		7:
			if button_name == "menu_button":
				_advance_step()
		8:
			if _is_trigger(button_name) and _points_at(controller, headset_confirm):
				_advance_step()
		9:
			if _is_trigger(button_name) and _points_at(controller, teleport_marker):
				var target_pos: Vector3 = teleport_marker.global_position
				xr_origin.global_position = Vector3(target_pos.x, xr_origin.global_position.y, target_pos.z)
				_advance_step()
		12:
			if _is_trigger(button_name) and held_object == cutter_tool:
				if held_object.global_position.distance_to(wire_target.global_position) < 0.32:
					wire_target.visible = false
					_advance_step()


func _on_button_released(button_name: String, controller: XRController3D, _side: String) -> void:
	if _is_grip(button_name):
		_try_release_grab(controller)


func _try_grab(controller: XRController3D) -> void:
	if held_object != null:
		return
	for body in grabbables:
		var node: Node3D = body
		if node.global_position.distance_to(controller.global_position) < GRAB_DISTANCE:
			held_object = node
			held_by_controller = controller
			held_local_xform = Transform3D(Basis.IDENTITY, Vector3(0, 0, -0.12))
			return


func _try_release_grab(controller: XRController3D) -> void:
	if held_by_controller != controller or held_object == null:
		return
	if current_step == 13 and held_object == movable_object:
		if movable_object.global_position.distance_to(drop_zone.global_position) < 0.28:
			movable_object.global_position = drop_zone.global_position + Vector3(0, 0.05, 0)
			_advance_step()
	held_object = null
	held_by_controller = null


func _check_stick_directions() -> void:
	var v: Vector2 = left_controller.get_vector2("primary")
	var changed := false
	if v.y > 0.6 and not stick_directions_done["up"]:
		stick_directions_done["up"] = true
		changed = true
	if v.y < -0.6 and not stick_directions_done["down"]:
		stick_directions_done["down"] = true
		changed = true
	if v.x < -0.6 and not stick_directions_done["left"]:
		stick_directions_done["left"] = true
		changed = true
	if v.x > 0.6 and not stick_directions_done["right"]:
		stick_directions_done["right"] = true
		changed = true
	if changed:
		_refresh_hud()
		if _count_done(stick_directions_done) >= 4:
			_advance_step()


func _check_screwdriver_task(delta: float) -> void:
	if held_object != screwdriver_tool or held_by_controller == null:
		return
	if held_object.global_position.distance_to(bolt_target.global_position) > 0.32:
		return
	if held_by_controller.is_button_pressed("trigger") or held_by_controller.is_button_pressed("trigger_click"):
		bolt_progress += delta
		bolt_target.rotate_y(delta * 6.0)
		if bolt_progress >= 1.4:
			_advance_step()


func _handle_smooth_locomotion(delta: float) -> void:
	var v: Vector2 = left_controller.get_vector2("primary")
	if v.length() > 0.15:
		var cam_basis: Basis = xr_camera.global_transform.basis
		var forward := -cam_basis.z
		var right := cam_basis.x
		forward.y = 0.0
		right.y = 0.0
		if forward.length() > 0.001:
			forward = forward.normalized()
		if right.length() > 0.001:
			right = right.normalized()
		var move_dir := forward * v.y + right * v.x
		xr_origin.global_position += move_dir * move_speed * delta

	var p := xr_origin.global_position
	p.x = clampf(p.x, -ROOM_HALF_X, ROOM_HALF_X)
	p.z = clampf(p.z, ROOM_MIN_Z, ROOM_MAX_Z)
	xr_origin.global_position = p

	if turn_cooldown <= 0.0:
		var rv: Vector2 = right_controller.get_vector2("primary")
		if rv.x > 0.6:
			xr_origin.rotate_y(deg_to_rad(-30))
			turn_cooldown = 0.35
		elif rv.x < -0.6:
			xr_origin.rotate_y(deg_to_rad(30))
			turn_cooldown = 0.35
