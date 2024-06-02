extends Node2D

var enemy_script = preload("res://scripts/Enemy.gd")
var soul = preload("res://scripts/gimmie_coin.gd")
var children
var enemy_instances
var gimmie_coins
var remove_child = CharacterBody2D
var remove_shard = StaticBody2D

func _ready():
	enemy_instances = []
	gimmie_coins = []
	children = []
	
	for child in children:
		if child.get_script() == enemy_script and not enemy_instances.has(child):
			enemy_instances.append(child)

func removal_service_enemy(enemy):
	remove_child = enemy
	if enemy_instances.has(remove_child):
		enemy_instances.erase(remove_child)
		
func removal_service_coin(coin):
	remove_child = coin
	if gimmie_coins.has(remove_child):
		gimmie_coins.erase(remove_child)

func survey_children():
	children = get_children()
	for child in children:
		if child.get_script() == soul and not gimmie_coins.has(child):
			gimmie_coins.append(child)
	
	var active_enemies = []
	for child in children:
		if child.get_script() == enemy_script:
			if child.freeze == true:
				active_enemies.append(child)
			else:
				if active_enemies.has(child):
					active_enemies.erase(child)
	if active_enemies.size() > 75:
		var first = active_enemies.pop_at(active_enemies.find(active_enemies.pick_random()))
		var second = active_enemies.pop_at(active_enemies.find(active_enemies.pick_random()))
		first.set_health(-second.health)
		first.scale += Vector2(0.15, 0.15)
		first.damage += (second.damage / 2)
		second.freeze = false
		second.position = Vector2(-5000, -5000)
		second.hazard_damage_instances = []
		second.recurring_hazard_instances = []
		second.scale = Vector2(1, 1)
		second.process_mode = Node.PROCESS_MODE_DISABLED

func magnet():
	# survey_children()
	for s in gimmie_coins:
		var gimmie_coin = gimmie_coins.pop_front()
		if gimmie_coin != null:
			if children.has(gimmie_coin):
				gimmie_coin.magnet = true
				gimmie_coins.erase(gimmie_coin)
			else:
				gimmie_coins.erase(gimmie_coin)
		else:
			gimmie_coins.erase(gimmie_coin)

func _on_nightfall_timeout():
	magnet()

func _on_sunrise_timeout():
	magnet()

func _on_timer_timeout():
	survey_children()
