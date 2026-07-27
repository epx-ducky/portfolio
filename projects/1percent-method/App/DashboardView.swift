import SwiftUI

/// Die Hauptübersicht (Dashboard) der "1% Methode"-App.
///
/// Diese Version ist vollständig funktional verknüpft:
/// - Führt ein Onboarding (`OnboardingView`) beim ersten Start aus.
/// - Die getroffenen Auswahlen fließen direkt in die aktive Habit-Liste ein.
/// - Zinseszins-Bogen ändert seine Farbe dynamisch basierend auf der Tagesleistung:
///   * Rot (< 0,5%), Gelb (>= 0,5% und < 1,0%), Grün (>= 1,0%).
/// - Die Tasten „Statistik“ und „Neues Habit“ öffnen funktionale Bottom-Sheets.
/// - Das Tageszertifikat ist jetzt sauber in der „Statistik“ eingebettet (nicht mehr direkt auf dem Dashboard).
/// - Die Habit-Liste wird dynamisch verwaltet und berechnet den Tages-Impact in Echtzeit.
/// - Das Profil-Icon öffnet die Account-Ansicht mit dem Quest- und Medaillen-Showcase.
/// - Das Trophy-Icon oben links öffnet die Saison-Bestenliste (Leaderboard).
/// - Die Entwickler-Optionen enthalten eine Taste, um das Onboarding jederzeit zurückzusetzen.
public struct DashboardView: View {
    
    @EnvironmentObject var authService: AuthService
    
    // AppStorage zur dauerhaften Sicherung des Onboarding-Status
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    // Dynamische Liste der heutigen Gewohnheiten
    @State private var habits: [Habit] = [
        Habit(title: "Gesundes Frühstück", isCompleted: false, category: .health, targetAttribute: .gesundheit, createdAt: Date().addingTimeInterval(-8 * 24 * 3600)),
        Habit(title: "Tägliches Dehnen", isCompleted: false, category: .fitness, targetAttribute: .sportlichkeit, createdAt: Date().addingTimeInterval(-8 * 24 * 3600)),
        Habit(title: "Bildschirmzeit limitieren", isCompleted: true, category: .focus, targetAttribute: .disziplin, createdAt: Date().addingTimeInterval(-8 * 24 * 3600))
    ]
    
    // Sheet Triggers
    @State private var showNewHabitSheet = false
    @State private var showStatsSheet = false
    @State private var showProfileSheet = false
    @State private var showLeaderboardSheet = false
    @State private var selectedHabitForDetail: Habit? = nil
    @State private var showingActionLimitAlert = false
    @State private var habitToComplete: Habit? = nil
    
    // Daily Recap States
    @State private var showDailyRecap = false
    @State private var yesterdayImpact: Double = 0.0
    @State private var yesterdayScore: Double = 0.0
    @State private var yesterdayCompletedCount: Int = 0
    @State private var yesterdayTotalCount: Int = 0
    @State private var yesterdayScreentimeSeconds: Int = 0
    @State private var yesterdayAttributeChanges: [(name: String, icon: String, delta: Int)] = []
    
    // Lokale Sensor-Werte für die Entwickler-Vorschau
    @State private var stepsCount: Int = 8400
    @State private var workoutMinutes: Int = 20
    @State private var screentimeSeconds: Int = 5400
    
    public let stepsTarget: Int = 10000
    public let workoutTarget: Int = 30
    public let screentimeLimitSeconds: Int = 7200
    
    public let seasonYear: Int = 26
    public let seasonBaseline: Double = 0.0
    private let engine = ScoreEngine()
    
    public init() {}
    
    private var hasPerformedActionToday: Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayStr = formatter.string(from: Date())
        let lastActionStr = UserDefaults.standard.string(forKey: "lastActionDateString") ?? ""
        return lastActionStr == todayStr
    }
    
    // Berechnet Attribut-Deltas basierend auf erledigten Habits
    private func computeAttributeChanges(completedHabits: [Habit], screentime: Int) -> [(name: String, icon: String, delta: Int)] {
        var changes: [(name: String, icon: String, delta: Int)] = []
        
        for attr in RPGAttribute.allCases {
            let count = completedHabits.filter { $0.targetAttribute == attr }.count
            var delta = count * 10
            
            // Disziplin-Bonus
            if attr == .disziplin {
                delta += completedHabits.count * 4
            }
            
            // Achtsamkeit fällt wenn nicht trainiert
            if attr == .achtsamkeit && count == 0 {
                delta = -1
            }
            
            // Finanzen sinkt bei hoher Screentime
            if attr == .finanzen {
                if screentime >= 10800 {
                    delta = -1
                } else {
                    delta += 6
                }
            }
            
            if delta != 0 {
                changes.append((name: attr.rawValue, icon: attr.icon, delta: delta))
            }
        }
        
        return changes
    }
    
    private func saveDailyProgress() {
        let completed = habits.filter { $0.isCompleted }
        let totalCount = habits.count
        
        UserDefaults.standard.set(projectedImpact, forKey: "yesterday_projected_impact")
        UserDefaults.standard.set(currentScore, forKey: "yesterday_current_score")
        UserDefaults.standard.set(completed.count, forKey: "yesterday_completed_count")
        UserDefaults.standard.set(totalCount, forKey: "yesterday_total_count")
        UserDefaults.standard.set(screentimeSeconds, forKey: "yesterday_screentime_seconds")
        
        // Speichere welche Attribute trainiert wurden
        if let encoded = try? JSONEncoder().encode(completed) {
            UserDefaults.standard.set(encoded, forKey: "yesterday_completed_habits_data")
        }
    }
    
    private func checkDayChange() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayStr = formatter.string(from: Date())
        let lastOpenedStr = UserDefaults.standard.string(forKey: "lastOpenedDateString") ?? ""
        
        if lastOpenedStr != todayStr {
            if hasCompletedOnboarding {
                let impact = UserDefaults.standard.double(forKey: "yesterday_projected_impact")
                let score = UserDefaults.standard.double(forKey: "yesterday_current_score")
                let completedCount = UserDefaults.standard.integer(forKey: "yesterday_completed_count")
                let total = UserDefaults.standard.integer(forKey: "yesterday_total_count")
                let screentime = UserDefaults.standard.integer(forKey: "yesterday_screentime_seconds")
                
                yesterdayImpact = impact
                yesterdayScore = score
                yesterdayCompletedCount = completedCount
                yesterdayTotalCount = total
                yesterdayScreentimeSeconds = screentime == 0 ? 5400 : screentime
                
                // Lade gespeicherte Habits und berechne Attribut-Deltas
                if let data = UserDefaults.standard.data(forKey: "yesterday_completed_habits_data"),
                   let savedHabits = try? JSONDecoder().decode([Habit].self, from: data) {
                    yesterdayAttributeChanges = computeAttributeChanges(completedHabits: savedHabits, screentime: yesterdayScreentimeSeconds)
                }
                
                showDailyRecap = true
            }
            UserDefaults.standard.set(todayStr, forKey: "lastOpenedDateString")
        }
    }
    
    // Berechnet den Tagesfortschritt basierend auf den erledigten Habits (Sinking Baseline Modell)
    private var projectedImpact: Double {
        guard !habits.isEmpty else { return 0.0 }
        
        let now = Date()
        
        // Etabliert (> 7 Tage alt) und neu (<= 7 Tage alt)
        let establishedHabits = habits.filter { now.timeIntervalSince($0.createdAt) > 7 * 24 * 3600 }
        let newHabits = habits.filter { now.timeIntervalSince($0.createdAt) <= 7 * 24 * 3600 }
        
        let completedEstablishedCount = establishedHabits.filter { $0.isCompleted }.count
        
        // Graduelle Berechnung:
        // Wenn noch etablierte Habits offen sind, wächst der Wert von -1.0% hoch auf 0.0%
        if !establishedHabits.isEmpty && completedEstablishedCount < establishedHabits.count {
            let ratio = Double(completedEstablishedCount) / Double(establishedHabits.count)
            return -1.0 + (ratio * 1.0) // Geht von -1.0 bis 0.0
        }
        
        // Alle etablierten Habits sind geschafft (oder es gibt keine).
        // Jetzt bringen neue Habits den Fortschritt bis zu +1.0%
        if newHabits.isEmpty {
            return 0.0 // Haltedosis (0.0% Zuwachs), Komfortzone gesichert
        }
        
        let completedNewCount = newHabits.filter { $0.isCompleted }.count
        let newProgress = Double(completedNewCount) / Double(newHabits.count)
        
        return newProgress * 1.0 // Bis zu +1.0%
    }
    
    // Die dynamische Ringfarbe basierend auf dem aktuellen Zuwachs
    private var ringColor: Color {
        if projectedImpact < 0.0 {
            return .red
        } else if projectedImpact < 1.0 {
            return .orange
        } else {
            return .green
        }
    }
    
    private var currentScore: Double {
        if seasonBaseline == 0.0 {
            return projectedImpact
        } else {
            let factor = 1.0 + (projectedImpact / 100.0)
            return seasonBaseline * factor
        }
    }
    
    private var seasonProgress: Double {
        engine.calculateSeasonProgress(currentScore: currentScore, seasonBaseline: seasonBaseline)
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                if !hasCompletedOnboarding {
                    // --- ONBOARDING INTERFACE (ERSTER BESUCH) ---
                    OnboardingView { selectedHabits in
                        self.habits = selectedHabits
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            self.hasCompletedOnboarding = true
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
                } else {
                    // --- HAUPT INTERFACE (DASHBOARD) ---
                    ZStack {
                        LinearGradient(
                            colors: [Color(.systemBackground), Color(.systemGroupedBackground).opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                        
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 36) {
                                
                                // --- 1. DER DYNAMISCHE KREISBOGEN (FARBEN NACH IMPACT) ---
                                ZStack {
                                    // Inaktive Spur
                                    Circle()
                                        .trim(from: 0.15, to: 0.85)
                                        .stroke(
                                            Color.primary.opacity(0.03),
                                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                                        )
                                        .rotationEffect(.degrees(90))
                                        .frame(width: 230, height: 230)
                                    
                                    // Aktiver Bogen mit dynamischer Farbe
                                    let normalizedProgress = (projectedImpact + 1.0) / 2.0
                                    Circle()
                                        .trim(from: 0.15, to: 0.15 + (0.70 * normalizedProgress))
                                        .stroke(
                                            LinearGradient(
                                                colors: [ringColor.opacity(0.85), ringColor],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                                        )
                                        .rotationEffect(.degrees(90))
                                        .frame(width: 230, height: 230)
                                        .shadow(color: ringColor.opacity(0.2), radius: 8, x: 0, y: 4)
                                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: projectedImpact)
                                    
                                    // Innentext
                                    VStack(spacing: 6) {
                                        let sign = projectedImpact >= 0 ? "+" : ""
                                        Text("\(sign)\(String(format: "%.1f", projectedImpact))%")
                                            .font(.system(size: 42, weight: .bold, design: .monospaced))
                                            .foregroundColor(ringColor)
                                            .tracking(-1.0)
                                            .contentTransition(.numericText())
                                        
                                        Text("TAGES-IMPACT")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.secondary)
                                            .tracking(2.0)
                                    }
                                }
                                .padding(.top, 20)
                                
                                // --- 2. DIE SCHWEBENDEN NAVIGATION-PILLS (ZWEI-SPALTIG RESTAURIERT) ---
                                HStack(spacing: 12) {
                                    // STATISTIK BUTTON
                                    Button(action: {
                                        showStatsSheet = true
                                    }) {
                                        Text("Statistik")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.primary)
                                            .padding(.horizontal, 24)
                                            .padding(.vertical, 10)
                                            .background(.ultraThinMaterial)
                                            .cornerRadius(20)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(TactileButtonStyle())
                                    
                                    // NEUES HABIT BUTTON
                                    Button(action: {
                                        if hasPerformedActionToday {
                                            showingActionLimitAlert = true
                                        } else {
                                            showNewHabitSheet = true
                                        }
                                    }) {
                                        Text("Neues Habit")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.primary)
                                            .padding(.horizontal, 24)
                                            .padding(.vertical, 10)
                                            .background(.ultraThinMaterial)
                                            .cornerRadius(20)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(TactileButtonStyle())
                                }
                                
                                // --- 3. DYNAMISCHE GEWOHNHEITEN ---
                                VStack(spacing: 24) {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("BESTEHENDE GEWOHNHEITEN")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.secondary)
                                            .tracking(1.5)
                                            .padding(.leading, 4)
                                        
                                        if habits.isEmpty {
                                            Text("Keine Habits für heute vorhanden. Klicke auf 'Neues Habit', um eines hinzuzufügen.")
                                                .font(.system(size: 13))
                                                .foregroundColor(.secondary)
                                                .padding(.vertical, 12)
                                                .padding(.horizontal, 4)
                                        } else {
                                            VStack(spacing: 10) {
                                                ForEach(habits) { habit in
                                                    HabitRowView(
                                                        habit: habit,
                                                        onToggle: {
                                                            if let index = habits.firstIndex(where: { $0.id == habit.id }) {
                                                                if habits[index].isCompleted {
                                                                    HapticManager.shared.triggerImpact(style: .light)
                                                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                                                        habits[index].isCompleted = false
                                                                    }
                                                                    var currentLogs = AttributeLog.loadLogs()
                                                                    currentLogs.removeAll(where: { Calendar.current.isDateInToday($0.date) && $0.habitTitle == habit.title })
                                                                    AttributeLog.saveLogs(currentLogs)
                                                                    saveDailyProgress()
                                                                } else {
                                                                    habitToComplete = habits[index]
                                                                }
                                                            }
                                                        },
                                                        onTapDetail: {
                                                            selectedHabitForDetail = habit
                                                        }
                                                    )
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 32)
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .bottom))
                    ))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if hasCompletedOnboarding {
                    // Linkes Trophy-Icon (Öffnet Saison-Rangliste / Bestenliste)
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { showLeaderboardSheet = true }) {
                            Image(systemName: "trophy")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary.opacity(0.8))
                        }
                    }
                    
                    ToolbarItem(placement: .principal) {
                        Text("1% METHOD")
                            .font(.system(size: 12, weight: .bold))
                            .tracking(3.0)
                            .foregroundColor(.primary)
                    }
                    
                    // Rechtes Profil-Icon (Öffnet Profil/Account-Menü)
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showProfileSheet = true }) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.primary.opacity(0.8))
                        }
                    }
                }
            }
            .sheet(isPresented: $showNewHabitSheet) {
                NewHabitSheet { newHabit in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        habits.append(newHabit)
                        // Registriere Aktion für heute
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        UserDefaults.standard.set(formatter.string(from: Date()), forKey: "lastActionDateString")
                        saveDailyProgress()
                    }
                }
            }
            // MODALES BLATT FÜR HABIT DETAILS & LEVEL UP (MIT REAKTIVEM ITEM-BINDING GEGEN WEISSE SCREENS)
            .sheet(item: $selectedHabitForDetail) { habit in
                HabitDetailSheet(
                    habit: habit,
                    onUpgrade: { upgradedHabit in
                        if let index = habits.firstIndex(where: { $0.id == upgradedHabit.id }) {
                            habits[index] = upgradedHabit
                            saveDailyProgress()
                        }
                    }
                )
            }
            // HINWEIS BEI REICHEN DER ERSTELLUNGSGRENZE
            .alert("Aktionslimit erreicht", isPresented: $showingActionLimitAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Du kannst nur 1 Habit pro Tag erstellen oder aufwerten. Konzentriere dich erst auf deine heutigen Aufgaben!")
            }
            // STATISTIK ÖFFNEN (Datenweiterleitung für eingebettetes Zertifikat)
            .sheet(isPresented: $showStatsSheet) {
                StatsView(
                    projectedImpact: projectedImpact,
                    currentScore: currentScore,
                    completedHabits: habits.filter { $0.isCompleted },
                    totalHabitsCount: habits.count,
                    screentimeSeconds: screentimeSeconds
                )
            }
            .sheet(isPresented: $showProfileSheet) {
                ProfileView()
                    .environmentObject(authService)
            }
            // MODALES BLATT FÜR DIE BESTENLISTE (LEADERBOARD)
            .sheet(isPresented: $showLeaderboardSheet) {
                LeaderboardView(currentUserScore: currentScore)
            }
            // MODALES BLATT ZUR AKTIVITÄTSDOKUMENTATION
            .sheet(item: $habitToComplete) { habit in
                HabitCompletionSheet(habit: habit) { details in
                    if let index = habits.firstIndex(where: { $0.id == habit.id }) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                            habits[index].isCompleted = true
                        }
                        AttributeLog.addLog(attribute: habit.targetAttribute, habitTitle: habit.title, details: details)
                        HapticManager.shared.triggerImpact(style: .medium)
                        saveDailyProgress()
                    }
                }
            }
            // AUTOMATISCHER TAGESBERICHT BEI TAGESWECHSEL
            .sheet(isPresented: $showDailyRecap) {
                DailyRecapView(
                    projectedImpact: yesterdayImpact,
                    currentScore: yesterdayScore,
                    completedHabitsCount: yesterdayCompletedCount,
                    totalHabitsCount: yesterdayTotalCount,
                    screentimeSeconds: yesterdayScreentimeSeconds,
                    attributeChanges: yesterdayAttributeChanges
                )
            }
            .onAppear {
                checkDayChange()
                NotificationManager.shared.requestPermission()
                saveDailyProgress()
            }
        }
    }
    
    private func formatSeconds(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

/// Eine überarbeitete Habit-Zeile im nativen iOS 17 Design.
struct HabitRowView: View {
    let habit: Habit
    let onToggle: () -> Void
    let onTapDetail: () -> Void
    
    private var categoryColor: Color {
        switch habit.category {
        case .fitness: return .orange
        case .health: return .blue
        case .focus: return .purple
        case .custom: return .secondary
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Linker Teil: Antippbar für Details
            Button(action: onTapDetail) {
                HStack(spacing: 12) {
                    Image(systemName: habit.category.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(habit.isCompleted ? .secondary : categoryColor)
                        .frame(width: 28, height: 28)
                        .background(habit.isCompleted ? Color.primary.opacity(0.04) : categoryColor.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(habit.title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(habit.isCompleted ? .secondary : .primary)
                                .strikethrough(habit.isCompleted, color: .secondary.opacity(0.4))
                            
                            // Level Badge
                            Text("Lvl. \(habit.level)")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(habit.isCompleted ? .secondary.opacity(0.6) : .red)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(habit.isCompleted ? Color.primary.opacity(0.03) : Color.red.opacity(0.08))
                                .cornerRadius(6)
                        }
                        
                        // Attribut-Untertitel
                        HStack(spacing: 4) {
                            Image(systemName: habit.targetAttribute.icon)
                                .font(.system(size: 8))
                            Text(habit.targetAttribute.rawValue)
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Rechter Teil: Das Checkmark zum Erledigen
            Button(action: onToggle) {
                Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(habit.isCompleted ? .green : .secondary.opacity(0.3))
                    .contentTransition(.symbolEffect(.replace))
                    .padding(.leading, 8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(habit.isCompleted ? Color.green.opacity(0.1) : Color.primary.opacity(0.04), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(habit.isCompleted ? 0.0 : 0.01), radius: 5, x: 0, y: 3)
    }
}
