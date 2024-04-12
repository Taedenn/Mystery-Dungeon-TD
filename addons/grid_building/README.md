# GridBuilding
 Grid Building and Targeting Systems for Tilemap Grid 2D Godot 4+ Games

Visit my YouTube playlist for tutorials on how to use the Grid Building System plugin 
https://www.youtube.com/playlist?list=PLyH-qXFkNSxl5bQkTYzMXyRwVr8Vc4Sib

Follow project devlog updates at https://itch.io/dashboard/game/2117450/devlog

=== Important Usage Tips ===
- When designing scenes to place into your game, you can get a good sense of where the collision lines will be drawn during object placement by toggling grid snap and putting the offset at half of the tile size. So for a 16x16 tile size game, your offset would be 8 in x and 8 in y. The step that adds up to the 16 x 16 tile size will represent where the tile indicators position themselves over.

=== How the system works ===\
In order to get RuleCheckIndicators to generate to evalulate collision or properties of tiles under the indicators in the tilemap, you set rules into the Placement Validator on the building system or in each placeable resource file in the case of object specific rules. A RuleCheckIndicatorManager is created by the placement validator to handle the finding of tile positions where the preview object's collisions shapes collide with a template RuleCheckIndicator. For the rules that have a rule_mask that matches one or more of the collision object's physics layers, the indicator will be generated and that rule (or rules if multiple rule mask match the collision object's shape) will be added to the indicator. The indicator will keep updating itself to check if all rules validate for that specific indicator. When the building system is ready to make a placement (Player presses enter build key, etc) then rules in each indicator will be evaluated. Only if all indicators validate, will the overall placement validate.

There are also rules that do not require checks on collision or tiles such as SpendMaterialsRuleGeneric, which checks the placer node (the user of the building system considered to be placing the objects in the scene) for an inventory, checks if it has enough materials to build a given object, and after building is complete, it spends the resources by subtracting the resources from the inventory through the BuildingSignalBus

=== How to Use ===
1. Save and backup your project before upgrading. Disable the plugin in Project -> Project Settings -> Plugins if enabled. Remove any old grid_builder plugin folder & contents if it exists. Download and add the .zip contents to your project in the directory addons/grid_building.
2. Turn on the plugin in Project Settings -> Plugins tab.
3. Add a GridTargetingSystem node to your main gameplay scene, either in the editor scene hierarchy or by instantiating the object
4. Add a BuildingSystem node to your main gameplay scene, either in the editor scene hierarchy or by instantiating the object
5. Add the grid_positioner.tscn scene to your node 2d game world parent. This should be the parent node where your game tilemap is a child of.
6. Assign external dependencies to each system under the External Dependencies property group. You can do this either in the inspector or as your level nodes for targeting objects like the build system placer.
7. To trigger build mode, you call set_buildable_preview on the BuildingSystem. You need to define a placeable resource file which holds the settings for placing a scene object into the game.
8. To make the system place the object into the game world, press the action(s) defined in the BuildingSystem for object placement. You set these up in the Godot project settings and then add the string names of those actions in the BuildingSystem inspector. By default ui_accept is used which you could test by pressing enter in a new project.
9. To limit where and when a placeable scene can be instantiated, you must use set a BuildingRule. Add rules you want to include for all placeables to the BuildingSystem and placeable object specific rules to each placeable resource file. You can read more below about build rules and what the default rules do.
10. For your RuleCheckIndicator, you can start with the provided templates. Right click them to create an inherited scene and save it your own project. You only need one indicator template set in the building system now. You can set the default textures in the template scene, but override failing textures for each rule as well. (If you want a yellow tile to show as a special case for invalid tile checks for instance)

=== Notable Object Classes and What they Do ===
- Placeable - A resource for defining an object that can be placed into the game world. The building system works by picking a placeable resource through set_building_placeable(placeable) to show a preview of the object being placed into the game world and ultimately to place a copy of it's PackedScene into the game world. Notably - each placeable can also define BuildRules on a placeable by placeable basis so if you want spending 100 of a resource to be a requirement for building, you can set that there
- BuildingSystem - Handles preview display and placing of Placeable objects into the game world (Uses the placeable resource for the settings and the actual PackedScene for the game world object). Relies on GridTargetingSystem to tell BuildingSystem where to show the preview and test for collisions with RuleCheckIndicators
- GridTargetingSystem - Takes the mouse cursor position and converts it into a tile position for the active tilemap. 
- BuildingRule - Base class for creating placement rules for building objects into the game world. When added to either a placeable or the BuildingSystem itself (as a universal rule), an object will be stopped from placement if it does not meet all BuildingRule requirements. In the demo, the build log is a handy way to see which rules failed out (it receives the data through signals)

=== Rules in the Plugin ===
Note that you can create your own by having a script inherit from BuildingRule or TileCheckRule (which is a Resource not a Node), and then implementing your own setup, validate_condition, and tear_down methods. Check the base class building_rule.gd for the inherited method signatures.

A rule result is created with RuleResult.new(success, reason) where success is a true / false bool, and reason is the string reason for the success or fail. The build log by default does not show success reasons, but does show fail reasons (You can toggle this on and off)

1. CollisionCheckRule - Rule that checks for collisions and determines if the rule passes or fails depending on pass_on_collision's true/false value
2. SpendMaterialsRuleGeneric - Generic spend material rule that allows you to define whatever classes you want to spend the resources. Therefore, no need to use the building system inventory classes. However, certain properties and methods will be expected. The most straight forward way to include those is to inherit virtual_item_container and implement the expected methods in the base class.
3. WithinTilemapBoundsRule - All TileCollisionIndicators must be cast over tilemap tiles that have valid tile data. A tile that has no tiles is considered off the grid and invalid.
5. ValidPlacementTileRule - Checks that the tiles under the indicators have tile data and optionally match a custom data field value like "buildable" is true, etc

=== GridBuilding Inventory ===
Now installed as a seperate package to be an optional base for an inventory system but not required.
Install into addons/grid_building_inventory/

1. ItemContainer - A node which can contain BaseItemStacks. You can define the types that the container is allowed to store with ItemTags like tag_item_material. An item container could be the full inventory for a player but you can also create different ItemContainers for different item types and then have a parent Inventory you define to manage them all under one roof. You could solely use the ItemContainer for the SpendMaterialsRule and have your own inventory system for the rest of the gameplay.
2. BaseItemStack - Stores a BaseItem type with a count integer
3. BaseItem - Intended as a generic base for any item resource you may setup in the game. For it to be compatible with SpendMaterialsRule, inherit from BaseItem in your item resource classes.
4. SpendMaterialsRule - Checks that an ItemContainer contains sufficient items of type BaseItem to spend in the building the placeable in the scene

=== CategoricalTag ===
These are resource files that exist for defining what another resource (BaseItem, Placeable) is or isnt. The CategoricalTag have two properties, display_name and icon to be used for showing the tags in game (for instance in the demo placement_selection_ui, tags are used in the header tabs between Building placeables and Fun placeables as categories for what you can place in the game.

You can create as many tags as you need to reference in your project and to check that something has a tag, simply compare the resource value to the expected resource value (matching tags)

If you'll use these, I recommend putting different tag types in different folders. For instance, placeable tags would be completely different than an item tag.

=== Optional Components ===
Add these as child nodes under their parent system nodes
1. TileMapBuildingOverlay - Draws a tile_set tile over all tiles of a targeted layer during build mode only and hides when build mode is exited. You can use this with a traparent png to draw an overlay onto the grid to indicate buildable areas or simply indicate that build mode is active. To set the tile texture, add it to your TileMap's TileSet and then find the Atlas ID and Texture Coords in the TileSet editor window (single texture tile atlas has coords of 0,0) Read more here https://chris-tutorials.itch.io/grid-building-godot/devlog/630838/320-isometric-tilemap-support

=== Asset Credits ===
For the demos graphics in the plugins, some 3rd party art assets are used.
Currently all used assets are under CC-0 license
Summary of credits can be found here. https://pastebin.com/HYznA3F8
