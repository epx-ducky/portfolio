import SwiftUI

/// Das Detail- und Upgrade-Menü für ein Habit (Stufenaufstieg-Mechanik).
struct HabitDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    // Das Habit, das wir bearbeiten/upgraden
    @State var habit: Habit
    
    // Callback, um Änderungen an das Dashboard zurückzugeben
    var onUpgrade: (Habit) -> Void
    
    // Neuer Titel für das Upgrade
    @State private var newTitle: String = ""
    @State private var showingUpgradeForm: Bool = false
    
    // Status, ob heute bereits ein Upgrade oder eine Neuanlage durchgeführt wurde
    private var hasPerformedActionToday: Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayStr = formatter.string(from: Date())
        let lastActionStr = UserDefaults.standard.string(forKey: "lastActionDateString") ?? ""
        return lastActionStr == todayStr
    }
    
    // Berechnet verbleibende Tage der Wachstumsphase
    private var growthDaysRemaining: Int {
        let daysPassed = Calendar.current.dateComponents([.day], from: habit.createdAt, to: Date()).day ?? 0
        return max(0, 7 - daysPassed)
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // --- 1. LEVEL & ATTRIBUT HEADER ---
                        VStack(spacing: 12) {
                            // Kreis-Emblem mit Level
                            ZStack {
                                Circle()
                                    .fill(Color.red.opacity(0.1))
                                    .frame(width: 80, height: 80)
                                
                                VStack(spacing: 2) {
                                    Text("Lvl")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.red.opacity(0.8))
                                    Text("\(habit.level)")
                                        .font(.system(size: 26, weight: .bold, design: .monospaced))
                                        .foregroundColor(.red)
                                }
                            }
                            
                            Text(habit.title)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                            
                            // Attribut Badge
                            HStack(spacing: 6) {
                                Image(systemName: habit.targetAttribute.icon)
                                Text(habit.targetAttribute.rawValue)
                            }
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.primary.opacity(0.04))
                            .cornerRadius(8)
                        }
                        .padding(.vertical, 16)
                        
                        // --- 2. WACHSTUMS- / STANDARDSTATUS ---
                        VStack(alignment: .leading, spacing: 12) {
                            let daysLeft = growthDaysRemaining
                            
                            if daysLeft > 0 {
                                // Aktiv in der 7-Tage-Wachstumsphase
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .font(.title3)
                                        .foregroundColor(.green)
                                        .padding(.top, 2)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Wachstumsphase aktiv")
                                            .font(.system(size: 14, weight: .bold))
                                        Text("Dieses Habit bringt dir aktuell noch \(daysLeft) Tage lang täglich +1.0% Fortschritt.")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                            .lineSpacing(2)
                                    }
                                }
                                
                                // Progress-Indikator
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.primary.opacity(0.05))
                                        Capsule()
                                            .fill(Color.green)
                                            .frame(width: geo.size.width * CGFloat(7 - daysLeft) / 7.0)
                                    }
                                }
                                .frame(height: 6)
                                .padding(.top, 4)
                            } else {
                                // Etablierter Standard (Baseline)
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "shield.fill")
                                        .font(.title3)
                                        .foregroundColor(.red)
                                        .padding(.top, 2)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Etablierter Standard (Baseline)")
                                            .font(.system(size: 14, weight: .bold))
                                        Text("Dieses Habit ist nun Teil deines täglichen Fundaments. Es bringt keinen aktiven Zuwachs mehr, aber bei Nichterfüllung verlierst du täglich -1.0%!")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                            .lineSpacing(2)
                                    }
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
                        
                        // --- 3. UPGRADE FORMULAR ---
                        VStack(alignment: .leading, spacing: 12) {
                            if hasPerformedActionToday {
                                // Sperrhinweis, wenn heute schon eine Aktion stattfand
                                VStack(spacing: 8) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.secondary)
                                    Text("Aktionslimit erreicht")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("Du kannst nur 1 Habit pro Tag erstellen oder aufwerten. Komm morgen wieder für das nächste Upgrade!")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                            } else {
                                if !showingUpgradeForm {
                                    Button(action: {
                                        showingUpgradeForm = true
                                        newTitle = habit.title
                                    }) {
                                        HStack {
                                            Image(systemName: "arrow.up.circle.fill")
                                            Text("Habit aufwerten (Stufenaufstieg)")
                                                .fontWeight(.bold)
                                        }
                                        .font(.system(size: 15))
                                        .foregroundColor(Color(.systemBackground))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                        .background(Color.primary)
                                        .cornerRadius(14)
                                    }
                                } else {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("NEUES LEVEL ZIELSETZUNG")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.secondary)
                                            .tracking(1.5)
                                        
                                        TextField("Z.B. Neues Buch / 15 statt 10 Seiten...", text: $newTitle)
                                            .padding(.horizontal, 14)
                                            .frame(height: 48)
                                            .background(Color(.systemBackground))
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                                            )
                                        
                                        HStack(spacing: 12) {
                                            Button("Abbrechen") {
                                                showingUpgradeForm = false
                                            }
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.secondary)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 44)
                                            .background(Color.primary.opacity(0.04))
                                            .cornerRadius(10)
                                            
                                            Button("Stufenaufstieg bestätigen") {
                                                guard !newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                                                
                                                // 1. Sichere alte Stufe in Log
                                                var updatedLogs = habit.upgradesLog
                                                updatedLogs.insert("Lvl. \(habit.level): \(habit.title)", at: 0)
                                                
                                                // 2. Erzeuge modifiziertes Habit
                                                var upgradedHabit = habit
                                                upgradedHabit.title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                                                upgradedHabit.level += 1
                                                upgradedHabit.upgradesLog = updatedLogs
                                                upgradedHabit.createdAt = Date() // Reset 7-Tage-Timer!
                                                
                                                // 3. Registriere Aktion für heute
                                                let formatter = DateFormatter()
                                                formatter.dateFormat = "yyyy-MM-dd"
                                                UserDefaults.standard.set(formatter.string(from: Date()), forKey: "lastActionDateString")
                                                
                                                HapticManager.shared.triggerNotification(type: .success)
                                                onUpgrade(upgradedHabit)
                                                dismiss()
                                            }
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 44)
                                            .background(Color.red)
                                            .cornerRadius(10)
                                        }
                                        .padding(.top, 4)
                                    }
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
                        
                        // --- 4. UPGRADE VERLAUF (LOGS) ---
                        VStack(alignment: .leading, spacing: 14) {
                            Text("STUFEN-CHRONIK")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                                .tracking(1.5)
                            
                            if habit.upgradesLog.isEmpty {
                                HStack {
                                    Spacer()
                                    Text("Bisher keine Upgrades (Start-Level).")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                            } else {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(habit.upgradesLog, id: \.self) { log in
                                        HStack(alignment: .top, spacing: 10) {
                                            Image(systemName: "checkmark.seal.fill")
                                                .foregroundColor(.red)
                                                .font(.footnote)
                                                .padding(.top, 2)
                                            
                                            Text(log)
                                                .font(.system(size: 12, design: .monospaced))
                                                .foregroundColor(.primary)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                        )

                        
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Habit Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Schließen") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                }
            }
        }
    }
}
