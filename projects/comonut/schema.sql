-- Create municipalities table
CREATE TABLE IF NOT EXISTS public.municipalities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    primary_hex TEXT NOT NULL,
    secondary_hex TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Enable RLS
ALTER TABLE public.municipalities ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow read for all authenticated users" 
    ON public.municipalities FOR SELECT TO authenticated USING (true);

-- Create profiles table linked to Auth
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    role TEXT NOT NULL CHECK (role IN ('resident', 'orga_member', 'business', 'admin', 'club_manager')),
    municipality_id UUID REFERENCES public.municipalities(id) ON DELETE SET NULL,
    business_name TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow read for profiles" 
    ON public.profiles FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow user to update own profile" 
    ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = id);

-- Create facilities table
CREATE TABLE IF NOT EXISTS public.facilities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    municipality_id UUID REFERENCES public.municipalities(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('Sportplatz', 'Sporthalle', 'Spielplatz', 'Sonstiges')),
    location TEXT NOT NULL,
    image_url TEXT,
    description TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

ALTER TABLE public.facilities ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow read for facilities" 
    ON public.facilities FOR SELECT TO authenticated USING (true);

-- Create activities table
CREATE TABLE IF NOT EXISTS public.activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    facility_id UUID REFERENCES public.facilities(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    organizer_name TEXT NOT NULL,
    organizer_role TEXT NOT NULL,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    max_participants INTEGER NOT NULL,
    participant_ids UUID[] DEFAULT '{}'::uuid[] NOT NULL,
    is_official_orga_activity BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow read for activities" 
    ON public.activities FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow authenticated to insert activities" 
    ON public.activities FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Allow organizer to update activity" 
    ON public.activities FOR UPDATE TO authenticated USING (true);

-- Create deals table (coupons)
CREATE TABLE IF NOT EXISTS public.deals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    municipality_id UUID REFERENCES public.municipalities(id) ON DELETE CASCADE NOT NULL,
    business_name TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    discount_value TEXT NOT NULL,
    image_url TEXT NOT NULL,
    expiry_date TIMESTAMPTZ NOT NULL,
    total_coupons INTEGER NOT NULL,
    claimed_count INTEGER DEFAULT 0 NOT NULL,
    is_boosted BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

ALTER TABLE public.deals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow read for deals" 
    ON public.deals FOR SELECT TO authenticated USING (true);

-- Create claimed_deals table
CREATE TABLE IF NOT EXISTS public.claimed_deals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deal_id UUID REFERENCES public.deals(id) ON DELETE CASCADE NOT NULL,
    profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    activation_code TEXT NOT NULL,
    claimed_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    UNIQUE (deal_id, profile_id)
);

ALTER TABLE public.claimed_deals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow read own claimed deals" 
    ON public.claimed_deals FOR SELECT TO authenticated USING (auth.uid() = profile_id);

CREATE POLICY "Allow insert own claimed deals" 
    ON public.claimed_deals FOR INSERT TO authenticated WITH CHECK (auth.uid() = profile_id);

-- Create job_offers table
CREATE TABLE IF NOT EXISTS public.job_offers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    municipality_id UUID REFERENCES public.municipalities(id) ON DELETE CASCADE NOT NULL,
    business_name TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    type TEXT NOT NULL,
    contact_email TEXT NOT NULL,
    date_posted TIMESTAMPTZ DEFAULT now() NOT NULL
);

ALTER TABLE public.job_offers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow read for job offers" 
    ON public.job_offers FOR SELECT TO authenticated USING (true);

-- Create damage_reports table
CREATE TABLE IF NOT EXISTS public.damage_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    municipality_id UUID REFERENCES public.municipalities(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    location_name TEXT NOT NULL,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    image_url TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'inProgress', 'resolved')),
    user_email TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

ALTER TABLE public.damage_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow read own damage reports" 
    ON public.damage_reports FOR SELECT TO authenticated USING (user_email = (SELECT email FROM public.profiles WHERE id = auth.uid()));

CREATE POLICY "Allow insert own damage reports" 
    ON public.damage_reports FOR INSERT TO authenticated WITH CHECK (true);

-- Create news_articles table
CREATE TABLE IF NOT EXISTS public.news_articles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    municipality_id UUID REFERENCES public.municipalities(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    author TEXT NOT NULL,
    is_emergency BOOLEAN DEFAULT false NOT NULL,
    is_pending_approval BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

ALTER TABLE public.news_articles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow read approved or own news articles" 
    ON public.news_articles FOR SELECT TO authenticated USING (is_pending_approval = false OR author LIKE '%' || (SELECT name FROM public.profiles WHERE id = auth.uid()) || '%');

CREATE POLICY "Allow insert news articles" 
    ON public.news_articles FOR INSERT TO authenticated WITH CHECK (true);

-- Create gazettes table
CREATE TABLE IF NOT EXISTS public.gazettes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    municipality_id UUID REFERENCES public.municipalities(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    publish_date TIMESTAMPTZ NOT NULL,
    pdf_url TEXT NOT NULL,
    highlights TEXT[] DEFAULT '{}'::text[] NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

ALTER TABLE public.gazettes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow read for gazettes" 
    ON public.gazettes FOR SELECT TO authenticated USING (true);
