import Foundation
import SwiftUI

// MARK: - Localization Manager
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: Language = .english
    @AppStorage("selectedLanguage") private var selectedLanguageCode: String = "en"
    
    enum Language: String, CaseIterable {
        case english = "en"
        case spanish = "es"
        
        var displayName: String {
            switch self {
            case .english: return "English"
            case .spanish: return "Español"
            }
        }
        
        var flag: String {
            switch self {
            case .english: return "🇺🇸"
            case .spanish: return "🇦🇷"
            }
        }
    }
    
    private init() {
        currentLanguage = Language(rawValue: selectedLanguageCode) ?? .english
    }
    
    func setLanguage(_ language: Language) {
        currentLanguage = language
        selectedLanguageCode = language.rawValue
    }
}

// MARK: - Localized Strings
struct LocalizedStrings {
    static func get(_ key: String) -> String {
        let language = LocalizationManager.shared.currentLanguage
        
        switch language {
        case .english:
            return englishStrings[key] ?? key
        case .spanish:
            return spanishStrings[key] ?? key
        }
    }
    
    // MARK: - English Strings
    private static let englishStrings: [String: String] = [
        // App
        "app_name": "PinIt",
        "app_tagline": "Find Study Partners",
        
        // Navigation
        "map": "Map",
        "friends_social": "Friends & Social",
        "community_hub": "Community Hub",
        "profile": "Profile",
        
        // Location
        "location_access_required": "Location Access Required",
        "location_permission_message": "PinIt needs your location to show nearby events and help you discover study groups in Buenos Aires.",
        "allow_location_access": "Allow Location Access",
        "continue_without_location": "Continue Without Location",
        "location_active": "Location Active",
        "getting_location": "Getting Location...",
        "location_disabled": "Location Disabled",
        "location_needed": "Location Needed",
        
        // Events
        "trending_events": "Trending Events",
        "recent_activity": "Recent Activity",
        "nearby_events": "Nearby Events",
        "create_event": "Create Event",
        "find_friends": "Find Friends",
        "rate_events": "Rate Events",
        
        // Profile
        "edit_profile": "Edit Profile",
        "user_reputation": "User Reputation",
        "friends": "Friends",
        "mutual_connections": "Mutual Connections",
        "recent_events": "Recent Events",
        "add_friend": "Add Friend",
        "block_user": "Block",
        "send_message": "Send Message",
        
        // Chat
        "group_chat": "Group Chat",
        "chat": "Chat",
        "type_message": "Type a message...",
        
        // Settings
        "settings": "Settings",
        "language": "Language",
        "notifications": "Notifications",
        "privacy": "Privacy",
        "about": "About",
        
        // Common
        "save": "Save",
        "cancel": "Cancel",
        "done": "Done",
        "back": "Back",
        "search": "Search",
        "loading": "Loading...",
        "error": "Error",
        "success": "Success",
        "retry": "Retry"
    ]
    
    // MARK: - Spanish Strings
    private static let spanishStrings: [String: String] = [
        // App
        "app_name": "PinIt",
        "app_tagline": "Encuentra Compañeros de Estudio",
        
        // Navigation
        "map": "Mapa",
        "friends_social": "Amigos y Social",
        "community_hub": "Centro Comunitario",
        "profile": "Perfil",
        
        // Location
        "location_access_required": "Acceso a Ubicación Requerido",
        "location_permission_message": "PinIt necesita tu ubicación para mostrar eventos cercanos y ayudarte a descubrir grupos de estudio en Buenos Aires.",
        "allow_location_access": "Permitir Acceso a Ubicación",
        "continue_without_location": "Continuar Sin Ubicación",
        "location_active": "Ubicación Activa",
        "getting_location": "Obteniendo Ubicación...",
        "location_disabled": "Ubicación Deshabilitada",
        "location_needed": "Ubicación Necesaria",
        
        // Events
        "trending_events": "Eventos Destacados",
        "recent_activity": "Actividad Reciente",
        "nearby_events": "Eventos Cercanos",
        "create_event": "Crear Evento",
        "find_friends": "Encontrar Amigos",
        "rate_events": "Calificar Eventos",
        
        // Profile
        "edit_profile": "Editar Perfil",
        "user_reputation": "Reputación del Usuario",
        "friends": "Amigos",
        "mutual_connections": "Conexiones Mutuas",
        "recent_events": "Eventos Recientes",
        "add_friend": "Agregar Amigo",
        "block_user": "Bloquear",
        "send_message": "Enviar Mensaje",
        
        // Chat
        "group_chat": "Chat Grupal",
        "chat": "Chat",
        "type_message": "Escribe un mensaje...",
        
        // Settings
        "settings": "Configuración",
        "language": "Idioma",
        "notifications": "Notificaciones",
        "privacy": "Privacidad",
        "about": "Acerca de",
        
        // Common
        "save": "Guardar",
        "cancel": "Cancelar",
        "done": "Listo",
        "back": "Atrás",
        "search": "Buscar",
        "loading": "Cargando...",
        "error": "Error",
        "success": "Éxito",
        "retry": "Reintentar"
    ]
}

// MARK: - String Extension for Easy Access
extension String {
    var localized: String {
        return LocalizedStrings.get(self)
    }
}
