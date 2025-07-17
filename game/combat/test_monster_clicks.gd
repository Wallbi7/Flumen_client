extends Node

## TEST: Simulation directe des clics sur les monstres
## Utilisation: Ajouter temporairement à la scène principale

func _ready():
	print("🧪 [MONSTER CLICK TEST] Test des clics sur monstres activé")
	print("🧪 Appuyez sur 'T' pour tester un clic sur le premier monstre")

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_T:
			test_direct_monster_click()

func test_direct_monster_click():
	print("🧪 [MONSTER CLICK TEST] Recherche du premier monstre...")
	
	var game_manager = get_node_or_null("/root/Main/GameManager")
	if not game_manager:
		print("❌ GameManager non trouvé")
		return
		
	var monsters = game_manager.monsters
	if monsters.size() == 0:
		print("❌ Aucun monstre trouvé")
		return
		
	var first_monster_id = monsters.keys()[0]
	var monster = monsters[first_monster_id]
	
	if not is_instance_valid(monster):
		print("❌ Monstre invalide")
		return
		
	print("🧪 Test d'émission directe du signal monster_clicked sur: ", monster.monster_name)
	
	# Test direct des signaux
	if monster.has_signal("monster_clicked"):
		print("✅ Signal monster_clicked trouvé - Émission...")
		monster.monster_clicked.emit(monster)
	else:
		print("❌ Signal monster_clicked non trouvé")
		
	# Liste tous les signaux du monstre
	print("🔍 Signaux disponibles:")
	var signal_list = monster.get_signal_list()
	for sig in signal_list:
		if "monster" in sig.name:
			print("  - ", sig.name) 