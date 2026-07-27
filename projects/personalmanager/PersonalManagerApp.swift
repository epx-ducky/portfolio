import SwiftUI
import SwiftData
import FamilyControls

@main
struct PersonalManagerApp: App {
    // Setting up the ModelContainer schema for persistence
    let container: ModelContainer
    
    init() {
        do {
            let schema = Schema([
                DopamineScore.self,
                DopamineGain.self,
                Activity.self,
                CalendarEvent.self
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            self.container = try ModelContainer(for: schema, configurations: config)
            
            // Seed initial data if database is empty
            seedInitialData()
        } catch {
            fatalError("Could not initialize SwiftData container: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainContainerView()
                .modelContainer(container)
                .task {
                    // Check Screen Time authorization status on app launch
                    ScreenTimeManager.shared.checkAuthorizationStatus()
                    
                    // Periodically evaluate active shields in case of day changes
                    if let score = try? container.mainContext.fetch(FetchDescriptor<DopamineScore>()).first {
                        ScreenTimeManager.shared.evaluateShieldState(currentScore: score.currentPercentage)
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
            
            // Proactively schedule the newly seeded activities in the Calendar timeline
            if let activities = try? context.fetch(FetchDescriptor<Activity>()) {
                CalendarScheduler.shared.proactivelyScheduleTasks(tasks: activities, modelContext: context)
            }
        }
    }
}
