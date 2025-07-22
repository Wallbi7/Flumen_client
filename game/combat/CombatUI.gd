extends Control
class_name CombatUI

## INTERFACE UTILISATEUR POUR LE COMBAT TACTIQUE DOFUS-LIKE
## ========================================================
## Interface adaptée pour le nouveau système de combat synchronisé avec serveur.
## Affiche PA/PM, initiative, timer 30s, ordre des tours et actions selon le modèle Dofus.

# ================================
# RÉFÉRENCES AUX NŒUDS UI
# ================================

## Conteneur principal de l'interface
@onready var main_container: Control = $MainContainer

## Section des ressources (PA/PM)
@onready var resources_panel: HBoxContainer = $MainContainer/ResourcesPanel
@onready var ap_label: Label = $MainContainer/ResourcesPanel/APContainer/APLabel
@onready var ap_bar: ProgressBar = $MainContainer/ResourcesPanel/APContainer/APBar
@onready var mp_label: Label = $MainContainer/ResourcesPanel/MPContainer/MPLabel
@onready var mp_bar: ProgressBar = $MainContainer/ResourcesPanel/MPContainer/MPBar

## Section de l'ordre des tours avec initiative
@onready var turn_order_panel: VBoxContainer = $MainContainer/TurnOrderPanel
@onready var turn_order_title: Label = $MainContainer/TurnOrderPanel/TitleLabel
@onready var turn_order_list: VBoxContainer = $MainContainer/TurnOrderPanel/ScrollContainer/TurnOrderList

## Section des actions (adaptée pour sorts avec coûts PA)
@onready var actions_panel: HBoxContainer = $MainContainer/ActionsPanel
@onready var attack_button: Button = $MainContainer/ActionsPanel/AttackButton
@onready var spell_button: Button = $MainContainer/ActionsPanel/SpellButton
@onready var item_button: Button = $MainContainer/ActionsPanel/ItemButton
@onready var pass_button: Button = $MainContainer/ActionsPanel/PassButton
@onready var end_turn_button: Button = $MainContainer/ActionsPanel/EndTurnButton
@onready var ready_button: Button = $MainContainer/ActionsPanel/ReadyButton

## Section du timer et informations (Timer 30s Dofus-like)
@onready var info_panel: HBoxContainer = $MainContainer/InfoPanel
@onready var timer_label: Label = $MainContainer/InfoPanel/TimerLabel
@onready var phase_label: Label = $MainContainer/InfoPanel/PhaseLabel

## Section des effets temporaires
@onready var effects_panel: VBoxContainer = $MainContainer/EffectsPanel
@onready var effects_title: Label = $MainContainer/EffectsPanel/EffectsTitle
@onready var effects_list: VBoxContainer = $MainContainer/EffectsPanel/EffectsList

## Section de la barre de sorts (style Dofus)
@onready var spell_bar: HBoxContainer = $MainContainer/SpellBar
@onready var spell_buttons: Array[Button] = []
@onready var weapon_button: Button = $MainContainer/SpellBar/WeaponButton

# ================================
# VARIABLES DE GESTION
# ================================

## État de combat synchronisé avec serveur
var current_combat_state: CombatState = null

## Combattant du joueur local
var local_player_combatant: CombatState.Combatant = null

## Timer pour mise à jour du countdown
var timer_update_timer: Timer = null

## Indique si on est en mode placement
var is_placement_mode: bool = false

## Couleurs pour les équipes et états (style Dofus authentique)
const ALLY_COLOR = Color(0.2, 0.6, 1.0, 1.0)      # Bleu Dofus 
const ENEMY_COLOR = Color(1.0, 0.3, 0.2, 1.0)     # Rouge Dofus
const CURRENT_FIGHTER_COLOR = Color(1.0, 0.9, 0.2, 1.0)  # Or Dofus (tour actuel)
const DEAD_FIGHTER_COLOR = Color(0.4, 0.4, 0.4, 1.0)     # Gris pour les morts
const DOFUS_GREEN = Color(0.2, 0.8, 0.3, 1.0)      # Vert Dofus (succès)
const DOFUS_ORANGE = Color(1.0, 0.6, 0.1, 1.0)     # Orange Dofus (attention)
const DOFUS_PURPLE = Color(0.7, 0.3, 0.9, 1.0)     # Violet Dofus (magie)"

# ================================
# SIGNAUX
# ================================

## Émis quand le joueur demande une action
signal action_requested(action_type: CombatState.ActionType, target_data: Dictionary)

# ================================
# INITIALISATION
# ================================

func _ready():
	print("[CombatUI] === INITIALISATION INTERFACE COMBAT DOFUS-LIKE ===")
	
	# Initialiser les références aux boutons de sorts
	_setup_spell_buttons()
	
	# Connecter les signaux des boutons
	_connect_action_buttons()
	
	# Créer le timer de mise à jour
	_setup_update_timer()
	
	# Masquer l'interface par défaut
	hide_combat_ui()

## Connecte les signaux des boutons d'actions
func _connect_action_buttons():
	if attack_button:
		attack_button.pressed.connect(_on_attack_button_pressed)
	if spell_button:
		spell_button.pressed.connect(_on_old_spell_button_pressed)
	if item_button:
		item_button.pressed.connect(_on_item_button_pressed)
	if pass_button:
		pass_button.pressed.connect(_on_pass_button_pressed)
	if end_turn_button:
		end_turn_button.pressed.connect(_on_end_turn_button_pressed)
	if ready_button:
		ready_button.pressed.connect(_on_ready_button_pressed)

## Configure le timer de mise à jour de l'interface
func _setup_update_timer():
	timer_update_timer = Timer.new()
	timer_update_timer.wait_time = 0.1  # Mise à jour toutes les 100ms
	timer_update_timer.timeout.connect(_on_timer_update)
	add_child(timer_update_timer)

## Initialise les boutons de sorts (style Dofus)
func _setup_spell_buttons():
	# Récupérer tous les boutons de sorts (Spell1 à Spell6)
	for i in range(1, 7):
		var spell_button = spell_bar.get_node_or_null("Spell%d" % i)
		if spell_button:
			spell_buttons.append(spell_button)
			# Connecter le signal avec l'index du sort
			spell_button.pressed.connect(_on_spell_button_pressed.bind(i))
	
	# Connecter le bouton d'arme
	if weapon_button:
		weapon_button.pressed.connect(_on_weapon_button_pressed)
	
	print("[CombatUI] ✅ %d boutons de sorts initialisés" % spell_buttons.size())

# ================================
# MÉTHODES PRINCIPALES DE SYNCHRONISATION
# ================================

## Met à jour l'interface avec un nouvel état de combat du serveur
func update_from_combat_state(combat_state: CombatState):
	current_combat_state = combat_state
	local_player_combatant = _find_local_player_combatant()
	
	print("[CombatUI] 🔄 Mise à jour interface depuis état serveur")
	
	# Mettre à jour tous les composants
	update_resources_display()
	update_turn_order_display()
	update_action_buttons()
	update_phase_display()
	update_effects_display()
	update_spell_bar_display()
	
	# Démarrer le timer dès que le combat commence (placement ou combat)
	if combat_state.status == CombatState.CombatStatus.IN_PROGRESS or combat_state.status == CombatState.CombatStatus.PLACEMENT:
		if not timer_update_timer.timeout.is_connected(_on_timer_update):
			timer_update_timer.timeout.connect(_on_timer_update)
		timer_update_timer.start()
		print("[CombatUI] ⏰ Timer démarré pour phase: ", combat_state.status)
	else:
		timer_update_timer.stop()
		print("[CombatUI] ⏸️ Timer arrêté pour phase: ", combat_state.status)

## Trouve le combattant correspondant au joueur local
func _find_local_player_combatant() -> CombatState.Combatant:
	if not current_combat_state:
		return null
	
	# Ici, on devrait obtenir l'ID du personnage du joueur actuel
	# Pour l'instant, on prend le premier joueur de l'équipe alliée
	for combatant in current_combat_state.combatants:
		if combatant.is_player and combatant.team_id == 0:  # Équipe alliée
			return combatant
	return null

# ================================
# AFFICHAGE DES RESSOURCES (PA/PM)
# ================================

## Met à jour l'affichage des PA/PM (style Dofus amélioré)
func update_resources_display():
	if not local_player_combatant:
		_hide_resources()
		return
	
	# Affichage des Points d'Action (PA) - Style Dofus avec couleurs vibrantes
	if ap_label and ap_bar:
		var current_ap = local_player_combatant.remaining_action_points
		var max_ap = local_player_combatant.base_action_points
		ap_label.text = "PA: %d/%d" % [current_ap, max_ap]
		ap_bar.max_value = max_ap
		ap_bar.value = current_ap
		
		# Couleurs style Dofus authentiques
		if current_ap == 0:
			ap_bar.modulate = ENEMY_COLOR  # Rouge Dofus
			ap_label.modulate = ENEMY_COLOR
		elif current_ap <= max_ap * 0.3:
			ap_bar.modulate = DOFUS_ORANGE  # Orange Dofus
			ap_label.modulate = DOFUS_ORANGE
		else:
			ap_bar.modulate = DOFUS_GREEN  # Vert Dofus
			ap_label.modulate = DOFUS_GREEN
	
	# Affichage des Points de Mouvement (PM) - Style Dofus
	if mp_label and mp_bar:
		var current_mp = local_player_combatant.remaining_movement_points
		var max_mp = local_player_combatant.base_movement_points
		mp_label.text = "PM: %d/%d" % [current_mp, max_mp]
		mp_bar.max_value = max_mp
		mp_bar.value = current_mp
		
		# Couleurs style Dofus pour les PM
		if current_mp == 0:
			mp_bar.modulate = ENEMY_COLOR  # Rouge Dofus
			mp_label.modulate = ENEMY_COLOR
		elif current_mp <= 1:
			mp_bar.modulate = DOFUS_ORANGE  # Orange Dofus
			mp_label.modulate = DOFUS_ORANGE
		else:
			mp_bar.modulate = ALLY_COLOR  # Bleu Dofus
			mp_label.modulate = ALLY_COLOR

## Masque l'affichage des ressources
func _hide_resources():
	if ap_label:
		ap_label.text = "PA: --/--"
	if ap_bar:
		ap_bar.value = 0
	if mp_label:
		mp_label.text = "PM: --/--"
	if mp_bar:
		mp_bar.value = 0

# ================================
# AFFICHAGE ORDRE DES TOURS AVEC INITIATIVE
# ================================

## Met à jour l'ordre des tours avec initiative (style Dofus amélioré)
func update_turn_order_display():
	if not current_combat_state or not turn_order_list:
		return
	
	# Nettoyer la liste existante
	for child in turn_order_list.get_children():
		child.queue_free()
	
	# Titre avec informations de tour actuelles (style Dofus)
	if turn_order_title:
		var current_turn = current_combat_state.current_turn_index + 1
		var total_turns = current_combat_state.turn_order.size()
		var current_combatant = current_combat_state.get_current_combatant()
		var combatant_name = current_combatant.name if current_combatant else "Inconnu"
		turn_order_title.text = "Tour %d/%d - %s" % [current_turn, total_turns, combatant_name]
		
		# Couleur selon l'équipe du combattant actuel
		if current_combatant:
			var color = ALLY_COLOR if current_combatant.team_id == 0 else ENEMY_COLOR
			turn_order_title.modulate = color
	
	# Créer l'affichage pour chaque combattant dans l'ordre
	for i in range(current_combat_state.turn_order.size()):
		var character_id = current_combat_state.turn_order[i]
		var combatant = current_combat_state.get_combatant_by_id(character_id)
		
		if combatant:
			var entry = _create_turn_order_entry(combatant, i == current_combat_state.current_turn_index, i)
			turn_order_list.add_child(entry)

## Crée une entrée dans l'ordre des tours (style Dofus amélioré)
func _create_turn_order_entry(combatant: CombatState.Combatant, is_current: bool, position_index: int) -> HBoxContainer:
	var entry = HBoxContainer.new()
	entry.custom_minimum_size.y = 35
	
	# Indicateur de position dans l'ordre (numéro de tour)
	var position_label = Label.new()
	position_label.text = "%d." % (position_index + 1)
	position_label.custom_minimum_size.x = 25
	position_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	entry.add_child(position_label)
	
	# Nom du combattant avec icône d'équipe
	var name_label = Label.new()
	var team_icon = "👤" if combatant.team_id == 0 else "👹"  # Allié vs Ennemi
	name_label.text = "%s %s" % [team_icon, combatant.name]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry.add_child(name_label)
	
	# Initiative avec style Dofus
	var initiative_label = Label.new()
	initiative_label.text = "(%d)" % combatant.initiative
	initiative_label.custom_minimum_size.x = 45
	initiative_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	entry.add_child(initiative_label)
	
	# PA/PM restants (toujours affichés mais plus visibles pour le tour actuel)
	var stats_label = Label.new()
	stats_label.text = "%d/%d" % [combatant.remaining_action_points, combatant.remaining_movement_points]
	stats_label.custom_minimum_size.x = 50
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	entry.add_child(stats_label)
	
	# Couleurs et styles selon l'état
	var base_color = ALLY_COLOR if combatant.team_id == 0 else ENEMY_COLOR
	var final_color = base_color
	
	if combatant.is_dead:
		final_color = DEAD_FIGHTER_COLOR
		name_label.text += " ☠️"  # Crâne pour les morts
	elif is_current:
		final_color = CURRENT_FIGHTER_COLOR
		# Effet de surbrillance pour le combattant actuel
		entry.modulate = Color(1.2, 1.2, 1.0, 1.0)
		# Bordure dorée simulée avec un fond
		var background = ColorRect.new()
		background.color = Color(1.0, 0.8, 0.0, 0.3)  # Doré transparent
		entry.add_child(background)
		entry.move_child(background, 0)  # Mettre en arrière-plan
	
	# Appliquer les couleurs
	position_label.modulate = final_color
	name_label.modulate = final_color
	initiative_label.modulate = final_color
	stats_label.modulate = final_color
	
	# Tooltips informatifs
	var tooltip_text = "Combattant: %s\nÉquipe: %s\nInitiative: %d\nPA: %d/%d | PM: %d/%d" % [
		combatant.name,
		"Alliés" if combatant.team_id == 0 else "Ennemis",
		combatant.initiative,
		combatant.remaining_action_points, combatant.base_action_points,
		combatant.remaining_movement_points, combatant.base_movement_points
	]
	entry.tooltip_text = tooltip_text
	
	return entry

# ================================
# AFFICHAGE ET CONTRÔLES PRINCIPAUX
# ================================

## Affiche l'interface de combat
func show_combat_ui():
	visible = true
	print("[CombatUI] 👁️ Interface de combat affichée")

## Masque l'interface de combat
func hide_combat_ui():
	visible = false
	print("[CombatUI] 🙈 Interface de combat masquée")

## Met à jour l'affichage de la phase (style Dofus)
func update_phase_display():
	if not current_combat_state or not phase_label:
		return
	
	match current_combat_state.status:
		CombatState.CombatStatus.PLACEMENT:
			phase_label.text = "⚡ Phase: Placement"
			phase_label.modulate = ALLY_COLOR
		CombatState.CombatStatus.IN_PROGRESS:
			phase_label.text = "⚔️ Phase: Combat"
			phase_label.modulate = ENEMY_COLOR
		CombatState.CombatStatus.FINISHED:
			phase_label.text = "🏆 Phase: Terminé"
			phase_label.modulate = DOFUS_GREEN
		CombatState.CombatStatus.STARTING:
			phase_label.text = "🎯 Phase: Démarrage"
			phase_label.modulate = DOFUS_ORANGE

## Met à jour l'affichage des effets temporaires
func update_effects_display():
	if not effects_list:
		return
	
	# Nettoyer la liste existante
	for child in effects_list.get_children():
		child.queue_free()
	
	# Ajouter les effets du combattant local
	if local_player_combatant and local_player_combatant.active_effects.size() > 0:
		for effect in local_player_combatant.active_effects:
			var effect_entry = _create_effect_entry(effect)
			effects_list.add_child(effect_entry)

## Crée une entrée pour un effet temporaire
func _create_effect_entry(effect: CombatState.TemporaryEffect) -> HBoxContainer:
	var entry = HBoxContainer.new()
	entry.custom_minimum_size.y = 25
	
	var name_label = Label.new()
	name_label.text = effect.description if effect.description else "Effet"
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry.add_child(name_label)
	
	var duration_label = Label.new()
	duration_label.text = "(%d tours)" % effect.duration
	duration_label.custom_minimum_size.x = 70
	entry.add_child(duration_label)
	
	# Couleur selon le type d'effet
	var color = Color.WHITE
	match effect.type:
		CombatState.EffectType.POISON:
			color = Color.PURPLE
		CombatState.EffectType.BOOST_PA, CombatState.EffectType.BOOST_PM, CombatState.EffectType.BOOST_DAMAGE:
			color = Color.GREEN
		CombatState.EffectType.REDUCE_PA, CombatState.EffectType.REDUCE_PM:
			color = Color.RED
	
	name_label.modulate = color
	duration_label.modulate = color
	
	return entry

## Met à jour l'état des boutons d'actions selon les capacités actuelles
func update_action_buttons():
	if not current_combat_state or not local_player_combatant:
		_disable_all_action_buttons()
		return
	
	var combatant = local_player_combatant
	var current_character_id = current_combat_state.get_current_combatant()
	var is_player_turn = current_character_id and current_character_id.character_id == combatant.character_id
	
	# Mettre à jour chaque bouton selon les capacités du combattant
	if attack_button:
		attack_button.disabled = not is_player_turn or not combatant.can_cast_spell(3)  # Attaque coûte 3 PA
		attack_button.text = "Attaque (3 PA)"
	
	if spell_button:
		spell_button.disabled = not is_player_turn or not combatant.can_cast_spell(2)  # Sort coûte 2 PA minimum
		spell_button.text = "Sort (2+ PA)"
	
	if item_button:
		item_button.disabled = not is_player_turn or not combatant.can_cast_spell(1)  # Objet coûte 1 PA
		item_button.text = "Objet (1 PA)"
	
	if pass_button:
		pass_button.disabled = not is_player_turn
		pass_button.text = "Passer (0 PA)"
	
	if end_turn_button:
		end_turn_button.disabled = not is_player_turn
		end_turn_button.text = "Fin de tour"
	
	if ready_button:
		# Le bouton Prêt n'est visible qu'en phase de placement
		var is_placement_phase = is_placement_mode or (current_combat_state and current_combat_state.status == CombatState.CombatStatus.PLACEMENT)
		ready_button.visible = is_placement_phase
		ready_button.disabled = not is_placement_phase

## Désactive tous les boutons d'actions
func _disable_all_action_buttons():
	if attack_button:
		attack_button.disabled = true
	if spell_button:
		spell_button.disabled = true
	if item_button:
		item_button.disabled = true
	if pass_button:
		pass_button.disabled = true
	if end_turn_button:
		end_turn_button.disabled = true
	if ready_button:
		ready_button.disabled = true

## Met à jour l'affichage du timer (style Dofus avec urgence)
func update_timer_display(remaining_time: float):
	if not timer_label:
		return
	
	var minutes = int(remaining_time / 60)  # Division entière explicite
	var seconds = int(remaining_time) % 60
	
	# Format avec icône selon l'urgence
	var time_icon = "⏰"
	if remaining_time <= 5:
		time_icon = "🚨"  # Urgence critique
	elif remaining_time <= 10:
		time_icon = "⚠️"  # Attention
	
	timer_label.text = "%s %02d:%02d" % [time_icon, minutes, seconds]
	
	# Couleurs style Dofus selon le temps restant
	if remaining_time > 15:
		timer_label.modulate = DOFUS_GREEN
	elif remaining_time > 10:
		timer_label.modulate = DOFUS_ORANGE
	elif remaining_time > 5:
		timer_label.modulate = ENEMY_COLOR
	else:
		timer_label.modulate = ENEMY_COLOR
		# Effet de clignotement en cas d'urgence
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(timer_label, "modulate:a", 0.3, 0.5)
		tween.tween_property(timer_label, "modulate:a", 1.0, 0.5)

# ================================
# TIMER ET MISE À JOUR CONTINUE
# ================================

## Gestionnaire du timer de mise à jour
func _on_timer_update():
	if current_combat_state:
		# Utiliser le temps du serveur si disponible, sinon utiliser un timer simple
		var remaining_time = current_combat_state.get_remaining_turn_time()
		if remaining_time <= 0:
			# Fallback: timer simple 30 secondes par défaut
			remaining_time = _get_simple_timer_fallback()
		update_timer_display(remaining_time)

## Système de timer de fallback simple quand le serveur ne répond pas
var _simple_timer_start_time: float = 0
var _simple_timer_duration: float = 30.0  # 30 secondes par défaut

func _get_simple_timer_fallback() -> float:
	"""Retourne un timer simple quand le serveur ne fournit pas de temps"""
	# Initialiser le timer si pas déjà fait
	if _simple_timer_start_time == 0:
		_simple_timer_start_time = Time.get_unix_time_from_system()
		print("[CombatUI] ⏰ Démarrage timer simple 30s")
	
	var elapsed_time = Time.get_unix_time_from_system() - _simple_timer_start_time
	var remaining = _simple_timer_duration - elapsed_time
	
	# Reset quand le temps est écoulé
	if remaining <= 0:
		_simple_timer_start_time = Time.get_unix_time_from_system()
		remaining = _simple_timer_duration
		print("[CombatUI] 🔄 Reset timer simple")
	
	return remaining

# ================================
# GESTIONNAIRES D'ÉVÉNEMENTS
# ================================
# CALLBACKS OBSOLÈTES - SUPPRIMÉS
# ================================
# Les callbacks CombatTurnManager ont été supprimés car remplacés par
# le système synchronisé CombatState qui met à jour automatiquement
# l'interface via update_from_combat_state().

# ================================
# GESTIONNAIRES DE BOUTONS
# ================================

## Gestionnaire du bouton d'attaque
func _on_attack_button_pressed():
	print("[CombatUI] 🗡️ Bouton Attaque pressé")
	action_requested.emit(CombatState.ActionType.CAST_SPELL, {"spell_id": "basic_attack"})

## Gestionnaire du bouton de sort (ancien)
func _on_old_spell_button_pressed():
	print("[CombatUI] ✨ Bouton Sort pressé")
	action_requested.emit(CombatState.ActionType.CAST_SPELL, {"spell_id": "player_spell"})

## Gestionnaire du bouton d'objet
func _on_item_button_pressed():
	print("[CombatUI] 🎒 Bouton Objet pressé")
	action_requested.emit(CombatState.ActionType.USE_ITEM, {"item_id": "healing_potion"})

## Gestionnaire du bouton passer
func _on_pass_button_pressed():
	print("[CombatUI] ⏭️ Bouton Passer pressé")
	action_requested.emit(CombatState.ActionType.PASS_TURN, {})

## Gestionnaire du bouton fin de tour
func _on_end_turn_button_pressed():
	print("[CombatUI] 🏁 Bouton Fin de tour pressé")
	action_requested.emit(CombatState.ActionType.PASS_TURN, {})

## Gestionnaire du bouton prêt (phase de placement)
func _on_ready_button_pressed():
	print("[CombatUI] ✅ Bouton Prêt pressé - Joueur prêt pour commencer le combat")
	
	# Méthodes multiples pour trouver CombatManager
	var combat_manager = _find_combat_manager()
	
	if combat_manager and combat_manager.has_method("confirm_placement"):
		print("[CombatUI] 🎯 CombatManager trouvé, confirmation du placement...")
		combat_manager.confirm_placement()
	else:
		print("[CombatUI] ⚠️ CombatManager non trouvé, émission du signal d'action")
		action_requested.emit(CombatState.ActionType.READY_FOR_COMBAT, {})

## Trouve le CombatManager par plusieurs méthodes
func _find_combat_manager() -> Node:
	"""Recherche exhaustive du CombatManager"""
	var combat_manager = null
	
	# Méthode 1: Nœud racine
	combat_manager = get_node_or_null("/root/CombatManager")
	if combat_manager:
		print("[CombatUI] 🔍 CombatManager trouvé dans /root/")
		return combat_manager
	
	# Méthode 2: Scène principale
	var main_scene = get_tree().current_scene
	if main_scene:
		combat_manager = main_scene.get_node_or_null("CombatManager")
		if combat_manager:
			print("[CombatUI] 🔍 CombatManager trouvé dans scène principale")
			return combat_manager
	
	# Méthode 3: Via GameManager
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has("combat_manager"):
		combat_manager = game_manager.combat_manager
		if combat_manager:
			print("[CombatUI] 🔍 CombatManager trouvé via GameManager")
			return combat_manager
	
	# Méthode 4: Recherche récursive dans la scène
	if main_scene:
		combat_manager = _find_node_recursive(main_scene, "CombatManager")
		if combat_manager:
			print("[CombatUI] 🔍 CombatManager trouvé par recherche récursive")
			return combat_manager
	
	print("[CombatUI] ❌ CombatManager introuvable par toutes les méthodes")
	return null

## Recherche récursive d'un nœud
func _find_node_recursive(node: Node, target_name: String) -> Node:
	"""Recherche un nœud par son nom de manière récursive"""
	if node.name == target_name:
		return node
	
	for child in node.get_children():
		var result = _find_node_recursive(child, target_name)
		if result:
			return result
	
	return null

# ================================
# UTILITAIRES PUBLICS
# ================================

## Force la mise à jour complète de l'interface
func refresh_all_displays():
	if not current_combat_state:
		return
	
	print("[CombatUI] 🔄 Actualisation complète de l'interface")
	
	update_phase_display()
	update_resources_display()
	update_turn_order_display()
	update_action_buttons()
	update_effects_display()

## Affiche un message temporaire à l'utilisateur
func show_temporary_message(message: String, _duration: float = 3.0):
	print("[CombatUI] 📢 Message: ", message)
	# TODO: Implémenter l'affichage de message temporaire avec durée variable

## Active/désactive le mode placement
func set_placement_mode(enabled: bool):
	"""Active ou désactive le mode placement"""
	is_placement_mode = enabled
	
	if enabled:
		print("[CombatUI] 🎯 Mode placement activé")
		# Masquer les actions de combat et afficher seulement le bouton Prêt
		if actions_panel:
			for child in actions_panel.get_children():
				if child != ready_button:
					child.visible = false
		
		# Mettre à jour l'affichage de phase
		if phase_label:
			phase_label.text = "Phase: Placement - Cliquez sur une case bleue"
			phase_label.modulate = Color.BLUE
	else:
		print("[CombatUI] ⚔️ Mode combat activé")
		# Réafficher tous les boutons d'action
		if actions_panel:
			for child in actions_panel.get_children():
				child.visible = true
		
		# Le bouton prêt sera caché automatiquement
		if ready_button:
			ready_button.visible = false
	
	# Mettre à jour les boutons
	update_action_buttons()

## Affiche les informations de débogage de l'interface
func debug_print_ui_state():
	print("[CombatUI] === ÉTAT DE L'INTERFACE ===")
	print("Visible: ", visible)
	print("Mode placement: ", is_placement_mode)
	print("Combat State connecté: ", current_combat_state != null)
	print("Combattant affiché: ", local_player_combatant.name if local_player_combatant else "Aucun")
	
	if local_player_combatant:
		print("Ressources affichées:")
		print("  - PA: ", local_player_combatant.remaining_action_points, "/", local_player_combatant.base_action_points)
		print("  - PM: ", local_player_combatant.remaining_movement_points, "/", local_player_combatant.base_movement_points)
	
	print("Boutons d'actions:")
	print("  - Attaque: ", "ACTIF" if (attack_button and not attack_button.disabled) else "INACTIF/N/A")
	print("  - Sort: ", "ACTIF" if (spell_button and not spell_button.disabled) else "INACTIF/N/A")
	print("  - Objet: ", "ACTIF" if (item_button and not item_button.disabled) else "INACTIF/N/A")
	print("  - Passer: ", "ACTIF" if (pass_button and not pass_button.disabled) else "INACTIF/N/A")
	print("  - Fin de tour: ", "ACTIF" if (end_turn_button and not end_turn_button.disabled) else "INACTIF/N/A")
	print("  - Prêt: ", "ACTIF" if (ready_button and ready_button.visible and not ready_button.disabled) else "INACTIF/N/A")
	
	print("======================================")

## Gestionnaire des boutons de sorts (style Dofus - raccourcis 1-6)
func _on_spell_button_pressed(spell_index: int):
	print("[CombatUI] ✨ Sort %d sélectionné" % spell_index)
	
	# Réinitialiser la sélection des autres boutons
	_reset_spell_selection()
	
	# Marquer ce sort comme sélectionné
	if spell_index >= 1 and spell_index <= spell_buttons.size():
		var button = spell_buttons[spell_index - 1]
		button.modulate = Color(1.2, 1.2, 0.8, 1.0)  # Surbrillance dorée
	
	# Émettre l'action avec l'ID du sort
	var spell_id = "spell_%d" % spell_index
	action_requested.emit(CombatState.ActionType.CAST_SPELL, {"spell_id": spell_id})

## Gestionnaire du bouton d'arme (attaque de base)
func _on_weapon_button_pressed():
	print("[CombatUI] ⚔️ Attaque d'arme sélectionnée")
	
	# Réinitialiser la sélection des sorts
	_reset_spell_selection()
	
	# Marquer l'arme comme sélectionnée
	weapon_button.modulate = Color(1.2, 1.2, 0.8, 1.0)  # Surbrillance dorée
	
	# Émettre l'action d'attaque de base
	action_requested.emit(CombatState.ActionType.CAST_SPELL, {"spell_id": "weapon_attack"})

## Réinitialise la sélection visuelle des sorts et arme
func _reset_spell_selection():
	# Réinitialiser tous les boutons de sorts
	for button in spell_buttons:
		button.modulate = Color.WHITE
	
	# Réinitialiser le bouton d'arme
	if weapon_button:
		weapon_button.modulate = Color.WHITE

## Met à jour la barre de sorts avec les sorts disponibles du personnage
func update_spell_bar_display():
	"""Met à jour l'affichage des sorts disponibles (style Dofus)"""
	if not local_player_combatant:
		_disable_spell_bar()
		return
	
	# TODO: Récupérer la liste des sorts depuis le serveur
	# Pour l'instant, utiliser des sorts par défaut
	var available_spells = ["Attaque", "Soin", "Boost", "Bouclier", "Sort5", "Sort6"]
	
	for i in range(spell_buttons.size()):
		var button = spell_buttons[i]
		if i < available_spells.size():
			button.text = available_spells[i]
			button.disabled = false
			button.tooltip_text = "Sort %s (Raccourci: %d)" % [available_spells[i], i + 1]
		else:
			button.text = str(i + 1)
			button.disabled = true
			button.tooltip_text = "Aucun sort assigné"
	
	# Mettre à jour le bouton d'arme
	if weapon_button:
		weapon_button.disabled = false
		weapon_button.tooltip_text = "Attaque d'arme"

## Désactive la barre de sorts
func _disable_spell_bar():
	for button in spell_buttons:
		button.disabled = true
		button.modulate = Color(0.5, 0.5, 0.5, 1.0)
	
	if weapon_button:
		weapon_button.disabled = true
		weapon_button.modulate = Color(0.5, 0.5, 0.5, 1.0) 
