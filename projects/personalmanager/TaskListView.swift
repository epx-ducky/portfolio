import SwiftUI
import SwiftData
import PhotosUI

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Activity.dueDate) private var tasks: [Activity]
    @Query private var scores: [DopamineScore]
    @Query(sort: \TaskCompletionRecord.timestamp) private var completionRecords: [TaskCompletionRecord]
    
    @State private var showingAddTask = false
    @State private var newTaskName = ""
    @State private var newTaskCategory: ActivityCategory = .learning
    @State private var newTaskDuration = 60
    @State private var newTaskPoints = 0.15 // Default 15%
    @State private var acceptedQuestDate = UserDefaults.standard.string(forKey: "acceptedQuestDate") ?? ""
    @State private var showingWorkoutPlans = false
    @State private var showingHistory = false
    @State private var selectedHistoryDate = Date()
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    @State private var newTaskRecurrence: ActivityRecurrence = .none
    @State private var newTaskHasScheduledDate = false
    @State private var newTaskScheduledDate = Date()
    
    // Edit task states
    @State private var editingTask: Activity? = nil
    @State private var editName = ""
    @State private var editCategory: ActivityCategory = .learning
    @State private var editDuration = 60
    @State private var editPoints = 0.15
    @State private var editPhotoItem: PhotosPickerItem? = nil
    @State private var editImageData: Data? = nil
    @State private var editRecurrence: ActivityRecurrence = .none
    @State private var editHasScheduledDate = false
    @State private var editScheduledDate = Date()
    
    private var dopamineScore: DopamineScore {
        if let existing = scores.first {
            existing.resetIfNewDay(context: modelContext)
            return existing
        } else {
            let newScore = DopamineScore(currentPercentage: 0.20, dailyResetTimestamp: Date())
            modelContext.insert(newScore)
            try? modelContext.save()
            return newScore
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Premium dark background
                Color(red: 10/255, green: 10/255, blue: 18/255)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    let todayString = formattedTodayString()
                    if acceptedQuestDate != todayString {
                        dailyQuestCard
                            .padding(.horizontal)
                            .padding(.top, 16)
                    }
                    
                    // Task Summary Card
                    taskSummaryCard
                        .padding()
                    
                    // Task Checklist
                    if tasks.isEmpty {
                        emptyStateView
                    } else {
                        List {
                            ForEach(tasks) { task in
                                taskRow(task)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            }
                            .onDelete(perform: deleteTasks)
                        }
                        .listStyle(.plain)
                        .background(Color.clear)
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 100)
                }
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { showingWorkoutPlans = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "figure.run")
                                .font(.system(size: 11, weight: .bold))
                            Text("Workouts")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 8) {
                        Button(action: { showingHistory = true }) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(8)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        
                        Button(action: { showingAddTask = true }) {
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
            .sheet(isPresented: $showingAddTask) {
                addTaskSheet
            }
            .sheet(isPresented: $showingWorkoutPlans) {
                workoutPlansSheet
            }
            .sheet(isPresented: $showingHistory) {
                historySheet
            }
            .sheet(item: $editingTask) { task in
                editTaskSheet(for: task)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Subviews
    
    private var taskSummaryCard: some View {
        HStack {
            let completedCount = tasks.filter { $0.isCompletedToday }.count
            let totalCount = tasks.count
            
            VStack(alignment: .leading, spacing: 6) {
                Text("TODAY'S TASKS")
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundStyle(.gray)
                    .tracking(1.5)
                
                Text("\(completedCount) of \(totalCount) Completed")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            
            Spacer()
            
            // Minimal progress bar inside card
            CircularCardProgress(progress: totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0.0)
                .frame(width: 48, height: 48)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checklist")
                .font(.system(size: 64))
                .foregroundStyle(LinearGradient(colors: [Color(hex: "00FF87"), Color(hex: "60EFFF")], startPoint: .top, endPoint: .bottom))
                .opacity(0.8)
            
            Text("Clear Mind, Empty List")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.white)
            
            Text("Add tasks you want to accomplish today.\nEach task boosts your dopamine & unlocks shields.")
                .font(.caption)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: { showingAddTask = true }) {
                Text("Create First Task")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(hex: "00FF87"))
                    .cornerRadius(24)
            }
            Spacer()
        }
    }
    
    private func taskRow(_ task: Activity) -> some View {
        HStack(spacing: 16) {
            // Interactive custom checkbox
            Button(action: { toggleTaskCompletion(task) }) {
                ZStack {
                    Circle()
                        .stroke(task.isCompletedToday ? Color(hex: "00FF87") : Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 26, height: 26)
                        .background(
                            Circle()
                                .fill(task.isCompletedToday ? Color(hex: "00FF87") : Color.clear)
                        )
                    
                    if task.isCompletedToday {
                        Image(systemName: "check")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.black)
                    }
                }
            }
            .buttonStyle(.plain)
            
            // Tapping the card opens the edit sheet
            Button(action: { editingTask = task }) {
                HStack(spacing: 12) {
                    // Image Attachment Thumbnail
                    if let data = task.imageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.12), lineWidth: 1))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.name)
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundStyle(task.isCompletedToday ? .gray : .white)
                            .strikethrough(task.isCompletedToday, color: .gray)
                            .multilineTextAlignment(.leading)
                        
                        HStack(spacing: 8) {
                            // Category Badge
                            HStack(spacing: 4) {
                                Image(systemName: task.category.icon)
                                    .font(.system(size: 8))
                                Text(task.category.rawValue)
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                            }
                            .foregroundStyle(categoryColor(task.category))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(categoryColor(task.category).opacity(0.12))
                            .cornerRadius(4)
                            
                            // Duration
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 8))
                                Text("\(task.durationMinutes)m")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                            }
                            .foregroundStyle(.gray)
                            
                            // Recurrence Badge if not none
                            if task.recurrence != .none {
                                HStack(spacing: 4) {
                                    Image(systemName: task.recurrence == .daily ? "arrow.3.trianglepath" : "calendar")
                                        .font(.system(size: 8))
                                    Text(task.recurrence.rawValue)
                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                }
                                .foregroundStyle(.gray)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(4)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Reward indicator
                    Text("+\(Int(task.dopaminePoints * 100))%")
                        .font(.system(.subheadline, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundStyle(task.isCompletedToday ? .gray : Color(hex: "00FF87"))
                }
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.02))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(task.isCompletedToday ? Color(hex: "00FF87").opacity(0.1) : Color.white.opacity(0.06), lineWidth: 1)
        )
    }
    
    private var addTaskSheet: some View {
        NavigationStack {
            Form {
                Section("Task details") {
                    TextField("Enter task name...", text: $newTaskName)
                        .foregroundStyle(.white)
                    
                    Picker("Category", selection: $newTaskCategory) {
                        ForEach(ActivityCategory.allCases) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                }
                
                Section("Einstellungen") {
                    Picker("Wiederholung", selection: $newTaskRecurrence) {
                        ForEach(ActivityRecurrence.allCases) { rec in
                            Text(rec.rawValue).tag(rec)
                        }
                    }
                    
                    Stepper("Duration: \(newTaskDuration) minutes", value: $newTaskDuration, in: 15...180, step: 15)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Dopamine Reward:")
                            Spacer()
                            Text("\(Int(newTaskPoints * 100))%")
                                .fontWeight(.bold)
                                .foregroundStyle(Color(hex: "00FF87"))
                        }
                        Slider(value: $newTaskPoints, in: 0.05...0.40, step: 0.05)
                            .tint(Color(hex: "00FF87"))
                    }
                }
                
                Section("Termin einplanen") {
                    Toggle("Uhrzeit festlegen", isOn: $newTaskHasScheduledDate)
                        .tint(Color(hex: "00FF87"))
                    
                    if newTaskHasScheduledDate {
                        DatePicker("Uhrzeit", selection: $newTaskScheduledDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                    }
                }
                
                Section("Bild hinzufügen (Optional)") {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack {
                            Image(systemName: "photo.badge.plus")
                            Text(selectedImageData == nil ? "Foto auswählen" : "Foto ändern")
                        }
                    }
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                selectedImageData = data
                            }
                        }
                    }
                    
                    if let data = selectedImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 120)
                            .cornerRadius(12)
                            .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showingAddTask = false }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveNewTask() }
                        .disabled(newTaskName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
    
    // MARK: - Helper Methods
    
    private func toggleTaskCompletion(_ task: Activity) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            task.isCompletedToday.toggle()
            
            if task.isCompletedToday {
                task.completedDate = Date()
                
                // Add a permanent completion record
                let record = TaskCompletionRecord(
                    taskName: task.name,
                    timestamp: Date(),
                    category: task.category,
                    durationMinutes: task.durationMinutes,
                    dopaminePoints: task.dopaminePoints,
                    imageData: task.imageData
                )
                modelContext.insert(record)
                
                // Add points
                dopamineScore.addPoints(task.dopaminePoints, activityName: task.name, context: modelContext)
                
                // Award consistency XP
                dopamineScore.consistencyXP = (dopamineScore.consistencyXP ?? 0) + 10
            } else {
                task.completedDate = nil
                
                // Remove completion record for this task today
                let calendar = Calendar.current
                let today = Date()
                if let records = try? modelContext.fetch(FetchDescriptor<TaskCompletionRecord>()) {
                    let todayRecord = records.first { record in
                        record.taskName == task.name && calendar.isDate(record.timestamp, inSameDayAs: today)
                    }
                    if let recordToDelete = todayRecord {
                        modelContext.delete(recordToDelete)
                    }
                }
                
                // Subtract points if unchecked
                let oldVal = dopamineScore.currentPercentage
                dopamineScore.currentPercentage = max(0.20, oldVal - task.dopaminePoints)
                
                // Remove the corresponding gain from database if found
                if let index = dopamineScore.gains.firstIndex(where: { $0.activityName == task.name }) {
                    modelContext.delete(dopamineScore.gains[index])
                }
                
                // Deduct consistency XP
                dopamineScore.consistencyXP = max(0, (dopamineScore.consistencyXP ?? 0) - 10)
            }
            
            try? modelContext.save()
        }
    }
    
    private func saveNewTask() {
        let newTask = Activity(
            name: newTaskName,
            dopaminePoints: newTaskPoints,
            isCompletedToday: false,
            category: newTaskCategory,
            dueDate: Date(),
            durationMinutes: newTaskDuration,
            imageData: selectedImageData,
            recurrence: newTaskRecurrence,
            scheduledDate: newTaskHasScheduledDate ? newTaskScheduledDate : nil
        )
        
        modelContext.insert(newTask)
        try? modelContext.save()
        
        // Reset sheet variables and dismiss
        newTaskName = ""
        newTaskCategory = .learning
        newTaskDuration = 60
        newTaskPoints = 0.15
        selectedPhotoItem = nil
        selectedImageData = nil
        newTaskRecurrence = .none
        newTaskHasScheduledDate = false
        newTaskScheduledDate = Date()
        showingAddTask = false
        
        // Proactively scan and schedule the new task in the calendar timeline
        CalendarScheduler.shared.proactivelyScheduleTasks(tasks: tasks, modelContext: modelContext)
    }
    
    private func deleteTasks(at offsets: IndexSet) {
        for index in offsets {
            let task = tasks[index]
            modelContext.delete(task)
        }
        try? modelContext.save()
        
        // Recalculate schedule
        CalendarScheduler.shared.proactivelyScheduleTasks(tasks: tasks, modelContext: modelContext)
    }
    
    private func categoryColor(_ category: ActivityCategory) -> Color {
        switch category {
        case .startup: return Color(hex: "8A2387")
        case .workout: return Color(hex: "F27121")
        case .learning: return Color(hex: "00FF87")
        case .social: return Color(hex: "60EFFF")
        }
    }
    
    // MARK: - Daily Quest System
    
    private func formattedTodayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private func dailyQuestForToday() -> (name: String, category: ActivityCategory, points: Double, duration: Int) {
        let quests: [(String, ActivityCategory, Double, Int)] = [
            ("30s FPV Clip schneiden", .startup, 0.25, 45),
            ("Lean Startup Business Plan entwerfen", .startup, 0.25, 60),
            ("Volleyball: 20 Min. Annahme gegen Wand üben", .workout, 0.25, 30),
            ("FPV Simulator: 3 Akkus Freestyle fliegen", .learning, 0.20, 30),
            ("High-Intensity Core Workout durchziehen", .workout, 0.25, 45),
            
            ("Neues Video-Schnitt-Tutorial ausprobieren", .learning, 0.20, 45),
            ("3 Problem-Lösungen für Startup aufschreiben", .startup, 0.25, 30),
            ("Volleyball: Beintraining für Sprungkraft", .workout, 0.25, 40),
            ("FPV Drohne: Hardware-Check & Reinigung", .startup, 0.20, 30),
            ("Dehn- und Stretch-Session (Flexibilität)", .workout, 0.20, 20),
            
            ("Video Farbkorrektur (Color Grading) üben", .startup, 0.20, 45),
            ("Marketing-Analyse von Unicorn-Startups lesen", .learning, 0.25, 45),
            ("Volleyball Profi-Matches (15 Min.) analysieren", .learning, 0.20, 20),
            ("FPV Simulator: Slalom & Loopings üben", .learning, 0.25, 30),
            ("Liegestütze & Plank Max-Out Challenge", .workout, 0.25, 20)
        ]
        
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let index = dayOfYear % quests.count
        return (quests[index].0, quests[index].1, quests[index].2, quests[index].3)
    }
    
    private var dailyQuestCard: some View {
        let quest = dailyQuestForToday()
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(LinearGradient(colors: [Color(hex: "FFD700"), Color(hex: "FFA500")], startPoint: .top, endPoint: .bottom))
                    Text("DAILY QUEST")
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .tracking(1.5)
                }
                
                Spacer()
                
                Text("+\(Int(quest.points * 100))% Dopamin")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: "00FF87"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: "00FF87").opacity(0.12))
                    .cornerRadius(6)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(quest.name)
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Text("Besondere Tagesaufgabe basierend auf deinen Hobbys.")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            
            Button(action: { acceptDailyQuest(quest) }) {
                HStack {
                    Spacer()
                    Image(systemName: "plus.circle.fill")
                    Text("Quest annehmen")
                        .fontWeight(.bold)
                    Spacer()
                }
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.black)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(colors: [Color(hex: "00FF87"), Color(hex: "60EFFF")], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(colors: [Color(hex: "00FF87").opacity(0.2), Color(hex: "60EFFF").opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1
                        )
                )
        )
    }
    
    private func acceptDailyQuest(_ quest: (name: String, category: ActivityCategory, points: Double, duration: Int)) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        let newQuestActivity = Activity(
            name: "Quest: \(quest.name)",
            dopaminePoints: quest.points,
            isCompletedToday: false,
            category: quest.category,
            dueDate: Date(),
            durationMinutes: quest.duration
        )
        
        modelContext.insert(newQuestActivity)
        try? modelContext.save()
        
        let todayString = formattedTodayString()
        UserDefaults.standard.set(todayString, forKey: "acceptedQuestDate")
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            acceptedQuestDate = todayString
        }
        
        // Re-schedule focus blocks to map the new workout task on calendar
        CalendarScheduler.shared.proactivelyScheduleTasks(tasks: tasks, modelContext: modelContext)
    }
    
    private func editTaskSheet(for task: Activity) -> some View {
        NavigationStack {
            Form {
                Section("Aufgabe bearbeiten") {
                    TextField("Aufgabenname...", text: $editName)
                        .foregroundStyle(.white)
                    
                    Picker("Kategorie", selection: $editCategory) {
                        ForEach(ActivityCategory.allCases) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                }
                
                Section("Einstellungen") {
                    Picker("Wiederholung", selection: $editRecurrence) {
                        ForEach(ActivityRecurrence.allCases) { rec in
                            Text(rec.rawValue).tag(rec)
                        }
                    }
                    
                    Stepper("Dauer: \(editDuration) Minuten", value: $editDuration, in: 15...180, step: 15)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Dopamin-Belohnung:")
                            Spacer()
                            Text("\(Int(editPoints * 100))%")
                                .fontWeight(.bold)
                                .foregroundStyle(Color(hex: "00FF87"))
                        }
                        Slider(value: $editPoints, in: 0.05...0.40, step: 0.05)
                            .tint(Color(hex: "00FF87"))
                    }
                }
                
                Section("Bild / Anhang") {
                    PhotosPicker(selection: $editPhotoItem, matching: .images) {
                        HStack {
                            Image(systemName: "photo.badge.plus")
                            Text(editImageData == nil ? "Foto auswählen" : "Foto ändern")
                        }
                    }
                    .onChange(of: editPhotoItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                editImageData = data
                            }
                        }
                    }
                    
                    if let data = editImageData, let uiImage = UIImage(data: data) {
                        VStack(spacing: 8) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 120)
                                .cornerRadius(12)
                                .padding(.vertical, 4)
                            
                            Button(role: .destructive, action: {
                                editPhotoItem = nil
                                editImageData = nil
                            }) {
                                Text("Bild entfernen")
                                    .font(.caption)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                }
                
                Section("Termin einplanen") {
                    Toggle("Uhrzeit festlegen", isOn: $editHasScheduledDate)
                        .tint(Color(hex: "00FF87"))
                    
                    if editHasScheduledDate {
                        DatePicker("Uhrzeit", selection: $editScheduledDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                    }
                }
            }
            .navigationTitle("Aufgabe bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") { editingTask = nil }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Speichern") {
                        task.name = editName
                        task.category = editCategory
                        task.durationMinutes = editDuration
                        task.dopaminePoints = editPoints
                        task.imageData = editImageData
                        task.recurrence = editRecurrence
                        task.scheduledDate = editHasScheduledDate ? editScheduledDate : nil
                        
                        // If they uncheck scheduled time, delete the associated CalendarEvent so it can be auto-scheduled
                        if !editHasScheduledDate {
                            let assocId = task.id
                            if let events = try? modelContext.fetch(FetchDescriptor<CalendarEvent>()) {
                                let eventsToDelete = events.filter { $0.associatedActivityID == assocId }
                                for ev in eventsToDelete {
                                    modelContext.delete(ev)
                                }
                            }
                        }
                        
                        try? modelContext.save()
                        
                        editingTask = nil
                        
                        // Re-run scheduler
                        CalendarScheduler.shared.proactivelyScheduleTasks(tasks: tasks, modelContext: modelContext)
                    }
                    .disabled(editName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                editName = task.name
                editCategory = task.category
                editDuration = task.durationMinutes
                editPoints = task.dopaminePoints
                editImageData = task.imageData
                editRecurrence = task.recurrence
                
                if let sched = task.scheduledDate {
                    editHasScheduledDate = true
                    editScheduledDate = sched
                } else {
                    editHasScheduledDate = false
                    editScheduledDate = Date()
                }
            }
            .preferredColorScheme(.dark)
        }
    }
    
    private var historySheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Graphical DatePicker Calendar
                DatePicker("Verlaufsauswahl", selection: $selectedHistoryDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(Color(hex: "00FF87"))
                    .padding()
                
                let dayString = DateFormatter.localizedString(from: selectedHistoryDate, dateStyle: .long, timeStyle: .none)
                HStack {
                    Text("ERLEDIGT AM \(dayString.uppercased())")
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundStyle(.gray)
                        .tracking(1.5)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                let calendar = Calendar.current
                let completedOnDate = completionRecords.filter { record in
                    calendar.isDate(record.timestamp, inSameDayAs: selectedHistoryDate)
                }
                
                if completedOnDate.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "checkmark.circle.badge.questionmark")
                            .font(.largeTitle)
                            .foregroundStyle(.gray.opacity(0.5))
                        Text("Keine Aufgaben an diesem Tag erledigt.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.gray)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(completedOnDate) { record in
                            HStack(spacing: 12) {
                                if let data = record.imageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 36, height: 36)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.12), lineWidth: 1))
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color(hex: "00FF87"))
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(record.taskName)
                                        .font(.system(.subheadline, design: .rounded))
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                    
                                    HStack(spacing: 8) {
                                        Text(record.category.rawValue)
                                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                                            .foregroundStyle(.gray)
                                        Text("\(record.durationMinutes)m")
                                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                                            .foregroundStyle(.gray)
                                    }
                                }
                                
                                Spacer()
                                
                                Text("+\(Int(record.dopaminePoints * 100))%")
                                    .font(.system(.caption, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color(hex: "00FF87"))
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.visible, edges: .bottom)
                        }
                    }
                    .listStyle(.plain)
                    .background(Color.clear)
                }
            }
            .navigationTitle("Aufgaben-Verlauf")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Schließen") { showingHistory = false }
                }
            }
            .preferredColorScheme(.dark)
        }
    }
    
    // MARK: - Workout Plans System
    
    private var workoutPlansSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    workoutCard(
                        title: "Volleyball Sprungkraft",
                        description: "Fokus auf Explosivität und vertikale Sprunghöhe für schlagkräftige Angriffe.",
                        duration: 40,
                        points: 0.25,
                        icon: "arrow.up.circle.fill",
                        color: "F27121",
                        exercises: [
                            "3x10 Squat Jumps (Explosiv)",
                            "3x15 Calf Raises (Wadenheben)",
                            "3x8 Depth Jumps (Tiefsprünge)",
                            "3x12 Lunges (Ausfallschritte)"
                        ]
                    )
                    
                    workoutCard(
                        title: "Core & Rumpfstabilität",
                        description: "Starke Rumpfmuskulatur für FPV-Fliegen und Stabilität am Volleyball-Netz.",
                        duration: 30,
                        points: 0.20,
                        icon: "shield.fill",
                        color: "00FF87",
                        exercises: [
                            "3x 60s Unterarmstütz (Plank)",
                            "3x15 Russian Twists (Rumpfdrehen)",
                            "3x12 Superman (Unterer Rücken)",
                            "3x15 Leg Raises (Beinheben)"
                        ]
                    )
                    
                    workoutCard(
                        title: "Oberkörper Kraft",
                        description: "Klassisches Bodyweight-Training für starke Arme, Brust und Schultern.",
                        duration: 45,
                        points: 0.25,
                        icon: "bolt.fill",
                        color: "60EFFF",
                        exercises: [
                            "4x12 Pushups (Liegestütze)",
                            "3x8 Pullups (Klimmzüge)",
                            "3x15 Dips (Trizepsbeugen)",
                            "3x12 Diamond Pushups"
                        ]
                    )
                }
                .padding()
            }
            .navigationTitle("Trainingspläne")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Schließen") { showingWorkoutPlans = false }
                }
            }
            .preferredColorScheme(.dark)
        }
    }
    
    private func workoutCard(title: String, description: String, duration: Int, points: Double, icon: String, color: String, exercises: [String]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundStyle(Color(hex: color))
                    Text(title)
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                Text("+\(Int(points * 100))% Dopamin")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: color))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: color).opacity(0.12))
                    .cornerRadius(6)
            }
            
            Text(description)
                .font(.caption)
                .foregroundStyle(.gray)
            
            VStack(alignment: .leading, spacing: 6) {
                ForEach(exercises, id: \.self) { ex in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(hex: color).opacity(0.6))
                            .frame(width: 4, height: 4)
                        Text(ex)
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
            }
            .padding(.leading, 4)
            
            Button(action: { addWorkoutToTasks(title: title, duration: duration, points: points) }) {
                HStack {
                    Spacer()
                    Image(systemName: "plus.circle.fill")
                    Text("Workout als Aufgabe hinzufügen")
                        .fontWeight(.bold)
                    Spacer()
                }
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.black)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(colors: [Color(hex: color), Color(hex: "60EFFF")], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    private func addWorkoutToTasks(title: String, duration: Int, points: Double) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        let newWorkoutTask = Activity(
            name: "Workout: \(title)",
            dopaminePoints: points,
            isCompletedToday: false,
            category: .workout,
            dueDate: Date(),
            durationMinutes: duration
        )
        
        modelContext.insert(newWorkoutTask)
        try? modelContext.save()
        
        showingWorkoutPlans = false
        
        // Re-run scheduler to map the new workout task on calendar
        CalendarScheduler.shared.proactivelyScheduleTasks(tasks: tasks, modelContext: modelContext)
    }
}

// MARK: - Mini Circular Progress Helper
struct CircularCardProgress: View {
    var progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.04), lineWidth: 6)
            
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    LinearGradient(colors: [Color(hex: "00FF87"), Color(hex: "60EFFF")], startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
    }
}
