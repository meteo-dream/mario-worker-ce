extends Window

@onready var container: SubViewportContainer = $VPControl/ViewportContainer
@onready var vp: SubViewport = $VPControl/ViewportContainer/SubViewport
@onready var center_container: AspectRatioContainer = $VPControl/AspectRatioContainer

@onready var vp_control: Control = $VPControl

func _update_view():
	vp_control._update_view()
