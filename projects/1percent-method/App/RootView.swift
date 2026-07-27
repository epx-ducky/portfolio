import SwiftUI

/// Die Root-Einstiegsansicht der App, die das Routing steuert.
///
/// Entscheidet anhand des Session-Zustands im `AuthService`, ob der
/// Authentifizierungsbildschirm (AuthView), der 2FA-Bildschirm (MFAVerificationView)
/// oder das Haupt-Dashboard (DashboardView) angezeigt werden soll.
public struct RootView: View {
    
    @StateObject private var authService = AuthService(isDemoMode: true)
    
    public init() {}
    
    public var body: some View {
        Group {
            switch authService.sessionState {
            case .loading:
                // Start- / Ladebildschirm mit Monospace-Ladeanzeige
                ZStack {
                    Color(.systemBackground)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        Text("1%")
                            .font(.custom("Courier New", size: 64))
                            .fontWeight(.bold)
                            .tracking(2.0)
                        
                        ProgressView()
                            .tint(.primary)
                        
                        Text("Sitzung wird geladen...")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                
            case .unauthenticated:
                AuthView(authService: authService)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                        removal: .opacity
                    ))
                
            case .emailVerificationPending(let email):
                ZStack {
                    Color(.systemGroupedBackground)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 32) {
                        Spacer()
                        
                        VStack(spacing: 20) {
                            Image(systemName: "envelope.badge.shield.half.filled")
                                .font(.system(size: 54))
                                .foregroundColor(.red)
                                .padding(.bottom, 4)
                            
                            Text("E-Mail verifizieren")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                            
                            VStack(spacing: 8) {
                                Text("Wir haben eine Aktivierungs-E-Mail gesendet an:")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                Text(email)
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                            }
                            
                            Text("Bitte bestätige dein Konto über den darin enthaltenen Link, um dich anschließend anzumelden.")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)
                                .padding(.horizontal, 10)
                        }
                        .padding(28)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                        )
                        
                        Button(action: {
                            authService.cancelEmailVerification()
                        }) {
                            Text("Zurück zum Login")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color(.systemBackground))
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.primary)
                                .cornerRadius(16)
                        }
                        .buttonStyle(TactileButtonStyle())
                        
                        Spacer()
                    }
                    .padding(24)
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                    removal: .opacity
                ))
                
            case .mfaChallengeRequired(_, let email, let factorId):
                MFAVerificationView(authService: authService, email: email, factorId: factorId)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity
                    ))
                
            case .authenticated(_, _, let username, let isMFAVerified):
                DashboardView()
                    .environmentObject(authService)
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .opacity
                    ))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: authService.sessionState)
    }
}

// Xcode Canvas Preview
#Preview {
    RootView()
}
