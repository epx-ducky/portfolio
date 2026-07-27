import SwiftUI

/// Die Ansicht zur Dokumentation und Protokollierung eines abgehakten Habits.
struct HabitCompletionSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let habit: Habit
    var onConfirm: (String) -> Void // Gibt die zusammengestellten Details zurück
    
    // --- Gemeinsame States ---
    @State private var generalDetails: String = ""
    
    // --- Sportlichkeit States ---
    @State private var sportType = 0 // 0: Kraft, 1: Ausdauer, 2: Dehnen / Beweglichkeit, 3: Sportart
    @State private var strengthDetails: String = ""
    @State private var cardioMinutes: String = ""
    @State private var cardioKm: String = ""
    @State private var flexibilityMinutes: String = ""
    @State private var flexibilityFocus: String = ""
    @State private var normalSportName: String = ""
    
    // --- Intelligenz States ---
    @State private var intelligenceType = 0 // 0: Buch, 1: Lernen
    @State private var bookTitle: String = ""
    @State private var bookPages: String = ""
    @State private var bookTopic: String = ""
    @State private var studySubject: String = ""
    @State private var studyGrade: String = ""
    
    // --- Achtsamkeit States ---
    @State private var mindfulnessType = 0 // 0: Tagebuch, 1: Meditation
    @State private var journalText: String = ""
    @State private var meditationMinutes: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // --- Header ---
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.primary.opacity(0.04))
                                    .frame(width: 64, height: 64)
                                Image(systemName: habit.targetAttribute.icon)
                                    .font(.title2)
                                    .foregroundColor(.primary)
                            }
                            
                            Text(habit.title)
                                .font(.system(size: 20, weight: .bold))
                                .multilineTextAlignment(.center)
                            
                            Text("Quest abschließen: \(habit.targetAttribute.rawValue)")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 16)
                        
                        // --- Formular nach Attribut ---
                        VStack(alignment: .leading, spacing: 20) {
                            switch habit.targetAttribute {
                            case .sportlichkeit:
                                sportForm
                            case .intelligenz:
                                intelligenceForm
                            case .achtsamkeit:
                                mindfulnessForm
                            default:
                                defaultForm
                            }
                        }
                        .padding(20)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                        )
                        
                        // --- Bestätigen Button ---
                        Button(action: {
                            HapticManager.shared.triggerImpact(style: .medium)
                            let details = getFormattedDetails()
                            onConfirm(details)
                            dismiss()
                        }) {
                            Text("Quest abschließen & eintragen")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(.systemBackground))
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(isFormValid() ? Color.primary : Color.primary.opacity(0.4))
                                .cornerRadius(16)
                        }
                        .disabled(!isFormValid())
                        .padding(.top, 8)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Aktivität dokumentieren")
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
    
    // --- FORMULARE ---
    
    // 1. Sportlichkeit Formular
    private var sportForm: some View {
        VStack(alignment: .leading, spacing: 18) {
            Picker("Sport-Typ", selection: $sportType) {
                Text("Kraft").tag(0)
                Text("Ausdauer").tag(1)
                Text("Dehnen").tag(2)
                Text("Sportart").tag(3)
            }
            .pickerStyle(.segmented)
            
            if sportType == 0 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("TRAINING DOKUMENTIEREN")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1.5)
                    
                    TextField("Z.B. 100 Liegestütze, 60 Bizeps Curls...", text: $strengthDetails)
                        .padding(.horizontal, 14)
                        .frame(height: 48)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                }
            } else if sportType == 1 {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DAUER (MINUTEN)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .tracking(1.5)
                        
                        TextField("Z.B. 45", text: $cardioMinutes)
                            .keyboardType(.numberPad)
                            .padding(.horizontal, 14)
                            .frame(height: 48)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ENTFERNUNG (KM)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .tracking(1.5)
                        
                        TextField("Z.B. 5.2", text: $cardioKm)
                            .keyboardType(.decimalPad)
                            .padding(.horizontal, 14)
                            .frame(height: 48)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                    }
                }
            } else if sportType == 2 {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DAUER DEHNEN / YOGA (MINUTEN)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .tracking(1.5)
                        
                        TextField("Z.B. 15", text: $flexibilityMinutes)
                            .keyboardType(.numberPad)
                            .padding(.horizontal, 14)
                            .frame(height: 48)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("FOKUS / ÜBUNGEN")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .tracking(1.5)
                        
                        TextField("Z.B. Beine dehnen, Yoga-Flow, Spagat...", text: $flexibilityFocus)
                            .padding(.horizontal, 14)
                            .frame(height: 48)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("WELCHE SPORTART?")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1.5)
                    
                    TextField("Z.B. Fußball, Volleyball, Tennis...", text: $normalSportName)
                        .padding(.horizontal, 14)
                        .frame(height: 48)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                    
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.orange)
                        Text("Tipp: Normaler Sport trainiert auch Geschicklichkeit!")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                }
            }
        }
    }
    
    // 2. Intelligenz Formular
    private var intelligenceForm: some View {
        VStack(alignment: .leading, spacing: 18) {
            Picker("Intelligenz-Typ", selection: $intelligenceType) {
                Text("Buch lesen").tag(0)
                Text("Lernen").tag(1)
            }
            .pickerStyle(.segmented)
            
            if intelligenceType == 0 {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("BUCH-TITEL")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .tracking(1.5)
                        
                        TextField("Z.B. Atomic Habits", text: $bookTitle)
                            .padding(.horizontal, 14)
                            .frame(height: 48)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("GELESENE SEITEN")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .tracking(1.5)
                        
                        TextField("Z.B. 15", text: $bookPages)
                            .keyboardType(.numberPad)
                            .padding(.horizontal, 14)
                            .frame(height: 48)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("INHALT / THEMA")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .tracking(1.5)
                        
                        TextField("Z.B. Gewohnheiten etablieren", text: $bookTopic)
                            .padding(.horizontal, 14)
                            .frame(height: 48)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                    }
                }
            } else {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("LERNSTOFF / THEMA")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .tracking(1.5)
                        
                        TextField("Z.B. Swift UI & iOS Programmierung", text: $studySubject)
                            .padding(.horizontal, 14)
                            .frame(height: 48)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NOTE / ERGEBNIS (OPTIONAL)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .tracking(1.5)
                        
                        TextField("Z.B. 1.3 oder Bestanden", text: $studyGrade)
                            .padding(.horizontal, 14)
                            .frame(height: 48)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                    }
                }
            }
        }
    }
    
    // 3. Achtsamkeit Formular
    private var mindfulnessForm: some View {
        VStack(alignment: .leading, spacing: 18) {
            Picker("Achtsamkeit-Typ", selection: $mindfulnessType) {
                Text("Tagebuch").tag(0)
                Text("Meditation").tag(1)
            }
            .pickerStyle(.segmented)
            
            if mindfulnessType == 0 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("TAGEBUCH-EINTRAG")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1.5)
                    
                    TextEditor(text: $journalText)
                        .padding(8)
                        .frame(height: 120)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("DAUER (MINUTEN)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1.5)
                    
                    TextField("Z.B. 15", text: $meditationMinutes)
                        .keyboardType(.numberPad)
                        .padding(.horizontal, 14)
                        .frame(height: 48)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
                }
            }
        }
    }
    
    // 4. Default Formular für andere Attribute
    private var defaultForm: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(defaultFormTitle)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)
                .tracking(1.5)
            
            TextField(defaultFormPlaceholder, text: $generalDetails)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.08), lineWidth: 1))
        }
    }
    
    private var defaultFormTitle: String {
        switch habit.targetAttribute {
        case .gesundheit:
            return "WAS HAST DU FÜR DEINE GESUNDHEIT GETAN / GEGESSEN?"
        case .finanzen:
            return "WAS HAST DU FINANZIELL DOKUMENTIERT / GESPART?"
        case .social:
            return "MIT WEM HAST DU DICH HEUTE AUSGETAUSCHT?"
        case .disziplin:
            return "WOBEI HAST DU HEUTE DISZIPLIN BEWIESEN?"
        case .geschicklichkeit:
            return "WAS HAST DU FÜR DEINE GESCHICKLICHKEIT GETAN?"
        default:
            return "WAS HAST DU HEUTE ERREICHT / ERLEDIGT?"
        }
    }
    
    private var defaultFormPlaceholder: String {
        switch habit.targetAttribute {
        case .gesundheit:
            return "z.B. Haferflocken mit Beeren gegessen, 2L Wasser..."
        case .finanzen:
            return "z.B. 15€ gespart, Haushaltsbuch gepflegt..."
        case .social:
            return "z.B. 30 Min. mit Familie telefoniert, Freunde getroffen..."
        case .disziplin:
            return "z.B. Keine Süßigkeiten gegessen, 2h fokussiert gearbeitet..."
        case .geschicklichkeit:
            return "z.B. Reaktionstraining absolviert, jongliert..."
        default:
            return "Details eintragen..."
        }
    }
    
    // --- LOGIK-FUNKTIONEN ---
    
    private func isFormValid() -> Bool {
        switch habit.targetAttribute {
        case .sportlichkeit:
            if sportType == 0 { return !strengthDetails.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            if sportType == 1 { return !cardioMinutes.isEmpty }
            if sportType == 2 { return !flexibilityMinutes.isEmpty }
            return !normalSportName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .intelligenz:
            if intelligenceType == 0 {
                return !bookTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !bookPages.isEmpty
            }
            return !studySubject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .achtsamkeit:
            if mindfulnessType == 0 { return !journalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            return !meditationMinutes.isEmpty
        default:
            return !generalDetails.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    private func getFormattedDetails() -> String {
        switch habit.targetAttribute {
        case .sportlichkeit:
            if sportType == 0 {
                return "Krafttraining: \(strengthDetails)"
            } else if sportType == 1 {
                let dist = cardioKm.isEmpty ? "" : " (\(cardioKm) km)"
                return "Ausdauertraining: \(cardioMinutes) Min.\(dist)"
            } else if sportType == 2 {
                let focus = flexibilityFocus.isEmpty ? "" : " (Fokus: \(flexibilityFocus))"
                return "Dehnen & Beweglichkeit: \(flexibilityMinutes) Min.\(focus)"
            } else {
                return "Normaler Sport: \(normalSportName)"
            }
        case .intelligenz:
            if intelligenceType == 0 {
                let topic = bookTopic.isEmpty ? "" : " (Thema: \(bookTopic))"
                return "Buch gelesen: \"\(bookTitle)\", \(bookPages) Seiten\(topic)"
            } else {
                let grade = studyGrade.isEmpty ? "" : " (Ergebnis: \(studyGrade))"
                return "Gelernt: \(studySubject)\(grade)"
            }
        case .achtsamkeit:
            if mindfulnessType == 0 {
                return "Tagebucheintrag: \(journalText)"
            } else {
                return "Meditiert: \(meditationMinutes) Min."
            }
        default:
            return generalDetails
        }
    }
}

#Preview {
    HabitCompletionSheet(
        habit: Habit(title: "Liegestütze", isCompleted: false, category: .fitness, targetAttribute: .sportlichkeit),
        onConfirm: { _ in }
    )
}
