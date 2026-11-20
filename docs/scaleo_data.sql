-- Shared storage for the Daily Report (External): Scaleo uploads and your own findings/action items.
-- Without these tables the dashboard keeps this data in the uploader's browser only.
-- Run once in Supabase → SQL Editor.

-- Scaleo conversions export (one row per Reg / FTD, keyed by transaction)
create table if not exists public.scaleo_conversions (
  txn         text primary key,
  data        jsonb not null,
  source      text,
  uploaded_at timestamptz not null default now()
);
-- Scaleo daily sheet (one row per day)
create table if not exists public.scaleo_daily (
  day         date primary key,
  data        jsonb not null,
  source      text,
  uploaded_at timestamptz not null default now()
);
-- Scaleo monthly sheet (one row per month, e.g. '2026-11')
create table if not exists public.scaleo_monthly (
  month       text primary key,
  data        jsonb not null,
  source      text,
  uploaded_at timestamptz not null default now()
);
-- Your own Key findings / Action items
create table if not exists public.report_notes (
  id          text primary key,
  kind        text not null check (kind in ('finding', 'action')),
  text        text not null,
  color       text,
  done        boolean not null default false,
  created_at  timestamptz not null default now()
);

alter table public.scaleo_conversions enable row level security;
alter table public.scaleo_daily       enable row level security;
alter table public.scaleo_monthly     enable row level security;
alter table public.report_notes       enable row level security;

create policy "scaleo_conversions read"   on public.scaleo_conversions for select using (true);
create policy "scaleo_conversions insert" on public.scaleo_conversions for insert with check (true);
create policy "scaleo_conversions update" on public.scaleo_conversions for update using (true) with check (true);
create policy "scaleo_daily read"   on public.scaleo_daily for select using (true);
create policy "scaleo_daily insert" on public.scaleo_daily for insert with check (true);
create policy "scaleo_daily update" on public.scaleo_daily for update using (true) with check (true);
create policy "scaleo_monthly read"   on public.scaleo_monthly for select using (true);
create policy "scaleo_monthly insert" on public.scaleo_monthly for insert with check (true);
create policy "scaleo_monthly update" on public.scaleo_monthly for update using (true) with check (true);
create policy "report_notes read"   on public.report_notes for select using (true);
create policy "report_notes insert" on public.report_notes for insert with check (true);
create policy "report_notes update" on public.report_notes for update using (true) with check (true);
create policy "report_notes delete" on public.report_notes for delete using (true);
