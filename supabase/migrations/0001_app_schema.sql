-- =====================================================================
-- BuchFix — Datenbank für die App
-- Eine Migration, direkt passend zum Frontend.
--
-- Grundsatz: Jede Zeile gehört genau einem Nutzer. Row Level Security
-- erzwingt das in der Datenbank, nicht in der App. Selbst wenn jemand
-- den Client manipuliert, kommt er an keine fremden Daten.
-- =====================================================================

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------
-- PROFIL (Unternehmensdaten, eines pro Nutzer)
-- ---------------------------------------------------------------------
create table if not exists public.profile (
  user_id       uuid primary key references auth.users(id) on delete cascade,
  daten         jsonb not null default '{}'::jsonb,
  zaehler       jsonb not null default '{}'::jsonb,   -- Rechnungsnummern je Jahr
  updated_at    timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- DATENSÄTZE
-- Positionen einer Rechnung stehen als JSON in der Zeile. Sie werden
-- immer zusammen gelesen und geschrieben, eine eigene Tabelle brächte
-- hier nur Joins ohne Nutzen.
-- ---------------------------------------------------------------------
create table if not exists public.kunden (
  id            uuid primary key,
  user_id       uuid not null references auth.users(id) on delete cascade,
  name          text not null default '',
  firma         text,
  strasse       text, plz text, ort text, land text default 'DE',
  email         text, telefon text,
  kundennummer  text, notizen text,
  updated_at    timestamptz not null default now(),
  geloescht_am  timestamptz
);

create table if not exists public.rechnungen (
  id            uuid primary key,
  user_id       uuid not null references auth.users(id) on delete cascade,
  kunde_id      uuid,
  nummer        text not null,
  status        text not null default 'offen',
  datum         date not null,
  leistungsdatum date,
  faellig       date,
  netto_cents   bigint not null default 0,
  ust_cents     bigint not null default 0,
  brutto_cents  bigint not null default 0,
  bezahlt_cents bigint not null default 0,
  bezahlt_am    date,
  kleinunternehmer boolean not null default false,
  mahnstufe     int not null default 0,
  letzte_mahnung date,
  aus_angebot   text,
  notiz         text,
  posten        jsonb not null default '[]'::jsonb,
  updated_at    timestamptz not null default now(),
  geloescht_am  timestamptz
);

create table if not exists public.angebote (
  id            uuid primary key,
  user_id       uuid not null references auth.users(id) on delete cascade,
  kunde_id      uuid,
  nummer        text not null,
  status        text not null default 'entwurf',
  datum         date not null,
  gueltig_bis   date,
  netto_cents   bigint not null default 0,
  ust_cents     bigint not null default 0,
  brutto_cents  bigint not null default 0,
  kleinunternehmer boolean not null default false,
  rechnung_id   uuid,
  notiz         text,
  posten        jsonb not null default '[]'::jsonb,
  updated_at    timestamptz not null default now(),
  geloescht_am  timestamptz
);

create table if not exists public.einnahmen (
  id            uuid primary key,
  user_id       uuid not null references auth.users(id) on delete cascade,
  kunde_id      uuid,
  rechnung_id   uuid,
  kategorie_id  uuid,
  datum         date not null,
  bezahlt_am    date,                      -- Zuflussprinzip § 11 EStG
  beschreibung  text,
  netto_cents   bigint not null default 0,
  ust_cents     bigint not null default 0,
  brutto_cents  bigint not null default 0,
  ust_satz      numeric(5,2) not null default 0,
  zahlart       text,
  status        text not null default 'bezahlt',
  rechnungsnummer text,
  notiz         text,
  updated_at    timestamptz not null default now(),
  geloescht_am  timestamptz
);

create table if not exists public.ausgaben (
  id            uuid primary key,
  user_id       uuid not null references auth.users(id) on delete cascade,
  kategorie_id  uuid,
  datum         date not null,
  bezahlt_am    date,                      -- Abflussprinzip
  haendler      text not null default '',
  beschreibung  text,
  netto_cents   bigint not null default 0,
  ust_cents     bigint not null default 0,
  brutto_cents  bigint not null default 0,
  ust_satz      numeric(5,2) not null default 19,
  privatanteil  numeric(5,2) not null default 0,
  zahlart       text,
  notiz         text,
  updated_at    timestamptz not null default now(),
  geloescht_am  timestamptz
);

-- Belegfotos liegen im Storage, hier steht nur der Verweis.
create table if not exists public.belege (
  id            uuid primary key,
  user_id       uuid not null references auth.users(id) on delete cascade,
  ausgabe_id    uuid,
  pfad          text,                      -- {user_id}/{id}.jpg im Bucket "belege"
  haendler      text,
  datum         date,
  updated_at    timestamptz not null default now(),
  geloescht_am  timestamptz
);

create table if not exists public.kategorien (
  id            uuid primary key,
  user_id       uuid not null references auth.users(id) on delete cascade,
  name          text not null,
  art           text not null check (art in ('einnahme','ausgabe')),
  bewirtung     boolean not null default false,
  system        boolean not null default false,
  updated_at    timestamptz not null default now(),
  geloescht_am  timestamptz
);

create table if not exists public.eks (
  id            uuid primary key,
  user_id       uuid not null references auth.users(id) on delete cascade,
  von           date not null,
  bis           date not null,
  modus         text not null default 'vorlaeufig',
  frist         date,
  monate        jsonb not null default '{}'::jsonb,
  updated_at    timestamptz not null default now(),
  geloescht_am  timestamptz
);

create table if not exists public.regeln (
  id            uuid primary key,
  user_id       uuid not null references auth.users(id) on delete cascade,
  muster        text not null,
  kategorie_id  uuid,
  treffer       int not null default 1,
  updated_at    timestamptz not null default now(),
  geloescht_am  timestamptz
);

-- ---------------------------------------------------------------------
-- INDIZES: Der Abgleich fragt immer "was hat sich seit X geändert".
-- ---------------------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array['kunden','rechnungen','angebote','einnahmen','ausgaben','belege','kategorien','eks','regeln']
  loop
    execute format('create index if not exists %1$s_sync_idx on public.%1$I (user_id, updated_at desc)', t);
  end loop;
end $$;
create index if not exists einnahmen_datum_idx on public.einnahmen (user_id, coalesce(bezahlt_am, datum));
create index if not exists ausgaben_datum_idx  on public.ausgaben  (user_id, coalesce(bezahlt_am, datum));
create unique index if not exists rechnungen_nummer_idx on public.rechnungen (user_id, nummer) where geloescht_am is null;

-- ---------------------------------------------------------------------
-- ROW LEVEL SECURITY
-- ---------------------------------------------------------------------
alter table public.profile enable row level security;
drop policy if exists profile_eigene on public.profile;
create policy profile_eigene on public.profile
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

do $$
declare t text;
begin
  foreach t in array array['kunden','rechnungen','angebote','einnahmen','ausgaben','belege','kategorien','eks','regeln']
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists %1$s_eigene on public.%1$I', t);
    execute format($p$
      create policy %1$s_eigene on public.%1$I
      for all using (user_id = auth.uid()) with check (user_id = auth.uid())
    $p$, t);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- updated_at wird serverseitig gesetzt. Ein manipulierter Client kann
-- damit keine fremden Zeitstempel unterschieben.
-- ---------------------------------------------------------------------
create or replace function public.set_updated_at() returns trigger
language plpgsql as $$
begin new.updated_at = now(); return new; end $$;

do $$
declare t text;
begin
  foreach t in array array['profile','kunden','rechnungen','angebote','einnahmen','ausgaben','belege','kategorien','eks','regeln']
  loop
    execute format('drop trigger if exists %1$s_touch on public.%1$I', t);
    execute format('create trigger %1$s_touch before insert or update on public.%1$I
                    for each row execute function public.set_updated_at()', t);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- BELEG-SPEICHER: privat, Pfad beginnt mit der Nutzer-ID
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit)
values ('belege', 'belege', false, 10485760)
on conflict (id) do nothing;

drop policy if exists belege_lesen on storage.objects;
create policy belege_lesen on storage.objects for select
  using (bucket_id = 'belege' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists belege_schreiben on storage.objects;
create policy belege_schreiben on storage.objects for insert
  with check (bucket_id = 'belege' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists belege_loeschen on storage.objects;
create policy belege_loeschen on storage.objects for delete
  using (bucket_id = 'belege' and (storage.foldername(name))[1] = auth.uid()::text);

-- ---------------------------------------------------------------------
-- Auswertung serverseitig — nützlich für spätere Berichte und
-- als Gegenprobe zu den Zahlen, die die App selbst rechnet.
-- ---------------------------------------------------------------------
create or replace function public.jahresauswertung(p_jahr int)
returns table (art text, kategorie_id uuid, netto_cents bigint, ust_cents bigint)
language sql stable security invoker as $$
  select 'einnahme'::text, kategorie_id, sum(netto_cents)::bigint, sum(ust_cents)::bigint
  from public.einnahmen
  where user_id = auth.uid() and geloescht_am is null and status <> 'storniert'
    and extract(year from coalesce(bezahlt_am, datum)) = p_jahr
  group by 2
  union all
  select 'ausgabe'::text, kategorie_id,
         sum(round(netto_cents * (1 - privatanteil/100)))::bigint,
         sum(round(ust_cents   * (1 - privatanteil/100)))::bigint
  from public.ausgaben
  where user_id = auth.uid() and geloescht_am is null
    and extract(year from coalesce(bezahlt_am, datum)) = p_jahr
  group by 2;
$$;
