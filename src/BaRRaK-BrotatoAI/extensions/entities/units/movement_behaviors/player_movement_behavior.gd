extends "res://entities/units/movement_behaviors/player_movement_behavior.gd"

var ai_client
var next_movement = Vector2.ZERO

func _ready():
	ai_client = $"/root/Main".ai_client
	ai_client.connect("action_received", self, "receive_movement")

func get_game_state() -> String:
	var player = $"/root/Main"._player
	
	var wave_timer = $"/root/Main"._wave_timer

	var enemies = []
	for enemy in $"/root/Main/EntitySpawner".enemies:
		enemies.append({
			"position":	vector_to_json(enemy.position),
			"velocity": vector_to_json(enemy.linear_velocity)
		})
	
	var projectiles = []
	var projectiles_container = $"/root/Main/Projectiles"
	for projectile in projectiles_container.get_children():
		projectiles.append({
			"position": vector_to_json(projectile.position),
			"rotation": projectile.rotation
		})

	var game_state = {
		"player": {
			"position": vector_to_json(player.position),
			"velocity": vector_to_json(player.linear_velocity),
			"health": player.current_stats.health
		},
		"enemies": enemies,
		"projectiles": projectiles,
		"duration": wave_timer.time_left
	}

	return to_json(game_state)
	
func vector_to_json(vector: Vector2)->Dictionary:
	return {
		"x": vector.x,
		"y": vector.y
	}
	
func receive_movement(movement):
	print('received', movement)
	if movement == 'up':
		next_movement = Vector2(0, -1)
	if movement == 'down':
		next_movement = Vector2(0, 1)
	if movement == 'left':
		next_movement = Vector2(-1, 0)
	if movement == 'right':
		next_movement = Vector2(1, 0)
	
func get_movement() ->Vector2:

	var options_node = $"/root/BrotatoAIOptions"

	var enabled = true; #options_node.enable_autobattler
	
	var item_weight = options_node.item_weight
	var projectile_weight = options_node.projectile_weight
	var tree_weight = options_node.tree_weight
	var boss_weight = options_node.boss_weight
	var bumper_weight = options_node.bumper_weight
	var egg_weight = options_node.egg_weight
	var bumper_distance = options_node.bumper_distance
	
#	print_debug("bumper distnace: ", bumper_distance)
#	print_debug("item_weight: ", item_weight)

#	if not enabled:
#		$"/root/Main/Camera".smoothing_enabled = false
	
	if ai_client.connected:
		var state = get_game_state()
		ai_client.send_state(state)
		# send and wait
		print('ai move ', next_movement)
		return next_movement
	else:
		print('normal move')
		return .get_movement()

	var _entity_spawner = $"/root/Main/EntitySpawner"
	var _consumables_container = $"/root/Main/Consumables"
	var items_container = $"/root/Main/Items"
	var projectiles_container = $"/root/Main/Projectiles"
	var is_soldier = RunData.current_character.my_id == "character_soldier"
	var is_bull = RunData.current_character.my_id == "character_bull"
	
	var player = $"/root/Main"._player
	
	var weapon_range = 1_000
	var bumper_spacing = 50
	
	var max_health = float(player.max_stats.health)
	var current_health = float(player.current_stats.health)
	
	if is_bull:
		if current_health / max_health < .6:
			weapon_range = 1000
		else:
			weapon_range = 0
	
	for weapon in player.current_weapons:
		#var max_range = weapon.stats.max_range
		var max_range = weapon.current_stats.max_range
		
		if max_range < weapon_range:
			weapon_range = max_range
	var preferred_distance_squared = weapon_range * weapon_range
	
	var move_vector = Vector2.ZERO
	
	var consumable_weight = (1.0 - (current_health / max_health)) * 2
	
	# Eat consumables, weighted by missing hp
	for consumable in _consumables_container.get_children():
		var consumable_pos = consumable.position
		var consumable_to_player = consumable_pos - player.position
		var squared_distance_to_consumable = consumable_to_player.length_squared()
		
		var to_add = (consumable_to_player.normalized() / squared_distance_to_consumable) * 10 * consumable_weight
		if not is_nan(to_add.x) and not is_nan(to_add.y):
			move_vector = move_vector + to_add
	
	# Go towards "items" (gold pickups)
	var item_weight_squared = item_weight * item_weight
	for item in items_container.get_children():
		var item_pos = item.position
		var item_to_player = item_pos - player.position
		var squared_distance_to_item = item_to_player.length_squared()
		
		var to_add = (item_to_player.normalized() / squared_distance_to_item) * item_weight_squared
		if not is_nan(to_add.x) and not is_nan(to_add.y):
			move_vector = move_vector + to_add
			
	# Go towards "neutrals" (trees)
	var tree_weight_squared = tree_weight * tree_weight
	for neutral in _entity_spawner.neutrals:
		var neutral_pos = neutral.position
		var neutral_to_player = neutral_pos - player.position
		var squared_distance_to_neutral = neutral_to_player.length_squared()
		
		var to_add = (neutral_to_player.normalized() / squared_distance_to_neutral) * tree_weight_squared
		
		# Weigh down nearby trees to keep from getting stuck on them
		if squared_distance_to_neutral < (preferred_distance_squared / 2):
			to_add = to_add * -1

		if not is_nan(to_add.x) and not is_nan(to_add.y):
			move_vector = move_vector + to_add
			
	# Go away from projectiles
	var projectile_weight_squared = projectile_weight * projectile_weight
	for projectile in projectiles_container.get_children():
		var projectile_shape = projectile._hitbox._collision.shape
		var extra_range = 0
		if projectile_shape is CircleShape2D:
			extra_range = projectile_shape.radius
		elif projectile_shape is RectangleShape2D:
			extra_range = projectile_shape.extents.x
			if projectile_shape.extents.y > extra_range:
				extra_range = projectile_shape.extents.y
		
		var projectile_pos = projectile.position
		var projectile_to_player = projectile_pos - player.position
		var extra_range_squared = extra_range * extra_range
		var squared_distance_to_item = projectile_to_player.length_squared() - extra_range_squared
		if squared_distance_to_item < 0:
			squared_distance_to_item = .001
		
		var to_add = (projectile_to_player.normalized() / squared_distance_to_item) * -1 * projectile_weight_squared
		if squared_distance_to_item > 250_000:
			to_add = Vector2.ZERO
		if not is_nan(to_add.x) and not is_nan(to_add.y):
			move_vector = move_vector + to_add
	
	var shooting_anyone = false
	var must_run_away = false
	var egg_weight_squared = egg_weight * egg_weight
	
	# Move towards distant enemies, away from nearby ones.  Determined by weapons range.
	for enemy in _entity_spawner.enemies:
		var is_egg = enemy._attack_behavior is SpawningAttackBehavior
		var enemy_to_player = enemy.position - player.position
		var squared_distance_to_enemy = (enemy_to_player).length_squared()
		
		var to_add = (enemy_to_player.normalized() / squared_distance_to_enemy)
		
		if enemy.stats.base_drop_chance == 1:
			to_add = to_add * egg_weight_squared * 4
		
		if squared_distance_to_enemy < preferred_distance_squared:
			shooting_anyone = true
			to_add = to_add * -1
			if enemy._current_attack_behavior is ChargingAttackBehavior:
				if enemy._move_locked:
					enemy_to_player = enemy._current_attack_behavior._charge_direction.tangent()
					to_add = to_add * 4
			
		if squared_distance_to_enemy < (preferred_distance_squared / 4):
			must_run_away = true
			
		if is_egg:
			to_add = to_add * egg_weight_squared
		
		move_vector = move_vector + to_add
		
	# Move towards distant enemies, away from nearby ones.  Determined by weapons range.
	var boss_weight_squared = boss_weight * boss_weight
	for boss in _entity_spawner.bosses:
		var boss_to_player = boss.position - player.position
		var squared_distance_to_boss = (boss_to_player).length_squared()
		
		var to_add = (boss_to_player.normalized() / squared_distance_to_boss) * boss_weight_squared
		if squared_distance_to_boss < preferred_distance_squared:
			shooting_anyone = true
			to_add = to_add * -1
			if boss._current_attack_behavior is ChargingAttackBehavior:
				if boss._move_locked:
					squared_distance_to_boss = squared_distance_to_boss / 4
					boss_to_player = boss._current_attack_behavior._charge_direction.tangent()
			
		if squared_distance_to_boss < (preferred_distance_squared / 4):
			must_run_away = true
		
		move_vector = move_vector + to_add
		
	
	var far_corner = ZoneService.current_zone_max_position
	var map_corners = [Vector2(0,0), Vector2(0, far_corner.y), Vector2(far_corner.x, 0), Vector2(far_corner.x, far_corner.y)]
	var corner_distance = 300
	var square_corner_distance = corner_distance * corner_distance
	
	for corner in map_corners:
		var corner_to_player = corner - player.position
		var squared_distance_to_corner = corner_to_player.length_squared()
		
		var to_add = (corner_to_player.normalized() / squared_distance_to_corner) * -2
		if squared_distance_to_corner > square_corner_distance:
			to_add = Vector2.ZERO
		if not is_nan(to_add.x) and not is_nan(to_add.y):
			move_vector = move_vector + to_add
	
	var bumper_x = 0
	var square_bumper_distance = bumper_distance * bumper_distance
	
	while bumper_x < far_corner.x:
		var bumper_position = Vector2(bumper_x, 0)
		
		var squared_distance = (bumper_position - player.position).length_squared()
		
		var to_add = (Vector2(-1,1).normalized() / squared_distance) * bumper_weight
		if squared_distance > square_bumper_distance:
			to_add = Vector2.ZERO
		if not is_nan(to_add.x) and not is_nan(to_add.y):
			move_vector = move_vector + to_add
		
		bumper_x = bumper_x + bumper_spacing
		
	bumper_x = 0
	while bumper_x < far_corner.x:
		var bumper_position = Vector2(bumper_x, far_corner.y)
		
		var squared_distance = (bumper_position - player.position).length_squared()
		
		var to_add = (Vector2(1,-1).normalized() / squared_distance) * bumper_weight
		if squared_distance > square_bumper_distance:
			to_add = Vector2.ZERO
		if not is_nan(to_add.x) and not is_nan(to_add.y):
			move_vector = move_vector + to_add
		
		bumper_x = bumper_x + bumper_spacing
		
	var bumper_y = 0
	while bumper_y < far_corner.y:
		var bumper_position = Vector2(0, bumper_y)
		
		var squared_distance = (bumper_position - player.position).length_squared()
		
		var to_add = (Vector2(1,1).normalized() / squared_distance) * bumper_weight
		if squared_distance > square_bumper_distance:
			to_add = Vector2.ZERO
		if not is_nan(to_add.x) and not is_nan(to_add.y):
			move_vector = move_vector + to_add
		
		bumper_y = bumper_y + bumper_spacing
		
	bumper_y = 0
	while bumper_y < far_corner.y:
		var bumper_position = Vector2(far_corner.x, bumper_y)
		
		var squared_distance = (bumper_position - player.position).length_squared()
		
		var to_add = (Vector2(-1,-1).normalized() / squared_distance) * bumper_weight
		if squared_distance > square_bumper_distance:
			to_add = Vector2.ZERO
		if not is_nan(to_add.x) and not is_nan(to_add.y):
			move_vector = move_vector + to_add
		
		bumper_y = bumper_y + bumper_spacing
		
	if (shooting_anyone and not must_run_away) and is_soldier:
		return Vector2.ZERO
		
	return move_vector.normalized()
