import SwiftUI

/// Das Eingabeformular zum Erstellen eines neuen Habits als Bottom-Sheet.
public struct NewHabitSheet: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var habitTitle = ""
    @State private var selectedCategory: HabitCategory = .fitness
    @State private var selectedAttribute: RPGAttribute = .disziplin
    
    public var onSave: (Habit) -> Void
    
    public init(onSave: @escaping (Habit) -> Void) {
        self.onSave = onSave
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    
                    // --- FORM CARD ---
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            // Titel Eingabe
                            VStack(alignment: .leading, spacing: 6) {
                                Text("NAME DER GEWOHNHEIT")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .tracking(1.5)
                                
                                TextField("z.B. 10 Min. Dehnen", text: $habitTitle)
                                    .padding()
                                    .frame(height: 48)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                                    )
                            }
                            
                            // Kategorie Auswahl
                            VStack(alignment: .leading, spacing: 6) {
                                Text("KATEGORIE")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .tracking(1.5)
                                
                                HStack(spacing: 8) {
                                    ForEach(HabitCategory.allCases, id: \.self) { category in
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.15)) {
                                                selectedCategory = category
                                            }
                                        }) {
                                            VStack(spacing: 6) {
                                                Image(systemName: category.icon)
                                                    .font(.system(size: 14))
                                                Text(category.rawValue)
                                                    .font(.system(size: 11, weight: .semibold))
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(selectedCategory == category ? Color.primary : Color(.systemBackground))
                                            .foregroundColor(selectedCategory == category ? Color(.systemBackground) : .primary)
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(selectedCategory == category ? Color.clear : Color.primary.opacity(0.06), lineWidth: 1)
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            
                            // Attribut Auswahl
                            VStack(alignment: .leading, spacing: 6) {
                                Text("ATTRIBUT")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .tracking(1.5)
                                
                                Menu {
                                    Picker("Attribut", selection: $selectedAttribute) {
                                        ForEach(RPGAttribute.allCases) { attribute in
                                            Label(attribute.rawValue, systemImage: attribute.icon)
                                                .tag(attribute)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: selectedAttribute.icon)
                                            .foregroundColor(.primary)
                                        Text(selectedAttribute.rawValue)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.footnote)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 14)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding(24)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                        )
                    }
                    
                    Spacer()
                    
                    // --- SPEICHERN BUTTON ---
                    Button(action: {
                        guard !habitTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        let newHabit = Habit(
                            title: habitTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                            isCompleted: false,
                            category: selectedCategory,
                            targetAttribute: selectedAttribute
                        )
                        onSave(newHabit)
                        dismiss()
                    }) {
                        Text("Habit hinzufügen")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(.systemBackground))
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(habitTitle.isEmpty ? Color.primary.opacity(0.4) : Color.primary)
                            .cornerRadius(16)
                    }
                    .buttonStyle(TactileButtonStyle())
                    .disabled(habitTitle.isEmpty)
                }
                .padding(20)
            }
            .navigationTitle("Neues Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .medium))
                }
            }
        }
    }
}

// Xcode Canvas Preview
#Preview {
    NewHabitSheet(onSave: { _ in })
}
