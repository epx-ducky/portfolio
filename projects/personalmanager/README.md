# Personal Manager - Focus & Scheduling System for iOS 17+

Personal Manager is a production-ready, fully integrated iOS application structure using **SwiftUI**, **SwiftData**, **EventKit**, and Apple's **Screen Time API** (`FamilyControls`, `DeviceActivity`, `ManagedSettings`).

## Features Included

1. **Daily Dopamine Score (Singleton)**
   - Starts at 20% (0.20) every morning.
   - Automatically resets when the calendar day changes.
   - Accumulates points as tasks are completed, capped at 100% (1.0).
   - Logs history entries for daily gains.

2. **Proactive Scheduling Engine (`CalendarScheduler`)**
   - Integrates with local device calendars via `EventKit`.
   - Automatically masks sleep hours (22:00 - 08:00) and school/work blocks (08:00 - 14:00, weekdays).
   - Merges overlaps and scans upcoming 3 days for free slots (within 08:00 - 20:00 productivity windows).
   - Proactively schedules 60–90 minute blocks for activities needing completion.

3. **Screen Time Block Engine (`ScreenTimeManager`)**
   - Requests user authorization using `FamilyControls`.
   - Automatically matches selected applications and categories.
   - Real-time restriction triggers: if the Dopamine Score < 1.0, shields block targeted distracting apps (Snapchat, Instagram, games, etc.).
   - Releasing the shield once the user reaches 100% score for full evening unlock.

4. **Premium SwiftUI Views (Dark Mode First)**
   - **`DashboardView.swift`**: Glowing circular progress ring tracking focus level, featuring custom impact haptics and success triggers.
   - **`TaskListView.swift`**: Modern checklist with custom checkbox animations, duration steppers, and dopamine gain sliders.
   - **`ProactiveTimelineView.swift`**: Hourly scrollable daily/weekly schedule displaying active slots alongside dashed AI suggestions, with Accept/Decline tools.
   - **`MainContainerView.swift`**: Custom glassmorphic tab-bar navigation wrapper.

---

## File Structure

All generated source files are located in this directory:
- [PersonalManagerApp.swift](file:///Users/villain/Documents/KI-Projekte/PersonalManager/PersonalManagerApp.swift) - App delegate and container configuration
- [DataModels.swift](file:///Users/villain/Documents/KI-Projekte/PersonalManager/DataModels.swift) - SwiftData Schemas
- [CalendarScheduler.swift](file:///Users/villain/Documents/KI-Projekte/PersonalManager/CalendarScheduler.swift) - AI Free-Slot Search Engine
- [ScreenTimeManager.swift](file:///Users/villain/Documents/KI-Projekte/PersonalManager/ScreenTimeManager.swift) - Screen Time Shields
- [MainContainerView.swift](file:///Users/villain/Documents/KI-Projekte/PersonalManager/MainContainerView.swift) - Tab Navigation & Shield config
- [DashboardView.swift](file:///Users/villain/Documents/KI-Projekte/PersonalManager/DashboardView.swift) - Core Score Display
- [ProactiveTimelineView.swift](file:///Users/villain/Documents/KI-Projekte/PersonalManager/ProactiveTimelineView.swift) - AI Timeline Grid
- [TaskListView.swift](file:///Users/villain/Documents/KI-Projekte/PersonalManager/TaskListView.swift) - Daily Checklist

---

## Xcode Setup & Integration

To load this project into Xcode 15+:

1. Create a new **iOS App** project named `PersonalManager` using **SwiftUI** interface and **SwiftData** storage.
2. Drag and drop these 8 Swift files into the project, replacing the default `ContentView.swift` and `PersonalManagerApp.swift`.
3. Add the following **Capabilities** to your target settings:
   - **Family Controls** (Required to request Screen Time permissions).
   - **Calendars** (Required for EventKit access).
4. Update the `Info.plist` (or Target Info) to add:
   - `NSCalendarsFullAccessUsageDescription` / `Privacy - Calendars Usage Description` (with a message like: *"Personal Manager scans your calendars to schedule focus blocks around existing events."*)
5. Build and run on a physical iOS device (Apple does not fully support Shield restrictions or the FamilyActivityPicker on macOS/Simulator targets).
