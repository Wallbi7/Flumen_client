extends PanelContainer

## GESTIONNAIRE HUD STYLE DOFUS 1.29
## ====================================
## Interface utilisateur principale déplaçable avec orbe de vie, barre d'XP, et boutons.

## MÉTHODES D'ACCÈS AUX NŒUDS
## ============================
# Les chemins sont mis à jour pour la nouvelle structure.

## VARIABLES POUR LE DÉPLACEMENT
## ==============================
var dragging = false
var drag_start_mouse_pos = Vector2()
var drag_start_panel_pos = Vector2()

## VARIABLES D'ÉTAT
## =================
var current_character_data: Dictionary = {}
var panels_visible: Dictionary = {"stats": false, "inventory": false, "character": false}

## INITIALISATION
## ===============
func _ready():
	print("[HUD] === INITIALISATION HUD (Style Dofus) ===")
	
	# Configuration initiale
	_setup_buttons()
	_setup_stats_panel()
	_load_character_data()
	_update_display()
	
	print("[HUD] HUD initialisé avec succès.")

## GESTION DU DÉPLACEMENT (DRAG & DROP)
## =====================================
func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
		if dragging:
			drag_start_mouse_pos = get_global_mouse_position()
			drag_start_panel_pos = position
	elif event is InputEventMouseMotion and dragging:
		position = drag_start_panel_pos + (get_global_mouse_position() - drag_start_mouse_pos)

## CONFIGURATION DES BOUTONS
## ==========================
func _setup_buttons():
	"""Configure les connexions des boutons."""
	var buttons_path = "MainHBox/RightVBox/Buttons/"
	var inventory_btn = get_node_or_null(buttons_path + "InventoryButton")
	if inventory_btn:
		inventory_btn.pressed.connect(_on_inventory_button_pressed)
	
	var stats_btn = get_node_or_null(buttons_path + "StatsButton")
	if stats_btn:
		stats_btn.pressed.connect(_on_stats_button_pressed)
	
	var spells_btn = get_node_or_null(buttons_path + "SpellsButton")
	if spells_btn:
		spells_btn.pressed.connect(_on_spells_button_pressed)
	
	var quests_btn = get_node_or_null(buttons_path + "QuestsButton")
	if quests_btn:
		quests_btn.pressed.connect(_on_quests_button_pressed)
	
	var options_btn = get_node_or_null(buttons_path + "OptionsButton")
	if options_btn:
		options_btn.pressed.connect(_on_options_button_pressed)

## CONFIGURATION DU PANEL DE STATS
## ================================
func _setup_stats_panel():
	"""Configure le panel de caractéristiques."""
	print("[HUD] Configuration du panel de stats...")
	
	# S'assurer que le panel est initialement caché
	var stats_panel_node = get_node_or_null("StatsPanel")
	if stats_panel_node:
		stats_panel_node.visible = false
		
		# Connecter les signaux du panel de stats
		if stats_panel_node.has_signal("stats_updated"):
			stats_panel_node.stats_updated.connect(_on_stats_updated)
		if stats_panel_node.has_signal("panel_closed"):
			stats_panel_node.panel_closed.connect(_on_stats_panel_close)
	else:
		print("[HUD] ⚠️ stats_panel non trouvé")

## CHARGEMENT DES DONNÉES PERSONNAGE
## ==================================
func _load_character_data():
	"""Charge les données du personnage depuis AuthManager."""
	print("[HUD] Chargement des données personnage...")
	
	# Récupérer les données depuis AuthManager
	var payload = AuthManager.get_jwt_payload()
	if payload.has("character"):
		current_character_data = payload.character
		print("[HUD] Données personnage chargées: ", current_character_data)
	else:
		print("[HUD] ⚠️ Aucune donnée personnage trouvée dans le JWT")
		# Données par défaut pour éviter les erreurs
		current_character_data = {
			"level": 1,
			"experience": 0,
			"stats": {
				"health": 50,
				"max_health": 50,
				"mana": 20,
				"max_mana": 20
			},
			"kamas": 0
		}

## MISE À JOUR DE L'AFFICHAGE
## ===========================
func _update_display():
	"""Met à jour tous les éléments visuels du HUD."""
	_update_level_display()
	_update_xp_display()
	_update_health_display()
	_update_action_points_display()
	_update_kamas_display() # Note: Kamas n'est plus dans le HUD, peut être retiré

## MISE À JOUR DU NIVEAU
## ======================
func _update_level_display():
	"""Met à jour l'affichage du niveau."""
	var level_lbl = get_node_or_null("MainHBox/CenterVBox/LevelLabel")
	if level_lbl:
		var level = current_character_data.get("level", 1)
		level_lbl.text = "Niv. " + str(level)

## MISE À JOUR DE L'EXPÉRIENCE
## ============================
func _update_xp_display():
	"""Met à jour la barre d'expérience."""
	var level = current_character_data.get("level", 1)
	var current_xp = current_character_data.get("experience", 0)
	
	var xp_for_current_level = _calculate_xp_for_level(level)
	var xp_for_next_level = _calculate_xp_for_level(level + 1)
	var xp_needed_for_level = xp_for_next_level - xp_for_current_level
	var xp_progress_in_level = current_xp - xp_for_current_level
	
	var xp_bar_node = get_node_or_null("MainHBox/CenterVBox/XPBar")
	if xp_bar_node:
		xp_bar_node.max_value = xp_needed_for_level if xp_needed_for_level > 0 else 1
		xp_bar_node.value = xp_progress_in_level
	
	var xp_lbl = get_node_or_null("MainHBox/CenterVBox/XPLabel")
	if xp_lbl:
		xp_lbl.text = "%s / %s (%d%%)" % [xp_progress_in_level, xp_needed_for_level, xp_bar_node.value / xp_bar_node.max_value * 100]

## MISE À JOUR DE LA SANTÉ
## ========================
func _update_health_display():
	"""Met à jour l'orbe de vie."""
	var stats = current_character_data.get("stats", {})
	var health = stats.get("health", 50)
	var max_health = stats.get("max_health", 50)
	
	var hp_lbl = get_node_or_null("MainHBox/HPOrb/HPLabel")
	if hp_lbl:
		hp_lbl.text = "%d\n%d" % [health, max_health]
		
	var hp_orb = get_node_or_null("MainHBox/HPOrb")
	if hp_orb:
		var health_percent = float(health) / max_health if max_health > 0 else 0.0
		if health_percent > 0.6:
			hp_orb.get("theme_override_styles/panel").bg_color = Color.html("#cc3333")
		elif health_percent > 0.3:
			hp_orb.get("theme_override_styles/panel").bg_color = Color.html("#cca333")
		else:
			hp_orb.get("theme_override_styles/panel").bg_color = Color.html("#802020")

## MISE À JOUR DES PA/PM
## =====================
func _update_action_points_display():
	"""Met à jour l'affichage des PA/PM."""
	var action_points = current_character_data.get("action_points", 6)
	var movement_points = current_character_data.get("movement_points", 3)
	
	var pa_lbl = get_node_or_null("MainHBox/RightVBox/PAPMBox/PALabel")
	if pa_lbl:
		pa_lbl.text = str(action_points) + " PA"
	
	var pm_lbl = get_node_or_null("MainHBox/RightVBox/PAPMBox/PMLabel")
	if pm_lbl:
		pm_lbl.text = str(movement_points) + " PM"

## MISE À JOUR DES KAMAS
## ======================
func _update_kamas_display():
	# Ce noeud n'existe plus dans le nouveau design, la fonction est conservée pour éviter les erreurs
	pass

## CALCUL DE L'XP
## ===============
func _calculate_xp_for_level(level: int) -> int:
	"""Calcule l'XP total nécessaire pour atteindre un niveau donné (formule Dofus)."""
	if level <= 1:
		return 0
	
	var total_xp = 0
	for i in range(2, level + 1):
		if i <= 100:
			total_xp += i * 100
		else:
			total_xp += (i * i) * 10
	
	return total_xp

## GESTION DES RACCOURCIS CLAVIER
## ===============================
func _input(event):
	"""Gère les raccourcis clavier pour les menus."""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_I:
				_toggle_character_panel()
			KEY_P:
				_toggle_character_panel()
			KEY_S:
				_on_spells_button_pressed()
			KEY_Q:
				_on_quests_button_pressed()
			KEY_O:
				_on_options_button_pressed()

## CALLBACKS DES BOUTONS
## ======================

func _on_inventory_button_pressed():
	"""Ouvre/ferme le panel personnage (inventaire + stats unifiés)."""
	print("[HUD] 📦 Panel Personnage (Inventaire + Stats)")
	_toggle_character_panel()

func _on_stats_button_pressed():
	"""Ouvre/ferme le panel personnage (inventaire + stats unifiés)."""
	print("[HUD] 📊 Panel Personnage (Inventaire + Stats)")
	_toggle_character_panel()

func _on_spells_button_pressed():
	"""Ouvre/ferme le grimoire de sorts."""
	print("[HUD] ✨ Sorts (non implémenté)")
	# TODO: Implémenter les sorts

func _on_quests_button_pressed():
	"""Ouvre/ferme le carnet de quêtes."""
	print("[HUD] 📜 Quêtes (non implémenté)")
	# TODO: Implémenter les quêtes

func _on_options_button_pressed():
	"""Ouvre/ferme les options."""
	print("[HUD] ⚙️ Options")
	# Pour l'instant, bouton de déconnexion direct
	_show_disconnect_dialog()

## GESTION DU PANEL DE STATS
## ==========================
func _toggle_stats_panel():
	"""Affiche/cache le panel de caractéristiques."""
	panels_visible.stats = !panels_visible.stats
	var stats_panel_node = get_node_or_null("StatsPanel")
	
	if panels_visible.stats and stats_panel_node:
		# Ouvrir le panel avec les données actuelles
		var stats = current_character_data.get("stats", {})
		var stat_points = current_character_data.get("stat_points", 0)
		
		if stats_panel_node.has_method("open_panel"):
			stats_panel_node.open_panel(stats, stat_points)
		else:
			stats_panel_node.visible = true
			_update_stats_panel()
	elif stats_panel_node:
		stats_panel_node.visible = false

func _on_stats_panel_close():
	"""Ferme le panel de caractéristiques."""
	panels_visible.stats = false
	var stats_panel_node = get_node_or_null("StatsPanel")
	if stats_panel_node:
		stats_panel_node.visible = false

func _on_stats_updated(update_data: Dictionary):
	"""Appelé quand le joueur valide des changements de stats."""
	print("[HUD] Mise à jour des stats reçue: ", update_data)
	
	# Mettre à jour les données locales
	if update_data.has("stats"):
		current_character_data.stats = update_data.stats
	if update_data.has("stat_points"):
		current_character_data.stat_points = update_data.stat_points
	
	# Envoyer au serveur via l'API
	_send_stats_to_server(update_data)
	
	# Mettre à jour l'affichage
	_update_display()

func _send_stats_to_server(update_data: Dictionary):
	"""Envoie les nouvelles stats au serveur via l'API REST."""
	print("[HUD] Envoi des stats au serveur...", update_data)

	var character_id = AuthManager.get_character_id()
	if character_id == 0:
		print("[HUD] ❌ ID de personnage non valide, impossible d'envoyer les stats.")
		return

	var url = "%s/v1/characters/%d/stats" % [ServerConfig.API_URL, character_id]
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + AuthManager.get_access_token()
	]

	# Le corps de la requête doit correspondre à la structure UpdateStatsRequest du backend
	var body = {
		"stats": update_data.get("stats", {}),
		"stat_points": update_data.get("stat_points", 0)
	}

	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_stats_update_response.bind(http_request))
	
	var error = http_request.request(url, headers, HTTPClient.METHOD_PUT, JSON.stringify(body))
	if error != OK:
		print("[HUD] ❌ Erreur lors de l'envoi de la requête de mise à jour des stats: ", error)
		http_request.queue_free()

func _on_stats_update_response(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, request_node: HTTPRequest):
	"""Gère la réponse du serveur pour la mise à jour des stats."""
	print("[HUD] Réponse serveur pour stats: ", response_code)
	
	if response_code == 200:
		print("[HUD] ✅ Stats sauvegardées avec succès")
		var response_data = JSON.parse_string(body.get_string_from_utf8())
		if response_data:
			# Mettre à jour les données locales avec la réponse du serveur pour rester synchronisé
			update_character_data(response_data)
	else:
		print("[HUD] ❌ Erreur lors de la sauvegarde des stats: ", response_code)
		var error_response = JSON.parse_string(body.get_string_from_utf8())
		var error_message = "Erreur inconnue"
		if error_response and error_response.has("error"):
			error_message = error_response.error
		# TODO: Afficher un message d'erreur à l'utilisateur
		print("[HUD] Message d'erreur du serveur: ", error_message)

	request_node.queue_free()

func _update_stats_panel():
	"""Met à jour le contenu du panel de caractéristiques."""
	print("[HUD] Mise à jour du panel de stats...")
	
	# Récupérer les stats depuis les données du personnage
	var _stats = current_character_data.get("stats", {})  # TODO: Utiliser pour affichage détaillé
	var stat_points = current_character_data.get("stat_points", 0)
	
	# Mettre à jour le label des points disponibles
	var stats_panel_node = get_node_or_null("StatsPanel")
	if stats_panel_node:
		var points_label = stats_panel_node.get_node_or_null("VBox/PointsLabel")
		if points_label:
			points_label.text = "Points à distribuer : " + str(stat_points)
	
	# TODO: Mettre à jour la liste des stats
	# Cela nécessitera le script StatsPanel.gd pour gérer les détails

## GESTION DU PANEL D'INVENTAIRE
## ===============================
func _toggle_character_panel():
	"""Affiche/cache le panel personnage unifié (inventaire + stats)."""
	panels_visible.character = !panels_visible.character
	var character_panel_node = get_node_or_null("CharacterPanel")
	
	if panels_visible.character:
		# Ouvrir le panel personnage
		if character_panel_node:
			if character_panel_node.has_method("open_character_panel"):
				character_panel_node.open_character_panel()
			else:
				character_panel_node.visible = true
		else:
			# Créer le panel personnage s'il n'existe pas
			_create_character_panel()
	else:
		# Fermer le panel personnage
		if character_panel_node and character_panel_node.has_method("close_character_panel"):
			character_panel_node.close_character_panel()
		elif character_panel_node:
			character_panel_node.visible = false

func _create_character_panel():
	"""Crée le panel personnage unifié."""
	print("[HUD] Création du panel personnage...")
	
	# Charger la scène du panel personnage
	var character_scene = preload("res://game/ui/CharacterPanel.tscn")
	if character_scene:
		var character_panel = character_scene.instantiate()
		character_panel.name = "CharacterPanel"
		add_child(character_panel)
		
		# Ouvrir le panel personnage
		if character_panel.has_method("open_character_panel"):
			character_panel.open_character_panel()
	else:
		print("[HUD] ❌ Impossible de charger la scène du panel personnage")

## MÉTHODES PUBLIQUES POUR MISE À JOUR
## ====================================

func update_character_data(new_data: Dictionary):
	"""Met à jour les données du personnage et l'affichage."""
	print("[HUD] Mise à jour des données personnage")
	current_character_data = new_data
	_update_display()

func update_experience(new_xp: int):
	"""Met à jour l'expérience et vérifie les montées de niveau."""
	print("[HUD] Mise à jour XP: ", new_xp)
	current_character_data.experience = new_xp
	_update_xp_display()

func update_level(new_level: int):
	"""Met à jour le niveau du personnage."""
	print("[HUD] Mise à jour niveau: ", new_level)
	current_character_data.level = new_level
	_update_level_display()
	_update_xp_display()

func update_kamas(new_kamas: int):
	"""Met à jour l'affichage des Kamas."""
	print("[HUD] Mise à jour Kamas: ", new_kamas)
	current_character_data.kamas = new_kamas
	_update_kamas_display()

## MISE À JOUR DES PA/PM
## ======================
func update_action_points(new_ap: int, max_ap: int = -1):
	"""Met à jour les Points d'Action."""
	print("[HUD] Mise à jour PA: ", new_ap, "/", max_ap)
	current_character_data.action_points = new_ap
	if max_ap >= 0:
		current_character_data.max_action_points = max_ap
	_update_action_points_display()

func update_movement_points(new_mp: int, max_mp: int = -1):
	"""Met à jour les Points de Mouvement."""
	print("[HUD] Mise à jour PM: ", new_mp, "/", max_mp)
	current_character_data.movement_points = new_mp
	if max_mp >= 0:
		current_character_data.max_movement_points = max_mp
	_update_action_points_display()

func update_health(new_health: int, new_max_health: int = -1):
	"""Met à jour les Points de Vie."""
	print("[HUD] Mise à jour PV: ", new_health, "/", new_max_health)
	if not current_character_data.has("stats"):
		current_character_data.stats = {}
	current_character_data.stats.health = new_health
	if new_max_health >= 0:
		current_character_data.stats.max_health = new_max_health
	_update_health_display()

func update_mana(new_mana: int, new_max_mana: int = -1):
	"""Met à jour les Points de Magie."""
	print("[HUD] Mise à jour Mana: ", new_mana, "/", new_max_mana)
	if not current_character_data.has("stats"):
		current_character_data.stats = {}
	current_character_data.stats.mana = new_mana
	if new_max_mana >= 0:
		current_character_data.stats.max_mana = new_max_mana
	_update_health_display()

## DÉCONNEXION
## ============
func _show_disconnect_dialog():
	"""Affiche une confirmation de déconnexion."""
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "Se déconnecter du jeu ?"
	dialog.title = "Déconnexion"
	
	# Ajouter un bouton de confirmation
	var confirm_button = Button.new()
	confirm_button.text = "Déconnexion"
	confirm_button.pressed.connect(_on_disconnect_confirmed)
	
	add_child(dialog)
	dialog.popup_centered()
	
	# Connecter la confirmation
	dialog.confirmed.connect(_on_disconnect_confirmed)

func _on_disconnect_confirmed():
	"""Effectue la déconnexion."""
	print("[HUD] Déconnexion confirmée")
	
	# Déconnecter via AuthManager
	AuthManager.logout()
	
	# Retourner à l'écran de connexion
	get_tree().change_scene_to_file("res://game/LoginScene.tscn")

## FONCTIONS DE TEST ET DÉMO
## ==========================
func _test_hud_functionality():
	"""Fonction de test pour démontrer les fonctionnalités du HUD."""
	print("[HUD] 🧪 Test des fonctionnalités HUD")
	
	# Test 1: Simuler une perte de PV
	await get_tree().create_timer(2.0).timeout
	update_health(30, 50)
	print("[HUD] ⚔️ Perte de PV (30/50)")
	
	# Test 2: Utiliser des PA
	await get_tree().create_timer(1.0).timeout
	update_action_points(3, 6)
	print("[HUD] ⚡ Utilisation des PA (3/6)")
	
	# Test 3: Utiliser des PM
	await get_tree().create_timer(1.0).timeout
	update_movement_points(1, 3)
	print("[HUD] 👟 Utilisation des PM (1/3)")
	
	# Test 4: Gain d'XP
	await get_tree().create_timer(1.0).timeout
	update_experience(150)
	print("[HUD] ⭐ Gain d'XP (150)")
	
	# Test 5: Restauration début de tour
	await get_tree().create_timer(2.0).timeout
	update_action_points(6, 6)
	update_movement_points(3, 3)
	update_health(50, 50)
	print("[HUD] 🔄 Restauration début de tour")

func start_hud_demo():
	"""Lance une démonstration des fonctionnalités du HUD."""
	print("[HUD] 🎬 Démarrage de la démo HUD")
	_test_hud_functionality()

## RACCOURCIS CLAVIER AVANCÉS
## ===========================
func _unhandled_key_input(event):
	"""Gère les raccourcis clavier spéciaux."""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				# Aide / Raccourcis
				_show_help_dialog()
			KEY_F5:
				# Démonstration du HUD
				start_hud_demo()
			KEY_ESCAPE:
				# Fermer tous les panels
				_close_all_panels()

func _show_help_dialog():
	"""Affiche l'aide avec les raccourcis clavier."""
	var dialog = AcceptDialog.new()
	dialog.title = "Aide - Raccourcis"
	dialog.dialog_text = """Raccourcis clavier disponibles:

🎮 MENUS:
• I - Inventaire
• P - Caractéristiques  
• S - Sorts
• Q - Quêtes
• O - Options

🔧 DEBUG:
• F1 - Cette aide
• F5 - Test du HUD
• ESC - Fermer panels

⚔️ JEU:
• Clic droit - Se déplacer
• Space - Passer le tour"""
	
	add_child(dialog)
	dialog.popup_centered()
	await dialog.confirmed
	dialog.queue_free()

func _close_all_panels():
	"""Ferme tous les panels ouverts."""
	panels_visible.stats = false
	panels_visible.inventory = false
	panels_visible.character = false
	
	var stats_panel_node = get_node_or_null("StatsPanel")
	if stats_panel_node:
		stats_panel_node.visible = false
	
	var character_panel_node = get_node_or_null("CharacterPanel")
	if character_panel_node:
		if character_panel_node.has_method("close_character_panel"):
			character_panel_node.close_character_panel()
		else:
			character_panel_node.visible = false
	
	print("[HUD] 📋 Tous les panels fermés") 