import Foundation
import EventKit
import SwiftData

@MainActor
public final class CalendarScheduler {
    public static let shared = CalendarScheduler()
    
    private let eventStore = EKEventStore()
    
    private init() {}
    
    /// Requests access to the iOS Calendar system.
    public func requestCalendarAccess() async -> Bool {
        do {
            if #available(iOS 17.0, *) {
                return try await eventStore.requestFullAccessToEvents()
            } else {
                return try await withCheckedThrowingContinuation { continuation in
                    eventStore.requestAccess(to: .event) { granted, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: granted)
                        }
                    }
                }
            }
        } catch {
            print("Failed to request calendar access: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Proactively schedules tasks in the user's free slots over the upcoming 3 days.
    public func proactivelyScheduleTasks(tasks: [Activity], modelContext: ModelContext) {
        let calendar = Calendar.current
        let now = Date()
        let startDate = now
        
        // 1. Delete all unaccepted AI-suggested calendar events in the future first to avoid duplicates
        let oldSuggestionsFetch = FetchDescriptor<CalendarEvent>()
        if let existingEvents = try? modelContext.fetch(oldSuggestionsFetch) {
            let suggestionsToDelete = existingEvents.filter { event in
                event.isAISuggested && !event.isAccepted && event.startDate >= now
            }
            for event in suggestionsToDelete {
                modelContext.delete(event)
            }
            try? modelContext.save()
        }
        
        // Define upcoming 3 days boundary
        guard let endDate = calendar.date(byAdding: .day, value: 3, to: now) else { return }
        
        var systemEvents: [EKEvent] = []
        let status = EKEventStore.authorizationStatus(for: .event)
        let hasAccess: Bool
        if #available(iOS 17.0, *) {
            hasAccess = (status == .fullAccess)
        } else {
            hasAccess = (status == .authorized)
        }
        
        if hasAccess {
            let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
            systemEvents = eventStore.events(matching: predicate)
        }
        
        // 2. Fetch in-app custom scheduled events
        let eventFetchDescriptor = FetchDescriptor<CalendarEvent>()
        var inAppEvents = (try? modelContext.fetch(eventFetchDescriptor)) ?? []
        
        // 2.1 Pre-process manually scheduled tasks to create/update calendar events
        for task in tasks {
            if let schedDate = task.scheduledDate {
                let durationSec = Double(task.durationMinutes) * 60.0
                if let existingEvent = inAppEvents.first(where: { $0.associatedActivityID == task.id }) {
                    existingEvent.startDate = schedDate
                    existingEvent.endDate = schedDate.addingTimeInterval(durationSec)
                    existingEvent.isAISuggested = false
                    existingEvent.isAccepted = true
                    existingEvent.title = "Focus: \(task.name)"
                } else {
                    let newEvent = CalendarEvent(
                        title: "Focus: \(task.name)",
                        startDate: schedDate,
                        endDate: schedDate.addingTimeInterval(durationSec),
                        associatedActivityID: task.id,
                        isAISuggested: false,
                        isAccepted: true
                    )
                    modelContext.insert(newEvent)
                    inAppEvents.append(newEvent)
                }
            }
        }
        try? modelContext.save()
        
        // 3. Construct busy intervals
        var busyIntervals: [DateInterval] = []
        
        // Add Sleep Blocks: 01:00 to 06:00
        var currentDay = calendar.startOfDay(for: now)
        for _ in 0...3 {
            if let sleepStart = calendar.date(bySettingHour: 1, minute: 0, second: 0, of: currentDay),
               let sleepEnd = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: currentDay) {
                busyIntervals.append(DateInterval(start: sleepStart, end: sleepEnd))
            }
            currentDay = calendar.date(byAdding: .day, value: 1, to: currentDay)!
        }
        
        // Sleep blocks and custom calendar events (including School/Work created by the user) are used as busy intervals.
        
        // Add actual system calendar events
        for event in systemEvents {
            // Ignore all-day events as they don't block hourly slots directly
            if !event.isAllDay {
                busyIntervals.append(DateInterval(start: event.startDate, end: event.endDate))
            }
        }
        
        // Add existing in-app calendar events (projecting weekly recurring ones)
        for event in inAppEvents {
            if event.isWeeklyRecurring {
                let eventWeekday = calendar.component(.weekday, from: event.startDate)
                var checkDay = calendar.startOfDay(for: now)
                for _ in 0...3 {
                    let checkWeekday = calendar.component(.weekday, from: checkDay)
                    if checkWeekday == eventWeekday {
                        // Skip if the event is cancelled on this specific checkDay
                        if event.isCancelled(on: checkDay) {
                            checkDay = calendar.date(byAdding: .day, value: 1, to: checkDay)!
                            continue
                        }
                        
                        let startComp = calendar.dateComponents([.hour, .minute], from: event.startDate)
                        let endComp = calendar.dateComponents([.hour, .minute], from: event.endDate)
                        
                        if let projectedStart = calendar.date(bySettingHour: startComp.hour ?? 0, minute: startComp.minute ?? 0, second: 0, of: checkDay) {
                            var projectedEnd = calendar.date(bySettingHour: endComp.hour ?? 0, minute: endComp.minute ?? 0, second: 0, of: checkDay)
                            if (endComp.hour ?? 0) < (startComp.hour ?? 0) {
                                if let tomorrow = calendar.date(byAdding: .day, value: 1, to: checkDay) {
                                    projectedEnd = calendar.date(bySettingHour: endComp.hour ?? 0, minute: endComp.minute ?? 0, second: 0, of: tomorrow)
                                }
                            }
                            
                            if let finalEnd = projectedEnd {
                                busyIntervals.append(DateInterval(start: projectedStart, end: finalEnd))
                                
                                // Add 1 hour travel buffer after school events
                                if event.eventType == .school {
                                    busyIntervals.append(DateInterval(start: finalEnd, duration: 3600))
                                }
                            }
                        }
                    }
                    checkDay = calendar.date(byAdding: .day, value: 1, to: checkDay)!
                }
            } else {
                if !event.isCancelled(on: event.startDate) {
                    busyIntervals.append(DateInterval(start: event.startDate, end: event.endDate))
                    
                    // Add 1 hour travel buffer after school events
                    if event.eventType == .school {
                        busyIntervals.append(DateInterval(start: event.endDate, duration: 3600))
                    }
                }
            }
        }
        
        // Sort and merge intervals to make scanning clean
        var busyIntervalsCopy = busyIntervals
        var mergedBusy = mergeIntervals(busyIntervalsCopy)
        
        // 4. Pre-plan study sessions for upcoming tests (type == .test)
        let testEvents = inAppEvents.filter { $0.eventType == .test && !$0.isAISuggested }
        for test in testEvents {
            let prepTitle = "Lernen: \(test.title)"
            
            // Check if we already have a study session scheduled for this test
            let alreadyScheduled = inAppEvents.contains { $0.title == prepTitle }
            if alreadyScheduled { continue }
            
            var searchStart = now
            let searchEnd = test.startDate
            let durationSeconds = 90.0 * 60.0 // 90 minutes study time
            var foundSlot = false
            
            while searchStart < searchEnd && !foundSlot {
                let hour = calendar.component(.hour, from: searchStart)
                if hour >= 1 && hour < 6 {
                    if let todaySix = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: searchStart) {
                        searchStart = todaySix
                    }
                    continue
                }
                
                let proposedEnd = searchStart.addingTimeInterval(durationSeconds)
                let proposedInterval = DateInterval(start: searchStart, end: proposedEnd)
                
                // Ensure it fits before the test starts
                if proposedEnd > searchEnd {
                    break
                }
                
                // Ensure proposed interval stays within the 01:00 AM limit
                let scanDayStart = calendar.startOfDay(for: searchStart)
                let limitDate: Date
                if hour >= 6 {
                    let tomorrow = calendar.date(byAdding: .day, value: 1, to: scanDayStart)!
                    limitDate = calendar.date(bySettingHour: 1, minute: 0, second: 0, of: tomorrow)!
                } else {
                    limitDate = calendar.date(bySettingHour: 1, minute: 0, second: 0, of: scanDayStart)!
                }
                
                if proposedEnd > limitDate {
                    let nextDay = hour >= 6 ? calendar.date(byAdding: .day, value: 1, to: scanDayStart)! : scanDayStart
                    if let tomorrowSix = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: nextDay) {
                        searchStart = tomorrowSix
                    }
                    continue
                }
                
                // Check intersection with busy intervals
                let intersects = mergedBusy.contains { busy in
                    guard let intersection = busy.intersection(with: proposedInterval) else { return false }
                    return intersection.duration > 0
                }
                
                if !intersects {
                    let newEvent = CalendarEvent(
                        title: prepTitle,
                        startDate: searchStart,
                        endDate: proposedEnd,
                        isAISuggested: true,
                        isAccepted: false,
                        eventType: .focus
                    )
                    modelContext.insert(newEvent)
                    foundSlot = true
                    
                    // Add this new slot to busy list and re-merge
                    busyIntervalsCopy.append(proposedInterval)
                    mergedBusy = mergeIntervals(busyIntervalsCopy)
                } else {
                    if let intersecting = mergedBusy.first(where: {
                        guard let intersection = $0.intersection(with: proposedInterval) else { return false }
                        return intersection.duration > 0
                    }) {
                        searchStart = max(searchStart.addingTimeInterval(60), intersecting.end)
                    } else {
                        searchStart = searchStart.addingTimeInterval(15 * 60)
                    }
                }
            }
        }
        
        // Filter tasks that need scheduling (not completed today and not already scheduled in next 3 days)
        let tasksToSchedule = tasks.filter { !$0.isCompletedToday }
        var currentScanDate = now
        
        for task in tasksToSchedule {
            // Check if this specific activity is already scheduled in the next 3 days
            let alreadyScheduled = inAppEvents.contains { event in
                event.associatedActivityID == task.id && event.startDate >= now
            }
            if alreadyScheduled { continue }
            
            let durationSeconds = Double(task.durationMinutes) * 60.0
            var foundSlot = false
            
            while currentScanDate < endDate && !foundSlot {
                // Ensure the scan date fits productivity hours: 06:00 - 01:00 (next day)
                let hour = calendar.component(.hour, from: currentScanDate)
                if hour >= 1 && hour < 6 {
                    if let todaySix = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: currentScanDate) {
                        currentScanDate = todaySix
                    }
                    continue
                }
                
                let proposedEnd = currentScanDate.addingTimeInterval(durationSeconds)
                let proposedInterval = DateInterval(start: currentScanDate, end: proposedEnd)
                
                // Determine 01:00 AM limit for current scan day (or tomorrow if currently past 06:00)
                let scanDayStart = calendar.startOfDay(for: currentScanDate)
                let limitDate: Date
                if hour >= 6 {
                    let tomorrow = calendar.date(byAdding: .day, value: 1, to: scanDayStart)!
                    limitDate = calendar.date(bySettingHour: 1, minute: 0, second: 0, of: tomorrow)!
                } else {
                    limitDate = calendar.date(bySettingHour: 1, minute: 0, second: 0, of: scanDayStart)!
                }
                
                // Ensure proposed interval stays within the 01:00 AM limit
                if proposedEnd > limitDate {
                    // Jump to 06:00 of the next segment
                    let nextDay = hour >= 6 ? calendar.date(byAdding: .day, value: 1, to: scanDayStart)! : scanDayStart
                    if let tomorrowSix = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: nextDay) {
                        currentScanDate = tomorrowSix
                    }
                    continue
                }
                
                // Check non-zero intersection with any merged busy intervals (to ignore boundaries touching)
                let intersects = mergedBusy.contains { busy in
                    guard let intersection = busy.intersection(with: proposedInterval) else { return false }
                    return intersection.duration > 0
                }
                
                if !intersects {
                    // Create in-app AI Suggested CalendarEvent
                    let newEvent = CalendarEvent(
                        title: "Focus: \(task.name)",
                        startDate: currentScanDate,
                        endDate: proposedEnd,
                        associatedActivityID: task.id,
                        isAISuggested: true,
                        isAccepted: false
                    )
                    modelContext.insert(newEvent)
                    
                    // Break loop, we successfully scheduled this task
                    foundSlot = true
                    
                    // Advance currentScanDate past this new event + 30 mins buffer
                    currentScanDate = proposedEnd.addingTimeInterval(30 * 60)
                } else {
                    // Find the busy interval that intersected and skip past it
                    if let intersecting = mergedBusy.first(where: {
                        guard let intersection = $0.intersection(with: proposedInterval) else { return false }
                        return intersection.duration > 0
                    }) {
                        currentScanDate = max(currentScanDate.addingTimeInterval(60), intersecting.end)
                    } else {
                        currentScanDate = currentScanDate.addingTimeInterval(15 * 60) // Fallback 15 mins increment
                    }
                }
            }
        }
        
        // Save database changes
        try? modelContext.save()
    }
    
    /// Helper to sort and merge overlapping date intervals
    private func mergeIntervals(_ intervals: [DateInterval]) -> [DateInterval] {
        guard intervals.count > 1 else { return intervals }
        
        let sorted = intervals.sorted { $0.start < $1.start }
        var merged: [DateInterval] = []
        
        for interval in sorted {
            if merged.isEmpty {
                merged.append(interval)
            } else {
                let last = merged.removeLast()
                if last.intersects(interval) || last.end >= interval.start {
                    let mergedStart = min(last.start, interval.start)
                    let mergedEnd = max(last.end, interval.end)
                    merged.append(DateInterval(start: mergedStart, end: mergedEnd))
                } else {
                    merged.append(last)
                    merged.append(interval)
                }
            }
        }
        
        return merged
    }
}
