-- learn_media + voices: the Learn tab's Content Hub corpus.
--
-- These two are the only Learn content the app could NOT update without shipping
-- a build: research_findings, glossary_terms and media_quotes all have tables and
-- ContentService fetchers, while media and voices were bundle-only. That matters
-- more here than anywhere else in Learn, because these rows are the ONLY ones that
-- carry outbound links, and links rot: Instagram restricts, renames, and removes
-- non-monogamy educators at a real rate, and creators migrate when it happens.
-- Bundle-only meant a dead handle cost an App Store release. Now it costs a row.
--
-- Shape follows the three existing content tables exactly: text PK matching the
-- bundled JSON id, is_published gate, sort_order, RLS with one public read policy.
-- Idempotent, so it is safe against a prod that already has the objects.
--
-- `links` is jsonb: [{ "label": "Bookshop", "url": "https://..." }]. An array, not
-- a single url column, so an item can offer a finder and a library rather than
-- forcing one vendor on a reader whose purchase history a partner may be able to
-- see. `background` is the longer copy the item sheet shows, so a row still has a
-- destination when it has no links at all.

-- learn_media: books, shows, podcasts.
create table if not exists public.learn_media (
  id text primary key,
  kind text not null,                 -- book | show | podcast
  title text not null,
  creator text not null,
  positioning text not null,
  tier text,
  platform text,
  artwork_url text,
  background text,
  links jsonb not null default '[]'::jsonb,
  is_published boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

alter table public.learn_media enable row level security;

drop policy if exists "learn_media public read" on public.learn_media;
create policy "learn_media public read"
  on public.learn_media for select
  using (is_published = true);

-- voices: public-facing creators. Creators only, by consent — a researcher
-- publishing a paper is cited under a finding, never listed here as a person to
-- follow (see Voice.swift). `mode` may never exceed what the person claims for
-- themselves; `topic` is assigned from their own framing, never inferred.
create table if not exists public.voices (
  id text primary key,                -- the Instagram handle
  name text not null,
  role text not null,                 -- free text, as they present themselves
  blurb text not null,
  topic text not null,                -- polyamory | open | lifestyle | sexEducation
  mode text not null,                 -- creator | writer | educator | coach | therapist
  platform text not null,
  background text,
  links jsonb not null default '[]'::jsonb,
  is_published boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

alter table public.voices enable row level security;

drop policy if exists "voices public read" on public.voices;
create policy "voices public read"
  on public.voices for select
  using (is_published = true);
