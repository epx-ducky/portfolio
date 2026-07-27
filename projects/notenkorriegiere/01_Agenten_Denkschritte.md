# Denkschritte: Initiale Planung & Datenbankschema

## Verständnis des Briefings
*   **Ziel:** Native iPadOS/iOS App (SwiftUI, MVVM) für Lehrkräfte zur Erstellung, Korrektur und Bewertung von Klassenarbeiten.
*   **Tech-Stack:** SwiftUI, Supabase (PostgreSQL, Storage, Edge Functions), LLM-API, pgvector für RAG (bis 150 Seiten Kontext), Apple VisionKit (Lokale OCR für DSGVO-Konformität).
*   **Kern-Module:**
    1.  Wissensdatenbank (PDFs -> pgvector Embeddings).
    2.  Klausurerstellung (Generative UI für Fragen).
    3.  Korrektur & Bewertung (Lokale OCR -> Anonymisierung -> KI-Abgleich).
    4.  Feedback & Nachhilfeplan (Sachliche Analyse, empathisches Feedback, 3-Schritte-Plan, Human-in-the-Loop-Dashboard).
*   **Architektur-Prinzipien:** DSGVO First (Anonymisierung), Clean Architecture, Iteratives Vorgehen, Apple HIG.

## Datenbank-Design (Supabase SQL)
Ich entwerfe das Schema so, dass RLS (Row Level Security) direkt von Anfang an greift. Jeder User (`auth.users`) repräsentiert eine Lehrkraft. Lehrkräfte dürfen nur ihre eigenen Daten sehen (Mandantenfähigkeit pro Lehrkraft).

### Tabellen-Übersicht:
1.  `teachers`: Profil-Daten der Lehrkraft (verknüpft mit `auth.users`).
2.  `classes`: Klassen/Kurse, die einer Lehrkraft zugeordnet sind.
3.  `documents`: Metadaten für hochgeladene PDFs (Context für RAG).
4.  `document_embeddings`: Die pgvector-Tabelle mit Chunks und Embeddings. Verknüpft mit `documents`.
5.  `exams`: Die eigentlichen Klassenarbeiten, verknüpft mit einer Klasse.
6.  `questions`: Die Fragen innerhalb einer Klausur.
7.  `submissions`: Eine anonymisierte Abgabe (Klausur) eines Schülers.
8.  `evaluations`: Die KI-Bewertung pro Frage für eine Abgabe, inkl. Feedback und Nachhilfeplan.

### Nächste Schritte:
Nach der Erstellung dieses initialen Schemas und der Bestätigung des Nutzers werde ich auf weitere Anweisungen warten. Wahrscheinlich folgt das Setup des Supabase-Projekts oder der Start der SwiftUI-App (Grundgerüst).
