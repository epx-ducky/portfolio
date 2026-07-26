const projectData = {
    fpv: {
        title: "🛸 FPV-Drohnen Konstruktion & Avionik",
        tag: "Hardware, CAD & Flight Controller",
        desc: "Eigenständige Konzeption und 3D-Konstruktion eines FPV-Drohnen-Frames in Autodesk Fusion 360. Erstellung von Fertigungsdateien für Carbon-Komponenten (Baseplate, Arme, Top Plate, Kamera- und Antennenhalterungen). Integration und Kalibrierung der Avionik via ArduPilot / Flight Controller in C++, Verdrahtung und Präzisionslöten der Elektronik (ESCs, Motoren, Kamera).",
        tech: ["C++", "Autodesk Fusion 360", "ArduPilot", "Flight Controller", "3D-Druck / STL", "Elektronik-Löten"],
        highlights: [
            "CAD-Dateien: Baseplate.stl, Top Plate.stl, Arm.stl, Kamera Halterung.stl",
            "Hardware-Erfahrung: Motorenverdrahtung, ESC-Abstimmung & Sensorintegration",
            "Software & Kalibrierung: ArduPilot Konfiguration in C++"
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
    },
    greenhouse: {
        title: "🌱 Intelligentes Gewächshaus (Arduino)",
        tag: "IoT, Embedded Systems & Sensorik",
        desc: "Entwicklung und Programmierung eines vollautomatisierten Gewächshauses als Schulprojekt. Der Arduino steuert auf Basis von Sensor-Echtzeitdaten in C/C++ (Temperatur, Bodenfeuchtigkeit) automatisch Bewässerungspumpen und Status-LEDs.",
        tech: ["C / C++", "Arduino IDE", "Bodenfeuchtigkeits- & Temperatursensorik", "Relais- & Aktorsteuerung"],
        highlights: [
            "Echtzeit-Schwellenwertsteuerung zur automatischen Bewässerung",
            "Energieeffizientes Messintervall-Management im C++ Code",
            "Praktischer Aufbau von Gehäuse, Verkabelung und Schaltelektronik"
        ]
    },
    notenkorrigierer: {
        title: "📝 Notenkorrigierer (EdTech AI Engine)",
        tag: "Python & KI OCR-Korrektur",
        desc: "Entwicklung von Algorithmen zur KI-unterstützten Auswertung und Korrektur von Prüfungen. Bild-Upload von Handgeschriebenem via OCR-Texterkennung, intelligente Noten- und Feedbackgenerierung über strukturierte Prompts.",
        tech: ["Python", "OCR & AI Prompting", "Datenverarbeitung"],
        highlights: [
            "Mehrseitiger OCR-Bildupload zur Erkennung handschriftlicher Arbeiten",
            "Präzises, nachvollziehbares Feedback via KI-Logik",
            "Automatische Generierung von Leistungsauswertungen"
        ]
    },
    pulseai: {
        title: "⚡ PulseAI Platform",
        tag: "KI-Anwendungsentwicklung",
        desc: "Konzeption und Entwicklung von intelligenter Anwendungslogik in Python. Fokus auf intelligentes Aktivitäts-Tracking und KI-unterstützte Datenanalyse.",
        tech: ["Python", "AI Integration", "Data Processing"],
        highlights: [
            "Integration von KI-Schnittstellen für intelligentes Tracking",
            "Datenanalyse und Auswertungslogik in Python"
        ]
    },
    comonut: {
        title: "🥥 Comonut Platform",
        tag: "Datenbank-Architektur & Systementwurf",
        desc: "Entwicklung von Datenbank-Architekturen und Logik für Community-Plattformen. Inklusive komplettem Datenbank-Design (SQL Schema), Benutzerrollen und Auditor-Systemen.",
        tech: ["SQL", "Datenbank-Architektur", "Systemdesign"],
        highlights: [
            "Eigenes Datenbankschema (schema.sql) mit Benutzer- & Rechteverwaltung",
            "Architektur: Auditor- & Reviewer-Mechanismen zur Inhaltsüberprüfung"
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