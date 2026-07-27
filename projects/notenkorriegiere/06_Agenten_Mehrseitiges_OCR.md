# Denkschritte: Mehrseitiger Bildupload & Batch-OCR für Schülerklausuren

## Ziel & Umsetzung
Da Klausuren fast immer aus mehreren Seiten bestehen, reicht der Upload eines einzelnen Bildes nicht aus. Wir mussten das Modul 3 (**Korrektur & Bewertung**) so erweitern, dass Lehrer beliebig viele Seiten hochladen, verwalten, seitenweise scannen und den Text gesammelt bearbeiten können.

### Lösungsansatz: Multi-Image State & Batch Sequential OCR
Folgende Features wurden implementiert:

1.  **State-Refactoring (`src/components/KorrekturBewertung.tsx`):**
    *   Umstellung des Bild-Pfades auf ein Array von Objekten: `imageFiles: { id: string; url: string; name: string }[]`.
    *   Einführung eines `activeImageIndex`, um das aktuell in der Großansicht fokussierte Blatt zu verwalten.
2.  **Dateiwähler- & Drag-and-Drop-Upgrade:**
    *   Das `<input>`-Feld akzeptiert nun `multiple` Dateiauswahlen.
    *   Der Dropzone-Handler verarbeitet nun Arrays von Bildern.
3.  **Thumbnail-Galerie & Bild-Verwaltung:**
    *   Unterhalb der Großansicht des aktiven Scans wird eine Thumbnail-Leiste aller hochgeladenen Seiten gerendert.
    *   Jedes Thumbnail kann angeklickt werden, um die Großansicht zu wechseln, und besitzt ein `(X)`-Symbol zum Löschen.
    *   Ein gestricheltes `S. +`-Feld ermöglicht das nachträgliche Hinzufügen weiterer Seiten.
4.  **Sequenzieller Batch-OCR-Prozess:**
    *   Sobald Bilder hochgeladen werden, startet das Batch-OCR.
    *   Die OCR-Routine läuft sequenziell über jede einzelne hochgeladene Seite (z. B. Seite 1 von 2, Seite 2 von 2...).
    *   Der Laser-Scanner-Effekt wandert dabei visuell mit.
    *   Die Ergebnisse aller Seiten werden seitenweise getrennt (z. B. durch `--- SEITE 1 (Dateiname) ---`) im Text-Editor zusammengeführt und formatiert.

## Testergebnisse
Der TypeScript-Build war erfolgreich. Der Demo-Modus lädt nun automatisch 2 Beispielseiten, scannt diese sequenziell durch (inkl. Laser-Animation auf dem aktiven Blatt) und fügt den erkannten Text beider Seiten getrennt im Editor ein.

## Nächste Schritte:
*   **Seiten-Sortierung:** Möglichkeit, die hochgeladenen Seiten per Drag & Drop in ihrer Reihenfolge zu sortieren.
