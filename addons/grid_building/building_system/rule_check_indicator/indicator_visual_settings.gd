class_name IndicatorVisualSettings
extends Resource
## Settings for controlling how a TileCheckIndicator should display

## Texture to show on RuleCheckIndicator when it fails to validate because of this rule.
## Leave blank if none desired
@export var texture : Texture2D

## The color adjustment to the fail texture when showing this rules fail state on the indicator
@export var modulate : Color = Color.WHITE
