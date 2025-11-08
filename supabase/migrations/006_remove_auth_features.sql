-- Remove authentication-related database structures now that the app runs without login.

-- Drop policies that depended on authenticated profiles.
drop policy if exists "profiles_select_authenticated" on profiles;
drop policy if exists "profiles_self_update" on profiles;
drop policy if exists "profiles_admin_manage" on profiles;

drop policy if exists "items_select_auth" on items;
drop policy if exists "items_admin_full" on items;

drop policy if exists "transactions_insert_authenticated" on transactions;
drop policy if exists "transactions_select_profiles" on transactions;

drop policy if exists "po_insert_authenticated" on purchase_orders;
drop policy if exists "po_select_creator_or_admin" on purchase_orders;
drop policy if exists "po_update_admin_or_creator" on purchase_orders;

drop policy if exists "notifications_select_auth" on notifications;
drop policy if exists "notifications_insert_internal" on notifications;

drop policy if exists "audit_admin_select" on audit_logs;
drop policy if exists "audit_insert_internal" on audit_logs;

-- Disable RLS entirely for operational tables.
alter table if exists items disable row level security;
alter table if exists transactions disable row level security;
alter table if exists purchase_orders disable row level security;
alter table if exists notifications disable row level security;
alter table if exists audit_logs disable row level security;

-- Remove helper function and tables tied to authenticated profiles.
drop function if exists public.create_admin_account(text, text, user_role);
drop function if exists public.create_admin_account(text, text);

drop table if exists profiles cascade;

drop type if exists user_role;
