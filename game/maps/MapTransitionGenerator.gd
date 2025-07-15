extends Node
class_name MapTransitionGenerator

## GÉNÉRATEUR SIMPLE DE TRANSITIONS
## =================================
## Génère automatiquement 4 zones de transition (gauche, droite, haut, bas)
## Chaque zone mène vers la map adjacente selon les coordonnées

static func generate_transitions_for_map(map_node: Node, map_id: String):
	"""Génère les 4 zones de transition pour une map"""
	print("[MapTransitionGenerator] Génération des transitions pour: ", map_id)
	
	# Supprimer les anciennes transitions
	_remove_existing_transitions(map_node)
	
	# Créer les 4 transitions possibles
	var directions = ["left", "right", "up", "down"]
	
	for direction in directions:
		_create_transition_area(map_node, map_id, direction)

static func _remove_existing_transitions(map_node: Node):
	"""Supprime les anciennes zones de transition"""
	for child in map_node.get_children():
		if child.name.begins_with("TransitionArea_"):
			child.queue_free()

static func _create_transition_area(map_node: Node, current_map: String, direction: String):
	"""Crée une zone de transition dans une direction"""
	
	# Calculer la map de destination
	var target_map = MapConfig.get_adjacent_map(current_map, direction)
	print("[MapTransitionGenerator] ", direction, " -> ", target_map)
	
	# Récupérer les données de la zone
	var zone_data = MapConfig.TRANSITION_ZONES.get(direction)
	if not zone_data:
		return
	
	# Créer l'Area2D
	var area = Area2D.new()
	area.name = "TransitionArea_" + direction
	area.collision_layer = 2
	
	# Attacher le script TransitionArea
	var script = load("res://game/maps/TransitionArea.gd")
	area.set_script(script)
	
	# Configurer les propriétés
	area.target_map = target_map
	area.direction = direction
	
	# Position de spawn sur la map de destination
	var spawn_direction = MapConfig.get_spawn_direction(current_map, target_map)
	area.entry_point = MapConfig.get_spawn_position(spawn_direction)
	
	# Créer la collision
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = zone_data.size
	collision.shape = shape
	collision.position = zone_data.position
	
	# Assembler
	area.add_child(collision)
	map_node.add_child(area)
	
	print("[MapTransitionGenerator] ✅ Transition ", direction, " créée vers ", target_map)

static func debug_print_map_info(map_id: String):
	"""Affiche les informations de debug pour une map"""
	print("[MapTransitionGenerator] === DEBUG MAP INFO ===")
	print("[MapTransitionGenerator] Map ID: ", map_id)
	
	var coords = MapConfig.parse_coords(map_id)
	print("[MapTransitionGenerator] Coordonnées: (", coords.x, ", ", coords.y, ")")
	
	# Test des 4 directions
	var directions = ["left", "right", "up", "down"]
	for direction in directions:
		var target = MapConfig.get_adjacent_map(map_id, direction)
		var spawn_dir = MapConfig.get_spawn_direction(map_id, target)
		var spawn_pos = MapConfig.get_spawn_position(spawn_dir)
		print("[MapTransitionGenerator]   ", direction, " -> ", target, " (spawn: ", spawn_dir, " à ", spawn_pos, ")")

 
