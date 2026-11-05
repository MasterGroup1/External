-- SMS Edge dashboard — full database schema for a NEW Supabase project.
-- Run once in Supabase → SQL Editor. Safe to re-run (everything is IF NOT EXISTS
-- / OR REPLACE / DROP ... IF EXISTS).
--
-- Column names and types match what index.html reads and writes. Some date
-- columns are deliberately TEXT: campaign dates come straight from CSV imports
-- and older rows hold values like "2026-30-08" that a DATE column would reject
-- (the dashboard repairs them on load — see fixSwappedDate in index.html).
--
-- The app has no login: the browser talks to the database with the public
-- "anon" key, so the policies below give anon full access to these tables,
-- the same way the original dashboard works. Anyone who has the site URL can
-- therefore read and edit the data — see DEPLOY.md, "Locking it down".

-- ── campaigns ────────────────────────────────────────────────────────────
-- One row per campaign send, imported from the SMS platform CSV export.
-- id is the platform's campaign id (not generated here).
create table if not exists public.campaigns (
  id          bigint primary key,
  name        text    default '',
  country     text    default '',
  brand       text    default '',
  type        text    default 'Fresh',   -- 'Fresh' (main list) or 'Clicked' (clicker list)
  list        text    default '',
  raw_list    text    default '',
  partner     text    default '',
  laps        integer default 0,
  sent        integer default 0,
  clicks      integer default 0,
  leads       integer default 0,
  sales       integer default 0,
  cost        numeric(12,2) default 0,
  revenue     numeric(12,2) default 0,
  roi         numeric(12,4) default 0,
  ctr         numeric(12,4) default 0,
  cpa         numeric(12,2) default 0,
  ecpa        numeric(12,2) default 0,
  breakeven   numeric(12,1) default 0,
  profitable  boolean default false,
  created     text    default '',        -- platform "Created" timestamp, as exported
  date        text    default ''         -- send date, YYYY-MM-DD
);
create index if not exists campaigns_date_idx on public.campaigns (date desc);
create index if not exists campaigns_list_idx on public.campaigns (list);

-- ── content_rows ─────────────────────────────────────────────────────────
-- Content tab: SMS copy per campaign, ordered by sort_order.
create table if not exists public.content_rows (
  id          uuid primary key default gen_random_uuid(),
  campaign    text    default '',
  copy        text    default '',
  route       text    default '',
  date        text    default '',
  sent        integer default 0,
  clicks      integer default 0,
  signups     integer default 0,
  ftds        integer default 0,
  status      text    default 'Draft',
  notes       text    default '',
  sort_order  integer default 0,
  created_at  timestamptz default now()
);
create index if not exists content_rows_sort_idx on public.content_rows (sort_order);

-- ── planned_sends ────────────────────────────────────────────────────────
-- Planner tab: scheduled and historical sends ("When Used" dates).
create table if not exists public.planned_sends (
  id            uuid primary key default gen_random_uuid(),
  planned_date  date,
  list          text default '',
  brand         text default '',
  country       text default '',
  status        text default 'Planned',   -- 'Planned' or 'Sent'
  notes         text default '',
  created_at    timestamptz default now(),
  updated_at    timestamptz default now()
);
create index if not exists planned_sends_date_idx on public.planned_sends (planned_date);
create index if not exists planned_sends_list_idx on public.planned_sends (list);

-- ── list_decisions ───────────────────────────────────────────────────────
-- Manual "Send or Not" override per list (one row per list).
create table if not exists public.list_decisions (
  list           text primary key,
  use_again      text,                 -- 'Yes' / 'Maybe' / 'No', null = auto
  reason         text default '',
  decision_date  date,
  updated_at     timestamptz default now()
);

-- ── list_decision_history ────────────────────────────────────────────────
-- Audit trail: every change to a list's Send-or-Not decision.
create table if not exists public.list_decision_history (
  id             bigint generated always as identity primary key,
  list           text not null,
  use_again      text,
  reason         text default '',
  decision_date  date,
  changed_at     timestamptz default now()
);
create index if not exists list_decision_history_list_idx on public.list_decision_history (list, changed_at desc);

-- ── list_sizes ───────────────────────────────────────────────────────────
-- Full list size (contacts), entered by hand in the Master List Planner.
create table if not exists public.list_sizes (
  list  text primary key,
  size  integer default 0
);

-- ── active_routes ────────────────────────────────────────────────────────
-- Active Routes table (route codes per country).
create table if not exists public.active_routes (
  id       uuid primary key default gen_random_uuid(),
  country  text default '',
  code     text default '',
  type     text default '',
  routes   text default '',
  notes    text default ''
);

-- ── list_registry ────────────────────────────────────────────────────────
-- Lists created on the platform but not sent yet, so they can be planned.
-- Seeded automatically from the dashboard's built-in list the first time the
-- table is empty.
create table if not exists public.list_registry (
  id       uuid primary key default gen_random_uuid(),
  list     text default '',
  country  text default '',
  partner  text default '',
  type     text default 'Fresh'           -- 'Fresh' or 'Clicked'
);

-- ── updated_at triggers ──────────────────────────────────────────────────
create or replace function public.set_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists planned_sends_set_updated_at on public.planned_sends;
create trigger planned_sends_set_updated_at before update on public.planned_sends
  for each row execute function public.set_updated_at();

drop trigger if exists list_decisions_set_updated_at on public.list_decisions;
create trigger list_decisions_set_updated_at before update on public.list_decisions
  for each row execute function public.set_updated_at();

-- ── access: row level security + policies for the browser (anon) key ─────
do $$
declare t text;
begin
  foreach t in array array['campaigns','content_rows','planned_sends','list_decisions',
                           'list_decision_history','list_sizes','active_routes','list_registry']
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists "dashboard access" on public.%I', t);
    execute format('create policy "dashboard access" on public.%I for all to anon, authenticated using (true) with check (true)', t);
    execute format('grant select, insert, update, delete on public.%I to anon, authenticated', t);
  end loop;
end $$;

-- Make the new tables visible to the API straight away.
notify pgrst, 'reload schema';
