import SwiftUI

/// Die Ansicht zur Benutzer-Registrierung und -Anmeldung.
///
/// Integriert sich mit `AuthService` und nutzt ein minimalistisches,
/// modernes Design mit Monospace-Performance-Indikatoren.
public struct AuthView: View {
    
    @ObservedObject var authService: AuthService
    
    @State private var isLoginTab = true
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password, username
    }
    
    public init(authService: AuthService) {
        self.authService = authService
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        
                        // --- LOGO / HEADER ---
                        VStack(spacing: 12) {
                            Text("1%")
                                .font(.custom("Courier New", size: 64))
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .padding(.top, 40)
                            
                            Text("Die Methode zur täglichen Verbesserung.")
                                .font(.system(.subheadline, design: .default))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // --- TAB STEUERUNG (Segmented Control) ---
                        Picker("Authentifizierungsmodus", selection: $isLoginTab) {
                            Text("Anmelden").tag(true)
                            Text("Registrieren").tag(false)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 4)
                        
                        // --- EINGABEFELDER-CARD ---
                        VStack(spacing: 18) {
                            if !isLoginTab {
                                // Benutzername-Feld (nur bei Registrierung)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("BENUTZERNAME")
                                        .font(.system(.caption, design: .default))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("z.B. max_mustermann", text: $username)
                                        .textFieldStyle(SimpleInputStyle(focused: focusedField == .username))
                                        .focused($focusedField, equals: .username)
                                        .textContentType(.username)
                                        .autocorrectionDisabled()
                                        .submitLabel(.next)
                                        .onSubmit {
                                            focusedField = .email
                                        }
                                }
                            }
                            
                            // E-Mail Feld
                            VStack(alignment: .leading, spacing: 6) {
                                Text("E-MAIL-ADRESSE")
                                    .font(.system(.caption, design: .default))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                
                                TextField("name@domain.de", text: $email)
                                    .textFieldStyle(SimpleInputStyle(focused: focusedField == .email))
                                    .focused($focusedField, equals: .email)
                                    .keyboardType(.emailAddress)
                                    .textContentType(.emailAddress)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                    .submitLabel(.next)
                                    .onSubmit {
                                        focusedField = .password
                                    }
                            }
                            
                            // Passwort Feld
                            VStack(alignment: .leading, spacing: 6) {
                                Text("PASSWORT")
                                    .font(.system(.caption, design: .default))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                
                                SecureField("••••••••", text: $password)
                                    .textFieldStyle(SimpleInputStyle(focused: focusedField == .password))
                                    .focused($focusedField, equals: .password)
                                    .textContentType(isLoginTab ? .password : .newPassword)
                                    .submitLabel(.done)
                                    .onSubmit {
                                        Task { @MainActor in
                                            focusedField = nil
                                            if isLoginTab {
                                                let _ = await authService.signIn(email: email, password: password)
                                            } else {
                                                let _ = await authService.signUp(email: email, password: password, username: username)
                                            }
                                        }
                                    }
                                
                                // Passwort-Stärkeanzeige (Monospace für Statistiken)
                                if !isLoginTab && !password.isEmpty {
                                    HStack {
                                        Text("Länge:")
                                            .font(.system(.caption, design: .default))
                                            .foregroundColor(.secondary)
                                        Text("\(password.count) Zeichen")
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(password.count >= 6 ? .green : .orange)
                                    }
                                    .padding(.top, 2)
                                }
                            }
                        }
                        .padding(24)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                        )
                        
                        // --- FEHLERANZEIGE (Typewriter-Stil in Monospace) ---
                        if let error = authService.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(.system(.footnote, design: .monospaced))
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // --- AKTIONSTASTE (Tactile Feedback & Shimmer) ---
                        Button(action: {
                            Task { @MainActor in
                                focusedField = nil
                                if isLoginTab {
                                    let _ = await authService.signIn(email: email, password: password)
                                } else {
                                    let _ = await authService.signUp(email: email, password: password, username: username)
                                }
                            }
                        }) {
                            HStack {
                                if authService.sessionState == .loading {
                                    ProgressView()
                                        .tint(.white)
                                        .padding(.trailing, 8)
                                    Text("Wird geladen...")
                                        .font(.system(.headline, design: .default))
                                } else {
                                    Text(isLoginTab ? "Anmelden" : "Konto erstellen")
                                        .font(.system(.headline, design: .default))
                                }
                            }
                            .foregroundColor(Color(.systemBackground))
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.primary)
                            .cornerRadius(16)
                        }
                        .buttonStyle(TactileButtonStyle())
                        .disabled(authService.sessionState == .loading)
                        
                    }
                    .padding()
                }
            }
            .navigationTitle(isLoginTab ? "Anmelden" : "Registrieren")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Fertig") {
                        focusedField = nil
                    }
                }
            }
        }
    }
}

// Minimalistischer, moderner Rahmen-Style für Eingabefelder
struct SimpleInputStyle: TextFieldStyle {
    var focused: Bool
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .frame(height: 48)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(focused ? Color.primary : Color.primary.opacity(0.08), lineWidth: focused ? 1.5 : 1)
            )
            .animation(.easeInOut(duration: 0.15), value: focused)
    }
}

// Springender Druck-Effekt für Knöpfe (Haptisches Gefühl)
struct TactileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.95 : 1.0)
            .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

// Xcode Canvas Preview
#Preview {
    AuthView(authService: AuthService(isDemoMode: true))
}
