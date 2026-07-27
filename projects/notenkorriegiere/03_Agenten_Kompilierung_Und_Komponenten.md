# Denkschritte: Frontend-Entwicklung Next.js & Tailwind CSS

## Webapp-Architektur & Komponenten
Wir haben uns entschieden, das Frontend als Next.js App Router Projekt im Verzeichnis `webapp` aufzubauen. 
Folgende Dateien wurden neu erstellt/angepasst:

1.  **LocalStorage State-Store (`src/lib/store.ts`):** 
    Ein synchronisierter lokaler State-Store, der alle Entitäten (Klassen, PDFs, Klausuren, Abgaben, Bewertungen) persistiert. Dies ermöglicht eine voll funktionsfähige Demo-Erfahrung im Browser (Offline- & Prototyping-fähig), während Supabase-Dienste konfiguriert werden.
2.  **Navigation & Sidebar (`src/components/Sidebar.tsx`):**
    Native-anmutendes Navigationsmenü, angelehnt an Apple HIG Design Patterns, optimiert für Tablet/Desktop Viewports.
3.  **Modul 1: RAG & Wissensdatenbank (`src/components/Wissensdatenbank.tsx`):**
    Drag-and-Drop Uploader Simulation mit animierten Fortschrittsbalken für Text-Chunking und pgvector Embedding Generierung. 
4.  **Modul 2: Klausurerstellung (`src/components/Klausurerstellung.tsx`):**
    Ermöglicht das Prompten neuer Klausuren basierend auf hochgeladenen PDF-Quellen (RAG) und die Modifikation generierter Fragen (Punkte ändern, Musterlösung editieren).
5.  **Modul 3: Korrektur & OCR (`src/components/KorrekturBewertung.tsx`):**
    Demonstriert die lokale Anonymisierung vor dem Senden an das Backend. Namen von Schülern werden lokal geschwärzt (DSGVO First).
6.  **Modul 4: Feedback & Noten (`src/components/FeedbackDashboard.tsx`):**
    Dashboard mit Schiebereglern (Sliders) zur Notenkorrektur (Human-in-the-Loop), Textbearbeitung und einem Formular für den 3-Schritte-Förderplan sowie Live-JSON-Payload Vorschau.
7.  **Dashboard Shell (`src/app/page.tsx`):**
    Verbindet alle Komponenten reaktiv, handhabt den globalen State und bietet ein visuell ansprechendes Layout mit radialen Indigo/Violett Verläufen und modernen Schatten.

## Kompilierung und Verifizierung
Die App kompiliert und baut fehlerfrei über `next build`. TypeScript und ESLint-Prüfungen liefen sauber durch.

## Nächste Schritte für nachfolgende AIs:
1.  **Integration mit echtem Supabase-Backend:**
    Wenn der User die echten Datenbank-Tabellen über Supabase bereitstellt, müssen die Dummy-Funktionen in `store.ts` gegen echte Fetch/Insert-Funktionen (Supabase JS Client SDK) ausgetauscht werden.
2.  **Edge Functions (RAG & OCR):**
    Aufbau der edge functions für OCR (falls serverseitig als Fallback gewünscht) und für PDF-Extraktion + OpenAI/Anthropic Vektor-Embeddings Generierung (pgvector).
3.  **Authentifizierung:**
    Einbindung von Supabase Auth, um den Login der Lehrer abzusichern und RLS-Policies voll auszunutzen.
