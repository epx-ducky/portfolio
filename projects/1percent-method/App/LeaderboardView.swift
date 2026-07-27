import SwiftUI

/// Modell für einen Spieler in der Rangliste.
struct LeaderboardPlayer: Identifiable {
    let id: UUID = UUID()
    let rank: Int
    let name: String
    let score: Double
    let dailyImpact: Double
    let isCurrentUser: Bool
}

/// Die Leaderboard-Ansicht (Rangliste der Saison) der App als Bottom-Sheet.
///
/// Listet Mitstreiter auf und hebt den aktuellen Benutzer farblich hervor.
/// Zeigt in dieser Version nur den echten Nutzer als Rank 1, da keine Fake-Nutzer gelistet werden sollen.
public struct LeaderboardView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    let currentUserScore: Double
    
    // Die echte Spielerliste der Saison (nur du selbst)
    private var players: [LeaderboardPlayer] {
        [
            LeaderboardPlayer(rank: 1, name: "Du (villain)", score: currentUserScore, dailyImpact: 0.0, isCurrentUser: true)
        ]
    }
    
    public init(currentUserScore: Double) {
        self.currentUserScore = currentUserScore
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // --- HEADER BRANDING ---
                    VStack(spacing: 6) {
                        Text("1% METHODE")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.red)
                            .tracking(3.0)
                        
                        Text("Saison-Rangliste")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Der FIFA-Loop Wettbewerb: Wer hält sein Zinseszins-Wachstum am konstantesten?")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    .padding(.top, 16)
                    
                    // --- PLAYER LIST ---
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(Array(players.enumerated()), id: \.offset) { index, player in
                                let displayRank = index + 1
                                LeaderboardRow(player: player, displayRank: displayRank)
                            }
                            
                            // Koop-Lobby Motivationseinladung, da der Nutzer alleine ist
                            VStack(spacing: 8) {
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 24))
                                    .foregroundColor(.secondary)
                                    .padding(.bottom, 4)
                                Text("Du bist aktuell auf Platz 1!")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Lade Freunde ein, um eure tägliche Capability live zu vergleichen und euch gegenseitig zu pushen!")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 16)
                            }
                            .padding(.vertical, 24)
                            .frame(maxWidth: .infinity)
                            .background(Color(.secondarySystemGroupedBackground).opacity(0.5))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                            )
                            .padding(.top, 16)
                        }
                        .padding(.horizontal, 2)
                    }
                    
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Bestenliste")
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

/// Einzelne Spielerzeile in der Rangliste.
struct LeaderboardRow: View {
    let player: LeaderboardPlayer
    let displayRank: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Rang-Emblem
            ZStack {
                Circle()
                    .fill(player.isCurrentUser ? Color.red.opacity(0.1) : Color.primary.opacity(0.03))
                    .frame(width: 36, height: 36)
                
                Text("\(displayRank)")
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(player.isCurrentUser ? .red : .primary)
            }
            
            // Name
            VStack(alignment: .leading, spacing: 2) {
                Text(player.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(player.isCurrentUser ? .red : .primary)
                
                Text(player.isCurrentUser ? "Das bist du" : "Mitstreiter")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Score & Trend
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.2f%%", player.score))
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    let impactSign = player.dailyImpact > 0 ? "+" : ""
                    Text("\(impactSign)\(String(format: "%.1f", player.dailyImpact))%")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(player.dailyImpact >= 0 ? .green : .red)
                    
                    Image(systemName: player.dailyImpact >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(player.dailyImpact >= 0 ? .green : .red)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(player.isCurrentUser ? Color.red.opacity(0.15) : Color.primary.opacity(0.04), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.01), radius: 5, x: 0, y: 3)
    }
}

// Xcode Canvas Preview
#Preview {
    LeaderboardView(currentUserScore: 143.02)
}
