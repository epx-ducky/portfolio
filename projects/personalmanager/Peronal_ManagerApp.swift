import SwiftUI
import SwiftData
import FamilyControls

@main
struct Peronal_ManagerApp: App {
    // Setting up the ModelContainer schema for persistence
    let container: ModelContainer
    
    init() {
        do {
            let schema = Schema([
                DopamineScore.self,
                DopamineGain.self,
                Activity.self,
                CalendarEvent.self,
                TaskCompletionRecord.self
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            self.container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Could not initialize SwiftData container: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .task {
                    // Seed initial data safely on the main actor after views are loaded
                    seedInitialData()
                    
                    // Migrate old completions to TaskCompletionRecords
                    migrateOldCompletions(context: container.mainContext)
                    
                    // Request location tracking access
                    LocationManager.shared.requestAuthorization()
                    LocationManager.shared.startUpdatingLocation()
                    
                    // Start the Local API Server to allow AI to query and update the database
                    LocalAPIServer.shared.start(modelContext: container.mainContext)
                    
                    // Periodically reset scores and tasks in case of day changes
                    if let score = try? container.mainContext.fetch(FetchDescriptor<DopamineScore>()).first {
                        score.resetIfNewDay(context: container.mainContext)
                    }
                }
        }
    }
    
    // Seeds example activities and singleton score if not already created
    @MainActor
    private func seedInitialData() {
        let context = container.mainContext
        
        // 1. Verify/Initialize DopamineScore singleton
        let scoreFetch = FetchDescriptor<DopamineScore>()
        if let existingScores = try? context.fetch(scoreFetch), existingScores.isEmpty {
            let newScore = DopamineScore(currentPercentage: 0.20, dailyResetTimestamp: Date())
            context.insert(newScore)
            print("Seeded DopamineScore singleton.")
        }
        
        // 2. Verify/Initialize standard focus tasks
        let activityFetch = FetchDescriptor<Activity>()
        if let existingActivities = try? context.fetch(activityFetch), existingActivities.isEmpty {
            let sampleActivities = [
                Activity(name: "Mathe lernen", dopaminePoints: 0.25, isCompletedToday: false, category: .learning, dueDate: Date(), durationMinutes: 90),
                Activity(name: "Video schneiden", dopaminePoints: 0.20, isCompletedToday: false, category: .startup, dueDate: Date(), durationMinutes: 60),
                Activity(name: "Daily Workout", dopaminePoints: 0.15, isCompletedToday: false, category: .workout, dueDate: Date(), durationMinutes: 45),
                Activity(name: "Review Goals", dopaminePoints: 0.10, isCompletedToday: false, category: .social, dueDate: Date(), durationMinutes: 30)
            ]
            
            for activity in sampleActivities {
                context.insert(activity)
            }
            
            try? context.save()
            print("Seeded sample activities list.")
        }
        
        // 3. Seed User's School Schedule once (v5 to include corrected Sport and Gitarre)
        if !UserDefaults.standard.bool(forKey: "didSeedSchoolScheduleV5") {
            let eventFetch = FetchDescriptor<CalendarEvent>()
            if let existingEvents = try? context.fetch(eventFetch) {
                // Delete existing school and Gitarre events to prevent duplicates/collissions
                let toDelete = existingEvents.filter { $0.eventType == .school || $0.title == "Gitarre" }
                for event in toDelete {
                    context.delete(event)
                }
                
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let weekday = calendar.component(.weekday, from: today)
                
                // Helper to get date for target weekday (2 = Mon, 3 = Tue, 4 = Wed, 5 = Thu, 6 = Fri)
                func dateForWeekday(_ targetWeekday: Int, hour: Int, minute: Int) -> Date {
                    let diff = targetWeekday - weekday
                    let targetDay = calendar.date(byAdding: .day, value: diff, to: today) ?? today
                    return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: targetDay) ?? targetDay
                }
                
                let schedule: [(String, Int, Int, Int, Int, Int, CalendarEventType)] = [
                    // Monday (2)
                    ("Deutsch Havertz", 2, 7, 45, 9, 15, .school),
                    ("Reli Preißler", 2, 9, 30, 11, 0, .school),
                    ("iBWL Busch", 2, 11, 15, 12, 45, .school),
                    ("iVWL Kloster", 2, 13, 30, 15, 0, .school),
                    
                    // Tuesday (3)
                    ("Deutsch Havertz", 3, 7, 45, 9, 15, .school),
                    ("Mathe Woerz", 3, 9, 30, 11, 0, .school),
                    ("Mathe Woerz", 3, 11, 15, 12, 0, .school),
                    ("Physik Köhle", 3, 12, 0, 12, 45, .school),
                    
                    // Wednesday (4)
                    ("WI Weißer", 4, 7, 45, 9, 15, .school),
                    ("Englisch Lachenmaier", 4, 9, 30, 11, 0, .school),
                    ("iBWL Busch", 4, 11, 15, 12, 45, .school),
                    ("Sport Keller-meier", 4, 13, 30, 15, 0, .school),
                    ("Gitarre", 4, 17, 45, 18, 30, .focus), // Green focus category!
                    
                    // Thursday (5)
                    ("Mathe Woerz", 5, 9, 30, 11, 0, .school),
                    ("Physik Köhler", 5, 11, 15, 12, 45, .school),
                    ("PVM Busch", 5, 13, 30, 15, 0, .school),
                    
                    // Friday (6)
                    ("Englisch Lachenmaier", 6, 7, 45, 9, 15, .school),
                    ("Info Demi", 6, 9, 30, 11, 0, .school),
                    ("GGK Striebel", 6, 11, 15, 12, 45, .school)
                ]
                
                for item in schedule {
                    let start = dateForWeekday(item.1, hour: item.2, minute: item.3)
                    let end = dateForWeekday(item.1, hour: item.4, minute: item.5)
                    let newEvent = CalendarEvent(
                        title: item.0,
                        startDate: start,
                        endDate: end,
                        eventType: item.6,
                        isWeeklyRecurring: true
                    )
                    context.insert(newEvent)
                }
                
                try? context.save()
                UserDefaults.standard.set(true, forKey: "didSeedSchoolScheduleV5")
                print("Seeded school schedule v5.")
            }
        }
        
        // Re-run scheduler to update focus activities around the seeded events
        if let activities = try? context.fetch(FetchDescriptor<Activity>()) {
            CalendarScheduler.shared.proactivelyScheduleTasks(tasks: activities, modelContext: context)
        }
    }
    
    // Migrates old completion dates to persistent TaskCompletionRecord records
    private func migrateOldCompletions(context: ModelContext) {
        let calendar = Calendar.current
        
        // 1. Recover from active completedDate if still set
        if let activities = try? context.fetch(FetchDescriptor<Activity>()) {
            var migratedAny = false
            for activity in activities {
                if let completedDate = activity.completedDate {
                    let fetchRecords = FetchDescriptor<TaskCompletionRecord>()
                    if let existingRecords = try? context.fetch(fetchRecords) {
                        let alreadyExists = existingRecords.contains { record in
                            record.taskName == activity.name && calendar.isDate(record.timestamp, inSameDayAs: completedDate)
                        }
                        if !alreadyExists {
                            let record = TaskCompletionRecord(
                                taskName: activity.name,
                                timestamp: completedDate,
                                category: activity.category,
                                durationMinutes: activity.durationMinutes,
                                dopaminePoints: activity.dopaminePoints,
                                imageData: activity.imageData
                            )
                            context.insert(record)
                            migratedAny = true
                            print("Migrated old completion for \(activity.name) on \(completedDate)")
                        }
                    }
                }
            }
            if migratedAny {
                try? context.save()
            }
        }
        
        // 2. Reconstruct from past accepted CalendarEvents (in case completedDate was already reset today)
        let eventFetch = FetchDescriptor<CalendarEvent>()
        if let events = try? context.fetch(eventFetch),
           let activities = try? context.fetch(FetchDescriptor<Activity>()) {
            var reconstructedAny = false
            let now = Date()
            
            for event in events {
                // If it is an in-app event in the past (yesterday or earlier)
                if event.startDate < calendar.startOfDay(for: now) {
                    if let assocId = event.associatedActivityID,
                       let activity = activities.first(where: { $0.id == assocId }) {
                        
                        let fetchRecords = FetchDescriptor<TaskCompletionRecord>()
                        if let existingRecords = try? context.fetch(fetchRecords) {
                            let alreadyExists = existingRecords.contains { record in
                                record.taskName == activity.name && calendar.isDate(record.timestamp, inSameDayAs: event.startDate)
                            }
                            
                            if !alreadyExists {
                                let record = TaskCompletionRecord(
                                    taskName: activity.name,
                                    timestamp: event.startDate,
                                    category: activity.category,
                                    durationMinutes: activity.durationMinutes,
                                    dopaminePoints: activity.dopaminePoints,
                                    imageData: activity.imageData
                                )
                                context.insert(record)
                                reconstructedAny = true
                                print("Reconstructed past completion from calendar event: \(activity.name) on \(event.startDate)")
                            }
                        }
                    }
                }
            }
            if reconstructedAny {
                try? context.save()
            }
        }
    }
}
