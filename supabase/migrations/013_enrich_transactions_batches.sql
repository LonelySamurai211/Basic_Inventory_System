-- Adds supplier and batch date metadata to transactions so stock movements capture batch context.
alter table transactions
  add column if not exists supplier_id uuid references suppliers(id) on delete set null;

alter table transactions
  add column if not exists manufactured_on date;

alter table transactions
  add column if not exists delivered_on date;

alter table transactions
  add column if not exists expiry_on date;

create index if not exists idx_transactions_supplier on transactions(supplier_id);
