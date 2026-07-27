import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import Combine
import SwiftUI

@MainActor
public final class ScreenTimeManager: ObservableObject {
    public static let shared = ScreenTimeManager()
    
    private let store = ManagedSettingsStore()
    
    @Published public var isAuthorized: Bool = false
    
    // FamilyActivitySelection holds the selected applications and categories chosen by the user via the FamilyActivityPicker.
    @Published public var selection = FamilyActivitySelection() {
        didSet {
            saveSelection()
        }
    }
    
    // Configurable/hardcoded list of bundle identifiers we target.
    // Note: Due to iOS sandbox security, bundle IDs cannot be direct-converted into ApplicationTokens programmatically.
    // However, they can be matched using DeviceActivityMonitor extensions or presented in UI instructions.
    public let targetedBundleIDs = [
        "com.toyopagroup.picaboo",    // Snapchat
        "com.ea.gp.fifamobile",       // FIFA Mobile
        "com.burbn.instagram",        // Instagram
        "com.zhiliaoapp.musically"    // TikTok
    ]
    
    private let userDefaultsKey = "PersonalManagerBlockedApps"
    
    private init() {
        loadSelection()
        checkAuthorizationStatus()
    }
    
    /// Checks the current authorization status.
    public func checkAuthorizationStatus() {
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
    }
    
    /// Requests Screen Time authorization for the individual user.
    public func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
        } catch {
            print("Failed to authorize Screen Time: \(error.localizedDescription)")
            isAuthorized = false
        }
    }
    
    /// Evaluates whether application shields should be active based on the current dopamine score.
    public func evaluateShieldState(currentScore: Double) {
        guard isAuthorized else {
            print("ScreenTimeManager: Not authorized. Shield evaluation skipped.")
            return
        }
        
        if currentScore < 1.0 {
            // Activating Shield: Block designated distracting apps/categories.
            // If the user has selected specific apps/categories via the picker, we block them.
            var hasActiveShield = false
            
            if !selection.applicationTokens.isEmpty {
                store.shield.applications = selection.applicationTokens
                hasActiveShield = true
            } else {
                store.shield.applications = nil
            }
            
            if !selection.categoryTokens.isEmpty {
                store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
                hasActiveShield = true
            } else {
                store.shield.applicationCategories = nil
            }
            
            // If the user hasn't selected anything yet, default to shielding all categories to prevent usage
            // during startup/learning blocks.
            if !hasActiveShield {
                store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.all()
                print("Shield activated: Shielding all application categories (default behavior).")
            } else {
                print("Shield activated: Shielding selected applications and categories.")
            }
        } else {
            // Deactivating Shield: User completed their daily checklist (score reaches 100%).
            store.shield.applications = nil
            store.shield.applicationCategories = nil
            print("Shield deactivated: Free evening use unlocked!")
        }
    }
    
    // MARK: - Persistence Helpers
    
    private func saveSelection() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(selection) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadSelection() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey) {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode(FamilyActivitySelection.self, from: data) {
                self.selection = decoded
            }
        }
    }
}
