//
//  LocalizationService.swift
//  EZTeach
//
//  Multi-language support service
//

import Foundation
import SwiftUI
import Combine

class LocalizationService: ObservableObject {
    static let shared = LocalizationService()
    
    @Published var currentLanguage: Language {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "app_language")
        }
    }
    
    enum Language: String, CaseIterable, Identifiable {
        case english = "English"
        case spanish = "Español"
        case french = "Français"
        case chinese = "中文"
        case vietnamese = "Tiếng Việt"
        case arabic = "العربية"
        case korean = "한국어"
        case tagalog = "Tagalog"
        
        var id: String { rawValue }
        
        var code: String {
            switch self {
            case .english: return "en"
            case .spanish: return "es"
            case .french: return "fr"
            case .chinese: return "zh-Hans"
            case .vietnamese: return "vi"
            case .arabic: return "ar"
            case .korean: return "ko"
            case .tagalog: return "fil"
            }
        }
        
        var flag: String {
            switch self {
            case .english: return "🇺🇸"
            case .spanish: return "🇪🇸"
            case .french: return "🇫🇷"
            case .chinese: return "🇨🇳"
            case .vietnamese: return "🇻🇳"
            case .arabic: return "🇸🇦"
            case .korean: return "🇰🇷"
            case .tagalog: return "🇵🇭"
            }
        }
    }
    
    init() {
        if let saved = UserDefaults.standard.string(forKey: "app_language"),
           let language = Language(rawValue: saved) {
            currentLanguage = language
        } else {
            currentLanguage = .english
        }
    }
    
    // MARK: - Localized Strings
    func localized(_ key: String) -> String {
        return translations[currentLanguage.code]?[key] ?? key.replacingOccurrences(of: "_", with: " ").capitalized
    }
    
    // Common UI strings
    var home: String { localized("home") }
    var grades: String { localized("grades") }
    var attendance: String { localized("attendance") }
    var messages: String { localized("messages") }
    var settings: String { localized("settings") }
    var signOut: String { localized("sign_out") }
    var cancel: String { localized("cancel") }
    var save: String { localized("save") }
    var delete: String { localized("delete") }
    var edit: String { localized("edit") }
    var add: String { localized("add") }
    var search: String { localized("search") }
    var loading: String { localized("loading") }
    var error: String { localized("error") }
    var success: String { localized("success") }
    
    // Roles
    var school: String { localized("school") }
    var teacher: String { localized("teacher") }
    var parent: String { localized("parent") }
    var student: String { localized("student") }
    var substitute: String { localized("substitute") }
    
    // Features
    var announcements: String { localized("announcements") }
    var calendar: String { localized("calendar") }
    var homework: String { localized("homework") }
    var lessonPlans: String { localized("lesson_plans") }
    var bellSchedule: String { localized("bell_schedule") }
    var documents: String { localized("documents") }
    var busTracking: String { localized("bus_tracking") }
    var lunchMenu: String { localized("lunch_menu") }
    
    // Translation dictionaries
    private let translations: [String: [String: String]] = [
        "en": [
            "home": "Home",
            "grades": "Grades",
            "attendance": "Attendance",
            "messages": "Messages",
            "settings": "Settings",
            "sign_out": "Sign Out",
            "cancel": "Cancel",
            "save": "Save",
            "delete": "Delete",
            "edit": "Edit",
            "add": "Add",
            "search": "Search",
            "loading": "Loading...",
            "error": "Error",
            "success": "Success",
            "school": "School",
            "teacher": "Teacher",
            "parent": "Parent",
            "student": "Student",
            "substitute": "Substitute",
            "announcements": "Announcements",
            "calendar": "Calendar",
            "homework": "Homework",
            "lesson_plans": "Lesson Plans",
            "bell_schedule": "Bell Schedule",
            "documents": "Documents",
            "bus_tracking": "Bus Tracking",
            "lunch_menu": "Lunch Menu"
        ],
        "es": [
            "home": "Inicio",
            "grades": "Calificaciones",
            "attendance": "Asistencia",
            "messages": "Mensajes",
            "settings": "Configuración",
            "sign_out": "Cerrar Sesión",
            "cancel": "Cancelar",
            "save": "Guardar",
            "delete": "Eliminar",
            "edit": "Editar",
            "add": "Añadir",
            "search": "Buscar",
            "loading": "Cargando...",
            "error": "Error",
            "success": "Éxito",
            "school": "Escuela",
            "teacher": "Maestro",
            "parent": "Padre",
            "student": "Estudiante",
            "substitute": "Sustituto",
            "announcements": "Anuncios",
            "calendar": "Calendario",
            "homework": "Tarea",
            "lesson_plans": "Planes de Lección",
            "bell_schedule": "Horario de Campana",
            "documents": "Documentos",
            "bus_tracking": "Seguimiento de Autobús",
            "lunch_menu": "Menú de Almuerzo"
        ],
        "fr": [
            "home": "Accueil",
            "grades": "Notes",
            "attendance": "Présence",
            "messages": "Messages",
            "settings": "Paramètres",
            "sign_out": "Déconnexion",
            "cancel": "Annuler",
            "save": "Enregistrer",
            "delete": "Supprimer",
            "edit": "Modifier",
            "add": "Ajouter",
            "search": "Rechercher",
            "loading": "Chargement...",
            "error": "Erreur",
            "success": "Succès",
            "school": "École",
            "teacher": "Enseignant",
            "parent": "Parent",
            "student": "Élève",
            "substitute": "Remplaçant",
            "announcements": "Annonces",
            "calendar": "Calendrier",
            "homework": "Devoirs",
            "lesson_plans": "Plans de Cours",
            "bell_schedule": "Horaire des Sonneries",
            "documents": "Documents",
            "bus_tracking": "Suivi du Bus",
            "lunch_menu": "Menu du Déjeuner"
        ],
        "zh-Hans": [
            "home": "首页",
            "grades": "成绩",
            "attendance": "出勤",
            "messages": "消息",
            "settings": "设置",
            "sign_out": "退出",
            "cancel": "取消",
            "save": "保存",
            "delete": "删除",
            "edit": "编辑",
            "add": "添加",
            "search": "搜索",
            "loading": "加载中...",
            "error": "错误",
            "success": "成功"
        ],
        "vi": [
            "home": "Trang chủ",
            "grades": "Điểm số",
            "attendance": "Điểm danh",
            "messages": "Tin nhắn",
            "settings": "Cài đặt",
            "sign_out": "Đăng xuất"
        ],
        "ar": [
            "home": "الرئيسية",
            "grades": "الدرجات",
            "attendance": "الحضور",
            "messages": "الرسائل",
            "settings": "الإعدادات",
            "sign_out": "تسجيل الخروج"
        ],
        "ko": [
            "home": "홈",
            "grades": "성적",
            "attendance": "출석",
            "messages": "메시지",
            "settings": "설정",
            "sign_out": "로그아웃"
        ],
        "fil": [
            "home": "Home",
            "grades": "Mga Grado",
            "attendance": "Pagdalo",
            "messages": "Mga Mensahe",
            "settings": "Mga Setting",
            "sign_out": "Mag-sign Out"
        ]
    ]
}

// MARK: - Language Settings View
struct LanguageSettingsView: View {
    @ObservedObject var localization = LocalizationService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(LocalizationService.Language.allCases) { language in
                    Button {
                        localization.currentLanguage = language
                    } label: {
                        HStack {
                            Text(language.flag)
                                .font(.title2)
                            
                            Text(language.rawValue)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if localization.currentLanguage == language {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(EZTeachColors.accent)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
