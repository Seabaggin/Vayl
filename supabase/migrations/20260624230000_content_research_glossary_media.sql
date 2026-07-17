-- Reconciliation backfill (2026-07-16, TestFlight blocker B4): these three content
-- tables exist in prod (created 2026-06-24 via dashboard migrations
-- "content_research_findings_and_glossary_terms" / "content_media_quotes") but had
-- no local migration file. Definitions below are a faithful transcription of prod
-- introspection: columns/defaults, PKs (no FKs, no extra indexes, no triggers),
-- RLS enabled, one public read policy each gated on is_published. Idempotent so it
-- is safe to run against prod where the objects already exist.

-- research_findings: Learn-tab research corpus.
create table if not exists public.research_findings (
  id text primary key,
  type text not null,
  stat text,
  headline text not null,
  finding text not null,
  bullets jsonb not null default '[]'::jsonb,
  limitation text not null,
  citation text not null,
  author text not null,
  year integer not null,
  topics jsonb not null default '[]'::jsonb,
  connected jsonb not null default '[]'::jsonb,
  is_published boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

alter table public.research_findings enable row level security;

drop policy if exists "research_findings public read" on public.research_findings;
create policy "research_findings public read"
  on public.research_findings for select
  using (is_published = true);

-- glossary_terms: Learn-tab vocabulary directory.
create table if not exists public.glossary_terms (
  id text primary key,
  kind text not null,
  term text not null,
  definition text not null,
  example text,
  is_published boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

alter table public.glossary_terms enable row level security;

drop policy if exists "glossary_terms public read" on public.glossary_terms;
create policy "glossary_terms public read"
  on public.glossary_terms for select
  using (is_published = true);

-- media_quotes: curated quote corpus (Home daily surfaces).
create table if not exists public.media_quotes (
  id text primary key,
  quote text not null,
  author text not null,
  source text,
  kind text,
  link text,
  is_published boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

alter table public.media_quotes enable row level security;

drop policy if exists "media_quotes public read" on public.media_quotes;
create policy "media_quotes public read"
  on public.media_quotes for select
  using (is_published = true);
