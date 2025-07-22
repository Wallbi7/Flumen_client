extends PanelContainer

## PANEL PERSONNAGE STYLE DOFUS 1.29
## ===================================
## Interface unifiée pour inventaire + stats + équipement avec design amélioré.

## CONSTANTES
## ===========
const INVENTORY_SLOTS = 60  # 6x10 grille comme Dofus
const EQUIPMENT_SLOTS = ["HEAD", "CHEST", "WEAPON", "AMULET", "RING", "BELT", "BOOTS", "PET", "MOUNT"]
const STAT_NAMES = {
	"vitality": "❤️ Vitalité",
	"wisdom": "🧠 Sagesse", 
	"strength": "💪 Force",
	"intelligence": "🎯 Intelligence",
	"chance": "🍀 Chance",
	"agility": "⚡ Agilité"
}

## VARIABLES D'ÉTAT
## =================
var is_visible = false
var character_id: String = ""
var character_data: Dictionary = {}
var inventory_data: Dictionary = {}
var dragging_item: Dictionary = {}
var drag_source_slot = null

## RÉFÉRENCES AUX NŒUDS UI
## ========================
var character_name_label: Label
var level_label: Label
var inventory_grid: GridContainer
var equipment_slots: Dictionary = {}
var stats_labels: Dictionary = {}
var item_tooltip: Control
var loading_label: Label

## INITIALISATION
## ===============
func _ready():
	print("[CharacterPanel] === INITIALISATION PANEL PERSONNAGE ===")
	
	# Configuration initiale
	if not _setup_ui_references():
		push_error("[CharacterPanel] Échec de l'initialisation des références UI")
		return
	
	_setup_drag_and_drop()
	_load_character_info()
	
	# Masquer initialement
	visible = false
	
	print("[CharacterPanel] Panel personnage initialisé.")

## CONFIGURATION DES RÉFÉRENCES UI
## ================================
func _setup_ui_references():
	"""Configure les références vers les nœuds UI."""
	
	# Header
	character_name_label = get_node_or_null("MainVBox/HeaderBar/HeaderHBox/CharacterName")
	level_label = get_node_or_null("MainVBox/HeaderBar/HeaderHBox/LevelLabel")
	loading_label = get_node_or_null("LoadingLabel")
	
	# Bouton fermeture
	var close_btn = get_node_or_null("MainVBox/HeaderBar/HeaderHBox/CloseButton")
	if close_btn:
		close_btn.pressed.connect(_on_close_button_pressed)
	
	# Grille d'inventaire
	inventory_grid = get_node_or_null("MainVBox/ContentHBox/RightPanel/InventoryScroll/InventoryGrid")
	if not inventory_grid:
		push_error("[CharacterPanel] ❌ InventoryGrid non trouvé")
		return false
	
	# Equipment slots
	var equipment_area = get_node_or_null("MainVBox/ContentHBox/MiddlePanel/EquipmentArea")
	if equipment_area:
		for slot_name in EQUIPMENT_SLOTS:
			var slot_node = equipment_area.get_node_or_null(slot_name + "Slot")
			if slot_node:
				equipment_slots[slot_name] = slot_node
	
	# Stats labels
	var stats_grid = get_node_or_null("MainVBox/ContentHBox/LeftPanel/CharacterStats/StatsVBox/StatsGrid")
	if stats_grid:
		stats_labels["vitality"] = stats_grid.get_node_or_null("VitalityValue")
		stats_labels["wisdom"] = stats_grid.get_node_or_null("WisdomValue")
		stats_labels["strength"] = stats_grid.get_node_or_null("StrengthValue")
		stats_labels["intelligence"] = stats_grid.get_node_or_null("IntelligenceValue")
		stats_labels["chance"] = stats_grid.get_node_or_null("ChanceValue")
		stats_labels["agility"] = stats_grid.get_node_or_null("AgilityValue")
	
	# Secondary stats
	var secondary_stats = get_node_or_null("MainVBox/ContentHBox/LeftPanel/CharacterStats/StatsVBox/SecondaryStatsGrid")
	if secondary_stats:
		stats_labels["hp"] = secondary_stats.get_node_or_null("HPValue")
		stats_labels["ap"] = secondary_stats.get_node_or_null("APValue")
		stats_labels["mp"] = secondary_stats.get_node_or_null("MPValue")
	
	# Tooltip
	item_tooltip = get_node_or_null("ItemTooltip")
	
	return true

## CONFIGURATION DRAG & DROP
## ==========================
func _setup_drag_and_drop():
	"""Configure le système de glisser-déposer."""
	# Configuration des slots d'inventaire
	if inventory_grid:
		for i in range(INVENTORY_SLOTS):
			var slot = _create_inventory_slot(i)
			inventory_grid.add_child(slot)
	
	# Configuration des slots d'équipement
	for slot_name in equipment_slots:
		var slot_node = equipment_slots[slot_name]
		_setup_equipment_slot(slot_node, slot_name)

func _create_inventory_slot(index: int) -> Control:
	"""Crée un slot d'inventaire."""
	var slot = Panel.new()
	slot.name = "InventorySlot_" + str(index)
	slot.custom_minimum_size = Vector2(48, 48)
	slot.set_script(load("res://game/ui/ItemSlot.gd"))
	
	# Style du slot
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.3, 0.4, 1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	slot.add_theme_stylebox_override("panel", style)
	
	# Configuration du slot
	if slot.has_method("setup_slot"):
		slot.setup_slot("inventory", index)
		slot.slot_clicked.connect(_on_inventory_slot_clicked)
		slot.item_dragged.connect(_on_item_drag_started)
		slot.item_dropped.connect(_on_item_dropped)
		slot.item_hovered.connect(_on_item_hovered)
		slot.item_unhovered.connect(_on_item_unhovered)
	
	return slot

func _setup_equipment_slot(slot_node: Control, slot_type: String):
	"""Configure un slot d'équipement."""
	if slot_node:
		# Ajouter le script ItemSlot au slot
		slot_node.set_script(load("res://game/ui/ItemSlot.gd"))
		if slot_node.has_method("setup_slot"):
			slot_node.setup_slot("equipment", slot_type)
			slot_node.slot_clicked.connect(_on_equipment_slot_clicked)
			slot_node.item_dragged.connect(_on_item_drag_started)
			slot_node.item_dropped.connect(_on_item_dropped)
			slot_node.item_hovered.connect(_on_item_hovered)
			slot_node.item_unhovered.connect(_on_item_unhovered)

## CHARGEMENT DES DONNÉES
## =======================
func _load_character_info():
	"""Charge l'ID du personnage depuis AuthManager."""
	# Debug: voir ce qu'il y a dans le JWT
	var payload = AuthManager.get_jwt_payload()
	print("[CharacterPanel] Payload JWT: ", payload)
	
	var char_id = AuthManager.get_character_id()
	if char_id > 0:
		character_id = str(char_id)
		print("[CharacterPanel] ID personnage trouvé: ", character_id)
	else:
		print("[CharacterPanel] ❌ character_id non trouvé, essai alternatives...")
		
		# Essai alternatif via payload JWT
		if payload.has("user_id"):
			character_id = str(payload.user_id)
			print("[CharacterPanel] ✅ Utilisation user_id comme character_id: ", character_id)
		elif payload.has("sub"):
			character_id = str(payload.sub) 
			print("[CharacterPanel] ✅ Utilisation sub comme character_id: ", character_id)
		else:
			print("[CharacterPanel] ❌ Aucun ID utilisable trouvé")
			character_id = ""

## OUVERTURE/FERMETURE
## ====================
func open_character_panel():
	"""Ouvre le panel personnage et charge les données."""
	if character_id.is_empty():
		print("[CharacterPanel] ❌ Impossible d'ouvrir: ID personnage manquant")
		return
	
	print("[CharacterPanel] 📊 Ouverture du panel personnage")
	is_visible = true
	visible = true
	
	# Afficher loading
	if loading_label:
		loading_label.visible = true
		loading_label.text = "Chargement..."
	
	# Charger les données depuis le serveur
	_fetch_character_data()
	_fetch_inventory_data()

func close_character_panel():
	"""Ferme le panel personnage."""
	print("[CharacterPanel] 📊 Fermeture du panel personnage")
	is_visible = false
	visible = false

func toggle_character_panel():
	"""Bascule l'état d'ouverture/fermeture."""
	if is_visible:
		close_character_panel()
	else:
		open_character_panel()

## COMMUNICATION SERVEUR - PERSONNAGE
## ====================================
func _fetch_character_data():
	"""Récupère les données du personnage depuis le serveur."""
	var url = "%s/character/%s" % [ServerConfig.API_URL, character_id]
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + AuthManager.get_access_token()
	]
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_character_data_received.bind(http_request))
	
	var error = http_request.request(url, headers, HTTPClient.METHOD_GET)
	if error != OK:
		print("[CharacterPanel] ❌ Erreur lors de la requête personnage: ", error)
		_show_error("Erreur de connexion au serveur")
		http_request.queue_free()

func _on_character_data_received(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, request_node: HTTPRequest):
	"""Traite les données du personnage reçues."""
	if response_code == 200:
		var response_data = JSON.parse_string(body.get_string_from_utf8())
		if response_data and response_data.has("success") and response_data.success:
			character_data = response_data.get("character", {})
			_update_character_display()
			print("[CharacterPanel] ✅ Données personnage chargées avec succès")
		else:
			_show_error("Données personnage invalides")
	else:
		print("[CharacterPanel] ❌ Erreur serveur: ", response_code)
		_show_error("Erreur lors du chargement")
	
	request_node.queue_free()

## COMMUNICATION SERVEUR - INVENTAIRE
## ====================================
func _fetch_inventory_data():
	"""Récupère les données d'inventaire depuis le serveur."""
	var url = "%s/inventory/%s" % [ServerConfig.API_URL, character_id]
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + AuthManager.get_access_token()
	]
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_inventory_data_received.bind(http_request))
	
	var error = http_request.request(url, headers, HTTPClient.METHOD_GET)
	if error != OK:
		print("[CharacterPanel] ❌ Erreur lors de la requête inventaire: ", error)
		_show_error("Erreur de connexion au serveur")
		http_request.queue_free()

func _on_inventory_data_received(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, request_node: HTTPRequest):
	"""Traite les données d'inventaire reçues."""
	if loading_label:
		loading_label.visible = false
	
	if response_code == 200:
		var response_data = JSON.parse_string(body.get_string_from_utf8())
		if response_data and response_data.has("success") and response_data.success:
			inventory_data = response_data.get("inventory", {})
			_update_inventory_display()
			print("[CharacterPanel] ✅ Inventaire chargé avec succès")
		else:
			_show_error("Données d'inventaire invalides")
	else:
		print("[CharacterPanel] ❌ Erreur serveur: ", response_code)
		_show_error("Erreur lors du chargement")
	
	request_node.queue_free()

## MISE À JOUR DE L'AFFICHAGE
## ===========================
func _update_character_display():
	"""Met à jour l'affichage des données du personnage."""
	if not character_data:
		return
	
	# Nom et niveau
	if character_name_label:
		character_name_label.text = character_data.get("name", "Personnage")
	
	if level_label:
		level_label.text = "Niveau " + str(character_data.get("level", 1))
	
	# Stats principales
	var stats = character_data.get("stats", {})
	for stat_name in stats_labels:
		var label = stats_labels[stat_name]
		if label and stats.has(stat_name):
			match stat_name:
				"hp":
					var current_hp = stats.get("current_hp", 0)
					var max_hp = stats.get("max_hp", 0)
					label.text = "%d/%d" % [current_hp, max_hp]
				"ap":
					var current_ap = stats.get("current_ap", 0)
					var max_ap = stats.get("max_ap", 6)
					label.text = "%d/%d" % [current_ap, max_ap]
				"mp":
					var current_mp = stats.get("current_mp", 0)
					var max_mp = stats.get("max_mp", 3)
					label.text = "%d/%d" % [current_mp, max_mp]
				_:
					label.text = str(stats.get(stat_name, 0))

func _update_inventory_display():
	"""Met à jour l'affichage de l'inventaire."""
	if not inventory_data:
		return
	
	# Vider les slots actuels
	_clear_all_slots()
	
	# Afficher les objets de l'inventaire
	var items = inventory_data.get("items", [])
	for item in items:
		_display_item_in_inventory(item)
	
	# Afficher les équipements
	var equipment = inventory_data.get("equipment", {})
	for slot_name in equipment:
		var equipped_item = equipment[slot_name]
		_display_item_in_equipment(equipped_item, slot_name)

func _display_item_in_inventory(item: Dictionary):
	"""Affiche un objet dans la grille d'inventaire."""
	# Trouver le premier slot libre
	for i in range(INVENTORY_SLOTS):
		var slot = inventory_grid.get_child(i)
		if slot and slot.has_method("is_slot_empty") and slot.is_slot_empty():
			if slot.has_method("set_item"):
				slot.set_item(item)
			break

func _display_item_in_equipment(item: Dictionary, slot_name: String):
	"""Affiche un objet équipé."""
	if equipment_slots.has(slot_name):
		var slot = equipment_slots[slot_name]
		if slot and slot.has_method("set_item"):
			slot.set_item(item)

func _clear_all_slots():
	"""Vide tous les slots de l'inventaire."""
	# Vider inventaire
	if inventory_grid:
		for i in range(inventory_grid.get_child_count()):
			var slot = inventory_grid.get_child(i)
			if slot and slot.has_method("clear_item"):
				slot.clear_item()
	
	# Vider équipements
	for slot_name in equipment_slots:
		var slot = equipment_slots[slot_name]
		if slot and slot.has_method("clear_item"):
			slot.clear_item()

## GESTION DES ÉQUIPEMENTS
## ========================
func _equip_item(item_id: String, slot: String):
	"""Équipe un objet."""
	var url = "%s/inventory/%s/equip" % [ServerConfig.API_URL, character_id]
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + AuthManager.get_access_token()
	]
	
	var body = {
		"item_id": item_id,
		"slot": slot
	}
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_equip_response.bind(http_request))
	
	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if error != OK:
		print("[CharacterPanel] ❌ Erreur lors de l'équipement: ", error)
		http_request.queue_free()

func _unequip_item(slot: String):
	"""Déséquipe un objet."""
	var url = "%s/inventory/%s/unequip" % [ServerConfig.API_URL, character_id]
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + AuthManager.get_access_token()
	]
	
	var body = {
		"slot": slot
	}
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_unequip_response.bind(http_request))
	
	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if error != OK:
		print("[CharacterPanel] ❌ Erreur lors du déséquipement: ", error)
		http_request.queue_free()

func _on_equip_response(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, request_node: HTTPRequest):
	"""Traite la réponse d'équipement."""
	if response_code == 200:
		var response_data = JSON.parse_string(body.get_string_from_utf8())
		if response_data and response_data.has("success") and response_data.success:
			print("[CharacterPanel] ✅ Objet équipé avec succès")
			# Rafraîchir les données
			_fetch_inventory_data()
			_fetch_character_data()
		else:
			_show_error("Impossible d'équiper cet objet")
	else:
		print("[CharacterPanel] ❌ Erreur équipement: ", response_code)
		_show_error("Erreur lors de l'équipement")
	
	request_node.queue_free()

func _on_unequip_response(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, request_node: HTTPRequest):
	"""Traite la réponse de déséquipement."""
	if response_code == 200:
		var response_data = JSON.parse_string(body.get_string_from_utf8())
		if response_data and response_data.has("success") and response_data.success:
			print("[CharacterPanel] ✅ Objet déséquipé avec succès")
			# Rafraîchir les données
			_fetch_inventory_data()
			_fetch_character_data()
		else:
			_show_error("Impossible de déséquiper cet objet")
	else:
		print("[CharacterPanel] ❌ Erreur déséquipement: ", response_code)
		_show_error("Erreur lors du déséquipement")
	
	request_node.queue_free()

## GESTION DES ÉVÉNEMENTS
## =======================
func _on_inventory_slot_clicked(slot_index: int, item_data: Dictionary):
	"""Gère le clic sur un slot d'inventaire."""
	print("[CharacterPanel] Clic sur slot inventaire: ", slot_index, " - ", item_data)
	
	if item_data.is_empty():
		return
	
	# Double-clic pour équiper automatiquement
	if Input.is_action_just_pressed("ui_accept"):
		_auto_equip_item(item_data)

func _on_equipment_slot_clicked(slot_name: String, item_data: Dictionary):
	"""Gère le clic sur un slot d'équipement."""
	print("[CharacterPanel] Clic sur slot équipement: ", slot_name, " - ", item_data)
	
	# Double-clic pour déséquiper
	if Input.is_action_just_pressed("ui_accept"):
		_unequip_item(slot_name)

func _on_item_drag_started(item_data: Dictionary, source_slot):
	"""Démarre le glisser-déposer d'un objet."""
	dragging_item = item_data
	drag_source_slot = source_slot
	print("[CharacterPanel] Début drag&drop: ", item_data.get("name", "Unknown"))

func _on_item_dropped(target_slot):
	"""Termine le glisser-déposer d'un objet."""
	if dragging_item.is_empty():
		return
	
	print("[CharacterPanel] Fin drag&drop vers: ", target_slot)
	
	# Logique selon le type de slot cible
	if target_slot.has_method("get_slot_type"):
		var slot_type = target_slot.get_slot_type()
		var slot_id = target_slot.get_slot_id()
		
		match slot_type:
			"equipment":
				# Équiper l'objet
				_equip_item(dragging_item.get("id", ""), slot_id)
			"inventory":
				# Déplacer dans l'inventaire (réorganisation)
				_move_item_in_inventory(dragging_item, slot_id)
	
	# Nettoyer
	dragging_item.clear()
	drag_source_slot = null

func _on_item_hovered(item_data: Dictionary, slot_position: Vector2):
	"""Affiche le tooltip d'un objet."""
	if item_tooltip:
		var tooltip_label = item_tooltip.get_node_or_null("TooltipLabel")
		if tooltip_label:
			tooltip_label.text = _generate_tooltip_text(item_data)
		item_tooltip.visible = true

func _on_item_unhovered():
	"""Masque le tooltip."""
	if item_tooltip:
		item_tooltip.visible = false

func _on_close_button_pressed():
	"""Ferme le panel personnage."""
	close_character_panel()

## FONCTIONS UTILITAIRES
## ======================
func _auto_equip_item(item_data: Dictionary):
	"""Équipe automatiquement un objet dans le bon slot."""
	var item_template = item_data.get("item_template", {})
	var item_type = item_template.get("item_type", "")
	
	# Déterminer le slot approprié selon le type d'objet
	var target_slot = _get_appropriate_slot(item_type)
	if not target_slot.is_empty():
		_equip_item(item_data.get("id", ""), target_slot)

func _get_appropriate_slot(item_type: String) -> String:
	"""Retourne le slot approprié pour un type d'objet."""
	match item_type:
		"WEAPON":
			return "WEAPON"
		"HELMET":
			return "HEAD"
		"ARMOR":
			return "CHEST"
		"BOOTS":
			return "BOOTS"
		"BELT":
			return "BELT"
		"AMULET":
			return "AMULET"
		"RING":
			return "RING"
		"PET":
			return "PET"
		"MOUNT":
			return "MOUNT"
		_:
			return ""

func _move_item_in_inventory(item_data: Dictionary, target_index: int):
	"""Déplace un objet dans l'inventaire (réorganisation)."""
	print("[CharacterPanel] Réorganisation inventaire: ", item_data.get("name", ""), " -> slot ", target_index)

func _show_error(message: String):
	"""Affiche un message d'erreur."""
	print("[CharacterPanel] ❌ ", message)
	if loading_label:
		loading_label.visible = true
		loading_label.text = "Erreur: " + message

func _generate_tooltip_text(item_data: Dictionary) -> String:
	"""Génère le texte du tooltip."""
	var template = item_data.get("item_template", {})
	var text = ""
	
	# Nom de l'objet avec couleur de rarité
	var item_name = template.get("name", "Objet inconnu")
	var rarity = template.get("rarity", "COMMON")
	var color = _get_rarity_color_name(rarity)
	text += "[b][color=%s]%s[/color][/b]\n" % [color, item_name]
	
	# Type et niveau requis
	var level_req = template.get("level_requirement", 0)
	if level_req > 0:
		text += "[color=gray]Niveau requis: %d[/color]\n" % level_req
	
	# Description
	var description = template.get("description", "")
	if not description.is_empty():
		text += "[i]%s[/i]\n\n" % description
	
	# Effets de l'objet
	var effects = template.get("effects", {})
	if not effects.is_empty():
		text += "[color=yellow]Effets:[/color]\n"
		for effect_name in effects:
			var effect_value = effects[effect_name]
			var effect_color = _get_effect_color(effect_name)
			text += "[color=%s]+%s %s[/color]\n" % [effect_color, str(effect_value), effect_name]
	
	return text

func _get_rarity_color_name(rarity: String) -> String:
	"""Retourne le nom de couleur pour une rarité."""
	match rarity:
		"COMMON":
			return "white"
		"UNCOMMON":
			return "green"
		"RARE":
			return "blue"
		"MYTHIC":
			return "purple"
		"LEGENDARY":
			return "orange"
		_:
			return "white"

func _get_effect_color(effect_name: String) -> String:
	"""Retourne la couleur d'un effet."""
	match effect_name.to_lower():
		"vitality", "vie", "hp":
			return "red"
		"strength", "force":
			return "orange"
		"intelligence":
			return "purple"
		"agility", "agilité":
			return "yellow"
		"chance":
			return "green"
		"wisdom", "sagesse":
			return "blue"
		_:
			return "white"

## MÉTHODES PUBLIQUES
## ===================
func refresh_character_panel():
	"""Rafraîchit le panel depuis le serveur."""
	if is_visible:
		_fetch_character_data()
		_fetch_inventory_data()

func update_character_data(new_character_data: Dictionary):
	"""Met à jour les données du personnage."""
	if new_character_data.has("stats"):
		character_data["stats"] = new_character_data["stats"]
		_update_character_display()

## RACCOURCIS CLAVIER
## ===================
func _input(event):
	"""Gère les raccourcis clavier pour le panel."""
	if not is_visible:
		return
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				close_character_panel()
			KEY_R:
				refresh_character_panel()