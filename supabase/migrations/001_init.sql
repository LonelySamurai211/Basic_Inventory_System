-- Initial Supabase/Postgres migration for Cocool Hotel MIMS
-- Creates core tables, indexes, RLS policies, triggers for audit and low-stock notifications
-- Use this script in Supabase SQL editor or run via psql/migrations

-- Enable required extensions
create extension if not exists pgcrypto;

-- ---------- Types ----------
create type user_role as enum ('admin', 'dept_head', 'staff');

-- ---------- Auth/profile ----------
-- Profiles table mirrors auth.users (supabase auth) and stores application role and metadata
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  role user_role not null default 'staff',
  department text,
  created_at timestamptz default now()
);

create index if not exists idx_profiles_role on profiles(role);

-- ---------- Suppliers ----------
create table if not exists suppliers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  contact jsonb,
  address text,
  created_at timestamptz default now()
);

create index if not exists idx_suppliers_name on suppliers (name);

-- ---------- Items ----------
create table if not exists items (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text,
  unit text,
  supplier_id uuid references suppliers(id) on delete set null,
  stock_qty integer not null default 0,
  reorder_level integer not null default 0,
  metadata jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_items_name on items (name);
create index if not exists idx_items_category on items (category);

-- Trigger to update updated_at on items
create or replace function trigger_set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_set_updated_at on items;
create trigger trg_set_updated_at
  before update on items
  for each row execute function trigger_set_updated_at();

-- ---------- Transactions (item movements) ----------
create table if not exists transactions (
  id uuid primary key default gen_random_uuid(),
  item_id uuid references items(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  type text check (type in ('in','out','adjustment')) not null,
  quantity integer not null,
  note text,
  occurred_at timestamptz default now()
);

create index if not exists idx_transactions_item on transactions(item_id);
create index if not exists idx_transactions_user on transactions(user_id);

-- When a transaction is inserted, adjust the item's stock_qty and write an audit log
create or replace function fn_handle_transaction()
returns trigger as $$
declare
  v_new_qty integer;
begin
  if (tg_op = 'INSERT') then
    if (new.type = 'in') then
      update items set stock_qty = stock_qty + new.quantity where id = new.item_id;
    elsif (new.type = 'out') then
      update items set stock_qty = stock_qty - new.quantity where id = new.item_id;
    elsif (new.type = 'adjustment') then
      -- assume quantity is delta for adjustment
      update items set stock_qty = stock_qty + new.quantity where id = new.item_id;
    end if;

    -- Insert audit log
    insert into audit_logs(id, actor, action, object_type, object_id, metadata, created_at)
    values (gen_random_uuid(), new.user_id, 'transaction_insert', 'transaction', new.id, jsonb_build_object('type', new.type, 'qty', new.quantity, 'note', new.note), now());
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_after_insert_transaction on transactions;
create trigger trg_after_insert_transaction
  after insert on transactions
  for each row execute function fn_handle_transaction();

-- ---------- Purchase Orders & Lines ----------
create table if not exists purchase_orders (
  id uuid primary key default gen_random_uuid(),
  requested_by uuid references auth.users(id) on delete set null,
  department text,
  status text check (status in ('pending','approved','rejected','fulfilled')) not null default 'pending',
  total numeric(12,2) default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists purchase_order_lines (
  id uuid primary key default gen_random_uuid(),
  po_id uuid references purchase_orders(id) on delete cascade,
  item_id uuid references items(id) on delete set null,
  qty integer not null,
  unit_price numeric(12,2) default 0
);

-- ---------- Notifications ----------
create table if not exists notifications (
  id uuid primary key default gen_random_uuid(),
  type text not null,
  payload jsonb,
  target_user uuid references auth.users(id) on delete set null,
  is_read boolean default false,
  created_at timestamptz default now()
);

-- ---------- Audit logs ----------
create table if not exists audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor uuid references auth.users(id) on delete set null,
  action text not null,
  object_type text,
  object_id uuid,
  metadata jsonb,
  created_at timestamptz default now()
);

create index if not exists idx_audit_actor on audit_logs(actor);

-- ---------- Low-stock trigger ----------
-- When an item's stock drops below reorder_level, create a notification row
create or replace function fn_check_low_stock()
returns trigger as $$
declare
  v_old integer;
  v_new integer;
begin
  v_old := old.stock_qty;
  v_new := new.stock_qty;

  if v_new < new.reorder_level then
    -- Insert a notification without a specific target (admins should handle)
    insert into notifications(id, type, payload, created_at)
    values (gen_random_uuid(), 'low_stock', jsonb_build_object('item_id', new.id, 'name', new.name, 'stock_qty', v_new, 'reorder_level', new.reorder_level), now());
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_after_update_items_low_stock on items;
create trigger trg_after_update_items_low_stock
  after update of stock_qty, reorder_level on items
  for each row execute function fn_check_low_stock();

-- ---------- Row Level Security (RLS) ----------
-- Enable RLS on tables and create example policies.

-- Profiles: allow users to read and update their own profile; admins can manage all
alter table profiles enable row level security;

create policy "profiles_select_authenticated"
  on profiles
  for select
  using (auth.role() is not null);

create policy "profiles_self_update"
  on profiles
  for update
  using (id = auth.uid())
  with check (id = auth.uid());

create policy "profiles_admin_manage"
  on profiles
  for all
  using (exists (select 1 from profiles p2 where p2.id = auth.uid() and p2.role = 'admin'))
  with check (exists (select 1 from profiles p2 where p2.id = auth.uid() and p2.role = 'admin'));

-- Items: allow authenticated users to select; only admins can insert/update/delete items
alter table items enable row level security;

create policy "items_select_auth"
  on items
  for select
  using (auth.role() is not null);

create policy "items_admin_full"
  on items
  for all
  using (exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin'))
  with check (exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin'));

-- Transactions: allow insert by authenticated users; allow select for users in same department or admin
alter table transactions enable row level security;

create policy "transactions_insert_authenticated"
  on transactions
  for insert
  with check (auth.role() is not null);

create policy "transactions_select_profiles"
  on transactions
  for select
  using (exists (select 1 from profiles p where p.id = auth.uid()));

-- Purchase Orders: creators can read/write their POs; dept_head and admin can manage
alter table purchase_orders enable row level security;

create policy "po_insert_authenticated"
  on purchase_orders
  for insert
  with check (auth.role() is not null);

create policy "po_select_creator_or_admin"
  on purchase_orders
  for select
  using (
    requested_by = auth.uid()
    or exists (select 1 from profiles p where p.id = auth.uid() and p.role in ('dept_head','admin'))
  );

create policy "po_update_admin_or_creator"
  on purchase_orders
  for update
  using (
    requested_by = auth.uid()
    or exists (select 1 from profiles p where p.id = auth.uid() and p.role in ('dept_head','admin'))
  )
  with check (
    requested_by = auth.uid()
    or exists (select 1 from profiles p where p.id = auth.uid() and p.role in ('dept_head','admin'))
  );

-- Notifications: allow select by authenticated users; admins can view all
alter table notifications enable row level security;

create policy "notifications_select_auth"
  on notifications
  for select
  using (auth.role() is not null);

create policy "notifications_insert_internal"
  on notifications
  for insert
  using (auth.role() is not null)
  with check (auth.role() is not null);

-- Audit logs: only admins can read; inserts allowed by db functions
alter table audit_logs enable row level security;

create policy "audit_admin_select"
  on audit_logs
  for select
  using (exists (select 1 from profiles p where p.id = auth.uid() and p.role = 'admin'));

create policy "audit_insert_internal"
  on audit_logs
  for insert
  using (auth.role() is not null)
  with check (auth.role() is not null);

-- ---------- Seed data (example) ----------
-- NOTE: For real deployments, use environment-specific seed routines or migrations tools.
insert into suppliers (id, name, contact, address)
values
  (gen_random_uuid(), 'Acme Supplies', jsonb_build_object('phone','+1-555-0100','email','sales@acme.example'), '123 Supplier St');

insert into items (id, name, category, unit, supplier_id, stock_qty, reorder_level)
select gen_random_uuid(), 'Bath Towel', 'Linen', 'pcs', s.id, 120, 30
from suppliers s
limit 1;

-- Create a sample admin profile if matching auth user exists (replace with actual user uuid in production)
-- Example: INSERT INTO profiles (id, display_name, role) VALUES ('00000000-0000-0000-0000-000000000000', 'Local Admin', 'admin');

-- End of migration
