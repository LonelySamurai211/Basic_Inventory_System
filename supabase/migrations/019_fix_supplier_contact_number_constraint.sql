-- Migration 019: fix supplier contact number constraint rejecting valid digits

alter table suppliers
  drop constraint if exists chk_suppliers_contact_number_format;

alter table suppliers
  add constraint chk_suppliers_contact_number_format
    check (
      btrim(contact_number) ~ '^[0-9]{7}$'
      or btrim(contact_number) ~ '^[0-9]{11}$'
    );
