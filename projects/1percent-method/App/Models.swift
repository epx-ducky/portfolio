import Foundation

/// Die verschiedenen Kategorien von Habits.
public enum HabitCategory: String, Codable, CaseIterable {
    case fitness = "Fitness"
    case health = "Gesundheit"
    case focus = "Fokus"
    case custom = "Sonstiges"
    
    public var icon: String {
        switch self {
        case .fitness: return "figure.walk"
        case .health: return "flame.fill"
        case .focus: return "ipad.and.iphone"
        case .custom: return "star.fill"
        }
    }
}

/// Die 8 Kern-Attribute für das RPG-Gamification-System (Solo Leveling).
public enum RPGAttribute: String, Codable, CaseIterable, Identifiable {
    case gesundheit = "Gesundheit"
    case sportlichkeit = "Sportlichkeit"
    case disziplin = "Disziplin"
    case achtsamkeit = "Achtsamkeit"
    case geschicklichkeit = "Geschicklichkeit"
    case finanzen = "Finanzen"
    case social = "Social"
    case intelligenz = "Intelligenz"
    
    public var id: String { self.rawValue }
    
    public var icon: String {
        switch self {
        case .gesundheit: return "heart.fill"
        case .sportlichkeit: return "figure.run"
        case .disziplin: return "bolt.fill"
        case .achtsamkeit: return "eye.fill"
        case .geschicklichkeit: return "hammer.fill"
        case .finanzen: return "banknote.fill"
        case .social: return "bubble.left.and.bubble.right.fill"
        case .intelligenz: return "book.closed.fill"
        }
    }
}

/// Struktur zur Haltung der 8 RPG-Attribute des Nutzers.
public struct UserAttributes: Codable, Hashable {
    public var gesundheit: Double
    public var sportlichkeit: Double
    public var disziplin: Double
    public var achtsamkeit: Double
    public var geschicklichkeit: Double
    public var finanzen: Double
    public var social: Double
    public var intelligenz: Double
    
    public init(
        gesundheit: Double = 50.0,
        sportlichkeit: Double = 50.0,
        disziplin: Double = 50.0,
        achtsamkeit: Double = 50.0,
        geschicklichkeit: Double = 50.0,
        finanzen: Double = 50.0,
        social: Double = 50.0,
        intelligenz: Double = 50.0
    ) {
        self.gesundheit = gesundheit
        self.sportlichkeit = sportlichkeit
        self.disziplin = disziplin
        self.achtsamkeit = achtsamkeit
        self.geschicklichkeit = geschicklichkeit
        self.finanzen = finanzen
        self.social = social
        self.intelligenz = intelligenz
    }
}

/// Das Habit-Modell für dynamische Einträge im Dashboard.
public struct Habit: Identifiable, Codable, Hashable {
    public let id: UUID
    public var title: String
    public var isCompleted: Bool
    public var category: HabitCategory
    public var targetAttribute: RPGAttribute
    public var level: Int
    public var upgradesLog: [String]
    public var createdAt: Date
    
    public init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        category: HabitCategory = .custom,
        targetAttribute: RPGAttribute = .disziplin,
        level: Int = 1,
        upgradesLog: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.category = category
        self.targetAttribute = targetAttribute
        self.level = level
        self.upgradesLog = upgradesLog
        self.createdAt = createdAt
    }
}

/// Struktur zur Definition eines Quests (Erfolgs) mit Medaillen-Design.
public struct Achievement: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let description: String
    public let icon: String
    public let metalType: MedalMetalType
    public var isUnlocked: Bool
    
    public init(id: String, title: String, description: String, icon: String, metalType: MedalMetalType, isUnlocked: Bool = false) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.metalType = metalType
        self.isUnlocked = isUnlocked
    }
}

/// Die Metall-Klassifizierung für die Medaillen.
public enum MedalMetalType: String, CaseIterable {
    case bronze = "Bronze"
    case silver = "Silber"
    case gold = "Gold"
    case platinum = "Platin"
    case special = "Spezial"
}

/// Struktur zur Haltung der Dokumentations-Logs für Attribute.
public struct AttributeLog: Codable, Identifiable, Hashable {
    public let id: UUID
    public let date: Date
    public let attribute: RPGAttribute
    public let habitTitle: String
    public let details: String
    
    public init(id: UUID = UUID(), date: Date = Date(), attribute: RPGAttribute, habitTitle: String, details: String) {
        self.id = id
        self.date = date
        self.attribute = attribute
        self.habitTitle = habitTitle
        self.details = details
    }
}

extension AttributeLog {
    public static func loadLogs() -> [AttributeLog] {
        guard let data = UserDefaults.standard.data(forKey: "attribute_logs_list"),
              let logs = try? JSONDecoder().decode([AttributeLog].self, from: data) else {
            return []
        }
        return logs
    }
    
    public static func saveLogs(_ logs: [AttributeLog]) {
        if let encoded = try? JSONEncoder().encode(logs) {
            UserDefaults.standard.set(encoded, forKey: "attribute_logs_list")
        }
    }
    
    public static func addLog(attribute: RPGAttribute, habitTitle: String, details: String) {
        var current = loadLogs()
        let newLog = AttributeLog(attribute: attribute, habitTitle: habitTitle, details: details)
        current.insert(newLog, at: 0)
        saveLogs(current)
    }
}
