-- ═══════════════════════════════════════════════════════════════
-- Financial Detective — Supabase Schema
-- ═══════════════════════════════════════════════════════════════

-- Companies table (fundamental data from Screener.in)
create table public.companies (
  ticker text primary key,
  name text not null,
  sector text not null,
  price double precision default 0,
  change_percent double precision default 0,
  beneish_m_score double precision default -2.5,
  altman_z_score double precision default 3.0,
  roce double precision default 0,
  operating_margin double precision default 0,
  debt_to_equity double precision default 0,
  truth_score int default 50,
  accounting_risk_score int default 25,
  sentiment_score int default 50,
  credibility_score int default 50,
  management_honesty_score int default 50,
  volatility double precision default 20,
  smart_money_signal text default 'mixed',
  trend text default 'stable',
  key_insights jsonb default '[]'::jsonb,
  red_flags jsonb default '[]'::jsonb,
  what_changed jsonb default '[]'::jsonb,
  credibility_timeline jsonb default '[]'::jsonb,
  fraud_similarities jsonb default '[]'::jsonb,
  smart_money_data jsonb default '{}'::jsonb,
  money_trail_data jsonb default '{}'::jsonb,
  price_history jsonb default '[]'::jsonb,
  truth_score_history jsonb default '[]'::jsonb,
  last_updated timestamptz default now()
);

-- Watchlists (per user)
create table public.watchlists (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  ticker text references public.companies(ticker) not null,
  position int default 0,
  created_at timestamptz default now(),
  unique(user_id, ticker)
);

-- Portfolio holdings (per user)
create table public.portfolio_holdings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  ticker text references public.companies(ticker) not null,
  shares int not null,
  avg_price double precision not null,
  created_at timestamptz default now(),
  unique(user_id, ticker)
);

-- ═══════════════════════════════════════════════════════════════
-- Row Level Security
-- ═══════════════════════════════════════════════════════════════

alter table public.companies enable row level security;
alter table public.watchlists enable row level security;
alter table public.portfolio_holdings enable row level security;

-- Companies: public read
create policy "Companies are publicly readable"
  on public.companies for select to anon, authenticated using (true);

-- Watchlists: users CRUD own rows
create policy "Users can read own watchlist"
  on public.watchlists for select to authenticated using (auth.uid() = user_id);
create policy "Users can insert own watchlist"
  on public.watchlists for insert to authenticated with check (auth.uid() = user_id);
create policy "Users can update own watchlist"
  on public.watchlists for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users can delete own watchlist"
  on public.watchlists for delete to authenticated using (auth.uid() = user_id);

-- Portfolio: users CRUD own rows
create policy "Users can read own portfolio"
  on public.portfolio_holdings for select to authenticated using (auth.uid() = user_id);
create policy "Users can insert own portfolio"
  on public.portfolio_holdings for insert to authenticated with check (auth.uid() = user_id);
create policy "Users can update own portfolio"
  on public.portfolio_holdings for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users can delete own portfolio"
  on public.portfolio_holdings for delete to authenticated using (auth.uid() = user_id);
