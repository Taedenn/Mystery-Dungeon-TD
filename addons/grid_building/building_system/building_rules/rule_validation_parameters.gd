class_name RuleValidationParameters
extends RefCounted
## The details to test placement rules against for validating whether
## a placeable object can place into the scene at the target location

## The node considered to be doing the placing of the placeable
var placer: Node:
	set(value):
		placer = value

## The currently tested instance of the scene
var preview_instance: Node2D:
	set(value):
		preview_instance = value

## The resource that defines how a game scene may be placed into the world
var placeable: Placeable:
	set(value):
		placeable = value

## Receive post validations and build signals
var building_signal_bus: BuildingSignalBus:
	set(value):
		building_signal_bus = value


func _init(
	p_placer: Node,
	p_preview_instance: Node2D,
	p_placeable: Placeable,
	p_building_signal_bus: BuildingSignalBus
):
	placer = p_placer
	preview_instance = p_preview_instance
	placeable = p_placeable
	building_signal_bus = p_building_signal_bus
