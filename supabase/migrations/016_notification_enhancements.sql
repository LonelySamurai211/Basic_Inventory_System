-- Migration 016: normalize notifications schema and modernize low-stock trigger

alter table notifications
  add column if not exists title text,
  add column if not exists message text,
  add column if not exists category text,
  add column if not exists recipient_id uuid references app_users(id) on delete set null;

alter table notifications
  alter column is_read set default false;

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'notifications'
      and column_name = 'target_user'
  ) and not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'notifications'
      and column_name = 'recipient_id'
  ) then
    execute 'alter table notifications rename column target_user to recipient_id';
  end if;
end;
$$;

do $$
begin
  if exists (
    select 1 from information_schema.table_constraints
    where table_schema = 'public'
      and table_name = 'notifications'
      and constraint_name = 'notifications_recipient_id_fkey'
  ) then
    execute 'alter table notifications drop constraint notifications_recipient_id_fkey';
  end if;
end;
$$;

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'notifications'
      and column_name = 'type'
  ) then
    execute $upd$
      update notifications
      set category = coalesce(category, type),
          title = coalesce(title, initcap(replace(type, '_', ' ')))
      where category is null or title is null;
    $upd$;
  end if;
end;
$$;

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'notifications'
      and column_name = 'payload'
  ) then
    execute $msg$
      update notifications
      set message = coalesce(
        message,
        case
          when payload ? 'name' then format('%s is below reorder level (%s remaining vs %s).',
            coalesce(payload->>'name', 'Tracked item'),
            coalesce(payload->>'stock_qty', '0'),
            coalesce(payload->>'reorder_level', '0'))
          else payload::text
        end)
      where message is null;
    $msg$;
  end if;
end;
$$;

update notifications
  set title = coalesce(title, 'System alert');

update notifications
  set message = coalesce(message, 'Automatic notification.');

update notifications
  set category = coalesce(category, 'general');

alter table notifications
  alter column title set not null,
  alter column message set not null;

do $$
begin
  if exists (
    select 1 from information_schema.table_constraints
    where table_name = 'notifications'
      and constraint_name = 'notifications_recipient_id_fkey'
  ) then
    execute 'alter table notifications drop constraint notifications_recipient_id_fkey';
  end if;
end;
$$;

alter table notifications
  add constraint notifications_recipient_id_fkey
    foreign key (recipient_id) references app_users(id) on delete set null;

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'notifications'
      and column_name = 'payload'
  ) then
    execute 'alter table notifications drop column payload';
  end if;
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'notifications'
      and column_name = 'type'
  ) then
    execute 'alter table notifications drop column type';
  end if;
end;
$$;

create index if not exists idx_notifications_recipient
  on notifications(recipient_id, is_read);

create index if not exists idx_notifications_category
  on notifications(category);

create or replace function fn_check_low_stock()
returns trigger as $$
declare
  was_low boolean := false;
  now_low boolean := false;
  unit_label text;
  alert_title text;
  alert_message text;
begin
  was_low :=
    old.stock_qty is not null and
    old.reorder_level is not null and
    old.stock_qty < old.reorder_level;

  now_low :=
    new.stock_qty is not null and
    new.reorder_level is not null and
    new.stock_qty < new.reorder_level;

  if now_low and not was_low then
    unit_label := coalesce(nullif(new.unit, ''), 'units');
    alert_title := format('Low stock: %s', coalesce(new.name, 'Inventory item'));
    alert_message := format(
      '%s %s remaining (reorder level %s).',
      coalesce(new.stock_qty::text, '0'),
      unit_label,
      coalesce(new.reorder_level::text, '0')
    );
    insert into notifications (title, message, category, created_at)
    values (alert_title, alert_message, 'low_stock', now());
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_after_update_items_low_stock on items;
create trigger trg_after_update_items_low_stock
  after update of stock_qty, reorder_level on items
  for each row execute function fn_check_low_stock();
