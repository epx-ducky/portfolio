import SwiftUI

/// Die Profil- und Erfolgsansicht (Account-Sheet) der App.
///
/// Zeigt Benutzerdaten und einen schwebenden Medaillen-Showcase für Quests.
/// Die Medaillen besitzen detaillierte Vektor-Designs mit metallischen Gradienten.
public struct ProfileView: View {
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    
    // Lokale Achievements-Liste zur Veranschaulichung
    @State private var achievements: [Achievement] = [
        Achievement(
            id: "start",
            title: "Startschuss",
            description: "Ersten Tag alle Ziele erfolgreich absolviert.",
            icon: "target",
            metalType: .bronze,
            isUnlocked: true
        ),
        Achievement(
            id: "streak7",
            title: "Disziplin",
            description: "7 Tage in Folge alle Ziele gemeistert.",
            icon: "calendar.badge.clock",
            metalType: .silver,
            isUnlocked: true
        ),
        Achievement(
            id: "streak30",
            title: "Unaufhaltsam",
            description: "30 Tage in Folge alle Ziele absolviert.",
            icon: "flame.fill",
            metalType: .gold,
            isUnlocked: false
        ),
        Achievement(
            id: "season20",
            title: "Saison-Master",
            description: "+20.0% Saisonfortschritt erreicht.",
            icon: "trophy.fill",
            metalType: .platinum,
            isUnlocked: false
        ),
        Achievement(
            id: "digital_detox",
            title: "Mönch-Modus",
            description: "3 Tage Bildschirmzeit unter 1 Stunde gehalten.",
            icon: "hourglass",
            metalType: .special,
            isUnlocked: true
        )
    ]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        
                        // --- NUTZER-KONTOÜBERSICHT ---
                        VStack(spacing: 8) {
                            // Avatar
                            ZStack {
                                Circle()
                                    .fill(Color.primary.opacity(0.03))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.primary.opacity(0.8))
                            }
                            
                            // Benutzername & Mail
                            if case .authenticated(_, let email, let username, let isMFA) = authService.sessionState {
                                Text(username)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text(email)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                
                                // Sicherheits-Badge (MFA)
                                HStack(spacing: 4) {
                                    Image(systemName: isMFA ? "shield.checkmark.fill" : "shield")
                                    Text(isMFA ? "2FA Aktiviert" : "2FA Deaktiviert")
                                }
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(isMFA ? .green : .secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(isMFA ? Color.green.opacity(0.08) : Color.primary.opacity(0.04))
                                )
                                .padding(.top, 2)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                        )
                        
                        // --- ERFOLGE & QUESTS SEKTION ---
                        VStack(alignment: .leading, spacing: 16) {
                            Text("QUESTS & MEDAILLEN")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                                .tracking(1.5)
                                .padding(.leading, 4)
                            
                            // Liste der Medaillen
                            ForEach(achievements) { quest in
                                HStack(spacing: 16) {
                                    // Medaillen Vektordesign
                                    MedalBadgeView(metalType: quest.metalType, icon: quest.icon, isUnlocked: quest.isUnlocked)
                                    
                                    // Textbeschreibung
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(quest.title)
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(quest.isUnlocked ? .primary : .secondary)
                                            
                                            Spacer()
                                            
                                            Text(quest.metalType.rawValue)
                                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Text(quest.description)
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }
                                }
                                .padding(16)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.01), radius: 5, x: 0, y: 3)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Mein Profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(role: .destructive, action: {
                        Task {
                            await authService.signOut()
                            dismiss()
                        }
                    }) {
                        Text("Abmelden")
                            .foregroundColor(.red)
                            .font(.system(size: 15, weight: .semibold))
                    }
                }
                
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

/// Detaillierte Vektor-Medaille mit metallischen Gradienten und Reflektions-Schatten.
struct MedalBadgeView: View {
    let metalType: MedalMetalType
    let icon: String
    let isUnlocked: Bool
    
    // Definiere die metallischen Farbverläufe
    private var metallicGradient: LinearGradient {
        switch metalType {
        case .bronze:
            return LinearGradient(
                colors: [Color(red: 0.8, green: 0.5, blue: 0.3), Color(red: 0.5, green: 0.25, blue: 0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .silver:
            return LinearGradient(
                colors: [Color(red: 0.95, green: 0.95, blue: 0.95), Color(red: 0.6, green: 0.6, blue: 0.65)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .gold:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.85, blue: 0.3), Color(red: 0.8, green: 0.55, blue: 0.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .platinum:
            return LinearGradient(
                colors: [Color(red: 0.85, green: 0.9, blue: 1.0), Color(red: 0.5, green: 0.55, blue: 0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .special:
            // Edler Rot-Gold Gradient
            return LinearGradient(
                colors: [.red, Color(red: 0.8, green: 0.1, blue: 0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var body: some View {
        ZStack {
            if isUnlocked {
                // Äußerer Schein / Glanz-Effekt
                Circle()
                    .fill(metallicGradient)
                    .frame(width: 48, height: 48)
                    .shadow(color: shadowColor.opacity(0.3), radius: 6, x: 0, y: 3)
                
                // Innerer Ring zur geometrischen Abgrenzung
                Circle()
                    .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                    .frame(width: 44, height: 44)
                
                // Spezialrahmen für Platin / Special
                if metalType == .platinum || metalType == .special {
                    Circle()
                        .stroke(metalType == .special ? Color(red: 1.0, green: 0.85, blue: 0.3) : Color.white, lineWidth: 1)
                        .frame(width: 40, height: 40)
                }
                
                // Zentrales Symbol
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(iconColor)
            } else {
                // Gesperrter Zustand (Graustufen)
                Circle()
                    .fill(Color.primary.opacity(0.04))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1.5)
                    )
                
                Image(systemName: "lock.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary.opacity(0.4))
            }
        }
        .frame(width: 52, height: 52)
    }
    
    private var shadowColor: Color {
        switch metalType {
        case .bronze: return .orange
        case .silver: return .gray
        case .gold: return .yellow
        case .platinum: return .blue
        case .special: return .red
        }
    }
    
    private var iconColor: Color {
        switch metalType {
        case .special:
            // Goldene Nadel bei der Spezialmedaille
            return Color(red: 1.0, green: 0.85, blue: 0.3)
        case .platinum:
            return .white
        default:
            return .white
        }
    }
}

// Xcode Canvas Preview
#Preview {
    ProfileView()
        .environmentObject(AuthService(isDemoMode: true))
}
