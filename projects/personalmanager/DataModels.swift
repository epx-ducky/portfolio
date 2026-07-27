import Foundation
import SwiftData

// MARK: - Activity Category Enum
public enum ActivityCategory: String, Codable, CaseIterable, Identifiable {
    case startup = "Startup"
    case workout = "Workout"
    case learning = "Learning"
    case social = "Social"
    
    public var id: String { self.rawValue }
    
    public var icon: String {
        switch self {
        case .startup: return "briefcase.fill"
        case .workout: return "figure.run"
        case .learning: return "book.closed.fill"
        case .social: return "bubble.left.and.bubble.right.fill"
        }
    }
    
    public var colorName: String {
        switch self {
        case .startup: return "accentPurple"
        case .workout: return "accentOrange"
        case .learning: return "accentBlue"
        case .social: return "accentGreen"
        }
    }
}

// MARK: - Dopamine Gain Log Model
@Model
public final class DopamineGain {
    public var id: UUID = UUID()
    public var amount: Double = 0.0
    public var timestamp: Date = Date()
    public var activityName: String = ""
    
    public init(id: UUID = UUID(), amount: Double, timestamp: Date = Date(), activityName: String) {
        self.id = id
        self.amount = amount
        self.timestamp = timestamp
        self.activityName = activityName
    }
}

// MARK: - Dopamine Score Singleton Model
@Model
public final class DopamineScore {
    public var id: UUID = UUID()
    public var currentPercentage: Double = 0.20 // Daily percentage starts at 20%
    public var dailyResetTimestamp: Date = Date()
    
    @Relationship(deleteRule: .cascade)
    public var gains: [DopamineGain] = []
    
    public var streakCount: Int? = 0
    public var lastStreakIncrementDateString: String? = ""
    public var consistencyXP: Int? = 0
    
    public enum StreakState: String, Codable {
        case active
        case frozen
        case lost
    }
    
    public var streakState: StreakState {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let incrementStr = lastStreakIncrementDateString,
              !incrementStr.isEmpty,
              let incrementDate = formatter.date(from: incrementStr) else {
            return .lost
        }
        
        let diffComponents = calendar.dateComponents([.day], from: calendar.startOfDay(for: incrementDate), to: today)
        let daysPassed = diffComponents.day ?? 0
        
        if daysPassed <= 1 {
            return .active
        } else if daysPassed == 2 {
            return .frozen
        } else {
            return .lost
        }
    }
    
    public init(id: UUID = UUID(), currentPercentage: Double = 0.20, dailyResetTimestamp: Date = Date()) {
        self.id = id
        self.currentPercentage = currentPercentage
        self.dailyResetTimestamp = dailyResetTimestamp
        self.gains = []
        self.streakCount = 0
        self.lastStreakIncrementDateString = ""
        self.consistencyXP = 0
    }
    
    /// Resets the score if a new calendar day has started.
    public func resetIfNewDay(context: ModelContext) {
        let calendar = Calendar.current
        if !calendar.isDateInToday(dailyResetTimestamp) {
            // Check if streak was lost
            if streakState == .lost {
                streakCount = 0
            }
            
            currentPercentage = 0.20
            dailyResetTimestamp = Date()
            gains.removeAll()
            
            // Reset daily checklist task completion states based on recurrence
            if let activities = try? context.fetch(FetchDescriptor<Activity>()) {
                for activity in activities {
                    let rec = activity.recurrence
                    
                    if activity.isCompletedToday {
                        if rec == .none {
                            // Completed one-time tasks are archived/deleted (already in history!)
                            context.delete(activity)
                            continue
                        }
                    }
                    
                    // Reset based on interval
                    if rec == .daily {
                        activity.isCompletedToday = false
                        activity.completedDate = nil
                    } else if rec == .weekly {
                        // Reset weekly tasks on Mondays
                        let weekday = calendar.component(.weekday, from: Date())
                        if weekday == 2 { // Monday
                            activity.isCompletedToday = false
                            activity.completedDate = nil
                        }
                    }
                    
                    // Remove temporary Quests and Workouts so they start fresh
                    if activity.name.hasPrefix("Quest:") || activity.name.hasPrefix("Workout:") {
                        context.delete(activity)
                    }
                }
            }
            
            try? context.save()
        }
    }
    
    /// Increments the score, capping it at 1.0.
    public func addPoints(_ points: Double, activityName: String, context: ModelContext) {
        resetIfNewDay(context: context)
        let newScore = min(1.0, currentPercentage + points)
        let addedAmount = newScore - currentPercentage
        currentPercentage = newScore
        
        let newGain = DopamineGain(amount: addedAmount, timestamp: Date(), activityName: activityName)
        gains.append(newGain)
        
        checkAndIncrementStreak()
    }
    
    public func checkAndIncrementStreak() {
        if currentPercentage >= 1.0 {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let todayString = formatter.string(from: Date())
            
            if lastStreakIncrementDateString != todayString {
                if streakState == .lost {
                    streakCount = 1
                } else {
                    streakCount = (streakCount ?? 0) + 1
                }
                lastStreakIncrementDateString = todayString
            }
        }
    }
}

// MARK: - Activity Recurrence Enum
public enum ActivityRecurrence: String, Codable, CaseIterable, Identifiable {
    case none = "Einmalig"
    case daily = "Täglich"
    case weekly = "Wöchentlich"
    
    public var id: String { self.rawValue }
}

// MARK: - Activity Task Model
@Model
public final class Activity {
    public var id: UUID = UUID()
    public var name: String = ""
    public var dopaminePoints: Double = 0.0
    public var isCompletedToday: Bool = false
    public var categoryString: String = "startup"
    public var dueDate: Date? = nil
    public var durationMinutes: Int = 60
    public var imageData: Data? = nil
    public var completedDate: Date? = nil
    public var recurrenceString: String? = "none"
    public var scheduledDate: Date? = nil
    
    public var category: ActivityCategory {
        get { ActivityCategory(rawValue: categoryString) ?? .startup }
        set { categoryString = newValue.rawValue }
    }
    
    public var recurrence: ActivityRecurrence {
        get { ActivityRecurrence(rawValue: recurrenceString ?? "none") ?? .none }
        set { recurrenceString = newValue.rawValue }
    }
    
    public init(id: UUID = UUID(), name: String, dopaminePoints: Double, isCompletedToday: Bool = false, category: ActivityCategory, dueDate: Date? = nil, durationMinutes: Int = 60, imageData: Data? = nil, completedDate: Date? = nil, recurrence: ActivityRecurrence = .none, scheduledDate: Date? = nil) {
        self.id = id
        self.name = name
        self.dopaminePoints = dopaminePoints
        self.isCompletedToday = isCompletedToday
        self.categoryString = category.rawValue
        self.dueDate = dueDate
        self.durationMinutes = durationMinutes
        self.imageData = imageData
        self.completedDate = completedDate
        self.recurrenceString = recurrence.rawValue
        self.scheduledDate = scheduledDate
    }
}

// MARK: - Calendar Event Type Enum
public enum CalendarEventType: String, Codable, CaseIterable, Identifiable {
    case focus = "Focus"
    case school = "School"
    case work = "Work"
    case test = "Test"
    case other = "Other"
    
    public var id: String { self.rawValue }
    
    public var icon: String {
        switch self {
        case .focus: return "bolt.fill"
        case .school: return "graduationcap.fill"
        case .work: return "briefcase.fill"
        case .test: return "pencil.and.list.number"
        case .other: return "calendar"
        }
    }
    
    public var colorHex: String {
        switch self {
        case .focus: return "00FF87"
        case .school: return "FFCC00"
        case .work: return "007AFF"
        case .test: return "FF2D55"
        case .other: return "8E8E93"
        }
    }
}

// MARK: - Calendar Event Model
@Model
public final class CalendarEvent {
    public var id: UUID = UUID()
    public var title: String = ""
    public var startDate: Date = Date()
    public var endDate: Date = Date()
    public var associatedActivityID: UUID? = nil
    public var isAISuggested: Bool = false
    public var isAccepted: Bool = false
    public var eventTypeString: String = "focus"
    public var isWeeklyRecurring: Bool = false
    public var cancelledDatesString: String = ""
    
    public var eventType: CalendarEventType {
        get { CalendarEventType(rawValue: eventTypeString) ?? .focus }
        set { eventTypeString = newValue.rawValue }
    }
    
    public var cancelledDates: Set<String> {
        get {
            Set(cancelledDatesString.components(separatedBy: ",").filter { !$0.isEmpty })
        }
        set {
            cancelledDatesString = newValue.joined(separator: ",")
        }
    }
    
    public func isCancelled(on date: Date) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: date)
        return cancelledDates.contains(dateStr)
    }
    
    public func setCancelled(_ cancelled: Bool, on date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: date)
        var current = cancelledDates
        if cancelled {
            current.insert(dateStr)
        } else {
            current.remove(dateStr)
        }
        cancelledDates = current
    }
    
    public init(id: UUID = UUID(), title: String, startDate: Date, endDate: Date, associatedActivityID: UUID? = nil, isAISuggested: Bool = false, isAccepted: Bool = false, eventType: CalendarEventType = .focus, isWeeklyRecurring: Bool = false, cancelledDatesString: String = "") {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.associatedActivityID = associatedActivityID
        self.isAISuggested = isAISuggested
        self.isAccepted = isAccepted
        self.eventTypeString = eventType.rawValue
        self.isWeeklyRecurring = isWeeklyRecurring
        self.cancelledDatesString = cancelledDatesString
    }
}

// MARK: - Task Completion History Record Model
@Model
public final class TaskCompletionRecord {
    public var id: UUID = UUID()
    public var taskName: String = ""
    public var timestamp: Date = Date()
    public var categoryString: String = "startup"
    public var durationMinutes: Int = 60
    public var dopaminePoints: Double = 0.0
    public var imageData: Data? = nil
    
    public var category: ActivityCategory {
        get { ActivityCategory(rawValue: categoryString) ?? .startup }
        set { categoryString = newValue.rawValue }
    }
    
    public init(id: UUID = UUID(), taskName: String, timestamp: Date = Date(), category: ActivityCategory, durationMinutes: Int = 60, dopaminePoints: Double, imageData: Data? = nil) {
        self.id = id
        self.taskName = taskName
        self.timestamp = timestamp
        self.categoryString = category.rawValue
        self.durationMinutes = durationMinutes
        self.dopaminePoints = dopaminePoints
        self.imageData = imageData
    }
}
