class_name BuildingSignalBus
extends Resource
## Communicates between signal emitter and connected objects on
## build related signals during gameplay

## Emitted when a build is tested to see if placement into the game world is valid or not
signal validation_ran(results : ValidationResults, attempt_params : BuildAttemptParameters)

## Emitted when an object is instanced into the game world through a building system
signal object_placed(placer : Node, placed : Node2D)

## Emitted whenever an action that the player tried to press was stopped or not
## allowed for a gameplay reason
signal action_failed(action : StringName, reason : String)

## To be emitted whenever a tile map used with the building system has tiles
## added or removed from its game map
signal tile_map_used_tiles_updated(used_tiles : Array[Vector2i], layer : int, tile_map : TileMap)

## Emit this when you need to update all building systems and components with a 
## new active tilemap
signal tile_map_changed(p_active_tile_map : TileMap)
