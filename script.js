const projectData = {
    fpv: {
        title: "🛸 FPV-Drohnen Konstruktion & Flug-Programmierung",
        tag: "Hardware, CAD & ArduPilot",
        desc: "Eigenständige Konzeption und 3D-Konstruktion eines FPV-Drohnen-Frames in Autodesk Fusion 360 (Baseplate, Arme, Top Plate, Kamera- und Antennenhalterungen). Präzisionslöten der Elektronik und Programmierung/Kalibrierung der Flugsteuerung via ArduPilot, damit die Drohne stabil und präzise fliegt.",
        tech: ["ArduPilot", "Autodesk Fusion 360", "Flight Controller", "3D-Druck / STL", "Elektronik-Löten"],
        highlights: [
            "CAD-Dateien: Baseplate.stl, Top Plate.stl, Arm.stl, Kamera Halterung.stl",
            "Hardware-Erfahrung: Motorenverdrahtung, ESC-Abstimmung & Sensorintegration",
            "Software & Kalibrierung: ArduPilot Konfiguration für stabilen Flug"
        ]
    },
    comonut: {
        title: "🥥 Comonut App Platform",
        tag: "iOS Native App & Datenbank-Architektur",
        desc: "Entwicklung einer vollstrukturierten Community- und Event-Plattform für iOS mit Swift und Xcode. Inklusive komplettem Datenbank-Design (schema.sql), Benutzerrollen, Auditor-Systemen und nativer UI.",
        tech: ["Swift", "Xcode", "SQL Database Schema", "iOS Native UI"],
        highlights: [
            "Eigenes Datenbankschema (schema.sql) mit Benutzer- & Rechteverwaltung",
            "Architektur: Auditor- & Reviewer-Mechanismen zur Inhaltsüberprüfung",
            "Native iOS Xcode Projektstruktur mit sauberer MVC/MVVM Trennung"
        ]
    },
    grady: {
        title: "🎓 Grady App",
        tag: "KI-gestützte Schul- & Lernanwendung",
        desc: "Konzeption und Entwicklung der Grady App zur Unterstützung von Schülern beim Lernen und Notenmanagement. Umgesetzt unter Einsatz moderner KI-Entwicklungstools (Claude Code & Antigravity).",
        tech: ["KI-Entwicklung", "Claude Code", "Google Antigravity", "App Architecture"],
        highlights: [
            "Intelligente Notenverwaltung und Lernunterstützung für Schüler",
            "Effiziente Entwicklung durch KI-unterstützte Softwareerstellung",
            "Benutzerfreundliches App-Design"
        ]
    },
    personal_manager: {
        title: "📊 PersonalManager App",
        tag: "iOS & Productivity Management",
        desc: "Native iOS-Anwendung für persönliches Aufgaben- & Fokus-Management. Enthält DashboardView, TaskListView, ProactiveTimelineView und ScreenTime-Verwaltung.",
        tech: ["Swift / SwiftUI", "Xcode", "Timeline Logic", "ScreenTime Manager"],
        highlights: [
            "Proaktive Zeitleiste und Dashboard-Visualisierung",
            "Aufgaben- und ScreenTime-Verwaltung in Swift",
            "Saubere Datenmodellierung (DataModels.swift)"
        ]
    },
    one_percent: {
        title: "🌱 1%-Methode App",
        tag: "Habit & Focus Tracking App",
        desc: "Eigenes App-Projekt basierend auf dem Prinzip der täglichen 1%-Verbesserung. Strukturierte Datenbank, Habit-Tracking und fokussierte Benutzeroberfläche.",
        tech: ["Swift", "Xcode", "Database Design", "Habit Logic"],
        highlights: [
            "Strukturierter Datenbank-Aufbau für Gewohnheits-Tracking",
            "Fokussierte Benutzeroberfläche zur täglichen Selbstverbesserung"
        ]
    },
    notenkorrigierer: {
        title: "📝 Notenkorrigierer (EdTech AI Engine)",
        tag: "Next.js Web App & KI OCR-Korrektur",
        desc: "Entwicklung einer Web-Anwendung zur KI-unterstützten Auswertung von Prüfungen. Mehrseitiger OCR-Bildupload handschriftlicher Arbeiten mit automatisierter KI-Feedbackgenerierung.",
        tech: ["Next.js", "TypeScript", "Multi-Page OCR", "AI Prompting", "SQL Database"],
        highlights: [
            "Mehrseitiger OCR-Bildupload zur Erkennung handschriftlicher Arbeiten",
            "Agenten-Denkschritte für präzises, nachvollziehbares Feedback",
            "PDF-Druckversion & automatische Generierung von Leistungsauswertungen"
        ]
    },
    greenhouse: {
        title: "🌿 Intelligentes Gewächshaus (Arduino)",
        tag: "IoT, Embedded Systems & Sensorik",
        desc: "Entwicklung und Programmierung eines vollautomatisierten Gewächshauses als Schulprojekt. Der Arduino steuert auf Basis von Sensor-Echtzeitdaten (Temperatur, Bodenfeuchtigkeit) automatisch Bewässerungspumpen und Status-LEDs.",
        tech: ["Arduino IDE", "C / C++", "Bodenfeuchtigkeits- & Temperatursensorik", "Relais- & Aktorsteuerung"],
        highlights: [
            "Echtzeit-Schwellenwertsteuerung zur automatischen Bewässerung",
            "Messintervall-Management im C++ Code",
            "Praktischer Aufbau von Gehäuse, Verkabelung und Schaltelektronik"
        ]
    }
};

function openModal(projectId) {
    const data = projectData[projectId];
    if (!data) return;

    const modalBody = document.getElementById('modal-body');
    modalBody.innerHTML = `
        <div class="modal-badge">${data.tag}</div>
        <h2 class="modal-title">${data.title}</h2>
        <p class="modal-desc">${data.desc}</p>
        
        <h4 style="color: #818cf8; margin-bottom: 0.5rem;">🚀 Kern-Features &amp; Highlights:</h4>
        <ul class="modal-list">
            ${data.highlights.map(h => `<li>✨ ${h}</li>`).join('')}
        </ul>

        <h4 style="color: #38bdf8; margin-bottom: 0.5rem;">🛠️ Verwendete Technologien:</h4>
        <div class="tech-stack">
            ${data.tech.map(t => `<span>${t}</span>`).join('')}
        </div>
    `;

    document.getElementById('modal-overlay').classList.add('active');
}

function closeModal() {
    document.getElementById('modal-overlay').classList.remove('active');
}

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeModal();
});