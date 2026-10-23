-- Four Fold Event Management: secure single-business admin schema
-- Apply only to the dedicated Four Fold Supabase project after reviewing it.
-- Admin access is based on the trusted app_metadata.role JWT claim.
-- Set that claim to "admin" only for the intended owner account using a trusted
-- Supabase dashboard/admin process. Never authorize from user_metadata.
-- All tables are private to admins; public website visitors get no table access.

create extension if not exists pgcrypto;

create table if not exists public.clients (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  phone text not null,
  email text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.enquiries (
  id uuid primary key default gen_random_uuid(),
  client_id uuid references public.clients(id) on delete set null,
  customer_name text not null,
  phone text not null,
  email text,
  event_type text not null,
  preferred_date date,
  location text,
  guest_count integer check (guest_count is null or guest_count >= 0),
  budget_min_paise bigint check (budget_min_paise is null or budget_min_paise >= 0),
  budget_max_paise bigint check (budget_max_paise is null or budget_max_paise >= 0),
  status text not null default 'new' check (status in ('new','contacted','quoted','converted','closed')),
  source text not null default 'website' check (source in ('website','whatsapp','phone','social','referral','other')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  client_id uuid references public.clients(id) on delete set null,
  enquiry_id uuid references public.enquiries(id) on delete set null,
  event_code text unique,
  event_name text not null,
  event_type text not null,
  event_date date not null,
  venue text,
  guest_count integer check (guest_count is null or guest_count >= 0),
  status text not null default 'enquiry' check (status in ('enquiry','confirmed','completed','cancelled')),
  total_amount_paise bigint not null default 0 check (total_amount_paise >= 0),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.quotations (
  id uuid primary key default gen_random_uuid(),
  quote_number text not null unique,
  client_id uuid references public.clients(id) on delete set null,
  event_id uuid references public.events(id) on delete set null,
  status text not null default 'draft' check (status in ('draft','sent','accepted','declined','expired')),
  issue_date date not null default current_date,
  valid_until date,
  subtotal_paise bigint not null default 0 check (subtotal_paise >= 0),
  discount_paise bigint not null default 0 check (discount_paise >= 0),
  tax_paise bigint not null default 0 check (tax_paise >= 0),
  total_paise bigint not null default 0 check (total_paise >= 0),
  terms text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.quotation_items (
  id uuid primary key default gen_random_uuid(),
  quotation_id uuid not null references public.quotations(id) on delete cascade,
  description text not null,
  quantity numeric(12,3) not null default 1 check (quantity > 0),
  unit text not null default 'item',
  unit_price_paise bigint not null default 0 check (unit_price_paise >= 0),
  line_total_paise bigint not null default 0 check (line_total_paise >= 0),
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete restrict,
  amount_paise bigint not null check (amount_paise > 0),
  payment_date date not null default current_date,
  method text not null default 'other' check (method in ('cash','upi','bank_transfer','card','cheque','other')),
  reference text,
  status text not null default 'received' check (status in ('received','pending','refunded','void')),
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.vendors (
  id uuid primary key default gen_random_uuid(),
  business_name text not null,
  contact_name text,
  phone text,
  email text,
  service_type text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.event_tasks (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  title text not null,
  description text,
  due_at timestamptz,
  status text not null default 'todo' check (status in ('todo','in_progress','done','blocked')),
  assigned_to uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.gallery_items (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  category text not null,
  image_url text not null,
  alt_text text,
  is_published boolean not null default false,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.audit_log (
  id bigint generated always as identity primary key,
  actor_id uuid references auth.users(id) on delete set null,
  action text not null,
  table_name text not null,
  record_id text,
  summary jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists enquiries_status_created_idx on public.enquiries(status, created_at desc);
create index if not exists enquiries_preferred_date_idx on public.enquiries(preferred_date);
create index if not exists events_date_status_idx on public.events(event_date, status);
create index if not exists events_client_idx on public.events(client_id);
create index if not exists quotations_client_idx on public.quotations(client_id);
create index if not exists quotation_items_quote_idx on public.quotation_items(quotation_id, sort_order);
create index if not exists payments_event_date_idx on public.payments(event_id, payment_date desc);
create index if not exists event_tasks_event_status_idx on public.event_tasks(event_id, status);
create index if not exists gallery_published_order_idx on public.gallery_items(is_published, sort_order);

-- Every public-schema table has RLS enabled. Only a trusted admin JWT claim can access records.
do $$
declare t text;
begin
  foreach t in array array[
    'clients','enquiries','events','quotations','quotation_items',
    'payments','vendors','event_tasks','gallery_items','audit_log'
  ] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all on table public.%I from anon, authenticated', t);
    execute format('grant select, insert, update, delete on table public.%I to authenticated', t);
    execute format('drop policy if exists "fourfold_admin_all" on public.%I', t);
    execute format(
      'create policy "fourfold_admin_all" on public.%I for all to authenticated using ((select auth.jwt() -> ''app_metadata'' ->> ''role'') = ''admin'') with check ((select auth.jwt() -> ''app_metadata'' ->> ''role'') = ''admin'')',
      t
    );
  end loop;
end $$;

-- Do not grant anon access to customer records or admin data.
revoke all on all tables in schema public from anon;
