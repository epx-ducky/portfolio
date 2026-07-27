import SwiftUI

/// Die Ansicht zur Verifizierung des 2FA-Codes (Zwei-Faktor-Authentisierung).
///
/// Bietet ein elegantes, rasterbasiertes Eingabefeld für den 6-stelligen Code
/// und leitet diesen an den `AuthService` weiter.
public struct MFAVerificationView: View {
    
    @ObservedObject var authService: AuthService
    let email: String
    let factorId: String
    
    @State private var code = ""
    @FocusState private var isCodeFieldFocused: Bool
    
    public init(authService: AuthService, email: String, factorId: String) {
        self.authService = authService
        self.email = email
        self.factorId = factorId
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    
                    // --- ICON & TITLE ---
                    VStack(spacing: 12) {
                        Image(systemName: "shield.keycard.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.primary)
                            .padding(.top, 40)
                        
                        Text("Zwei-Faktor-Schutz")
                            .font(.system(.title2, design: .default))
                            .fontWeight(.bold)
                        
                        Text("Wir haben einen zusätzlichen Schutz für dein Konto aktiviert. Bitte gib den 6-stelligen Code aus deiner Authenticator-App für \(email) ein.")
                            .font(.system(.subheadline, design: .default))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    
                    // --- 6-STELLIGES EINGABERASTER ---
                    ZStack {
                        // Unsichtbares Textfeld zur Tastatur-Anbindung
                        TextField("", text: Binding(
                            get: { code },
                            set: { newValue in
                                // Filtere nur Zahlen und begrenze auf 6 Zeichen
                                let filtered = newValue.filter { $0.isNumber }
                                code = String(filtered.prefix(6))
                                
                                // Sobald 6 Ziffern erreicht sind, verifizieren wir automatisch
                                if code.count == 6 {
                                    Task {
                                        let _ = await authService.verifyTOTPCode(factorId: factorId, code: code)
                                    }
                                }
                            }
                        ))
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .focused($isCodeFieldFocused)
                        .opacity(0.01) // Fast unsichtbar, aber interaktiv
                        .frame(width: 1, height: 1)
                        
                        // Das sichtbare Raster (6 separate Boxen)
                        HStack(spacing: 12) {
                            ForEach(0..<6, id: \.self) { index in
                                let digit = getDigit(at: index)
                                let isActive = isCodeFieldFocused && code.count == index
                                
                                Text(digit)
                                    .font(.custom("Courier New", size: 28))
                                    .fontWeight(.bold)
                                    .frame(width: 48, height: 56)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                isActive ? Color.primary : Color.primary.opacity(0.08),
                                                lineWidth: isActive ? 2 : 1
                                            )
                                    )
                                    .multilineTextAlignment(.center)
                                    .onTapGesture {
                                        isCodeFieldFocused = true
                                    }
                            }
                        }
                    }
                    .padding(.vertical, 12)
                    
                    // --- FEHLERANZEIGE (Typewriter Monospace) ---
                    if let error = authService.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.system(.footnote, design: .monospaced))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer()
                    
                    // --- AKTIONSTASTEN (Haptisches Feedback) ---
                    VStack(spacing: 14) {
                        Button(action: {
                            Task {
                                let _ = await authService.verifyTOTPCode(factorId: factorId, code: code)
                            }
                        }) {
                            Text("Bestätigen")
                                .font(.system(.headline))
                                .foregroundColor(Color(.systemBackground))
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(code.count == 6 ? Color.primary : Color.primary.opacity(0.4))
                                .cornerRadius(16)
                        }
                        .buttonStyle(TactileButtonStyle())
                        .disabled(code.count < 6 || authService.sessionState == .loading)
                        
                        Button(action: {
                            authService.cancelMFAChallenge()
                        }) {
                            Text("Zurück zur Anmeldung")
                                .font(.system(.subheadline))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Zwei-Faktor")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Automatischer Fokus auf die Codeeingabe beim Laden der View
                isCodeFieldFocused = true
            }
        }
    }
    
    // Extrahiert die Ziffer an einem bestimmten Index des Codes
    private func getDigit(at index: Int) -> String {
        guard index < code.count else { return "" }
        let startIndex = code.index(code.startIndex, offsetBy: index)
        return String(code[startIndex])
    }
}

// Xcode Canvas Preview
#Preview {
    MFAVerificationView(
        authService: AuthService(isDemoMode: true),
        email: "demo@1percent.de",
        factorId: "demo-factor"
    )
}
