extends Node

## Script de test pour valider les signaux de monstres
## Utilisation : Ajouter ce script à la scène principale temporairement

func _ready():
	print("🧪 [MONSTER SIGNAL TEST] Script de test chargé")
	
	# Attendre que les monstres soient chargés
	await get_tree().create_timer(3.0).timeout
	test_monster_signals()

func test_monster_signals():
	print("🧪 [MONSTER SIGNAL TEST] Recherche des monstres...")
	
	var game_manager = get_node_or_null("/root/Main/GameManager")
	if not game_manager:
		print("❌ GameManager non trouvé")
		return
		
	var monsters = game_manager.monsters
	print("🧪 [MONSTER SIGNAL TEST] Nombre de monstres trouvés: ", monsters.size())
	
	for monster_id in monsters.keys():
		var monster = monsters[monster_id]
		if monster and is_instance_valid(monster):
			print("🧪 [MONSTER SIGNAL TEST] Testant monstre: ", monster.monster_name)
			test_single_monster(monster)

func test_single_monster(monster: Monster):
	# Vérifier les signaux
	var signals_check = {
		"monster_clicked": monster.has_user_signal("monster_clicked"),
		"monster_right_clicked": monster.has_user_signal("monster_right_clicked"), 
		"monster_hovered": monster.has_user_signal("monster_hovered"),
		"monster_died": monster.has_user_signal("monster_died")
	}
	
	print("🧪 [MONSTER SIGNAL TEST] Signaux pour ", monster.monster_name, ": ", signals_check)
	
	# Simuler un clic gauche
	if signals_check["monster_clicked"]:
		print("✅ Signal monster_clicked prêt - Simulation du clic...")
		monster.monster_clicked.emit(monster)
	else:
		print("❌ Signal monster_clicked manquant") 