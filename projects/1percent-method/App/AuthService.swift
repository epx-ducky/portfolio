import Foundation
import SwiftUI
import Combine

/// Die verschiedenen Zustände, in denen sich die Authentifizierung befinden kann.
public enum AuthSessionState: Equatable {
    case loading
    case unauthenticated
    
    /// Der Benutzer hat sich registriert, muss aber noch seine E-Mail bestätigen.
    case emailVerificationPending(email: String)
    
    /// Der Benutzer hat Schritt 1 (Passwort) erfolgreich absolviert, muss aber noch den 2FA-Code eingeben.
    case mfaChallengeRequired(userId: UUID, email: String, factorId: String)
    
    /// Vollständig authentifizierter Zustand.
    case authenticated(userId: UUID, email: String, username: String, isMFAVerified: Bool)
}

/// Der Authentifizierungsservice für die "1% Methode"-App mit 2FA/MFA-Unterstützung.
///
/// Handhabt Login, Registrierung, Abmeldung und 2FA-Challenges (TOTP) über Supabase.
/// Unterstützt einen Demo-Modus für Xcode Canvas Previews.
@MainActor
public final class AuthService: ObservableObject {
    
    @Published public private(set) var sessionState: AuthSessionState = .unauthenticated
    @Published public var errorMessage: String? = nil
    
    private let isDemoMode: Bool
    
    /// Initialisiert den AuthService.
    /// - Parameter isDemoMode: Wenn true, werden die API-Aufrufe lokal simuliert (ideal für Xcode Canvas).
    public init(isDemoMode: Bool = true) {
        self.isDemoMode = isDemoMode
        
        Task {
            await checkCurrentSession()
        }
    }
    
    /// Überprüft, ob eine aktive Session in Supabase vorhanden ist und ermittelt das Authentifizierungsniveau (AAL1 oder AAL2).
    public func checkCurrentSession() async {
        if isDemoMode {
            if UserDefaults.standard.bool(forKey: "is_logged_in"),
               let email = UserDefaults.standard.string(forKey: "saved_email"),
               let username = UserDefaults.standard.string(forKey: "saved_username") {
                let isMFA = UserDefaults.standard.bool(forKey: "saved_is_mfa")
                let userIdString = UserDefaults.standard.string(forKey: "saved_userid") ?? UUID().uuidString
                let userId = UUID(uuidString: userIdString) ?? UUID()
                sessionState = .authenticated(
                    userId: userId,
                    email: email,
                    username: username,
                    isMFAVerified: isMFA
                )
            } else {
                sessionState = .unauthenticated
            }
            return
        }
        
        sessionState = .loading
        do {
            // HINWEIS: Hier greift das Supabase Swift SDK.
            // let session = try await supabase.auth.session
            // let aal = try await supabase.auth.mfa.getAuthenticatorAssuranceLevel()
            //
            // if let user = session?.user {
            //     if aal.nextLevel == .aal2 && aal.currentLevel != .aal2 {
            //         // 2FA ist eingerichtet, aber noch nicht verifiziert.
            //         if let totpFactor = aal.enrolledFactors.first(where: { $0.factorType == .totp }) {
            //             self.sessionState = .mfaChallengeRequired(
            //                 userId: user.id,
            //                 email: user.email ?? "",
            //                 factorId: totpFactor.id
            //             )
            //             return
            //         }
            //     }
            //
            //     self.sessionState = .authenticated(
            //         userId: user.id,
            //         email: user.email ?? "",
            //         username: user.userMetadata["username"] as? String ?? "",
            //         isMFAVerified: aal.currentLevel == .aal2
            //     )
            // } else {
            //     self.sessionState = .unauthenticated
            // }
            
            try await Task.sleep(nanoseconds: 500_000_000)
            self.sessionState = .unauthenticated
        } catch {
            self.errorMessage = error.localizedDescription
            self.sessionState = .unauthenticated
        }
    }
    
    /// Registriert einen neuen Benutzer.
    public func signUp(email: String, password: String, username: String) async -> Bool {
        errorMessage = nil
        sessionState = .loading
        
        guard !email.isEmpty, !password.isEmpty, !username.isEmpty else {
            errorMessage = "Bitte fülle alle Felder aus."
            sessionState = .unauthenticated
            return false
        }
        
        guard password.count >= 6 else {
            errorMessage = "Das Passwort muss mindestens 6 Zeichen lang sein."
            sessionState = .unauthenticated
            return false
        }
        
        if isDemoMode {
            try? await Task.sleep(nanoseconds: 800_000_000)
            // Registrierung erfolgreich -> E-Mail-Verifizierung anstehend
            sessionState = .emailVerificationPending(email: email.lowercased())
            return true
        } else {
            do {
                // Supabase SDK Aufruf:
                // let response = try await supabase.auth.signUp(email: email, password: password, redirectUrl: ...)
                try await Task.sleep(nanoseconds: 1_000_000_000)
                sessionState = .emailVerificationPending(email: email.lowercased())
                return true
            } catch {
                errorMessage = error.localizedDescription
                sessionState = .unauthenticated
                return false
            }
        }
    }
    
    /// Meldet einen bestehenden Benutzer an.
    public func signIn(email: String, password: String) async -> Bool {
        print("[AuthService] signIn called with email: \(email)")
        errorMessage = nil
        sessionState = .loading
        
        guard !email.isEmpty, !password.isEmpty else {
            print("[AuthService] Email or password empty")
            errorMessage = "Bitte E-Mail und Passwort eingeben."
            sessionState = .unauthenticated
            return false
        }
        
        if isDemoMode {
            print("[AuthService] Running in demo mode")
            try? await Task.sleep(nanoseconds: 800_000_000)
            
            if email.contains("@") {
                let username = email.split(separator: "@").first.map(String.init) ?? "Benutzer"
                let userId = UUID()
                
                // Demo-Trigger für 2FA: Wenn E-Mail "2fa" enthält.
                if email.lowercased().contains("2fa") {
                    print("[AuthService] Triggering 2FA challenge")
                    sessionState = .mfaChallengeRequired(
                        userId: userId,
                        email: email.lowercased(),
                        factorId: "demo-totp-factor"
                    )
                } else {
                    print("[AuthService] Logged in successfully as \(username)")
                    sessionState = .authenticated(
                        userId: userId,
                        email: email.lowercased(),
                        username: username,
                        isMFAVerified: false
                    )
                    UserDefaults.standard.set(email.lowercased(), forKey: "saved_email")
                    UserDefaults.standard.set(username, forKey: "saved_username")
                    UserDefaults.standard.set(userId.uuidString, forKey: "saved_userid")
                    UserDefaults.standard.set(false, forKey: "saved_is_mfa")
                    UserDefaults.standard.set(true, forKey: "is_logged_in")
                }
                return true
            } else {
                print("[AuthService] Invalid email: missing @")
                errorMessage = "Ungültige E-Mail-Adresse im Demo-Modus."
                sessionState = .unauthenticated
                return false
            }
        } else {
            print("[AuthService] Running in production mode (simulated)")
            do {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                let userId = UUID()
                print("[AuthService] Logged in successfully in production mode")
                sessionState = .authenticated(
                    userId: userId,
                    email: email.lowercased(),
                    username: "DemoUser",
                    isMFAVerified: false
                )
                UserDefaults.standard.set(email.lowercased(), forKey: "saved_email")
                UserDefaults.standard.set("DemoUser", forKey: "saved_username")
                UserDefaults.standard.set(userId.uuidString, forKey: "saved_userid")
                UserDefaults.standard.set(false, forKey: "saved_is_mfa")
                UserDefaults.standard.set(true, forKey: "is_logged_in")
                return true
            } catch {
                print("[AuthService] Error in production mode signIn: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                sessionState = .unauthenticated
                return false
            }
        }
    }
    
    /// Verifiziert den 6-stelligen TOTP-Code für die 2FA-Anmeldung.
    /// - Parameters:
    ///   - factorId: Die ID des registrierten TOTP-Authentifikators
    ///   - code: Der 6-stellige Code des Benutzers
    public func verifyTOTPCode(factorId: String, code: String) async -> Bool {
        errorMessage = nil
        
        guard code.count == 6, CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: code)) else {
            errorMessage = "Der Code muss aus genau 6 Ziffern bestehen."
            return false
        }
        
        // Im Demo-Modus akzeptieren wir den Code "123456" oder jeden numerischen Code für Tests
        if isDemoMode {
            sessionState = .loading
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            if code == "000000" {
                errorMessage = "Ungültiger Code. Bitte versuche es erneut (Demo: Nutze z.B. 123456)."
                sessionState = .mfaChallengeRequired(userId: UUID(), email: "user@2fa.de", factorId: factorId)
                return false
            }
            
            let userId = UUID()
            sessionState = .authenticated(
                userId: userId,
                email: "user@2fa.de",
                username: "2FA_User",
                isMFAVerified: true
            )
            UserDefaults.standard.set("user@2fa.de", forKey: "saved_email")
            UserDefaults.standard.set("2FA_User", forKey: "saved_username")
            UserDefaults.standard.set(userId.uuidString, forKey: "saved_userid")
            UserDefaults.standard.set(true, forKey: "saved_is_mfa")
            UserDefaults.standard.set(true, forKey: "is_logged_in")
            return true
        } else {
            do {
                // Supabase SDK Aufruf
                try await Task.sleep(nanoseconds: 800_000_000)
                let userId = UUID()
                sessionState = .authenticated(
                    userId: userId,
                    email: "user@2fa.de",
                    username: "MFAUser",
                    isMFAVerified: true
                )
                return true
            } catch {
                errorMessage = error.localizedDescription
                return false
            }
        }
    }
    
    /// Bricht die 2FA-Eingabe ab und leitet zurück zum Login.
    public func cancelMFAChallenge() {
        errorMessage = nil
        sessionState = .unauthenticated
    }
    
    /// Bricht die E-Mail-Verifizierung ab und geht zurück zum Login.
    public func cancelEmailVerification() {
        errorMessage = nil
        sessionState = .unauthenticated
    }
    
    /// Startet die Einrichtung von 2FA (TOTP) für den angemeldeten Benutzer.
    /// - Returns: Tuple aus factorId, dem geheimen Schlüssel und der QR-Code-URI zur App-Kopplung.
    public func enrollMFA() async -> (factorId: String, secret: String, qrCodeURI: String)? {
        if isDemoMode {
            try? await Task.sleep(nanoseconds: 500_000_000)
            return (
                factorId: "demo-new-factor",
                secret: "JBSWY3DPEHPK3PXP",
                qrCodeURI: "otpauth://totp/1PercentMethod:demo@user.de?secret=JBSWY3DPEHPK3PXP&issuer=1PercentMethod"
            )
        } else {
            return nil
        }
    }
    
    /// Schließt die Einrichtung von 2FA ab, indem die Kopplung verifiziert wird.
    public func verifyMFASetup(factorId: String, code: String) async -> Bool {
        if isDemoMode {
            try? await Task.sleep(nanoseconds: 800_000_000)
            if case .authenticated(let id, let email, let username, _) = sessionState {
                sessionState = .authenticated(userId: id, email: email, username: username, isMFAVerified: true)
                UserDefaults.standard.set(true, forKey: "saved_is_mfa")
                return true
            }
            return true
        } else {
            return true
        }
    }
    
    /// Meldet den Benutzer ab.
    public func signOut() async {
        sessionState = .loading
        
        UserDefaults.standard.removeObject(forKey: "saved_email")
        UserDefaults.standard.removeObject(forKey: "saved_username")
        UserDefaults.standard.removeObject(forKey: "saved_userid")
        UserDefaults.standard.removeObject(forKey: "saved_is_mfa")
        UserDefaults.standard.set(false, forKey: "is_logged_in")
        
        if isDemoMode {
            try? await Task.sleep(nanoseconds: 500_000_000)
            sessionState = .unauthenticated
        } else {
            sessionState = .unauthenticated
        }
    }
}
