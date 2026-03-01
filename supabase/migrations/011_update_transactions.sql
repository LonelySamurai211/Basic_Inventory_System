-- Migration 011: enforce stock in/out transactions and capture transaction dates

alter table transactions
  add column if not exists transaction_date date;

update transactions
  set transaction_date = coalesce(transaction_date, occurred_at::date);

update transactions
  set transaction_date = current_date
  where transaction_date is null;

update transactions
  set type = case when quantity < 0 then 'out' else 'in' end,
      quantity = abs(quantity)
  where type = 'adjustment';

alter table transactions
  alter column transaction_date set default current_date;

alter table transactions
  alter column transaction_date set not null;

alter table transactions
  drop constraint if exists transactions_type_check;

alter table transactions
  add constraint chk_transactions_type_in_out check (type in ('in','out'));

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
    end if;

    insert into audit_logs(id, actor, action, object_type, object_id, metadata, created_at)
    values (
      gen_random_uuid(),
      new.user_id,
      'transaction_insert',
      'transaction',
      new.id,
      jsonb_build_object('type', new.type, 'qty', new.quantity, 'note', new.note),
      now()
    );
  end if;
  return new;
end;
$$ language plpgsql;
