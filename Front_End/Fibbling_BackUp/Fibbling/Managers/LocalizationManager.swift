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
        "retry": "Retry",
        
        // Welcome & Onboarding
        "welcome_to_pinit": "Welcome to PinIt",
        "find_study_partners": "Find Study Partners",
        "discover_events": "Discover Events",
        "connect_with_students": "Connect with Students",
        "get_started": "Get Started",
        "skip": "Skip",
        "next": "Next",
        "finish": "Finish",
        
        // Profile & User Info
        "profile_completion": "Profile Completion",
        "complete_your_profile": "Complete your profile to unlock better auto-matching and build trust with other students!",
        "personal_info": "Personal Information",
        "academic_info": "Academic Information",
        "interests": "Interests",
        "skills": "Skills",
        "bio": "Bio",
        "university": "University",
        "degree": "Degree",
        "year": "Year",
        "major": "Major",
        "minor": "Minor",
        
        // Events
        "event_details": "Event Details",
        "event_title": "Event Title",
        "event_description": "Event Description",
        "event_location": "Event Location",
        "event_time": "Event Time",
        "event_date": "Event Date",
        "attendees": "Attendees",
        "host": "Host",
        "join_event": "Join Event",
        "leave_event": "Leave Event",
        "rsvp": "RSVP",
        "invite_friends": "Invite Friends",
        "share_event": "Share Event",
        
        // Study Types
        "study_group": "Study Group",
        "exam_prep": "Exam Prep",
        "project_collaboration": "Project Collaboration",
        "language_exchange": "Language Exchange",
        "research": "Research",
        "homework_help": "Homework Help",
        "peer_tutoring": "Peer Tutoring",
        
        // Social Features
        "friend_requests": "Friend Requests",
        "pending_requests": "Pending Requests",
        "accept": "Accept",
        "decline": "Decline",
        "unfriend": "Unfriend",
        "block": "Block",
        "unblock": "Unblock",
        "report": "Report",
        
        // Notifications
        "notifications": "Notifications",
        "push_notifications": "Push Notifications",
        "email_notifications": "Email Notifications",
        "event_reminders": "Event Reminders",
        "friend_requests_notifications": "Friend Requests",
        "message_notifications": "Message Notifications",
        
        // Settings
        "account_settings": "Account Settings",
        "privacy_settings": "Privacy Settings",
        "notification_settings": "Notification Settings",
        "appearance": "Appearance",
        "dark_mode": "Dark Mode",
        "light_mode": "Light Mode",
        "system_mode": "System Mode",
        
        // Actions
        "create": "Create",
        "edit": "Edit",
        "delete": "Delete",
        "update": "Update",
        "refresh": "Refresh",
        "filter": "Filter",
        "sort": "Sort",
        "clear": "Clear",
        "reset": "Reset",
        
        // Status Messages
        "no_events_found": "No events found",
        "no_friends_found": "No friends found",
        "no_messages": "No messages",
        "loading_events": "Loading events...",
        "loading_friends": "Loading friends...",
        "loading_messages": "Loading messages...",
        "connection_error": "Connection error",
        "try_again": "Try again",
        
        // Time & Date
        "today": "Today",
        "tomorrow": "Tomorrow",
        "yesterday": "Yesterday",
        "this_week": "This Week",
        "next_week": "Next Week",
        "this_month": "This Month",
        "next_month": "Next Month",
        "all_day": "All Day",
        "morning": "Morning",
        "afternoon": "Afternoon",
        "evening": "Evening",
        "night": "Night"
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
        "retry": "Reintentar",
        
        // Welcome & Onboarding
        "welcome_to_pinit": "Bienvenido a PinIt",
        "find_study_partners": "Encuentra Compañeros de Estudio",
        "discover_events": "Descubre Eventos",
        "connect_with_students": "Conecta con Estudiantes",
        "get_started": "Comenzar",
        "skip": "Omitir",
        "next": "Siguiente",
        "finish": "Finalizar",
        
        // Profile & User Info
        "profile_completion": "Completar Perfil",
        "complete_your_profile": "¡Completa tu perfil para desbloquear mejor emparejamiento automático y generar confianza con otros estudiantes!",
        "personal_info": "Información Personal",
        "academic_info": "Información Académica",
        "interests": "Intereses",
        "skills": "Habilidades",
        "bio": "Biografía",
        "university": "Universidad",
        "degree": "Carrera",
        "year": "Año",
        "major": "Especialización",
        "minor": "Menor",
        
        // Events
        "event_details": "Detalles del Evento",
        "event_title": "Título del Evento",
        "event_description": "Descripción del Evento",
        "event_location": "Ubicación del Evento",
        "event_time": "Hora del Evento",
        "event_date": "Fecha del Evento",
        "attendees": "Asistentes",
        "host": "Anfitrión",
        "join_event": "Unirse al Evento",
        "leave_event": "Salir del Evento",
        "rsvp": "Confirmar Asistencia",
        "invite_friends": "Invitar Amigos",
        "share_event": "Compartir Evento",
        
        // Study Types
        "study_group": "Grupo de Estudio",
        "exam_prep": "Preparación de Exámenes",
        "project_collaboration": "Colaboración en Proyectos",
        "language_exchange": "Intercambio de Idiomas",
        "research": "Investigación",
        "homework_help": "Ayuda con Tareas",
        "peer_tutoring": "Tutoría entre Pares",
        
        // Social Features
        "friend_requests": "Solicitudes de Amistad",
        "pending_requests": "Solicitudes Pendientes",
        "accept": "Aceptar",
        "decline": "Rechazar",
        "unfriend": "Eliminar Amigo",
        "block": "Bloquear",
        "unblock": "Desbloquear",
        "report": "Reportar",
        
        // Notifications
        "notifications": "Notificaciones",
        "push_notifications": "Notificaciones Push",
        "email_notifications": "Notificaciones por Email",
        "event_reminders": "Recordatorios de Eventos",
        "friend_requests_notifications": "Solicitudes de Amistad",
        "message_notifications": "Notificaciones de Mensajes",
        
        // Settings
        "account_settings": "Configuración de Cuenta",
        "privacy_settings": "Configuración de Privacidad",
        "notification_settings": "Configuración de Notificaciones",
        "appearance": "Apariencia",
        "dark_mode": "Modo Oscuro",
        "light_mode": "Modo Claro",
        "system_mode": "Modo del Sistema",
        
        // Actions
        "create": "Crear",
        "edit": "Editar",
        "delete": "Eliminar",
        "update": "Actualizar",
        "refresh": "Actualizar",
        "filter": "Filtrar",
        "sort": "Ordenar",
        "clear": "Limpiar",
        "reset": "Restablecer",
        
        // Status Messages
        "no_events_found": "No se encontraron eventos",
        "no_friends_found": "No se encontraron amigos",
        "no_messages": "No hay mensajes",
        "loading_events": "Cargando eventos...",
        "loading_friends": "Cargando amigos...",
        "loading_messages": "Cargando mensajes...",
        "connection_error": "Error de conexión",
        "try_again": "Intentar de nuevo",
        
        // Time & Date
        "today": "Hoy",
        "tomorrow": "Mañana",
        "yesterday": "Ayer",
        "this_week": "Esta Semana",
        "next_week": "Próxima Semana",
        "this_month": "Este Mes",
        "next_month": "Próximo Mes",
        "all_day": "Todo el Día",
        "morning": "Mañana",
        "afternoon": "Tarde",
        "evening": "Noche",
        "night": "Noche"
    ]
}

// MARK: - String Extension for Easy Access
extension String {
    var localized: String {
        return LocalizedStrings.get(self)
    }
}
