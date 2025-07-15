extends Node

## Script de test pour le système de monstres

func _ready():
	print("=== TEST SYSTÈME DE MONSTRES ===")
	
	# Attendre un peu pour que les autoloads soient prêts
	await get_tree().create_timer(2.0).timeout
	
	# Test 1: Vérifier GameManager
	if GameManager:
		print("✅ GameManager trouvé")
		print("  - Monstres actuels: ", GameManager.monsters.size())
	else:
		print("❌ GameManager non trouvé")
	
	# Test 2: Vérifier AuthManager
	if AuthManager:
		print("✅ AuthManager trouvé")
		var token = AuthManager.get_access_token()
		print("  - Token présent: ", token != "")
	else:
		print("❌ AuthManager non trouvé")
	
	# Test 3: Créer un monstre de test
	test_create_monster()

func test_create_monster():
	print("=== TEST CRÉATION MONSTRE ===")
	
	# Données de test d'un monstre
	var monster_data = {
		"id": "test-monster-123",
		"template_id": "bouftou",
		"name": "Bouftou de Test",
		"level": 2,
		"is_alive": true,
		"behavior": "neutral",
		"pos_x": 500,
		"pos_y": 300,
		"stats": {
			"health": 25,
			"max_health": 25,
			"strength": 12,
			"intelligence": 0,
			"agility": 6,
			"vitality": 12
		}
	}
	
	# Charger la scène monstre
	var monster_scene = preload("res://game/monsters/Monster.tscn")
	var monster_instance = monster_scene.instantiate()
	
	# Initialiser avec les données de test
	monster_instance.initialize_monster(monster_data)
	
	# Ajouter à la scène
	add_child(monster_instance)
	
	print("✅ Monstre de test créé: ", monster_instance.monster_name)
	print("  - Position: (", monster_instance.position.x, ", ", monster_instance.position.y, ")")
	print("  - Niveau: ", monster_instance.level)
	print("  - Vie: ", monster_instance.health, "/", monster_instance.max_health)
	
	# Test d'attaque après 3 secondes
	await get_tree().create_timer(3.0).timeout
	print("=== TEST ATTAQUE ===")
	monster_instance.take_damage(10)
	
	# Test de mort après 2 secondes
	await get_tree().create_timer(2.0).timeout
	print("=== TEST MORT ===")
	monster_instance.take_damage(20) 