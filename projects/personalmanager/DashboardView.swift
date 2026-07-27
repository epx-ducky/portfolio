import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var scores: [DopamineScore]
    
    @State private var isUnlocking = false
    @State private var animateGlow = false
    @State private var showGainNotification = false
    @State private var lastGainAmount = 0.0
    
    // Core Dopamine Score computed property
    private var dopamineScore: DopamineScore {
        if let existing = scores.first {
            existing.resetIfNewDay(context: modelContext)
            return existing
        } else {
            let newScore = DopamineScore(currentPercentage: 0.20, dailyResetTimestamp: Date())
            modelContext.insert(newScore)
            try? modelContext.save()
            return newScore
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background Gradient
                Color(red: 10/255, green: 10/255, blue: 18/255)
                    .ignoresSafeArea()
                
                // Ambient Background Glow
                ambientGlowView
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        headerView
                        
                        // Circular Progress Bar Section
                        progressRingSection
                        
                        // Gamified Stats & Quotes Section
                        gamifiedStatsSection
                        
                        // Recent Gains History List
                        gainsHistorySection
                    }
                    .padding()
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 100)
                }
            }
            .navigationTitle("Daily Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    let state = dopamineScore.streakState
                    let count = dopamineScore.streakCount ?? 0
                    
                    HStack(spacing: 4) {
                        Image(systemName: state == .frozen ? "snowflake" : "flame.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(state == .frozen ? Color(hex: "60EFFF") : Color(hex: "F27121"))
                        
                        Text("\(count)")
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: triggerManualReset) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
            .onChange(of: dopamineScore.currentPercentage) { oldValue, newValue in
                handleScoreChange(from: oldValue, to: newValue)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        VStack(spacing: 4) {
            Text("TODAY'S SCORE")
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.bold)
                .foregroundStyle(.gray)
                .tracking(2)
            
            Text(Date().formatted(date: .complete, time: .omitted))
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.gray)
        }
        .padding(.top, 8)
    }
    
    private var progressRingSection: some View {
        VStack {
            ZStack {
                // Outer Track Ring
                Circle()
                    .stroke(Color.white.opacity(0.04), lineWidth: 28)
                    .frame(width: 260, height: 260)
                
                // Glowing background shadow for progress
                Circle()
                    .trim(from: 0, to: CGFloat(dopamineScore.currentPercentage))
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "8A2387"), Color(hex: "E94057"), Color(hex: "F27121")],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        style: StrokeStyle(lineWidth: 28, lineCap: .round)
                    )
                    .frame(width: 260, height: 260)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Color(hex: "E94057").opacity(animateGlow ? 0.6 : 0.3), radius: 15, x: 0, y: 0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateGlow)
                
                // Center Percentage Label
                VStack(spacing: 8) {
                    Text("\(Int(dopamineScore.currentPercentage * 100))%")
                        .font(.system(size: 54, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                    
                    let state = dopamineScore.streakState
                    if state == .frozen {
                        HStack(spacing: 4) {
                            Image(systemName: "snowflake")
                                .font(.system(size: 8))
                            Text("GEFROREN")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                        }
                        .foregroundStyle(Color(hex: "60EFFF"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(hex: "60EFFF").opacity(0.15))
                        .cornerRadius(6)
                    } else {
                        Text(dopamineScore.currentPercentage >= 1.0 ? "UNLOCKED" : "LOCKED")
                            .font(.system(.caption2, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundStyle(dopamineScore.currentPercentage >= 1.0 ? Color(hex: "00FF87") : .gray)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(dopamineScore.currentPercentage >= 1.0 ? Color(hex: "00FF87").opacity(0.1) : Color.white.opacity(0.05))
                            )
                    }
                }
            }
            .frame(width: 280, height: 280)
            .onAppear {
                animateGlow = true
            }
        }
    }
    
    private var gamifiedStatsSection: some View {
        VStack(spacing: 16) {
            // Daily Quote Card
            let quote = getDailyQuote()
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "quote.opening")
                        .font(.title3)
                        .foregroundStyle(Color(hex: "00FF87").opacity(0.8))
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\"\(quote.text)\"")
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)
                            .italic()
                            .foregroundStyle(.white.opacity(0.95))
                            .lineSpacing(4)
                        
                        Text("— \(quote.speaker)")
                            .font(.system(.caption2, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundStyle(Color(hex: "FF5E3A"))
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            
            // Consistency Rank Card
            let xp = dopamineScore.consistencyXP ?? 0
            let level = (xp / 100) + 1
            let xpProgress = xp % 100
            let rank = consistencyRank(for: dopamineScore.streakCount ?? 0)
            
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Konsistenz-Rang")
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundStyle(.gray)
                        
                        HStack(spacing: 6) {
                            Text(rank.title)
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundStyle(rank.color)
                            Text(rank.badge)
                                .font(.title3)
                        }
                    }
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Level \(level)")
                            .font(.system(.title3, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundStyle(Color(hex: "00FF87"))
                        
                        Text("Gesamt: \(xp) XP")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.gray)
                    }
                }
                
                // XP Progress Bar
                VStack(alignment: .leading, spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "00FF87"), Color(hex: "60EFFF")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * CGFloat(xpProgress) / 100.0, height: 8)
                        }
                    }
                    .frame(height: 8)
                    
                    Text("\(xpProgress)/100 XP bis Level Up")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.gray)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
    }
    
    private var gainsHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("TODAY'S GAINS")
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.bold)
                .foregroundStyle(.gray)
                .tracking(1)
            
            if dopamineScore.gains.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "chart.bar.fill")
                            .font(.title)
                            .foregroundStyle(.gray.opacity(0.3))
                        Text("No gains logged yet today.")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }
                    .padding(.vertical, 24)
                    Spacer()
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.02))
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(dopamineScore.gains.sorted(by: { $0.timestamp > $1.timestamp })) { gain in
                        HStack {
                            Image(systemName: "bolt.fill")
                                .foregroundStyle(Color(hex: "F27121"))
                                .padding(8)
                                .background(Color(hex: "F27121").opacity(0.1))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(gain.activityName)
                                    .font(.system(.body, design: .rounded))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                Text(gain.timestamp.formatted(date: .omitted, time: .shortened))
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                            }
                            Spacer()
                            Text("+\(Int(gain.amount * 100))%")
                                .font(.system(.subheadline, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundStyle(Color(hex: "00FF87"))
                        }
                        .padding()
                        .background(Color.white.opacity(0.02))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    private var ambientGlowView: some View {
        VStack {
            Spacer()
            Circle()
                .fill(Color(hex: dopamineScore.currentPercentage >= 1.0 ? "00FF87" : "E94057").opacity(0.15))
                .frame(width: 400, height: 400)
                .blur(radius: 80)
                .offset(y: 150)
        }
    }
    
    // MARK: - Actions & Handlers
    
    private func handleScoreChange(from old: Double, to new: Double) {
        // Haptic Feedback for increments
        if new > old {
            if new >= 1.0 {
                // Large Unlock Haptic Pattern
                triggerUnlockHaptic()
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    isUnlocking = true
                }
            } else {
                // Minor gain feedback
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }
        }
    }
    
    private func triggerManualReset() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
        
        withAnimation {
            dopamineScore.currentPercentage = 0.20
            dopamineScore.gains.removeAll()
            dopamineScore.dailyResetTimestamp = Date()
            try? modelContext.save()
        }
    }
    
    private func triggerUnlockHaptic() {
        // Trigger sequence of haptics for full unlock
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
        }
    }
    
    // MARK: - Consistency & Quote Helpers
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
    
    struct MotivationalQuote {
        let text: String
        let speaker: String
    }
    
    private let motivationalQuotes = [
        MotivationalQuote(text: "Tough times create strong men. Strong men create easy times. Easy times create weak men. Weak men create tough times.", speaker: "G. Michael Hopf"),
        MotivationalQuote(text: "Don't stop when you're tired. Stop when you're done.", speaker: "David Goggins"),
        MotivationalQuote(text: "Who's gonna carry the boats and the logs?!", speaker: "David Goggins"),
        MotivationalQuote(text: "We are what we repeatedly do. Excellence, then, is not an act, but a habit.", speaker: "Aristotle"),
        MotivationalQuote(text: "Discipline equals freedom.", speaker: "Jocko Willink"),
        MotivationalQuote(text: "The pain of discipline is nothing like the pain of disappointment.", speaker: "Albert Einstein"),
        MotivationalQuote(text: "You have power over your mind - not outside events. Realize this, and you will find strength.", speaker: "Marcus Aurelius"),
        MotivationalQuote(text: "There are no limits. There are only plateaus, and you must not stay there, you must go beyond them.", speaker: "Bruce Lee"),
        MotivationalQuote(text: "Dedication makes dreams come true.", speaker: "Kobe Bryant"),
        MotivationalQuote(text: "If you want to shine like a sun, first burn like a sun.", speaker: "A. P. J. Abdul Kalam"),
        MotivationalQuote(text: "He who has a why to live for can bear almost any how.", speaker: "Friedrich Nietzsche"),
        MotivationalQuote(text: "It is not death that a man should fear, but he should fear never beginning to live.", speaker: "Marcus Aurelius"),
        MotivationalQuote(text: "Be so good they can't ignore you.", speaker: "Steve Martin"),
        MotivationalQuote(text: "The hard way is the right way. It's the only way.", speaker: "Jocko Willink")
    ]
    
    private func getDailyQuote() -> MotivationalQuote {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return motivationalQuotes[dayOfYear % motivationalQuotes.count]
    }
}

// MARK: - Color Hex Helper
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 1)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
