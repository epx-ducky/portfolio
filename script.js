const projectData = {
    fpv: {
        title: "🛸 FPV-Drohnen Konstruktion & Avionik",
        tag: "Hardware, CAD & Flight Controller",
        desc: "Eigenständige Konzeption und 3D-Konstruktion eines FPV-Drohnen-Frames in Autodesk Fusion 360. Erstellung von Fertigungsdateien für Carbon-Komponenten (Baseplate, Arme, Top Plate, Kamera- und Antennenhalterungen). Integration und Kalibrierung der Avionik via ArduPilot / Flight Controller, Verdrahtung und Präzisionslöten der Elektronik (ESCs, Motoren, Kamera).",
        tech: ["Autodesk Fusion 360", "ArduPilot", "Flight Controller", "3D-Druck / STL", "Elektronik-Löten"],
        highlights: [
            "CAD-Dateien: Baseplate.stl, Top Plate.stl, Arm.stl, Kamera Halterung.stl",
            "Hardware-Erfahrung: Motorenverdrahtung, ESC-Abstimmung & Sensorintegration",
            "Software & Kalibrierung: ArduPilot Konfiguration & Flugsteuerung"
        ]
    },
    drone_ai: {
        title: "🧠 KI-Algorithmen für Drohnensteuerung",
        tag: "KI-Entwicklung & Autonome Logik",
        desc: "Konzeption von KI-Algorithmen und Steuerungslogik für autonome Systeme und Drohnen. Entwicklung durch den gezielten Einsatz moderner KI-Entwicklerwerkzeuge wie Claude Code und Google Antigravity.",
        tech: ["KI-Prompt Engineering", "Claude Code", "Google Antigravity", "Drohnen-Logik"],
        highlights: [
            "Entwurf intelligenter Logikketten für autonome Abläufe",
            "Nutzung fortschrittlicher AI-Agents zur schnellen Prototypenerstellung",
            "Verknüpfung von Steuerungsbefehlen mit KI-Entwicklungs-Workflows"
        ]
    },
    web_apps: {
        title: "🌐 KI-gestützte Webseiten & Apps (10+ Projekte)",
        tag: "Software- & App-Entwicklung mit KI",
        desc: "Entwicklung von über 10 interaktiven Anwendungen, Webseiten und App-Projekten. Effiziente Konzeption, Architektur und Umsetzung durch KI-Entwicklungstools.",
        tech: ["KI-Entwicklung", "Web & App Architecture", "UI / UX Design", "VS Code"],
        highlights: [
            "Über 10 erfolgreich umgesetzte Web- und App-Projekte",
            "Strukturierte Architektur und modernes UI/UX-Design",
            "Zukunftsorientierte Arbeitsweise mit KI-Assistenten"
        ]
    },
    greenhouse: {
        title: "🌱 Intelligentes Gewächshaus (Arduino)",
        tag: "IoT, Embedded Systems & Sensorik",
        desc: "Entwicklung und Programmierung eines vollautomatisierten Gewächshauses als Schulprojekt. Der Arduino steuert auf Basis von Sensor-Echtzeitdaten (Temperatur, Bodenfeuchtigkeit) automatisch Bewässerungspumpen und Status-LEDs.",
        tech: ["Arduino IDE", "Bodenfeuchtigkeits- & Temperatursensorik", "Relais- & Aktorsteuerung"],
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