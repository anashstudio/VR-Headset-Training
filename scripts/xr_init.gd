extends Node

func _ready() -> void:
	var xr_interface: XRInterface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR already initialized.")
		get_viewport().use_xr = true
	elif xr_interface and xr_interface.initialize():
		print("OpenXR initialized.")
		get_viewport().use_xr = true
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	else:
		print("No XR headset found. Desktop preview mode.")
