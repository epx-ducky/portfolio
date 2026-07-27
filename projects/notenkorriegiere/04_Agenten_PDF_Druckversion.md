# Denkschritte: PDF-Druckversion für Klassenarbeiten

## Ziel & Umsetzung
Das Ziel war es, dem Benutzer das Generieren eines sauberen PDFs (ohne UI-Elemente wie Sidebars, Buttons, Dropdowns und Musterlösungen) für die Schüler direkt aus dem Klausur-Editor heraus zu ermöglichen.

### Lösungsansatz: Native CSS Print Styles (`@media print`)
Um Bildkompressionen, asynchrone Skalierungsprobleme und fehlerhafte Zeilenumbrüche durch externe Bibliotheken zu vermeiden, haben wir uns für eine native Druck-CSS-Lösung entschieden:

1.  **Druck-CSS Overrides (`src/app/globals.css`):**
    *   Wir haben einen `@media print` Block definiert, der beim Drucken (`window.print()`) alle interaktiven Bildschirm-Elemente (`aside`, `header`, `form`, `button`, `select`, `input`, `textarea`, `.no-print`) ausblendet (`display: none !important`).
    *   Das Layout der Hauptseite wird für den Druck auf volle Breite gesetzt, Ränder entfernt und Hintergrundfarben auf neutrales Weiß gesetzt.
    *   Eine Klasse `.print-only` blendet Inhalte ein, die ausschließlich für das gedruckte Papier bestimmt sind.
2.  **Klausur-Druckvorlage (`src/components/Klausurerstellung.tsx`):**
    *   Ein neuer Button "PDF generieren" ruft `window.print()` auf.
    *   Am Ende des Klausur-Editors haben wir ein Template mit der Klasse `print-only` eingebaut.
    *   Dieses Template enthält strukturierte Header-Daten für Schülerarbeiten (Name, Datum, Klasse, Punkte, Note).
    *   Die Fragen werden sauber untereinander aufgelistet. Für jede Frage werden – proportional zur erreichbaren Punktzahl (3 Zeilen pro Punkt, mindestens 3 Zeilen) – leere Schreiblinien (`_________________`) gerendert, auf denen Schüler ihre Antworten handschriftlich verfassen können.

## Testergebnisse
Der Build über `npm run build` lief fehlerfrei durch. Die Selektoren und CSS-Klassen verhalten sich auf dem Bildschirm unsichtbar und greifen erst, sobald der Druckdialog (oder der System-PDF-Export) geöffnet wird.

## Nächste Schritte:
*   **Fach- und Schul-Dynamisierung:** Derzeit ist das Fach fest auf "Mathematik" gesetzt. Dies kann später an die ausgewählte Klasse bzw. das Fach aus der Supabase-Datenbank gekoppelt werden.
