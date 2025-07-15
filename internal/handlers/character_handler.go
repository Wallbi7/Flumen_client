package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"

	"github.com/flumen/flumen_server/internal/auth"
	"github.com/flumen/flumen_server/internal/database"
	"github.com/flumen/flumen_server/internal/models"
	"github.com/gofiber/fiber/v2"
)

// CharacterHandler gère les requêtes liées aux personnages
type CharacterHandler struct {
	characterRepo *database.CharacterRepository
	jwtService    *auth.JWTService
}

// NewCharacterHandler crée un nouveau handler pour les personnages
func NewCharacterHandler(characterRepo *database.CharacterRepository, jwtService *auth.JWTService) *CharacterHandler {
	return &CharacterHandler{
		characterRepo: characterRepo,
		jwtService:    jwtService,
	}
}

// GetCharacters récupère tous les personnages d'un utilisateur
func (h *CharacterHandler) GetCharacters(c *fiber.Ctx) error {
	// Extraire l'utilisateur du token JWT
	userID, err := h.getUserIDFromToken(c)
	if err != nil {
		return c.Status(http.StatusUnauthorized).JSON(fiber.Map{
			"success": false,
			"error":   "Token invalide",
		})
	}

	// Récupérer les personnages
	characters, err := h.characterRepo.GetCharactersByUser(userID)
	if err != nil {
		return c.Status(http.StatusInternalServerError).JSON(fiber.Map{
			"success": false,
			"error":   "Erreur lors de la récupération des personnages",
		})
	}

	return c.JSON(fiber.Map{
		"success":    true,
		"characters": characters,
		"classes":    models.GetAllClasses(), // Envoyer aussi les infos des classes
	})
}

// CreateCharacter crée un nouveau personnage
func (h *CharacterHandler) CreateCharacter(c *fiber.Ctx) error {
	// Extraire l'utilisateur du token JWT
	userID, err := h.getUserIDFromToken(c)
	if err != nil {
		return c.Status(http.StatusUnauthorized).JSON(fiber.Map{
			"success": false,
			"error":   "Token invalide",
		})
	}

	// Parser la requête
	var req models.CreateCharacterRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "Données invalides",
		})
	}

	// Valider les données
	if err := h.validateCreateCharacterRequest(&req); err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   err.Error(),
		})
	}

	// Créer le personnage
	character, err := h.characterRepo.CreateCharacter(userID, req)
	if err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"success":   true,
		"character": character,
	})
}

// SelectCharacter sélectionne un personnage pour jouer
func (h *CharacterHandler) SelectCharacter(c *fiber.Ctx) error {
	// Extraire l'utilisateur du token JWT
	userID, err := h.getUserIDFromToken(c)
	if err != nil {
		return c.Status(http.StatusUnauthorized).JSON(fiber.Map{
			"success": false,
			"error":   "Token invalide",
		})
	}

	// Récupérer l'ID du personnage
	characterIDStr := c.Params("id")
	characterID, err := strconv.Atoi(characterIDStr)
	if err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "ID de personnage invalide",
		})
	}

	// Récupérer le personnage
	character, err := h.characterRepo.GetCharacterByID(characterID)
	if err != nil {
		return c.Status(http.StatusNotFound).JSON(fiber.Map{
			"success": false,
			"error":   "Personnage non trouvé",
		})
	}

	// Vérifier que le personnage appartient à l'utilisateur
	if character.UserID != userID {
		return c.Status(http.StatusForbidden).JSON(fiber.Map{
			"success": false,
			"error":   "Personnage non autorisé",
		})
	}

	// Mettre à jour la dernière connexion
	err = h.characterRepo.UpdateCharacterLastLogin(characterID)
	if err != nil {
		// Log l'erreur mais ne pas faire échouer la requête
		fmt.Printf("Erreur lors de la mise à jour de la dernière connexion: %v\n", err)
	}

	return c.JSON(fiber.Map{
		"success":   true,
		"character": character,
	})
}

// DeleteCharacter supprime un personnage
func (h *CharacterHandler) DeleteCharacter(c *fiber.Ctx) error {
	// Extraire l'utilisateur du token JWT
	userID, err := h.getUserIDFromToken(c)
	if err != nil {
		return c.Status(http.StatusUnauthorized).JSON(fiber.Map{
			"success": false,
			"error":   "Token invalide",
		})
	}

	// Récupérer l'ID du personnage
	characterIDStr := c.Params("id")
	characterID, err := strconv.Atoi(characterIDStr)
	if err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "ID de personnage invalide",
		})
	}

	// Supprimer le personnage
	err = h.characterRepo.DeleteCharacter(characterID, userID)
	if err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": "Personnage supprimé avec succès",
	})
}

// GetClassInfo retourne les informations sur toutes les classes
func (h *CharacterHandler) GetClassInfo(c *fiber.Ctx) error {
	classes := models.GetAllClasses()
	return c.JSON(fiber.Map{
		"success": true,
		"classes": classes,
	})
}

// getUserIDFromToken extrait l'ID utilisateur du token JWT
func (h *CharacterHandler) getUserIDFromToken(c *fiber.Ctx) (int, error) {
	// Récupérer le token depuis l'en-tête Authorization
	authHeader := c.Get("Authorization")
	if authHeader == "" {
		return 0, fmt.Errorf("token manquant")
	}

	// Extraire le token (format: "Bearer <token>")
	token := authHeader
	if len(authHeader) > 7 && authHeader[:7] == "Bearer " {
		token = authHeader[7:]
	}

	// Valider le token
	claims, err := h.jwtService.ValidateToken(token)
	if err != nil {
		return 0, fmt.Errorf("token invalide: %w", err)
	}

	return claims.UserID, nil
}

// validateCreateCharacterRequest valide les données de création de personnage
func (h *CharacterHandler) validateCreateCharacterRequest(req *models.CreateCharacterRequest) error {
	// Vérifier le nom
	if len(req.Name) < 3 || len(req.Name) > 20 {
		return fmt.Errorf("le nom doit contenir entre 3 et 20 caractères")
	}

	// Vérifier la classe
	if req.Class != models.ClassWarrior && req.Class != models.ClassArcher {
		return fmt.Errorf("classe invalide")
	}

	return nil
}

// WebSocket Handler pour les personnages (à intégrer dans le hub existant)
type CharacterWebSocketMessage struct {
	Type string          `json:"type"`
	Data json.RawMessage `json:"data"`
}

// HandleCharacterWebSocket gère les messages WebSocket liés aux personnages
func (h *CharacterHandler) HandleCharacterWebSocket(message []byte, userID int) ([]byte, error) {
	var wsMsg CharacterWebSocketMessage
	if err := json.Unmarshal(message, &wsMsg); err != nil {
		return nil, fmt.Errorf("message invalide")
	}

	switch wsMsg.Type {
	case "get_characters":
		return h.handleGetCharactersWS(userID)
	case "select_character":
		return h.handleSelectCharacterWS(wsMsg.Data, userID)
	case "create_character":
		return h.handleCreateCharacterWS(wsMsg.Data, userID)
	default:
		return nil, fmt.Errorf("type de message non supporté: %s", wsMsg.Type)
	}
}

// handleGetCharactersWS gère la récupération des personnages via WebSocket
func (h *CharacterHandler) handleGetCharactersWS(userID int) ([]byte, error) {
	characters, err := h.characterRepo.GetCharactersByUser(userID)
	if err != nil {
		return h.createErrorResponse("Erreur lors de la récupération des personnages")
	}

	response := map[string]interface{}{
		"type": "characters_list",
		"data": map[string]interface{}{
			"success":    true,
			"characters": characters,
			"classes":    models.GetAllClasses(),
		},
	}

	return json.Marshal(response)
}

// handleSelectCharacterWS gère la sélection d'un personnage via WebSocket
func (h *CharacterHandler) handleSelectCharacterWS(data json.RawMessage, userID int) ([]byte, error) {
	var req struct {
		CharacterID int `json:"character_id"`
	}

	if err := json.Unmarshal(data, &req); err != nil {
		return h.createErrorResponse("Données invalides")
	}

	character, err := h.characterRepo.GetCharacterByID(req.CharacterID)
	if err != nil {
		return h.createErrorResponse("Personnage non trouvé")
	}

	if character.UserID != userID {
		return h.createErrorResponse("Personnage non autorisé")
	}

	// Mettre à jour la dernière connexion
	h.characterRepo.UpdateCharacterLastLogin(req.CharacterID)

	response := map[string]interface{}{
		"type": "character_selected",
		"data": map[string]interface{}{
			"success":   true,
			"character": character,
		},
	}

	return json.Marshal(response)
}

// handleCreateCharacterWS gère la création d'un personnage via WebSocket
func (h *CharacterHandler) handleCreateCharacterWS(data json.RawMessage, userID int) ([]byte, error) {
	var req models.CreateCharacterRequest
	if err := json.Unmarshal(data, &req); err != nil {
		return h.createErrorResponse("Données invalides")
	}

	if err := h.validateCreateCharacterRequest(&req); err != nil {
		return h.createErrorResponse(err.Error())
	}

	character, err := h.characterRepo.CreateCharacter(userID, req)
	if err != nil {
		return h.createErrorResponse(err.Error())
	}

	response := map[string]interface{}{
		"type": "character_created",
		"data": map[string]interface{}{
			"success":   true,
			"character": character,
		},
	}

	return json.Marshal(response)
}

// createErrorResponse crée une réponse d'erreur pour WebSocket
func (h *CharacterHandler) createErrorResponse(message string) ([]byte, error) {
	response := map[string]interface{}{
		"type": "error",
		"data": map[string]interface{}{
			"success": false,
			"error":   message,
		},
	}

	return json.Marshal(response)
}
