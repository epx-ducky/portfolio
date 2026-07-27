-- ==============================================================================
-- EDTECH GRADING & FEEDBACK APP - SUPABASE DATABASE SCHEMA
-- ==============================================================================
-- Fokus: DSGVO-Konformität, Row Level Security (RLS), und KI/RAG (pgvector)
-- ==============================================================================

-- 1. Extension für Vektor-Suche aktivieren (RAG)
create extension if not exists vector with schema extensions;

-- ==============================================================================
-- TABLES
-- ==============================================================================

-- 1. TEACHERS (Lehrkräfte)
-- Verknüpft mit Supabase Auth
create table public.teachers (
    id uuid primary key references auth.users(id) on delete cascade,
    email text not null,
    first_name text,
    last_name text,
    created_at timestamptz default now()
);

-- 2. CLASSES (Klassen / Kurse)
create table public.classes (
    id uuid primary key default gen_random_uuid(),
    teacher_id uuid not null references public.teachers(id) on delete cascade,
    name text not null, -- z.B. "10a", "Mathe LK"
    subject text,       -- z.B. "Mathematik", "Geschichte"
    created_at timestamptz default now()
);

-- 3. DOCUMENTS (Wissensdatenbank PDFs - Metadaten)
create table public.documents (
    id uuid primary key default gen_random_uuid(),
    teacher_id uuid not null references public.teachers(id) on delete cascade,
    title text not null,
    storage_path text not null, -- Pfad im Supabase Storage Bucket
    page_count integer default 0,
    created_at timestamptz default now()
);

-- 4. DOCUMENT_EMBEDDINGS (pgvector für RAG)
create table public.document_embeddings (
    id uuid primary key default gen_random_uuid(),
    document_id uuid not null references public.documents(id) on delete cascade,
    teacher_id uuid not null references public.teachers(id) on delete cascade, -- Redundant, aber praktisch für RLS
    content text not null, -- Der eigentliche Text-Chunk
    embedding vector(1536), -- 1536 für OpenAI's text-embedding-ada-002 oder text-embedding-3-small
    metadata jsonb, -- Z.B. Seitenzahl, Kapitel
    created_at timestamptz default now()
);

-- Index für Vektor-Suche (optional, aber empfohlen für Performance)
create index on public.document_embeddings using ivfflat (embedding vector_cosine_ops)
with (lists = 100);

-- 5. EXAMS (Klassenarbeiten / Klausuren)
create table public.exams (
    id uuid primary key default gen_random_uuid(),
    teacher_id uuid not null references public.teachers(id) on delete cascade,
    class_id uuid references public.classes(id) on delete set null,
    title text not null,
    description text,
    status text default 'draft' check (status in ('draft', 'published', 'graded')),
    created_at timestamptz default now()
);

-- 6. QUESTIONS (Fragen pro Klausur)
create table public.questions (
    id uuid primary key default gen_random_uuid(),
    exam_id uuid not null references public.exams(id) on delete cascade,
    question_text text not null,
    max_points numeric not null default 0,
    order_index integer not null default 0,
    expected_answer text, -- Erwartungshorizont (durch KI generiert oder manuell)
    created_at timestamptz default now()
);

-- 7. SUBMISSIONS (Anonymisierte Abgaben der Schüler)
create table public.submissions (
    id uuid primary key default gen_random_uuid(),
    exam_id uuid not null references public.exams(id) on delete cascade,
    student_identifier text not null, -- Anonymisierte ID (z.B. "Schüler A", "ID-123")
    total_score numeric default 0,
    created_at timestamptz default now()
);

-- 8. EVALUATIONS (KI-Bewertung & Feedback pro Frage)
create table public.evaluations (
    id uuid primary key default gen_random_uuid(),
    submission_id uuid not null references public.submissions(id) on delete cascade,
    question_id uuid not null references public.questions(id) on delete cascade,
    student_answer_text text, -- OCR extrahierter Text
    awarded_points numeric, -- Vorgeschlagene oder finale Punkte
    teacher_analysis text, -- Sachliche Analyse für die Lehrkraft
    student_feedback text, -- Empathisches Feedback für den Schüler
    tutoring_plan jsonb, -- 3-Schritte Plan: { "recommendation": "", "exercise": "", "long_term_tip": "" }
    is_overridden boolean default false, -- Hat die Lehrkraft die KI überstimmt?
    created_at timestamptz default now()
);

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ==============================================================================
-- Wir stellen sicher, dass Lehrkräfte NUR ihre eigenen Daten sehen und bearbeiten können.

alter table public.teachers enable row level security;
alter table public.classes enable row level security;
alter table public.documents enable row level security;
alter table public.document_embeddings enable row level security;
alter table public.exams enable row level security;
alter table public.questions enable row level security;
alter table public.submissions enable row level security;
alter table public.evaluations enable row level security;

-- 1. Teachers RLS
create policy "Teachers can view own profile" on public.teachers
    for select using (auth.uid() = id);
create policy "Teachers can update own profile" on public.teachers
    for update using (auth.uid() = id);

-- 2. Classes RLS
create policy "Teachers can manage their classes" on public.classes
    for all using (auth.uid() = teacher_id);

-- 3. Documents RLS
create policy "Teachers can manage their documents" on public.documents
    for all using (auth.uid() = teacher_id);

-- 4. Document Embeddings RLS
create policy "Teachers can manage their embeddings" on public.document_embeddings
    for all using (auth.uid() = teacher_id);

-- 5. Exams RLS
create policy "Teachers can manage their exams" on public.exams
    for all using (auth.uid() = teacher_id);

-- 6. Questions RLS
-- Fragen sind über exam_id an teacher_id gebunden. Für performante RLS können wir einen Join nutzen
-- oder teacher_id auf der questions Tabelle speichern. Der Einfachheit halber mit Join:
create policy "Teachers can manage questions for their exams" on public.questions
    for all using (
        exists (
            select 1 from public.exams
            where exams.id = questions.exam_id
            and exams.teacher_id = auth.uid()
        )
    );

-- 7. Submissions RLS
create policy "Teachers can manage submissions for their exams" on public.submissions
    for all using (
        exists (
            select 1 from public.exams
            where exams.id = submissions.exam_id
            and exams.teacher_id = auth.uid()
        )
    );

-- 8. Evaluations RLS
create policy "Teachers can manage evaluations for their exams" on public.evaluations
    for all using (
        exists (
            select 1 from public.submissions
            join public.exams on exams.id = submissions.exam_id
            where submissions.id = evaluations.submission_id
            and exams.teacher_id = auth.uid()
        )
    );
