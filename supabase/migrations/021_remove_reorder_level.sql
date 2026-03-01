-- Migration 021: remove reorder level requirements from items and disable legacy low-stock trigger
-- Context: the application no longer captures manual reorder thresholds.
-- This migration drops the obsolete column plus the notification trigger/function
-- that depended on it so inserts/updates stop failing when no threshold is provided.

begin;

-- Drop the low-stock trigger if it still exists.
do $$
begin
  if exists (
    select 1
    from information_schema.triggers
    where trigger_name = 'trg_after_update_items_low_stock'
      and event_object_table = 'items'
      and event_object_schema = 'public'
  ) then
    execute 'drop trigger if exists trg_after_update_items_low_stock on public.items';
  end if;
end;
$$;

-- Drop the helper function backing the trigger (safe if it was already removed).
drop function if exists public.fn_check_low_stock();

-- Remove the reorder_level column so inserts no longer require it.
do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'items'
      and column_name = 'reorder_level'
  ) then
    execute 'alter table public.items drop column reorder_level';
  end if;
end;
$$;

commit;
