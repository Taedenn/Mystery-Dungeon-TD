class_name BuildAttemptParameters
extends RefCounted
## Parameters used for attempting a build

var preview_instance : Node2D
var placeable : Placeable
var is_drag_build : bool

func _init(p_preview_instance : Node2D, p_placeable : Placeable, p_is_drag_build : bool):
	preview_instance = p_preview_instance
	placeable = p_placeable
	is_drag_build = p_is_drag_build
