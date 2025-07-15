extends Resource
class_name MapConfig

## SYSTÈME DE MAPS SIMPLE BASÉ SUR COORDONNÉES
## ============================================
## Système simple : (0,0) = origine
## (1,0) = droite, (-1,0) = gauche, (0,1) = haut, (0,-1) = bas

# Positions de spawn selon la direction d'arrivée
const SPAWN_POSITIONS = {
	"left": Vector2(100, 538),       # Vient de la gauche
	"right": Vector2(1820, 538),     # Vient de la droite
	"up": Vector2(960, 100),         # Vient du haut  
	"down": Vector2(960, 977),       # Vient du bas
	"center": Vector2(960, 538)      # Centre par défaut
}

# Zones de transition sur les bords
const TRANSITION_ZONES = {
	"left": {"position": Vector2(37, 538), "size": Vector2(64, 1019)},
	"right": {"position": Vector2(1858, 538), "size": Vector2(167, 1020)},
	"up": {"position": Vector2(960, 31), "size": Vector2(1779, 54)},
	"down": {"position": Vector2(960, 1055), "size": Vector2(1916, 62)}
}

## MÉTHODES SIMPLES
## ================

static func get_map_id(x: int, y: int) -> String:
	"""Retourne l'ID de la map aux coordonnées données"""
	return "map_" + str(x) + "_" + str(y)

static func parse_coords(map_id: String) -> Vector2i:
	"""Parse map_X_Y pour extraire les coordonnées"""
	var parts = map_id.split("_")
	if parts.size() >= 3:
		return Vector2i(int(parts[1]), int(parts[2]))
	return Vector2i(999, 999)  # Coordonnées invalides

static func get_adjacent_map(current_map: String, direction: String) -> String:
	"""Calcule la map adjacente dans une direction"""
	var coords = parse_coords(current_map)
	
	match direction:
		"left":
			coords.x -= 1
		"right":
			coords.x += 1
		"up":
			coords.y += 1
		"down":
			coords.y -= 1
		_:
			return ""
	
	return get_map_id(coords.x, coords.y)

static func get_spawn_direction(from_map: String, to_map: String) -> String:
	"""Calcule la direction de spawn selon le mouvement"""
	var from_coords = parse_coords(from_map)
	var to_coords = parse_coords(to_map)
	
	var diff_x = to_coords.x - from_coords.x
	var diff_y = to_coords.y - from_coords.y
	
	if diff_x > 0:
		return "left"    # Vient de la gauche -> spawn à gauche
	elif diff_x < 0:
		return "right"   # Vient de la droite -> spawn à droite
	elif diff_y > 0:
		return "down"    # Vient du bas -> spawn en bas
	elif diff_y < 0:
		return "up"      # Vient du haut -> spawn en haut
	else:
		return "center"

static func get_spawn_position(direction: String) -> Vector2:
	"""Retourne la position de spawn"""
	return SPAWN_POSITIONS.get(direction, SPAWN_POSITIONS.center)

 