-- Add richer metadata to purchase orders for the Flutter admin UI.

alter table if exists purchase_orders
  add column if not exists supplier_id uuid references suppliers(id) on delete set null;

alter table if exists purchase_orders
  add column if not exists supplier_name text;

alter table if exists purchase_orders
  add column if not exists notes text;

alter table if exists purchase_orders
  add column if not exists recorded_by uuid references app_users(id) on delete set null;

alter table if exists purchase_orders
  add column if not exists expected_date date;

create index if not exists idx_purchase_orders_status on purchase_orders(status);
create index if not exists idx_purchase_orders_supplier on purchase_orders(supplier_id);

update purchase_orders
  set supplier_name = coalesce(supplier_name, 'Unspecified supplier')
  where supplier_name is null;

drop trigger if exists trg_touch_purchase_orders on purchase_orders;
create trigger trg_touch_purchase_orders
  before update on purchase_orders
  for each row
  execute procedure touch_updated_at();
