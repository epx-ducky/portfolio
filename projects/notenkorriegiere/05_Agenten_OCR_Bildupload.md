# Denkschritte: Bildupload & OCR-Erkennung für Schülerklausuren

## Ziel & Umsetzung
Das Ziel war es, Lehrkräften das lästige Abtippen oder Copy-Pasten der handschriftlichen Klausuren zu ersparen. Stattdessen soll direkt ein Foto der Arbeit hochgeladen und per OCR ausgewertet werden können.

### Lösungsansatz: Dreispaltiger OCR-Workspace
Um den Prozess hochgradig visuell, flüssig und leicht bedienbar zu machen, haben wir das Modul 3 (**Korrektur & Bewertung**) in einen dreispaltigen Workspace umgestaltet:

1.  **Spalte 1: Bild-Upload & Vorschau (`lg:col-span-4`):**
    *   Unterstützt Drag-and-Drop sowie klassischen File-Upload für `.png`/`.jpg`/`.jpeg` Dateien.
    *   Zeigt das hochgeladene Bild vollflächig an.
    *   **Demo-Modus:** Integriert einen Button "Demo-Arbeit laden (Max)", der das von uns mittels KI generierte, realistische Bild einer handschriftlichen Klausur ([handwritten_exam.png](file:///Users/villain/Documents/KI-Projekte/Notenkorriegiere/webapp/public/handwritten_exam.png)) lädt.
    *   **Scan-Animation:** Beim Starten der OCR läuft eine visuelle Scan-Linie (Laser) über das Bild, um den OCR-Prozess greifbar zu machen.
2.  **Spalte 2: OCR-Text-Editor & Korrektur (`lg:col-span-5`):**
    *   Zeigt den erkannten Text an. 
    *   Erlaubt das Umschalten auf die **DSGVO-Vorschau**, in der sensible Schülerdaten (z. B. der Name Max Mustermann) live durch Platzhalter wie `[DSGVO-REDACTED: SCHÜLERNAME]` ersetzt werden.
    *   Führt nach Bestätigung den KI-Korrekturabgleich (simuliertes RAG und Grading) durch.
3.  **Spalte 3: DSGVO-Info & Verlauf (`lg:col-span-3`):**
    *   Visualisiert die lokale Datenverarbeitungskette.
    *   Listet die letzten erfolgreich korrigierten Abgaben auf.

## Testergebnisse
Der TypeScript-Build war erfolgreich. Der Demo-Modus mit dem generierten Bild greift perfekt auf `/handwritten_exam.png` zu und demonstriert den DSGVO-First-Ansatz (lokale Namensschwärzung) hervorragend.

## Nächste Schritte:
*   **Tesseract.js Integration:** Für eine echt-lokale OCR im Browser kann in `KorrekturBewertung.tsx` die Bibliothek `tesseract.js` eingebunden werden.
*   **Multipage OCR:** Unterstützung für mehrseitige PDFs/Bilder pro Schülerabgabe.
