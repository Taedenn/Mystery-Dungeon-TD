class_name RuleCheckIndicator
extends ShapeCast2D
## Hovers over a specific tile to indicator what the status of the space undernearth
## the tile is including collisions or if the tilemap tile space is invalid.

## Shows whether a tile collision indicator is considered valid over the
## current tile based on the set rules to test
@export var validity_sprite : Sprite2D

@export_group("Settings")
## Whether to show the indicator visual sprites for players or not
@export var show_indicators : bool = true :
	set(value):
		show_indicators = value
		
		if(show_indicators):
			propagate_call("hide")
		else:
			propagate_call("show")
				
		_shown_sprite = null
		
## Default display settings for when the rule chcek indicator
## is marked valid
@export var valid_settings : IndicatorVisualSettings

## Default display settings for when the rule chcek indicator
## is marked invalid
@export var invalid_settings : IndicatorVisualSettings

## Controls whether extra collision information should be drawn to the viewport for debug
## purposes and contact information printed in output
@export var debug_mode = false

## Indicators will be only be generated for collision objects
## that match all mask layers from the collision indicator. This
## can be helpful for collision objects that share a collision layer 
## but need to be generated for different rules.
#@export var require_all_mask_layers_to_generate = false

## The rules to validate for whether this tile is valid for placement or not
## All rules must validate true to be valid. Otherwise, failed status will be shown
var rules : Array[TileCheckRule] :
	set(value):
		if (rules == value):
			return
			
		# Add and remove self from the rules indicators arrays
		for rule in rules:
			var pos_in_rule = rule.indicators.find(self)
			if(pos_in_rule >= 0):
				rule.indicators.remove_at(pos_in_rule)
		
		rules = value
		
		for rule in rules:
			rule.indicators.append(self)

var current_display_settings : IndicatorVisualSettings = valid_settings :
	set(value):
		if(value == current_display_settings):
			return
		
		current_display_settings = value
		_update_visuals()

## Whether the indicator is considered valid for the tile check rules or not
var valid : bool :
	set(value):
		if(valid == value):
			return
		
		valid = value

## Tilemap to test for invalid tiles against
var tilemap : TileMap
		
## Tje tile that is under the RuleCheckIndicator in the current physics frame
var tile_under_indicator : Vector2i


## The currently showing sprite
@onready var _shown_sprite : Sprite2D = null :
	get:
		return _shown_sprite
	set(value):
		if(_shown_sprite != value):
			_shown_sprite = value


## Giving the tile indicator instance the necessary components it needs
## to fully run
func setup(p_tilemap : TileMap, p_rules : Array[TileCheckRule]):
	tilemap = p_tilemap
	rules = p_rules
	_validate_setup()
	
## Tests each of the TileCheckRules against the indicator
## Returns all failing rules
func validate_rules(p_rules : Array[TileCheckRule]) -> Array[TileCheckRule]:
	var failing_rules : Array[TileCheckRule] = []
	
	for rule in p_rules:
		if(rule.get_failing_indicators([self]).size() > 0):
			failing_rules.append(rule)
			
	return failing_rules

## Change the display settings of the indicator's sprite
## based on validity and highest rule visual priority
func _update_current_display_settings(p_display_rules : Array[TileCheckRule]):
	if(valid):
		current_display_settings = valid_settings
		return
	
	var displaying_rule = _find_highest_rule_with_visual_settings(p_display_rules)
	
	if(displaying_rule != null):
		current_display_settings = displaying_rule.fail_visual_settings
	else:
		current_display_settings = invalid_settings

func _find_highest_rule_with_visual_settings(p_rules : Array[TileCheckRule]) -> TileCheckRule:
	var selected_rule : TileCheckRule = null
	var selected_priority = null
	
	# Find the highest priority failing rule with fail visual settings
	for rule in p_rules:
		if(rule.fail_visual_settings == null):
			continue
					
		if(selected_priority == null || rule.visual_priority > selected_priority):
			selected_rule = rule
			selected_priority = rule.visual_priority
			
	return selected_rule
	
func _init(p_tilemap : TileMap = null, p_rules : Array[TileCheckRule] = []):
	tilemap = p_tilemap
	rules = p_rules
	target_position = Vector2.ZERO

func _ready():
	valid = validate_rules(rules).size() == 0
	
func _physics_process(_delta):
	if(tilemap):
		tile_under_indicator = tilemap.local_to_map(tilemap.to_local(global_position))
		var invalid_rules = validate_rules(rules)
		valid = invalid_rules.size() == 0
		_update_current_display_settings(invalid_rules)
		
func _validate_setup() -> bool:
	var no_problems = true
	
	if(tilemap == null):
		push_warning(str(get_path()) + " has no tilemap set to check collisions against.")
		no_problems = false
		
	if(target_position != Vector2.ZERO):
		push_warning("Rule check indicators are meant to check directly under their positions. Make sure the target_position is set to 0,0")
		no_problems = false
		
	if skew != 0.0:
		push_warning("Indicator skew is not 0. Polygon shape STRONGLY recommended instead of skew to avoid unexpected collision detection.")
	
	return no_problems

## Controls the currently display textures and colors for the tile collision indicator
func _update_visuals():
	if(not current_display_settings):
		return
	
	if(current_display_settings.texture != null):
		validity_sprite.texture = current_display_settings.texture
	else:
		validity_sprite.texture = invalid_settings.texture
	
	validity_sprite.modulate = current_display_settings.modulate

func _draw():
	if(not debug_mode):
		return
		
	if(collision_result.size() > 0):
		# prints("Collisions in tile ", tile_under_indicator)
		var tile_position = tilemap.to_global(tilemap.map_to_local(tile_under_indicator))
		
		for contact in collision_result:
			var local_contact_point = to_local(contact.point)
			draw_circle(local_contact_point, 10, Color.MAROON) # Where it contacted
			draw_circle(Vector2.ZERO, 12, Color.FUCHSIA) # Current Location
			draw_line(Vector2.ZERO, local_contact_point, Color.YELLOW, 3) # Location to Contact line

func _child_exiting_tree(node: Node):
	print_debug("Exiting")
