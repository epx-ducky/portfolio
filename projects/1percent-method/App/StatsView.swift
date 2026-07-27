import SwiftUI

/// Die Statistik-Ansicht der App als Bottom-Sheet.
///
/// Komplett überarbeitet nach deinen Skizzen:
/// - Segmentierte Auswahl: Tag, Woche, Monat, Gesamt.
/// - Zwei Kreise: linker Kreis für %-Zuwachs, rechter Kreis für Bildschirmzeit.
/// - Bildschirmzeit mit Ampel-Indikator (Gut / Mittel / Schlecht).
/// - Zinseszins-Kurve: Wird NUR in Woche/Monat/Gesamt angezeigt, NICHT in der Tagesansicht!
/// - Attribute-Raster: Die 8 RPG-Attribute mit Wert und farbigen Up/Down-Tendenzen.
/// - Button zum Aufrufen des offiziellen Tageszertifikats am Fuß der Ansicht.
public struct StatsView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    // Datenübergabe vom Dashboard
    let projectedImpact: Double
    let currentScore: Double
    let completedHabits: [Habit]
    let totalHabitsCount: Int
    let screentimeSeconds: Int
    
    @State private var selectedRange = 0 // 0: Tag, 1: Woche, 2: Monat, 3: Gesamt
    @State private var showCertificateSheet = false
    @State private var selectedAttributeForLogs: RPGAttribute? = nil
    
    public init(
        projectedImpact: Double,
        currentScore: Double,
        completedHabits: [Habit],
        totalHabitsCount: Int,
        screentimeSeconds: Int
    ) {
        self.projectedImpact = projectedImpact
        self.currentScore = currentScore
        self.completedHabits = completedHabits
        self.totalHabitsCount = totalHabitsCount
        self.screentimeSeconds = screentimeSeconds
    }
    
    // Berechnet die Werte für die Doppelkreise je nach gewähltem Bereich
    private var rangePercentString: String {
        switch selectedRange {
        case 0: // Tag
            let sign = projectedImpact >= 0 ? "+" : ""
            return "\(sign)\(String(format: "%.1f", projectedImpact))%"
        case 1: // Woche
            return "+6.2%"
        case 2: // Monat
            return "+24.8%"
        default: // Gesamt
            return "+142.3%"
        }
    }
    
    private var rangeScreentimeString: String {
        switch selectedRange {
        case 0: // Tag
            return formatSeconds(screentimeSeconds)
        case 1: // Woche
            return "2h 36m"
        case 2: // Monat
            return "3h 12m"
        default: // Gesamt
            return "2h 55m"
        }
    }
    
    private var isScreentimeGoodForRange: Bool {
        switch selectedRange {
        case 0:
            return screentimeSeconds < 7200
        case 1:
            return true // 2h 36m ist gut (unter 3h)
        case 2:
            return false // 3h 12m ist mittel/schlecht
        default:
            return true
        }
    }
    
    // Verlaufskurve-Punkte je nach Zinseszins (Tagesansicht blendet den Graph aus)
    private var historyDataForRange: [Double] {
        if selectedRange == 0 {
            return []
        }
        // Da es sich um ein neues Konto handelt (Start bei 0.0%), zeichnen wir den Verlauf vom Start (0.0%) bis zum heutigen Score
        return [0.0, currentScore]
    }
    
    // Berechnet dynamisch die RPG-Attribute (Startwert 50) basierend auf deinen historischen Logs
    private func getAttributeStatus(for attribute: RPGAttribute) -> (value: Int, isUp: Bool) {
        let allLogs = AttributeLog.loadLogs()
        var score = 50
        
        let count = allLogs.filter { log in
            log.attribute == attribute || 
            (attribute == .geschicklichkeit && log.attribute == .sportlichkeit && log.details.contains("Normaler Sport:"))
        }.count
        
        score += count * 5
        
        // Ist der Trend steigend? (Habit heute erledigt?)
        let countToday = completedHabits.filter { $0.targetAttribute == attribute }.count
        var isUp = countToday > 0
        
        if attribute == .geschicklichkeit {
            isUp = isUp || completedHabits.contains(where: { $0.targetAttribute == .sportlichkeit && $0.isCompleted })
        }
        
        return (score, isUp)
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // --- 1. ZEITRAUM SELEKTOR (Tag, Woche, Monat, Gesamt) ---
                        Picker("Zeitraum", selection: $selectedRange) {
                            Text("Tag").tag(0)
                            Text("Woche").tag(1)
                            Text("Monat").tag(2)
                            Text("Gesamt").tag(3)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 4)
                        
                        // --- 2. DOPPELKREIS METRIKEN ---
                        HStack(spacing: 24) {
                            // Linker Kreis: %-Zuwachs
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.primary.opacity(0.04), lineWidth: 6)
                                        .frame(width: 95, height: 95)
                                    
                                    Circle()
                                        .trim(from: 0, to: 0.8)
                                        .stroke(
                                            LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom),
                                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                                        )
                                        .frame(width: 95, height: 95)
                                        .rotationEffect(.degrees(-90))
                                    
                                    Text(rangePercentString)
                                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                                        .foregroundColor(.primary)
                                }
                                
                                Text("%-Zuwachs")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                            
                            // Rechter Kreis: Bildschirmzeit
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.primary.opacity(0.04), lineWidth: 6)
                                        .frame(width: 95, height: 95)
                                    
                                    Circle()
                                        .trim(from: 0, to: 0.65)
                                        .stroke(
                                            isScreentimeGoodForRange ? Color.green : Color.red,
                                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                                        )
                                        .frame(width: 95, height: 95)
                                        .rotationEffect(.degrees(-90))
                                    
                                    VStack(spacing: 2) {
                                        Text(rangeScreentimeString)
                                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                                            .foregroundColor(.primary)
                                        
                                        // Kleiner Richtungs-Indikator im Kreis
                                        Image(systemName: isScreentimeGoodForRange ? "arrow.down.forward.and.arrow.up.backward.circle.fill" : "exclamationmark.circle.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(isScreentimeGoodForRange ? .green : .red)
                                    }
                                }
                                
                                Text("Bildschirmzeit")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 10)
                        
                        // --- 3. DYNAMISCHE VERLAUFSKURVE (AUSGEBLENDET IN TAGESANSICHT) ---
                        if selectedRange > 0 {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("ZINSESZINS VERLAUF")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .tracking(1.5)
                                    .padding(.leading, 4)
                                
                                VStack(spacing: 0) {
                                    TypewriterChartView(points: historyDataForRange)
                                        .frame(height: 150)
                                        .padding(.top, 20)
                                        .padding(.horizontal, 16)
                                        .padding(.bottom, 16)
                                    
                                    Divider()
                                    
                                    HStack {
                                        Text("Start (0%)")
                                        Spacer()
                                        Text("Heute")
                                    }
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                }
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(24)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                                )
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        // --- 4. RPG ATTRIBUTE (UNTER ABSCHNITT 'ATTRIBUTES') ---
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ATTRIBUTES")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                                .tracking(1.5)
                                .padding(.leading, 4)
                            
                             LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                                 ForEach(RPGAttribute.allCases) { attribute in
                                     let status = getAttributeStatus(for: attribute)
                                     
                                     Button(action: {
                                         HapticManager.shared.triggerImpact(style: .light)
                                         selectedAttributeForLogs = attribute
                                     }) {
                                         HStack(spacing: 6) {
                                             // Attribut-Icon
                                             Image(systemName: attribute.icon)
                                                 .font(.system(size: 13, weight: .bold))
                                                 .foregroundColor(status.isUp ? .green : .red)
                                                 .frame(width: 28, height: 28)
                                                 .background(status.isUp ? Color.green.opacity(0.08) : Color.red.opacity(0.08))
                                                 .clipShape(RoundedRectangle(cornerRadius: 8))
                                             
                                             VStack(alignment: .leading, spacing: 2) {
                                                 Text(attribute.rawValue)
                                                     .font(.system(size: 11, weight: .bold))
                                                     .foregroundColor(.secondary)
                                                     .lineLimit(1)
                                                     .minimumScaleFactor(0.65)
                                                 
                                                 HStack(alignment: .lastTextBaseline, spacing: 2) {
                                                     Text("\(status.value)")
                                                         .font(.system(size: 15, weight: .bold, design: .monospaced))
                                                         .foregroundColor(.primary)
                                                     
                                                     Text(status.isUp ? "↑" : "↓")
                                                         .font(.system(size: 11, weight: .bold))
                                                         .foregroundColor(status.isUp ? .green : .red)
                                                 }
                                             }
                                             Spacer(minLength: 2)
                                         }
                                         .padding(.horizontal, 10)
                                         .padding(.vertical, 10)
                                         .background(Color(.secondarySystemGroupedBackground))
                                         .cornerRadius(18)
                                         .overlay(
                                             RoundedRectangle(cornerRadius: 18)
                                                 .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                                         )
                                     }
                                     .buttonStyle(PlainButtonStyle())
                                 }
                             }
                        }
                        
                        // --- 5. TAGESBERICHT BUTTON ---
                        Button(action: {
                            showCertificateSheet = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "doc.text.fill")
                                Text("Gestrigen Tagesbericht ansehen")
                            }
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(.systemBackground))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.primary)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
                        }
                        .buttonStyle(TactileButtonStyle())
                        .padding(.top, 8)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Leistungsstatistik")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Schließen") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                }
            }
            // Modales Blatt für den gestrigen Tagesbericht
            .sheet(isPresented: $showCertificateSheet) {
                DailyRecapView(
                    projectedImpact: projectedImpact,
                    currentScore: currentScore,
                    completedHabitsCount: completedHabits.count,
                    totalHabitsCount: totalHabitsCount,
                    screentimeSeconds: screentimeSeconds
                )
            }
            // Modales Blatt für die Dokumentations-Logs
            .sheet(item: $selectedAttributeForLogs) { attribute in
                AttributeLogsSheet(attribute: attribute)
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

/// Modulare Zinseszins-Kurve für die Statistik.
struct TypewriterChartView: View {
    let points: [Double]
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            
            if points.isEmpty {
                EmptyView()
            } else {
                let minVal = points.min() ?? 0.0
                let maxVal = points.max() ?? 100.0
                let valRange = max(maxVal - minVal, 1.0)
                
                let stepX = width / CGFloat(points.count - 1)
                
                ZStack {
                    Path { path in
                        for i in 1...3 {
                            let y = height * CGFloat(i) / 4.0
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: width, y: y))
                        }
                    }
                    .stroke(Color.primary.opacity(0.03), style: StrokeStyle(lineWidth: 1.5, dash: [4, 6]))
                    
                    Path { path in
                        for (index, point) in points.enumerated() {
                            let x = CGFloat(index) * stepX
                            let y = height - (CGFloat(point - minVal) / CGFloat(valRange) * (height - 30) + 15)
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(
                        LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )
                    
                    ForEach(0..<points.count, id: \.self) { index in
                        let point = points[index]
                        let x = CGFloat(index) * stepX
                        let y = height - (CGFloat(point - minVal) / CGFloat(valRange) * (height - 30) + 15)
                        
                        if index == 0 || index == points.count / 2 || index == points.count - 1 {
                            ZStack {
                                Circle()
                                    .fill(Color(.secondarySystemGroupedBackground))
                                    .frame(width: 10, height: 10)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.red, lineWidth: 2)
                                    )
                                    .position(x: x, y: y)
                                
                                Text(String(format: "%.1f", point))
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color(.secondarySystemGroupedBackground).opacity(0.9))
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                                    )
                                    .position(x: x, y: y - 20)
                            }
                        }
                    }
                }
            }
        }
    }
}

/// Kleine Kachel zur Anzeige einer einzelnen Kennzahl.
struct StatCounterTile: View {
    let label: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.footnote)
                    .foregroundColor(color)
                Spacer()
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
                Text(unit)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.secondary)
                .tracking(1.0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.primary.opacity(0.04), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.01), radius: 5, x: 0, y: 3)
    }
}

/// Zeile für tabellarische Daten in der Statistik.
struct HistoryRow: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            Spacer()
            HStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                Text(unit)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

// Xcode Canvas Preview
#Preview {
    StatsView(
        projectedImpact: 0.7,
        currentScore: 143.02,
        completedHabits: [
            Habit(title: "Training", isCompleted: true, category: .fitness, targetAttribute: .sportlichkeit),
            Habit(title: "Lesen", isCompleted: true, category: .custom, targetAttribute: .intelligenz)
        ],
        totalHabitsCount: 5,
        screentimeSeconds: 5400
    )
}

/// Struktur zur Darstellung eines Unter-Attributs in der Zusammensetzung.
struct SubAttribute: Identifiable {
    let id = UUID()
    let name: String
    let rating: Int
    let icon: String
    let sourceDescription: String
}

/// Modal-Ansicht zur Darstellung der detaillierten Quest-Protokolle eines Attributs.
struct AttributeLogsSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    // Aktuell ausgewähltes Hauptattribut
    @State private var currentAttribute: RPGAttribute
    
    // View-Modus: 0 = Zusammensetzung, 1 = Historie
    @State private var viewMode = 0
    
    // Filter für die Sportlichkeit-Historie
    @State private var sportFilter = 0 // 0: Alle, 1: Kraft, 2: Ausdauer, 3: Dehnen, 4: Sportart
    
    public init(attribute: RPGAttribute) {
        self._currentAttribute = State(initialValue: attribute)
    }
    
    // Lädt alle Logs aus UserDefaults und filtert sie nach dem Attribut
    private var logs: [AttributeLog] {
        let allLogs = AttributeLog.loadLogs()
        let filteredByAttribute = allLogs.filter { log in
            log.attribute == currentAttribute || 
            (currentAttribute == .geschicklichkeit && log.attribute == .sportlichkeit && log.details.contains("Normaler Sport:"))
        }
        
        if currentAttribute == .sportlichkeit {
            switch sportFilter {
            case 1:
                return filteredByAttribute.filter { $0.details.contains("Krafttraining:") }
            case 2:
                return filteredByAttribute.filter { $0.details.contains("Ausdauertraining:") }
            case 3:
                return filteredByAttribute.filter { $0.details.contains("Dehnen & Beweglichkeit:") }
            case 4:
                return filteredByAttribute.filter { $0.details.contains("Normaler Sport:") }
            default:
                return filteredByAttribute
            }
        }
        return filteredByAttribute
    }
    
    private func overallRating(for attr: RPGAttribute) -> Int {
        let allLogs = AttributeLog.loadLogs()
        let count = allLogs.filter { log in
            log.attribute == attr || 
            (attr == .geschicklichkeit && log.attribute == .sportlichkeit && log.details.contains("Normaler Sport:"))
        }.count
        return 50 + count * 5
    }
    
    private func getSubAttributes(for attr: RPGAttribute) -> [SubAttribute] {
        let allLogs = AttributeLog.loadLogs()
        let attributeLogs = allLogs.filter { log in
            log.attribute == attr || 
            (attr == .geschicklichkeit && log.attribute == .sportlichkeit && log.details.contains("Normaler Sport:"))
        }
        
        switch attr {
        case .sportlichkeit:
            let kraftLogs = attributeLogs.filter { $0.details.contains("Krafttraining:") }
            let ausdauerLogs = attributeLogs.filter { $0.details.contains("Ausdauertraining:") }
            let dehnLogs = attributeLogs.filter { $0.details.contains("Dehnen & Beweglichkeit:") }
            
            return [
                SubAttribute(
                    name: "Kraft",
                    rating: 50 + kraftLogs.count * 5,
                    icon: "scalemass.fill",
                    sourceDescription: getSourceDescription(logs: kraftLogs)
                ),
                SubAttribute(
                    name: "Ausdauer",
                    rating: 50 + ausdauerLogs.count * 5,
                    icon: "waveform.path.ecg",
                    sourceDescription: getSourceDescription(logs: ausdauerLogs)
                ),
                SubAttribute(
                    name: "Dehnbarkeit / Beweglichkeit",
                    rating: 50 + dehnLogs.count * 5,
                    icon: "figure.cooldown",
                    sourceDescription: getSourceDescription(logs: dehnLogs)
                )
            ]
            
        case .geschicklichkeit:
            let sportLogs = attributeLogs.filter { $0.details.contains("Normaler Sport:") }
            let otherLogs = attributeLogs.filter { !$0.details.contains("Normaler Sport:") }
            
            return [
                SubAttribute(
                    name: "Sportarten (gesamt)",
                    rating: 50 + sportLogs.count * 5,
                    icon: "sportscourt.fill",
                    sourceDescription: getSourceDescription(logs: sportLogs)
                ),
                SubAttribute(
                    name: "Koordination & Präzision",
                    rating: 50 + otherLogs.count * 5,
                    icon: "target",
                    sourceDescription: getSourceDescription(logs: otherLogs)
                )
            ]
            
        case .intelligenz:
            let lesenLogs = attributeLogs.filter { $0.details.contains("Buch gelesen:") }
            let lernenLogs = attributeLogs.filter { $0.details.contains("Gelernt:") }
            
            return [
                SubAttribute(
                    name: "Lesen",
                    rating: 50 + lesenLogs.count * 5,
                    icon: "book.fill",
                    sourceDescription: getSourceDescription(logs: lesenLogs)
                ),
                SubAttribute(
                    name: "Lernen & Fokus",
                    rating: 50 + lernenLogs.count * 5,
                    icon: "graduationcap.fill",
                    sourceDescription: getSourceDescription(logs: lernenLogs)
                )
            ]
            
        case .achtsamkeit:
            let tagebuchLogs = attributeLogs.filter { $0.details.contains("Tagebucheintrag:") }
            let meditationLogs = attributeLogs.filter { $0.details.contains("Meditiert:") }
            
            return [
                SubAttribute(
                    name: "Reflektion / Tagebuch",
                    rating: 50 + tagebuchLogs.count * 5,
                    icon: "square.and.pencil",
                    sourceDescription: getSourceDescription(logs: tagebuchLogs)
                ),
                SubAttribute(
                    name: "Meditation & Stille",
                    rating: 50 + meditationLogs.count * 5,
                    icon: "sparkles",
                    sourceDescription: getSourceDescription(logs: meditationLogs)
                )
            ]
            
        case .gesundheit:
            let nutritionLogs = attributeLogs.filter { $0.details.lowercased().contains("gegessen") || $0.details.lowercased().contains("frühstück") }
            let otherLogs = attributeLogs.filter { !($0.details.lowercased().contains("gegessen") || $0.details.lowercased().contains("frühstück")) }
            
            return [
                SubAttribute(
                    name: "Ernährung",
                    rating: 50 + nutritionLogs.count * 5,
                    icon: "leaf.fill",
                    sourceDescription: getSourceDescription(logs: nutritionLogs)
                ),
                SubAttribute(
                    name: "Regeneration",
                    rating: 50 + otherLogs.count * 5,
                    icon: "heart.text.square.fill",
                    sourceDescription: getSourceDescription(logs: otherLogs)
                )
            ]
            
        case .finanzen:
            let savingLogs = attributeLogs.filter { $0.details.lowercased().contains("gespart") }
            let otherLogs = attributeLogs.filter { !$0.details.lowercased().contains("gespart") }
            
            return [
                SubAttribute(
                    name: "Sparen",
                    rating: 50 + savingLogs.count * 5,
                    icon: "piggybank.fill",
                    sourceDescription: getSourceDescription(logs: savingLogs)
                ),
                SubAttribute(
                    name: "Budgetierung",
                    rating: 50 + otherLogs.count * 5,
                    icon: "dollarsign.circle.fill",
                    sourceDescription: getSourceDescription(logs: otherLogs)
                )
            ]
            
        case .social:
            let familyLogs = attributeLogs.filter { $0.details.lowercased().contains("familie") || $0.details.lowercased().contains("eltern") || $0.details.lowercased().contains("mutter") || $0.details.lowercased().contains("vater") }
            let otherLogs = attributeLogs.filter { !($0.details.lowercased().contains("familie") || $0.details.lowercased().contains("eltern") || $0.details.lowercased().contains("mutter") || $0.details.lowercased().contains("vater")) }
            
            return [
                SubAttribute(
                    name: "Familie",
                    rating: 50 + familyLogs.count * 5,
                    icon: "house.fill",
                    sourceDescription: getSourceDescription(logs: familyLogs)
                ),
                SubAttribute(
                    name: "Freunde & Kontakte",
                    rating: 50 + otherLogs.count * 5,
                    icon: "person.2.fill",
                    sourceDescription: getSourceDescription(logs: otherLogs)
                )
            ]
            
        case .disziplin:
            return [
                SubAttribute(
                    name: "Fokus & Willenskraft",
                    rating: 50 + attributeLogs.count * 3,
                    icon: "brain.head.profile",
                    sourceDescription: getSourceDescription(logs: attributeLogs)
                ),
                SubAttribute(
                    name: "Konsequenz",
                    rating: 50 + attributeLogs.count * 2,
                    icon: "calendar.badge.clock",
                    sourceDescription: "Gestärkt durch alle Quest-Erfüllungen"
                )
            ]
        }
    }
    
    private func getSourceDescription(logs: [AttributeLog]) -> String {
        if logs.isEmpty {
            return "Zuwachs: Keine eingetragenen Aktivitäten vorhanden."
        }
        var counts: [String: Int] = [:]
        for log in logs {
            counts[log.habitTitle, default: 0] += 1
        }
        let desc = counts.map { "\($0.key) (\($0.value)x)" }.joined(separator: ", ")
        return "Zuwachs kommt von: \(desc)"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // --- 1. HORIZONTALER ATTRIBUT-SWITCHER ---
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(RPGAttribute.allCases) { attr in
                            Button(action: {
                                HapticManager.shared.triggerImpact(style: .light)
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    currentAttribute = attr
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: attr.icon)
                                        .font(.system(size: 13, weight: .bold))
                                    Text(attr.rawValue)
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(currentAttribute == attr ? Color.primary : Color.primary.opacity(0.04))
                                .foregroundColor(currentAttribute == attr ? Color(.systemBackground) : .primary)
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(Color(.secondarySystemGroupedBackground))
                
                // --- 2. SWITCH ZWISCHEN ZUSAMMENSETZUNG & HISTORIE ---
                Picker("Ansicht", selection: $viewMode) {
                    Text("Zusammensetzung").tag(0)
                    Text("Historie").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemGroupedBackground))
                .overlay(
                    VStack {
                        Spacer()
                        Divider()
                    }
                )
                
                ZStack {
                    Color(.systemGroupedBackground)
                        .ignoresSafeArea()
                    
                    if viewMode == 0 {
                        // --- A. ZUSAMMENSETZUNG VIEW ---
                        ScrollView {
                            VStack(spacing: 24) {
                                // Hauptattribut-Card mit Gesamtrating
                                VStack(spacing: 8) {
                                    HStack(spacing: 6) {
                                        Image(systemName: currentAttribute.icon)
                                            .font(.headline)
                                            .foregroundColor(.red)
                                        Text(currentAttribute.rawValue.uppercased())
                                            .font(.system(size: 13, weight: .bold))
                                            .tracking(2.0)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Text("\(overallRating(for: currentAttribute))")
                                        .font(.system(size: 64, weight: .black, design: .monospaced))
                                        .foregroundColor(.primary)
                                    
                                    Text("Gesamtwert")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.secondary)
                                        .tracking(1.0)
                                }
                                .padding(.vertical, 24)
                                .frame(maxWidth: .infinity)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(20)
                                .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 4)
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                                
                                // Unter-Attribute
                                VStack(alignment: .leading, spacing: 14) {
                                    Text("UNTER-RATING AUFSCHLÜSSELUNG")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.secondary)
                                        .tracking(1.5)
                                        .padding(.horizontal, 20)
                                    
                                    ForEach(getSubAttributes(for: currentAttribute)) { sub in
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                HStack(spacing: 8) {
                                                    Image(systemName: sub.icon)
                                                        .font(.system(size: 14, weight: .bold))
                                                        .foregroundColor(.red)
                                                        .frame(width: 28, height: 28)
                                                        .background(Color.red.opacity(0.08))
                                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                                    
                                                    Text(sub.name)
                                                        .font(.system(size: 14, weight: .bold))
                                                        .foregroundColor(.primary)
                                                }
                                                
                                                Spacer()
                                                
                                                Text("\(sub.rating)")
                                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 3)
                                                    .background(Color.primary.opacity(0.05))
                                                    .cornerRadius(6)
                                            }
                                            
                                            Text(sub.sourceDescription)
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                                .lineSpacing(2)
                                            
                                            // Progress Bar
                                            GeometryReader { geo in
                                                ZStack(alignment: .leading) {
                                                    Capsule()
                                                        .fill(Color.primary.opacity(0.04))
                                                    
                                                    Capsule()
                                                        .fill(LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing))
                                                        .frame(width: max(0, min(geo.size.width * CGFloat(Double(sub.rating) / 100.0), geo.size.width)))
                                                }
                                            }
                                            .frame(height: 5)
                                            .padding(.top, 4)
                                        }
                                        .padding(16)
                                        .background(Color(.secondarySystemGroupedBackground))
                                        .cornerRadius(16)
                                        .padding(.horizontal, 16)
                                    }
                                }
                            }
                        }
                    } else {
                        // --- B. HISTORIE VIEW ---
                        VStack(spacing: 0) {
                            if currentAttribute == .sportlichkeit {
                                Picker("Sport-Filter", selection: $sportFilter) {
                                    Text("Alle").tag(0)
                                    Text("Kraft").tag(1)
                                    Text("Ausdauer").tag(2)
                                    Text("Dehnen").tag(3)
                                    Text("Sportart").tag(4)
                                }
                                .pickerStyle(.segmented)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(.secondarySystemGroupedBackground))
                                Divider()
                            }
                            
                            if logs.isEmpty {
                                VStack(spacing: 16) {
                                    Spacer()
                                    Image(systemName: "doc.text.magnifyingglass")
                                        .font(.system(size: 48))
                                        .foregroundColor(.secondary)
                                    
                                    Text("Noch keine Einträge")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.secondary)
                                    
                                    Text("Schließe Quests mit dem Attribut \"\(currentAttribute.rawValue)\" ab, um hier deinen Verlauf zu sehen.")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)
                                    Spacer()
                                }
                                .padding()
                            } else {
                                List {
                                    Section {
                                        ForEach(logs) { log in
                                            VStack(alignment: .leading, spacing: 6) {
                                                HStack {
                                                    Text(log.habitTitle)
                                                        .font(.system(size: 14, weight: .bold))
                                                        .foregroundColor(.primary)
                                                    Spacer()
                                                    Text(formatDate(log.date))
                                                        .font(.system(size: 11))
                                                        .foregroundColor(.secondary)
                                                }
                                                
                                                Text(log.details)
                                                    .font(.system(size: 13))
                                                    .foregroundColor(.secondary)
                                                    .lineSpacing(2)
                                            }
                                            .padding(.vertical, 4)
                                        }
                                    } header: {
                                        Text("Quest-Einträge")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.secondary)
                                            .tracking(1.5)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Dokumentation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                }
            }
        }
    }
}
