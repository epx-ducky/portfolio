import SwiftUI
import FamilyControls

struct ContentView: View {
    @State private var activeTab: Tab = .dashboard
    
    enum Tab {
        case dashboard
        case tasks
        case timeline
        case blockList
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
                case .blockList:
                    BlockListView()
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
            tabButton(tab: .dashboard, icon: "bolt.heart.fill", label: "Dopamine")
            tabButton(tab: .tasks, icon: "checklist", label: "Tasks")
            tabButton(tab: .timeline, icon: "calendar.day.timeline.left", label: "Timeline")
            tabButton(tab: .blockList, icon: "shield.fill", label: "Shield")
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
                    .font(.system(size: 10, weight: isSelected ? .bold : .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? .white : .gray)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Block List View for App Shield Picker
struct BlockListView: View {
    @StateObject private var screenTime = ScreenTimeManager.shared
    @State private var showingPicker = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 10/255, green: 10/255, blue: 18/255)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Title Card
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "shield.lefthalf.filled")
                                    .font(.title2)
                                    .foregroundStyle(Color(hex: "00FF87"))
                                Text("SYSTEM SHIELDING")
                                    .font(.system(.caption, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundStyle(.gray)
                                    .tracking(2)
                            }
                            
                            Text("Configure distractions to block when your daily dopamine is under 100%.")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(.gray)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.02))
                        .cornerRadius(20)
                        
                        // Select Button
                        Button(action: { showingPicker = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                Text("Choose Distracting Apps")
                                    .fontWeight(.bold)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                            }
                            .foregroundStyle(.black)
                            .padding()
                            .background(Color(hex: "00FF87"))
                            .cornerRadius(16)
                        }
                        .familyActivityPicker(isPresented: $showingPicker, selection: $screenTime.selection)
                        
                        // Current Selection Summary
                        VStack(alignment: .leading, spacing: 16) {
                            Text("ACTIVE RESTRICTIONS")
                                .font(.system(.caption, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundStyle(.gray)
                                .tracking(1.5)
                            
                            let appCount = screenTime.selection.applicationTokens.count
                            let categoryCount = screenTime.selection.categoryTokens.count
                            
                            if appCount == 0 && categoryCount == 0 {
                                HStack {
                                    Spacer()
                                    VStack(spacing: 8) {
                                        Image(systemName: "lock.shield")
                                            .font(.title)
                                            .foregroundStyle(.gray.opacity(0.4))
                                        Text("No individual apps selected.")
                                            .font(.subheadline)
                                            .foregroundStyle(.gray)
                                        Text("By default, the shield will restrict all entertainment & social media categories.")
                                            .font(.caption2)
                                            .foregroundStyle(.gray.opacity(0.8))
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 16)
                                    }
                                    .padding(.vertical, 24)
                                    Spacer()
                                }
                                .background(Color.white.opacity(0.02))
                                .cornerRadius(16)
                            } else {
                                VStack(spacing: 12) {
                                    if appCount > 0 {
                                        HStack {
                                            Image(systemName: "app.badge.fill")
                                                .foregroundStyle(Color(hex: "60EFFF"))
                                            Text("Selected Apps")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                            Spacer()
                                            Text("\(appCount) configured")
                                                .font(.caption)
                                                .foregroundStyle(.gray)
                                        }
                                        .padding()
                                        .background(Color.white.opacity(0.03))
                                        .cornerRadius(12)
                                    }
                                    
                                    if categoryCount > 0 {
                                        HStack {
                                            Image(systemName: "grid.circle.fill")
                                                .foregroundStyle(Color(hex: "8A2387"))
                                            Text("Selected Categories")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                            Spacer()
                                            Text("\(categoryCount) configured")
                                                .font(.caption)
                                                .foregroundStyle(.gray)
                                        }
                                        .padding()
                                        .background(Color.white.opacity(0.03))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 100)
                }
            }
            .navigationTitle("Shielding")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
