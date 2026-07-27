import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var activeTab: Tab = .dashboard
    
    enum Tab {
        case dashboard
        case tasks
        case timeline
        case profile
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Screen switching
            Group {
                switch activeTab {
                case .dashboard:
                    DashboardView()
                case .tasks:
                    TaskListView()
                case .timeline:
                    ProactiveTimelineView()
                case .profile:
                    ConsistencyProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Navigation Glassmorphism Tab Bar
            customTabBar
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .preferredColorScheme(.dark)
    }
    
    private var customTabBar: some View {
        HStack {
            tabButton(tab: .dashboard, icon: "flame.fill", label: "Daily Score")
            tabButton(tab: .tasks, icon: "checklist", label: "Tasks")
            tabButton(tab: .timeline, icon: "calendar.day.timeline.left", label: "Timeline")
            tabButton(tab: .profile, icon: "crown.fill", label: "Profil")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
    
    private func tabButton(tab: Tab, icon: String, label: String) -> some View {
        let isSelected = activeTab == tab
        
        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                activeTab = tab
            }
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred()
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(
                        isSelected ?
                        LinearGradient(colors: [Color(hex: "00FF87"), Color(hex: "60EFFF")], startPoint: .top, endPoint: .bottom) :
                        LinearGradient(colors: [.gray], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(height: 26)
                
                Text(label)
                    .font(.system(size: 9, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundStyle(isSelected ? .white : .gray)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Consistency & Level Profile View
struct ConsistencyProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var scores: [DopamineScore]
    @Query(sort: \TaskCompletionRecord.timestamp) private var completionRecords: [TaskCompletionRecord]
    
    private var dopamineScore: DopamineScore {
        scores.first ?? DopamineScore(currentPercentage: 0.20, dailyResetTimestamp: Date())
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 10/255, green: 10/255, blue: 18/255)
                    .ignoresSafeArea()
                
                // Ambient Background Glow
                ambientGlowView
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Profile Banner / Level Badge
                        profileHeader
                        
                        // Consistency Stats Grid
                        statsGrid
                        
                        // Milestones / Achievements
                        milestonesSection
                    }
                    .padding()
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 100)
                }
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var ambientGlowView: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(Color(hex: "00FF87").opacity(0.12))
                    .frame(width: 250, height: 250)
                    .blur(radius: 80)
                    .position(x: geo.size.width * 0.8, y: geo.size.height * 0.2)
                
                Circle()
                    .fill(Color(hex: "FF5E3A").opacity(0.12))
                    .frame(width: 300, height: 300)
                    .blur(radius: 90)
                    .position(x: geo.size.width * 0.2, y: geo.size.height * 0.7)
            }
        }
    }
    
    private var profileHeader: some View {
        let xp = dopamineScore.consistencyXP ?? 0
        let level = (xp / 100) + 1
        let rank = consistencyRank(for: dopamineScore.streakCount ?? 0)
        
        return VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "00FF87").opacity(0.15), Color(hex: "FF5E3A").opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 110, height: 110)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color(hex: "00FF87"), Color(hex: "FF5E3A")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: Color(hex: "00FF87").opacity(0.3), radius: 15)
                
                Text(rank.badge)
                    .font(.system(size: 48))
            }
            
            VStack(spacing: 4) {
                Text(rank.title)
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Text("Level \(level) Coach")
                    .font(.system(.subheadline, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundStyle(.gray)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var statsGrid: some View {
        let xp = dopamineScore.consistencyXP ?? 0
        let streak = dopamineScore.streakCount ?? 0
        let totalCompleted = completionRecords.count
        
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            statCard(title: "AKTUELLER STREAK", value: "\(streak) Tage", icon: "flame.fill", iconColor: Color(hex: "FF5E3A"))
            statCard(title: "GESAMT XP", value: "\(xp) XP", icon: "bolt.fill", iconColor: Color(hex: "00FF87"))
            statCard(title: "ERLEDIGTE TASKS", value: "\(totalCompleted)", icon: "checkmark.circle.fill", iconColor: Color(hex: "60EFFF"))
            statCard(title: "LEVEL FORTSCHRITT", value: "\(xp % 100) / 100", icon: "star.fill", iconColor: Color(hex: "FFCC00"))
        }
    }
    
    private func statCard(title: String, value: String, icon: String, iconColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(iconColor)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(.gray)
                    .tracking(1)
                
                Text(value)
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
    
    private var milestonesSection: some View {
        let streak = dopamineScore.streakCount ?? 0
        let total = completionRecords.count
        
        let milestones = [
            Milestone(id: 1, title: "Erster Schritt", desc: "Erledige deine erste Aufgabe", target: 1, current: total, type: .tasks),
            Milestone(id: 2, title: "Flammen-Starter", desc: "Erreiche einen 3-Tage-Streak", target: 3, current: streak, type: .streak),
            Milestone(id: 3, title: "Fokus-Krieger", desc: "Erreiche einen 7-Tage-Streak", target: 7, current: streak, type: .streak),
            Milestone(id: 4, title: "Disziplin-Legende", desc: "Erreiche einen 15-Tage-Streak", target: 15, current: streak, type: .streak),
            Milestone(id: 5, title: "Meister der Beständigkeit", desc: "Erledige insgesamt 50 Aufgaben", target: 50, current: total, type: .tasks)
        ]
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("MEILENSTEINE")
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.bold)
                .foregroundStyle(.gray)
                .tracking(1.5)
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                ForEach(milestones) { milestone in
                    let isUnlocked = milestone.current >= milestone.target
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(isUnlocked ? Color(hex: "00FF87").opacity(0.12) : Color.white.opacity(0.04))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: isUnlocked ? "checkmark.seal.fill" : "lock.fill")
                                .font(.body)
                                .foregroundStyle(isUnlocked ? Color(hex: "00FF87") : .gray)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(milestone.title)
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundStyle(isUnlocked ? .white : .gray)
                            
                            Text(milestone.desc)
                                .font(.caption2)
                                .foregroundStyle(.gray)
                        }
                        Spacer()
                        
                        Text("\(min(milestone.current, milestone.target))/\(milestone.target)")
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundStyle(isUnlocked ? Color(hex: "00FF87") : .gray)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.01))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(isUnlocked ? Color(hex: "00FF87").opacity(0.1) : Color.white.opacity(0.04), lineWidth: 1)
                            )
                    )
                }
            }
        }
    }
    
    struct Milestone: Identifiable {
        let id: Int
        let title: String
        let desc: String
        let target: Int
        let current: Int
        enum MType { case streak, tasks }
        let type: MType
    }
    
    struct RankInfo {
        let title: String
        let badge: String
        let color: Color
    }
    
    private func consistencyRank(for streak: Int) -> RankInfo {
        switch streak {
        case 0...2:
            return RankInfo(title: "Anfänger", badge: "🥉", color: .gray)
        case 3...5:
            return RankInfo(title: "Gewohnheits-Schmied", badge: "🥈", color: Color(hex: "FF9500"))
        case 6...10:
            return RankInfo(title: "Disziplin-Schüler", badge: "🥇", color: Color(hex: "FFCC00"))
        case 11...20:
            return RankInfo(title: "Fokus-Meister", badge: "💎", color: Color(hex: "00C7BE"))
        case 21...30:
            return RankInfo(title: "Unaufhaltsam", badge: "🏆", color: Color(hex: "FF2D55"))
        default:
            return RankInfo(title: "Götter-Modus", badge: "🌌", color: Color(hex: "AF52DE"))
        }
    }
}
