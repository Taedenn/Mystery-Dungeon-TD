extends Button
## Turns build mode on for the building_system when the button is pressed

@export var placeable_object : Placeable
@export var building_system : BuildingSystem :
	set(value):
		if(building_system):
			building_system.disconnect("building_mode_changed", _on_building_mode_changed)
		
		building_system = value
		building_system.connect("building_mode_changed", _on_building_mode_changed)

func _on_pressed():
	# Make the build system start build preview mode with the buildable scene
	building_system.set_buildable_preview(placeable_object)
	
func _on_building_mode_changed(is_building : bool):
	self.disabled = is_building
