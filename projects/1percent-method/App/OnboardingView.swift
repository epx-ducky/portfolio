import SwiftUI

/// Die Onboarding-Ansicht zur ersten Erfassung der täglichen Gewohnheiten.
public struct OnboardingView: View {
    
    // Callback, wenn das Onboarding abgeschlossen ist und die Habits übergeben werden.
    public var onComplete: ([Habit]) -> Void
    
    // Vordefinierte Habits zum Auswählen
    @State private var presetHabits: [Habit] = [
        Habit(title: "Tägliches Training (30 Min.)", isCompleted: false, category: .fitness, targetAttribute: .sportlichkeit, createdAt: Date().addingTimeInterval(-8 * 24 * 3600)),
        Habit(title: "10.000 Schritte gehen", isCompleted: false, category: .health, targetAttribute: .gesundheit, createdAt: Date().addingTimeInterval(-8 * 24 * 3600)),
        Habit(title: "Bildschirmzeit unter 2h", isCompleted: false, category: .focus, targetAttribute: .disziplin, createdAt: Date().addingTimeInterval(-8 * 24 * 3600)),
        Habit(title: "Gesundes Frühstück", isCompleted: false, category: .health, targetAttribute: .gesundheit, createdAt: Date().addingTimeInterval(-8 * 24 * 3600)),
        Habit(title: "30 Min. Lesen", isCompleted: false, category: .custom, targetAttribute: .intelligenz, createdAt: Date().addingTimeInterval(-8 * 24 * 3600))
    ]
    
    // Lokale Zustände für ein manuell hinzugefügtes Onboarding-Habit
    @State private var customTitle = ""
    @State private var selectedCategory: HabitCategory = .fitness
    
    // Set von IDs der aktuell ausgewählten Habits
    @State private var selectedIds: Set<UUID> = []
    
    public init(onComplete: @escaping ([Habit]) -> Void) {
        self.onComplete = onComplete
    }
    
    public var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemGroupedBackground).opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // --- 1. TYPOGRAFIE KOPFBEREICH ---
                VStack(spacing: 8) {
                    Text("1% METHODE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.red)
                        .tracking(3.0)
                    
                    Text("Richte deinen Tag ein")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Wähle aus, welche Alltags-Habits du jeden Tag bewältigen willst, um dich täglich um 1% zu steigern.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .lineSpacing(4)
                }
                .padding(.top, 24)
                
                // --- 2. LISTE DER PRESSETS ---
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(presetHabits) { habit in
                            let isSelected = selectedIds.contains(habit.id)
                            Button(action: {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                    if isSelected {
                                        selectedIds.remove(habit.id)
                                    } else {
                                        selectedIds.insert(habit.id)
                                    }
                                }
                            }) {
                                HStack(spacing: 16) {
                                    // Kategorie Icon
                                    Image(systemName: habit.category.icon)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(isSelected ? .white : categoryColor(for: habit.category))
                                        .frame(width: 28, height: 28)
                                        .background(isSelected ? Color.white.opacity(0.25) : categoryColor(for: habit.category).opacity(0.08))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    
                                    Text(habit.title)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(isSelected ? .white : .primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 20))
                                        .foregroundColor(isSelected ? .white : .secondary.opacity(0.3))
                                        .contentTransition(.symbolEffect(.replace))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    isSelected ? 
                                    LinearGradient(colors: [.red, Color(red: 0.8, green: 0.1, blue: 0.1)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                    LinearGradient(colors: [Color(.secondarySystemGroupedBackground), Color(.secondarySystemGroupedBackground)], startPoint: .top, endPoint: .bottom)
                                )
                                .cornerRadius(18)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(isSelected ? Color.clear : Color.primary.opacity(0.04), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // --- 3. EIGENES HABIT HINZUFÜGEN ---
                        VStack(spacing: 12) {
                            HStack {
                                Text("Eigenes Habit hinzufügen:")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .tracking(1.0)
                                Spacer()
                            }
                            .padding(.top, 12)
                            .padding(.horizontal, 4)
                            
                            HStack(spacing: 8) {
                                TextField("z.B. Meditation", text: $customTitle)
                                    .padding(.horizontal, 12)
                                    .frame(height: 44)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                                    )
                                
                                Button(action: {
                                    guard !customTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                                    let targetAttr: RPGAttribute
                                    switch selectedCategory {
                                    case .fitness: targetAttr = .sportlichkeit
                                    case .health: targetAttr = .gesundheit
                                    case .focus: targetAttr = .disziplin
                                    case .custom: targetAttr = .intelligenz
                                    }
                                    let newCustom = Habit(
                                        title: customTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                                        isCompleted: false,
                                        category: selectedCategory,
                                        targetAttribute: targetAttr,
                                        createdAt: Date().addingTimeInterval(-8 * 24 * 3600)
                                    )
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        presetHabits.append(newCustom)
                                        selectedIds.insert(newCustom.id)
                                        customTitle = ""
                                    }
                                }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                        .background(customTitle.isEmpty ? Color.secondary.opacity(0.3) : Color.primary)
                                        .cornerRadius(12)
                                }
                                .disabled(customTitle.isEmpty)
                            }
                            
                            // Kategorie-Auswahl für das eigene Habit
                            HStack(spacing: 8) {
                                ForEach(HabitCategory.allCases, id: \.self) { category in
                                    Button(action: { selectedCategory = category }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: category.icon)
                                                .font(.caption)
                                            Text(category.rawValue)
                                                .font(.system(size: 10, weight: .medium))
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(selectedCategory == category ? Color.primary.opacity(0.08) : Color.clear)
                                        .foregroundColor(selectedCategory == category ? .primary : .secondary)
                                        .cornerRadius(8)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 2)
                        }
                    }
                    .padding(.horizontal, 4)
                }
                
                // --- 4. ABSCHLUSS-BUTTON ---
                Button(action: {
                    // Filtert die vordefinierten & eigenen Habits anhand der getroffenen Selektion
                    let selectedHabits = presetHabits.filter { selectedIds.contains($0.id) }
                    // Falls nichts ausgewählt wurde, nehmen wir alle (Fallschutz)
                    let finalHabits = selectedHabits.isEmpty ? presetHabits : selectedHabits
                    onComplete(finalHabits)
                }) {
                    Text("Habits festlegen")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            LinearGradient(
                                colors: [.red, Color(red: 0.8, green: 0.1, blue: 0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.red.opacity(0.2), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(TactileButtonStyle())
            }
            .padding(20)
        }
    }
    
    private func categoryColor(for cat: HabitCategory) -> Color {
        switch cat {
        case .fitness: return .orange
        case .health: return .blue
        case .focus: return .purple
        case .custom: return .secondary
        }
    }
}

// Xcode Canvas Preview
#Preview {
    OnboardingView(onComplete: { _ in })
}
