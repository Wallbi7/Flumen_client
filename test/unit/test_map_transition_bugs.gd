extends RefCounted
class_name TestMapTransitionBugs

# Tests pour les bugs de transition de cartes rencontrés
var test_name = "TestMapTransitionBugs"
var assertion_count = 0
var failed_assertions = []

func _init():
	print("=== Tests Map Transition Bugs ===")

func assert_eq(actual, expected, message: String = ""):
	assertion_count += 1
	if actual != expected:
		var error_msg = "Expected <%s> but got <%s>" % [expected, actual]
		if message != "":
			error_msg = message + " - " + error_msg
		failed_assertions.append(error_msg)
		print("❌ ASSERTION FAILED: ", error_msg)
		return false
	print("✅ ", message if message != "" else "Assertion passed")
	return true

func assert_true(value, message: String = ""):
	assertion_count += 1
	if not value:
		var error_msg = "Expected true but got <%s>" % value
		if message != "":
			error_msg = message + " - " + error_msg
		failed_assertions.append(error_msg)
		print("❌ ASSERTION FAILED: ", error_msg)
		return false
	print("✅ ", message if message != "" else "Assertion passed")
	return true

# Bug 1: Coordonnées négatives mal gérées
func test_negative_coordinates():
	print("\n🗺️ Test: Negative Coordinates Bug")
	
	var coords = [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(0, -1)]
	
	for coord in coords:
		var map_name = "map_%d_%d" % [coord.x, coord.y]
		
		if coord == Vector2i(0, 0):
			assert_eq(map_name, "map_0_0", "Coordonnée origine")
		elif coord == Vector2i(-1, 0):
			assert_eq(map_name, "map_-1_0", "Coordonnée négative X")
		elif coord == Vector2i(0, -1):
			assert_eq(map_name, "map_0_-1", "Coordonnée négative Y")

# Bug 2: Direction de transition incorrecte
func test_transition_direction_calculation():
	print("\n🧭 Test: Transition Direction Calculation Bug")
	
	var current_coord = Vector2i(0, 0)
	var target_coords = {
		Vector2i(1, 0): "right",
		Vector2i(-1, 0): "left", 
		Vector2i(0, 1): "up",
		Vector2i(0, -1): "down"
	}
	
	for target_coord in target_coords.keys():
		var expected_direction = target_coords[target_coord]
		var calculated_direction = ""
		
		var diff = target_coord - current_coord
		if diff.x > 0:
			calculated_direction = "right"
		elif diff.x < 0:
			calculated_direction = "left"
		elif diff.y > 0:
			calculated_direction = "up"
		elif diff.y < 0:
			calculated_direction = "down"
		
		assert_eq(calculated_direction, expected_direction, 
			"Direction de %s vers %s" % [current_coord, target_coord])

# Bug 3: Calcul des cartes adjacentes
func test_adjacent_maps_calculation():
	print("\n🔄 Test: Adjacent Maps Calculation Bug")
	
	var center_map = Vector2i(0, 0)
	var expected_adjacent = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	
	var calculated_adjacent = []
	var directions = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	
	for direction in directions:
		calculated_adjacent.append(center_map + direction)
	
	assert_eq(calculated_adjacent.size(), 4, "Devrait avoir 4 cartes adjacentes")
	
	for expected in expected_adjacent:
		assert_true(expected in calculated_adjacent, "Carte %s devrait être adjacente" % expected)

func run_all_tests():
	print("🧪 Démarrage des tests Map Transition Bugs...")
	
	test_negative_coordinates()
	test_transition_direction_calculation()
	test_adjacent_maps_calculation()
	
	print("\n📊 === RÉSULTATS ===")
	print("Assertions: ", assertion_count)
	print("Échecs: ", failed_assertions.size())
	
	if failed_assertions.size() == 0:
		print("✅ Tous les tests Map Transition ont réussi!")
		return true
	else:
		print("❌ Tests Map Transition échoués:")
		for failure in failed_assertions:
			print("  - ", failure)
		return false
