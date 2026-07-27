import SwiftUI
import UIKit
import UserNotifications

/// Der Haptic Feedback Manager zur Steuerung von physischen Vibrationen.
public struct HapticManager {
    public static let shared = HapticManager()
    
    /// Löst eine dezenten Stoß aus (z. B. beim Abhaken eines Habits).
    public func triggerImpact(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Löst ein Erfolgsmuster aus (z. B. beim Stufenaufstieg / Level Up).
    public func triggerNotification(type: UINotificationFeedbackGenerator.FeedbackType = .success) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}

/// Der Notification Manager zur Planung von täglichen Quests-Remindern.
public struct NotificationManager {
    public static let shared = NotificationManager()
    
    /// Fragt nach Benachrichtigungsrechten und plant tägliche Erinnerungen.
    public func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                self.scheduleDailyReminder()
            }
        }
    }
    
    /// Plant eine tägliche Erinnerung um 20:00 Uhr.
    public func scheduleDailyReminder() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let content = UNMutableNotificationContent()
        content.title = "1% Methode: Tagesquest abschließen!"
        content.body = "Schließe deine verbleibenden Habits vor Mitternacht ab, um deine Zinseszins-Serie zu sichern! 📈"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_habit_reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}

/// Die moderne Tagesbericht-Ansicht (Daily Recap Screen).
///
/// Zeigt nach dem Tageswechsel (0 Uhr) automatisch die Zusammenfassung des Vortages:
/// Zuwachs/Verlust, Attributänderungen und verbleibende Bildschirmzeit.
public struct DailyRecapView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    let projectedImpact: Double
    let currentScore: Double
    let completedHabitsCount: Int
    let totalHabitsCount: Int
    let screentimeSeconds: Int
    let attributeChanges: [(name: String, icon: String, delta: Int)]
    
    public init(
        projectedImpact: Double,
        currentScore: Double,
        completedHabitsCount: Int,
        totalHabitsCount: Int,
        screentimeSeconds: Int,
        attributeChanges: [(name: String, icon: String, delta: Int)] = []
    ) {
        self.projectedImpact = projectedImpact
        self.currentScore = currentScore
        self.completedHabitsCount = completedHabitsCount
        self.totalHabitsCount = totalHabitsCount
        self.screentimeSeconds = screentimeSeconds
        self.attributeChanges = attributeChanges
    }
    
    // Bildschirmzeit Bewertung
    private var screentimeRating: (text: String, color: Color, desc: String) {
        let hours = Double(screentimeSeconds) / 3600.0
        if hours < 2.0 {
            return ("EXTREM GUT", .green, "Du hast deine digitale Zeit perfekt im Griff.")
        } else if hours < 4.0 {
            return ("MITTELWEG", .orange, "Solide Leistung, aber versuche Ablenkungen zu reduzieren.")
        } else {
            return ("SCHLECHT", .red, "Hoher Medienkonsum. Gönn dir heute eine digitale Pause!")
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .long
        return formatter.string(from: Date().addingTimeInterval(-86400)) // Gestern
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // --- 1. TAGESZERTIFIKAT HEADER ---
                        VStack(spacing: 8) {
                            Text("1% METHODE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.red)
                                .tracking(3.0)
                            
                            Text("Tagesbericht: Gestern")
                                .font(.system(size: 24, weight: .bold))
                            
                            Text(formattedDate)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 16)
                        
                        // --- 2. ZINSEZINS ZUWACHS CARD ---
                        VStack(spacing: 12) {
                            let sign = projectedImpact >= 0 ? "+" : ""
                            Text("\(sign)\(String(format: "%.2f", projectedImpact))%")
                                .font(.system(size: 48, weight: .bold, design: .monospaced))
                                .foregroundColor(projectedImpact >= 0 ? .green : .red)
                            
                            Text("ZINSESZINS KAPAZITÄT")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                                .tracking(1.5)
                            
                            Divider()
                                .padding(.vertical, 8)
                            
                            HStack {
                                Text("Neuer Gesamtwert:")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "%.2f%%", currentScore))
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                            }
                        }
                        .padding(24)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                        )
                        
                        // --- 3. GEWOHNHEITS-QUOTE ---
                        VStack(alignment: .leading, spacing: 14) {
                            Text("ERLEDIGTE GEWOHNHEITEN")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                                .tracking(1.5)
                            
                            HStack {
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.primary.opacity(0.05))
                                        
                                        let progress = totalHabitsCount > 0 ? CGFloat(completedHabitsCount) / CGFloat(totalHabitsCount) : 0.0
                                        Capsule()
                                            .fill(projectedImpact >= 0 ? Color.green : Color.red)
                                            .frame(width: geo.size.width * progress)
                                    }
                                }
                                .frame(height: 12)
                                
                                Text("\(completedHabitsCount)/\(totalHabitsCount)")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .padding(.leading, 8)
                            }
                        }
                        .padding(20)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                        )
                        
                        // --- 4. ATTRIBUT-VERÄNDERUNGEN ---
                        if !attributeChanges.isEmpty {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("ATTRIBUT-VERÄNDERUNGEN")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .tracking(1.5)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 10),
                                    GridItem(.flexible(), spacing: 10)
                                ], spacing: 10) {
                                    ForEach(attributeChanges, id: \.name) { attr in
                                        HStack(spacing: 8) {
                                            Image(systemName: attr.icon)
                                                .font(.system(size: 14))
                                                .foregroundColor(attr.delta > 0 ? .green : (attr.delta < 0 ? .red : .secondary))
                                                .frame(width: 20)
                                            
                                            Text(attr.name)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.primary)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.7)
                                            
                                            Spacer()
                                            
                                            Text(attr.delta > 0 ? "+\(attr.delta)" : "\(attr.delta)")
                                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                                .foregroundColor(attr.delta > 0 ? .green : (attr.delta < 0 ? .red : .secondary))
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(Color(.systemBackground))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                            .padding(20)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                            )
                        }
                        
                        // --- 4. SCREEN TIME CARD ---
                        VStack(alignment: .leading, spacing: 12) {
                            Text("BILDSCHIRMZEIT RECAP")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                                .tracking(1.5)
                            
                            HStack {
                                Image(systemName: "hourglass")
                                    .foregroundColor(screentimeRating.color)
                                Text(formatSeconds(screentimeSeconds))
                                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                                Spacer()
                                Text(screentimeRating.text)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(screentimeRating.color)
                                    .cornerRadius(6)
                            }
                            
                            Text(screentimeRating.desc)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .lineSpacing(2)
                        }
                        .padding(20)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                        )
                        
                        // --- 5. TAGESQUEST STARTEN BUTTON ---
                        Button(action: {
                            HapticManager.shared.triggerImpact(style: .medium)
                            dismiss()
                        }) {
                            Text("Tagesquest für heute starten!")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(.systemBackground))
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(Color.primary)
                                .cornerRadius(16)
                        }
                        .padding(.top, 12)
                        
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Schließen") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .bold))
                }
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

#Preview {
    DailyRecapView(
        projectedImpact: 1.0,
        currentScore: 1.0,
        completedHabitsCount: 4,
        totalHabitsCount: 5,
        screentimeSeconds: 5400
    )
}
