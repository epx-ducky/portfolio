const projectData = {
    comonut: {
        title: "🥥 Comonut App Platform",
        tag: "iOS Native App & Community Plattform",
        vision: "💡 Meine Vision: Mir ist in Städten wie Erbach aufgefallen, dass das Gemeindeleben unorganisierter wird, immer weniger lokale Events stattfinden und Sportstätten (Fußballplätze, Beachvolleyballfelder, Tischtennisplatten) oft leer stehen, weil Kinder und Jugendliche sich kaum noch draußen verabreden. Comonut löst dieses Problem durch eine zentralisierte Plattform mit Sportstätten-Buchung, Bürgerbeteiligung und Müllkalender.",
        desc: "Vollwertige Community- und Event-Plattform für iOS (Gemeinde Erbach 89155). Inklusive Abfuhrkalender (Restmüll, Gelber Sack, Bioabfall), Mängelmelder, Bürgerbeteiligung (Umfragen) und Event-Buchungssystem für Sportstätten (Beachvolleyballplatz Badesee, Jahnhalle, Kunstrasenplatz).",
        tech: ["Swift", "Xcode", "SQL Database Schema", "iOS Native UI"],
        images: ["images/comonut_feed.png", "images/comonut_activities.png"],
        highlights: [
            "Echtes App-Interface: Gemeinde-News, Müllkalender & Bürgerumfragen",
            "Aktivitäten & Sportstätten-Buchung (Beachvolleyball, Kunst-Fußballplatz, Jahnhalle)",
            "Eigenes Datenbankschema (schema.sql) mit Rechteverwaltung & Rollensystem",
            "Saubere native iOS Xcode Projektstruktur (SwiftUI / UIKit)"
        ]
    },
    one_percent: {
        title: "🌱 1%-Methode App",
        tag: "iOS Habit & Focus Tracking App",
        vision: "💡 Meine Vision: Große Lebensveränderungen scheitern meist an zu hohen, kurzfristigen Zielen. Die 1%-Methode App setzt auf kontinuierliche Selbstoptimierung – '1% at a time'. Wer sich die App lädt, baut Schritt für Schritt bessere Gewohnheiten in Disziplin, Gesundheit, Finanzen und Intelligenz auf und sieht den Zinseszins-Effekt auf dem eigenen Dashboard.",
        desc: "Eigenes App-Projekt basierend auf dem Prinzip der täglichen 1%-Verbesserung. Visualisierung des Tages-Impacts, Leistungsstatistik mit Zinseszins-Verlaufsgraph, Bildschirmzeit-Verwaltung und Attribut-System (Gesundheit, Sportlichkeit, Disziplin, Achtsamkeit, Finanzen, Intelligenz).",
        tech: ["Swift", "Xcode", "Graph & Analytics", "Habit Logic"],
        images: ["images/one_percent_main.png", "images/one_percent_stats.png", "images/one_percent_graph.png"],
        highlights: [
            "Tages-Impact Dashboard (-0.7% bis +6.2% Zuwachs-Berechnung)",
            "Attribut-System: Gesundheit, Sportlichkeit, Disziplin, Finanzen, Intelligenz",
            "Zinseszins-Verlaufsgraph & Bildschirmzeit-Verwaltung",
            "Strukturierte Gewohnheitsliste mit Level-System"
        ]
    },
    fpv: {
        title: "🛸 FPV-Drohnen Konstruktion & Flug-Programmierung",
        tag: "Hardware, CAD & ArduPilot",
        vision: "💡 Meine Vision: Maximale Kontrolle, Zuverlässigkeit und Flugstabilität durch maßgeschneiderte 3D-CAD-Framekonstruktion in Fusion 360 und präzise kalibrierte ArduPilot-Avionik.",
        desc: "Eigenständige Konzeption und 3D-Konstruktion eines FPV-Drohnen-Frames in Autodesk Fusion 360 (Baseplate, Arme, Top Plate, Kamera- und Antennenhalterungen). Präzisionslöten der Elektronik und Programmierung/Kalibrierung der Flugsteuerung via ArduPilot, damit die Drohne stabil und präzise fliegt.",
        tech: ["ArduPilot", "Autodesk Fusion 360", "Flight Controller", "3D-Druck / STL", "Elektronik-Löten"],
        images: [],
        highlights: [
            "CAD-Dateien: Baseplate.stl, Top Plate.stl, Arm.stl, Kamera Halterung.stl",
            "Hardware-Erfahrung: Motorenverdrahtung, ESC-Abstimmung & Sensorintegration",
            "Software & Kalibrierung: ArduPilot Konfiguration für präzisen Flug"
        ]
    },
    personal_manager: {
        title: "📊 PersonalManager App",
        tag: "iOS & Productivity Management",
        vision: "💡 Meine Vision: Proaktive Zeit- & Fokussteuerung für den Alltag, um unnötige Bildschirmzeit zu reduzieren und Aufgaben mit einer klaren Zeitleiste strukturiert abzuarbeiten.",
        desc: "Native iOS-Anwendung für persönliches Aufgaben- & Fokus-Management. Enthält DashboardView, TaskListView, ProactiveTimelineView und ScreenTime-Verwaltung.",
        tech: ["Swift / SwiftUI", "Xcode", "Timeline Logic", "ScreenTime Manager"],
        images: [],
        highlights: [
            "Proaktive Zeitleiste und Dashboard-Visualisierung",
            "Aufgaben- und ScreenTime-Verwaltung in Swift",
            "Saubere Datenmodellierung (DataModels.swift)"
        ]
    },
    grady: {
        title: "🎓 Grady App",
        tag: "KI-gestützte Schul- & Lernanwendung",
        vision: "💡 Meine Vision: Schülern das Lernen und das Notenmanagement vereinfachen, um schulischen Erfolg strukturiert und ohne unnötigen Stress erreichbar zu machen.",
        desc: "Konzeption und Entwicklung der Grady App zur Unterstützung von Schülern beim Lernen und Notenmanagement. Umgesetzt unter Einsatz moderner KI-Entwicklungstools (Claude Code & Antigravity).",
        tech: ["KI-Entwicklung", "Claude Code", "Google Antigravity", "App Architecture"],
        images: [],
        highlights: [
            "Intelligente Notenverwaltung und Lernunterstützung für Schüler",
            "Effiziente Entwicklung durch KI-unterstützte Softwareerstellung",
            "Benutzerfreundliches App-Design"
        ]
    },
    notenkorrigierer: {
        title: "📝 Notenkorrigierer (EdTech AI Engine)",
        tag: "Next.js Web App & KI OCR-Korrektur",
        vision: "💡 Meine Vision: Zeitersparnis bei der Prüfungskorrektur durch automatisierte OCR-Erkennung handschriftlicher Arbeiten und präzises, nachvollziehbares KI-Feedback.",
        desc: "Entwicklung einer Web-Anwendung zur KI-unterstützten Auswertung von Prüfungen. Mehrseitiger OCR-Bildupload handschriftlicher Arbeiten mit automatisierter KI-Feedbackgenerierung.",
        tech: ["Next.js", "TypeScript", "Multi-Page OCR", "AI Prompting", "SQL Database"],
        images: [],
        highlights: [
            "Mehrseitiger OCR-Bildupload zur Erkennung handschriftlicher Arbeiten",
            "Agenten-Denkschritte für präzises, nachvollziehbares Feedback",
            "PDF-Druckversion & automatische Generierung von Leistungsauswertungen"
        ]
    }
};

function openModal(projectId) {
    const data = projectData[projectId];
    if (!data) return;

    const modalBody = document.getElementById('modal-body');
    
    let galleryHtml = '';
    if (data.images && data.images.length > 0) {
        galleryHtml = `
            <div class="modal-gallery">
                ${data.images.map(imgSrc => `<img src="${imgSrc}" alt="${data.title}" loading="lazy">`).join('')}
            </div>
        `;
    }

    let visionHtml = '';
    if (data.vision) {
        visionHtml = `
            <div class="modal-vision">
                ${data.vision}
            </div>
        `;
    }

    modalBody.innerHTML = `
        <div class="modal-badge">${data.tag}</div>
        <h2 class="modal-title">${data.title}</h2>
        
        ${visionHtml}
        
        <p class="modal-desc">${data.desc}</p>
        
        ${galleryHtml}

        <h4 style="color: #ffffff; margin-bottom: 0.6rem; font-family: 'Space Grotesk', sans-serif;">🚀 Kern-Features &amp; Highlights:</h4>
        <ul class="modal-list">
            ${data.highlights.map(h => `<li>✨ ${h}</li>`).join('')}
        </ul>

        <h4 style="color: #a1a1aa; margin-bottom: 0.6rem; font-size: 0.85rem; text-transform: uppercase;">🛠️ Verwendete Technologien:</h4>
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