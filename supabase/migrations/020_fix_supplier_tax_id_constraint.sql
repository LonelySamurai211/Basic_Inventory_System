-- Migration 020: fix supplier tax ID constraint rejecting valid formats

alter table suppliers
  drop constraint if exists chk_suppliers_tax_id_format;

alter table suppliers
  add constraint chk_suppliers_tax_id_format
    check (
      tax_id ~ '^[0-9]{3}-[0-9]{3}-[0-9]{3}-[0-9]{3}$'
    );
