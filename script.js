const projectData = {
    fpv: {
        title: "🛸 FPV-Drohnen Konstruktion & Avionik",
        tag: "Hardware, CAD & Flight Controller",
        desc: "Eigenständige Konzeption und 3D-Konstruktion eines FPV-Drohnen-Frames in Autodesk Fusion 360. Erstellung von Fertigungsdateien für Carbon-Komponenten (Baseplate, Arme, Top Plate, Kamera- und Antennenhalterungen). Integration und Kalibrierung der Avionik via ArduPilot / Flight Controller, Verdrahtung und Präzisionslöten der Elektronik (ESCs, Motoren, Kamera).",
        tech: ["Autodesk Fusion 360", "ArduPilot", "Flight Controller (C++)", "3D-Druck / STL", "Elektronik-Löten"],
        highlights: [
            "CAD-Dateien: Baseplate.stl, Top Plate.stl, Arm.stl, Kamera Halterung.stl",
            "Hardware-Erfahrung: Motorenverdrahtung, ESC-Abstimmung & Sensorintegration",
            "Software & Kalibrierung: ArduPilot Konfiguration & Flugeigenschafts-Feintuning"
        ]
    },
    comonut: {
        title: "🥥 Comonut App Platform",
        tag: "iOS Native App & Datenbank-Architektur",
        desc: "Entwicklung einer vollstrukturierten Community- und Event-Plattform für iOS mit Swift und Xcode. Inklusive komplettem Datenbank-Design (SQL Schema), Benutzerrollen, Auditor-Systemen und moderner UI.",
        tech: ["Swift", "Xcode", "SQL Database Schema", "iOS Native UI"],
        highlights: [
            "Eigenes Datenbankschema (schema.sql) mit Benutzer- & Rechteverwaltung",
            "Architektur: Auditor- & Reviewer-Mechanismen zur Inhaltsüberprüfung",
            "Native iOS Xcode Projektstruktur mit sauberer MVC/MVVM Trennung"
        ]
    },
    pulseai: {
        title: "⚡ PulseAI App Platform",
        tag: "Cross-Platform Mobile App & KI Integration",
        desc: "Entwicklung einer modernen, performanten Mobile-App mit Flutter und Dart für iOS & Android. Fokus auf intelligentes Aktivitäts-Tracking, intuitive Benutzeroberfläche und KI-gestützte Datenanalyse.",
        tech: ["Flutter", "Dart", "AI Integration", "iOS & Android"],
        highlights: [
            "Cross-Platform Deployment für iOS, Android und Web",
            "Integration von KI-Schnittstellen für intelligentes Tracking",
            "Moderne UI mit flüssigen Animationen und State Management"
        ]
    },
    notenkorrigierer: {
        title: "📝 Notenkorrigierer (EdTech AI Engine)",
        tag: "Next.js Web App & KI OCR-Korrektur",
        desc: "Entwicklung einer Web-Anwendung zur automatisierten KI-Korrektur von Prüfungen. Bild-Upload von Handgeschriebenem via OCR-Texterkennung, intelligente Noten- und Feedbackgenerierung über strukturierte LLM-Prompts.",
        tech: ["Next.js", "TypeScript", "Multi-Page OCR", "AI Prompt Engineering", "SQL Database"],
        highlights: [
            "Mehrseitiger OCR-Bildupload zur Erkennung handschriftlicher Arbeiten",
            "Agenten-Denkschritte für präzises, nachvollziehbares Feedback",
            "PDF-Druckversion & automatische Generierung von Leistungsauswertungen"
        ]
    },
    greenhouse: {
        title: "🌱 Intelligentes Gewächshaus (Arduino)",
        tag: "IoT, Embedded Systems & Sensorik",
        desc: "Entwicklung und Programmierung eines vollautomatisierten Gewächshauses als Schulprojekt. Der Arduino steuert auf Basis von Sensor-Echtzeitdaten (Temperatur, Bodenfeuchtigkeit) automatisch Bewässerungspumpen und Status-LEDs.",
        tech: ["Arduino IDE", "C / C++", "Bodenfeuchtigkeits- & Temperatursensorik", "Relais- & Aktorsteuerung"],
        highlights: [
            "Echtzeit-Schwellenwertsteuerung zur automatischen Bewässerung",
            "Energieeffizientes Messintervall-Management im C++ Code",
            "Praktischer Aufbau von Gehäuse, Verkabelung und Schaltelektronik"
        ]
    },
    exif: {
        title: "📁 EXIF Media Auto-Organizer",
        tag: "Python 3 Automation & TIFF Metadata",
        desc: "Entwicklung eines Hochleistungs-Python-Skripts zur automatischen Analyse von TIFF- und EXIF-Metadaten aus Sony RAW (.ARW) Fotos und 4K (.MP4/XML) Videos. Vollautomatische Sortierung von hunderten Dateien in Datums-Ordnerstrukturen ohne Qualitätsverlust.",
        tech: ["Python 3", "TIFF / EXIF Binary Parsing", "File System Automation"],
        highlights: [
            "Reiner Binary-TIFF-Parser in Python ohne externe Abhängigkeiten",
            "Verarbeitung von 300+ Sony RAW-Dateien in unter 0,2 Sekunden",
            "Automatische Zuordnung von MP4-Videos und XML-Sidecar-Dateien"
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