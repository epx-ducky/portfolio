import SwiftUI
import SwiftData
import EventKit

struct ProactiveTimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CalendarEvent.startDate) private var events: [CalendarEvent]
    @Query private var activities: [Activity]
    
    @State private var selectedDate = Date()
    @State private var showingScheduleAlert = false
    @State private var isRefreshing = false
    
    // Custom Event Sheet & Delete Confirmation State
    @State private var showingAddEvent = false
    @State private var newEventTitle = ""
    @State private var newEventType: CalendarEventType = .school
    @State private var newEventStartDate = Date()
    @State private var newEventEndDate = Date()
    @State private var newEventIsWeeklyRecurring = false
    
    @State private var selectedEventForDelete: CalendarEvent? = nil
    @State private var showingDeleteConfirmation = false
    @State private var editingEvent: CalendarEvent? = nil
    @State private var isEventCancelledOnSelectedDate = false
    @State private var showingDatePicker = false
    
    // Generate dates for the weekly calendar bar (7 days starting from today)
    private var weekDates: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
    }
    
    // Filter events for the currently selected date (supporting weekly recurring events)
    private var filteredEvents: [CalendarEvent] {
        let calendar = Calendar.current
        return events.filter { event in
            if event.isWeeklyRecurring {
                let eventWeekday = calendar.component(.weekday, from: event.startDate)
                let selectedWeekday = calendar.component(.weekday, from: selectedDate)
                return eventWeekday == selectedWeekday
            } else {
                return calendar.isDate(event.startDate, inSameDayAs: selectedDate)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Premium dark background
                Color(red: 10/255, green: 10/255, blue: 18/255)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Horizontal Weekly Date Selector
                    weeklyDateSelector
                    
                    // Main Timeline Grid
                    ScrollView(showsIndicators: false) {
                        ZStack(alignment: .top) {
                            // Hour grid lines (08:00 to 21:00)
                            hourGridLines
                            
                            // Event blocks overlaid on the grid
                            eventsOverlayView
                        }
                        .frame(height: 20 * 60) // 20 hours * 60 points per hour
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .onTapGesture(coordinateSpace: .local) { location in
                            let yOffset = location.y
                            let totalMinutes = Int(yOffset)
                            let tappedHours = 6 + (totalMinutes / 60)
                            let tappedMinutes = (totalMinutes % 60)
                            
                            // Round minutes to nearest 15 minutes
                            let roundedMinutes = ((tappedMinutes + 7) / 15) * 15
                            
                            let calendar = Calendar.current
                            var comps = calendar.dateComponents([.year, .month, .day], from: selectedDate)
                            
                            let finalHour = tappedHours % 24
                            if tappedHours >= 24 {
                                if let tomorrow = calendar.date(byAdding: .day, value: 1, to: selectedDate) {
                                    comps = calendar.dateComponents([.year, .month, .day], from: tomorrow)
                                }
                            }
                            comps.hour = finalHour
                            comps.minute = roundedMinutes >= 60 ? 0 : roundedMinutes
                            if roundedMinutes >= 60 {
                                comps.hour = (finalHour + 1) % 24
                            }
                            
                            if let start = calendar.date(from: comps) {
                                newEventStartDate = start
                                newEventEndDate = start.addingTimeInterval(90 * 60) // Pre-fill 90 minutes (e.g., 11:15 -> 12:45)
                                newEventIsWeeklyRecurring = false
                                newEventTitle = ""
                                newEventType = .school
                                editingEvent = nil
                                showingAddEvent = true
                                
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            }
                        }
                    }
                    .safeAreaInset(edge: .bottom) {
                        Color.clear.frame(height: 100)
                    }
                    .background(Color.white.opacity(0.01))
                    .cornerRadius(24)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Timeline")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: runAIScheduler) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.caption)
                            Text("AI Schedule")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(Color(hex: "00FF87"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "00FF87").opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {

                        Button(action: { showingDatePicker = true }) {
                            Image(systemName: "calendar")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(8)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        
                        Button(action: {
                            // Set initial start/end times based on selectedDate
                            let calendar = Calendar.current
                            var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
                            components.hour = 9
                            components.minute = 0
                            newEventStartDate = calendar.date(from: components) ?? Date()
                            newEventEndDate = newEventStartDate.addingTimeInterval(90 * 60)
                            showingAddEvent = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(8)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingAddEvent) {
            addEventSheet
        }
        .sheet(isPresented: $showingDatePicker) {
            NavigationStack {
                VStack {
                    DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                        .padding()
                        .tint(Color(hex: "00FF87"))
                    
                    Button("Done") {
                        showingDatePicker = false
                    }
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(hex: "00FF87"))
                    .clipShape(Capsule())
                    .padding(.bottom, 20)
                }
                .navigationTitle("Choose Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Today") {
                            selectedDate = Date()
                            showingDatePicker = false
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Close") {
                            showingDatePicker = false
                        }
                    }
                }
                .preferredColorScheme(.dark)
            }
            .presentationDetents([.medium])
        }
        .confirmationDialog("Cancel Event", isPresented: $showingDeleteConfirmation, presenting: selectedEventForDelete) { event in
            Button("Delete \"\(event.title)\"", role: .destructive) {
                deleteEvent(event)
            }
            Button("Cancel", role: .cancel) {}
        } message: { event in
            Text("Do you want to remove this event from your schedule? The AI scheduler will immediately reorganize your tasks.")
        }
    }
    
    // MARK: - Subviews
    
    private var weeklyDateSelector: some View {
        HStack(spacing: 12) {
            ForEach(weekDates, id: \.self) { date in
                let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                let dayName = date.formatted(.dateTime.weekday(.abbreviated)).uppercased()
                let dayNumber = date.formatted(.dateTime.day())
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedDate = date
                    }
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }) {
                    VStack(spacing: 6) {
                        Text(dayName)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(isSelected ? .black : .gray)
                        
                        Text(dayNumber)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(isSelected ? .black : .white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isSelected ? Color(hex: "00FF87") : Color.white.opacity(0.03))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color(hex: "00FF87") : Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private var hourGridLines: some View {
        VStack(spacing: 0) {
            ForEach(6..<26) { hour in
                HStack(alignment: .top, spacing: 16) {
                    let displayHour = hour % 24
                    Text(String(format: "%02d:00", displayHour))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.gray.opacity(0.6))
                        .frame(width: 45, alignment: .leading)
                        .offset(y: -7) // Center text vertically relative to the grid line
                    
                    VStack {
                        Divider()
                            .background(Color.white.opacity(0.08))
                    }
                    .padding(.top, 1) // Micro-align the divider with the text baseline
                }
                .frame(height: 60, alignment: .top) // Align the hour content to the top of the 60pt slot
            }
        }
    }
    
    private var eventsOverlayView: some View {
        let calendar = Calendar.current
        return GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                ForEach(filteredEvents) { event in
                    // Calculate start minutes relative to 06:00 start time
                    let startComponents = calendar.dateComponents([.hour, .minute], from: event.startDate)
                    let startHourRaw = startComponents.hour ?? 6
                    let startMinute = startComponents.minute ?? 0
                    
                    // Map early morning hours (00:00 to 05:59) to 24+ for linear rendering
                    let startHour = startHourRaw < 6 ? startHourRaw + 24 : startHourRaw
                    
                    let durationMinutes = calendar.dateComponents([.minute], from: event.startDate, to: event.endDate).minute ?? 60
                    
                    // Skip if out of bounds (before 06:00 or after 02:00 AM next day)
                    if startHour >= 6 && startHour < 26 {
                        let topOffset = CGFloat((startHour - 6) * 60 + startMinute)
                        let height = CGFloat(durationMinutes)
                        
                        eventBlock(for: event)
                            .frame(width: geometry.size.width - 70, height: height - 4)
                            .offset(x: 60, y: topOffset + 2)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func eventBlock(for event: CalendarEvent) -> some View {
        let isCancelled = event.isCancelled(on: selectedDate)
        let calendar = Calendar.current
        let durationMinutes = calendar.dateComponents([.minute], from: event.startDate, to: event.endDate).minute ?? 60
        let isCompact = durationMinutes < 60
        
        HStack(spacing: 0) {
            // Accent bar showing category or AI status
            Rectangle()
                .fill(
                    event.isAISuggested ?
                    LinearGradient(colors: [Color(hex: "8A2387"), Color(hex: "E94057")], startPoint: .top, endPoint: .bottom) :
                    LinearGradient(colors: [Color(hex: event.eventType.colorHex), Color(hex: "60EFFF")], startPoint: .top, endPoint: .bottom)
                )
                .frame(width: 4)
            
            Group {
                if isCompact {
                    // Compact Layout for short events (e.g. 45 or 30 minutes)
                    HStack(spacing: 8) {
                        HStack(spacing: 6) {
                            if !event.isAISuggested {
                                Image(systemName: event.eventType.icon)
                                    .font(.system(size: 10))
                                    .foregroundStyle(isCancelled ? .gray : Color(hex: event.eventType.colorHex))
                            }
                            
                            Text(event.title)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(isCancelled ? .gray : .white)
                                .strikethrough(isCancelled, color: .gray)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        if isCancelled {
                            Text("ENTFÄLLT")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundStyle(.gray)
                        } else {
                            Text("\(event.startDate.formatted(date: .omitted, time: .shortened))-\(event.endDate.formatted(date: .omitted, time: .shortened))")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(.gray.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                } else {
                    // Normal Layout for events >= 60 minutes
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            HStack(spacing: 6) {
                                if !event.isAISuggested {
                                    Image(systemName: event.eventType.icon)
                                        .font(.caption2)
                                        .foregroundStyle(isCancelled ? .gray : Color(hex: event.eventType.colorHex))
                                }
                                
                                Text(event.title)
                                    .font(.system(.subheadline, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundStyle(isCancelled ? .gray : .white)
                                    .strikethrough(isCancelled, color: .gray)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            if isCancelled {
                                Text("ENTFÄLLT")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.gray)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(4)
                            } else if event.isAISuggested {
                                HStack(spacing: 4) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 8))
                                    Text("AI")
                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                }
                                .foregroundStyle(Color(hex: "E94057"))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: "E94057").opacity(0.15))
                                .cornerRadius(4)
                            }
                        }
                        
                        HStack {
                            Image(systemName: "clock")
                                .font(.caption2)
                                .foregroundStyle(.gray)
                            
                            Text("\(event.startDate.formatted(date: .omitted, time: .shortened)) - \(event.endDate.formatted(date: .omitted, time: .shortened))")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundStyle(.gray)
                        }
                        
                        if event.isAISuggested {
                            HStack(spacing: 12) {
                                Button(action: { acceptAISuggestion(event) }) {
                                    Text("Accept")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.black)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 4)
                                        .background(Color(hex: "00FF87"))
                                        .cornerRadius(6)
                                }
                                
                                Button(action: { declineAISuggestion(event) }) {
                                    Text("Decline")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 4)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(6)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
            Spacer()
        }
        .opacity(isCancelled ? 0.4 : 1.0)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    isCancelled ? Color.gray.opacity(0.02) :
                    event.isAISuggested ? Color(hex: "E94057").opacity(0.04) :
                    Color(hex: event.eventType.colorHex).opacity(0.04)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isCancelled ? Color.gray.opacity(0.15) :
                    event.isAISuggested ? Color(hex: "E94057").opacity(0.2) :
                    Color(hex: event.eventType.colorHex).opacity(0.15),
                    style: StrokeStyle(lineWidth: 1, dash: (event.isAISuggested || isCancelled) ? [4, 4] : [])
                )
        )
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture {
            if !event.isAISuggested {
                editingEvent = event
                newEventTitle = event.title
                newEventType = event.eventType
                newEventStartDate = event.startDate
                newEventEndDate = event.endDate
                newEventIsWeeklyRecurring = event.isWeeklyRecurring
                isEventCancelledOnSelectedDate = event.isCancelled(on: selectedDate)
                showingAddEvent = true
                
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        }
    }
    
    // MARK: - Actions
    
    private func runAIScheduler() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        CalendarScheduler.shared.proactivelyScheduleTasks(tasks: activities, modelContext: modelContext)
    }
    
    private func requestSystemCalendarAccess() {
        Task {
            let success = await CalendarScheduler.shared.requestCalendarAccess()
            if success {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
    }
    
    private func acceptAISuggestion(_ event: CalendarEvent) {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
        
        withAnimation {
            event.isAISuggested = false
            event.isAccepted = true
            try? modelContext.save()
        }
    }
    
    private func declineAISuggestion(_ event: CalendarEvent) {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
        
        withAnimation {
            modelContext.delete(event)
            try? modelContext.save()
        }
    }
    
    // MARK: - Add Event Sheet View
    private var addEventSheet: some View {
        NavigationStack {
            Form {
                Section("Event Details") {
                    TextField("Title (e.g. Schule, Mathe LK)", text: $newEventTitle)
                        .foregroundStyle(.white)
                    
                    Picker("Event Type", selection: $newEventType) {
                        ForEach(CalendarEventType.allCases) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }
                }
                
                Section("Time Slot") {
                    DatePicker("Starts", selection: $newEventStartDate)
                    DatePicker("Ends", selection: $newEventEndDate, in: newEventStartDate...)
                }
                                Section("Recurrence") {
                    Toggle("Repeat Weekly", isOn: $newEventIsWeeklyRecurring)
                        .tint(Color(hex: "00FF87"))
                }
                if editingEvent != nil {
                    Section("Status") {
                        Toggle("Entfällt an diesem Tag", isOn: $isEventCancelledOnSelectedDate)
                            .tint(Color(hex: "FFCC00"))
                    }
                }
                if editingEvent != nil {
                    Section {
                        Button("Delete Event", role: .destructive) {
                            if let event = editingEvent {
                                deleteEvent(event)
                            }
                            showingAddEvent = false
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle(editingEvent != nil ? "Edit Event" : "Add Custom Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        showingAddEvent = false
                        editingEvent = nil
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveCustomEvent() }
                        .disabled(newEventTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
    
    private func saveCustomEvent() {
        if let event = editingEvent {
            event.title = newEventTitle
            event.eventType = newEventType
            event.startDate = newEventStartDate
            event.endDate = newEventEndDate
            event.isWeeklyRecurring = newEventIsWeeklyRecurring
            event.setCancelled(isEventCancelledOnSelectedDate, on: selectedDate)
            try? modelContext.save()
        } else {
            let newEvent = CalendarEvent(
                title: newEventTitle,
                startDate: newEventStartDate,
                endDate: newEventEndDate,
                associatedActivityID: nil,
                isAISuggested: false,
                isAccepted: true,
                eventType: newEventType,
                isWeeklyRecurring: newEventIsWeeklyRecurring
            )
            modelContext.insert(newEvent)
            try? modelContext.save()
        }
        
        showingAddEvent = false
        editingEvent = nil
        newEventTitle = ""
        newEventType = .school
        newEventIsWeeklyRecurring = false
        isEventCancelledOnSelectedDate = false
        
        // Re-run scheduling around the new custom event
        CalendarScheduler.shared.proactivelyScheduleTasks(tasks: activities, modelContext: modelContext)
    }
    
    private func deleteEvent(_ event: CalendarEvent) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        withAnimation {
            modelContext.delete(event)
            try? modelContext.save()
            
            // Re-run scheduler to fill the freed slot
            CalendarScheduler.shared.proactivelyScheduleTasks(tasks: activities, modelContext: modelContext)
        }
    }
}
