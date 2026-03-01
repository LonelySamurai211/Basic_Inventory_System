-- Adds required metadata fields for purchase orders.
alter table purchase_orders
  add column if not exists item_name text,
  add column if not exists product_name text,
  add column if not exists supplier_details text,
  add column if not exists delivery_date date,
  add column if not exists delivery_agent text;
