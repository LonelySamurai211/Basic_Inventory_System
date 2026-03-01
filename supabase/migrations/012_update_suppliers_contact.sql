-- Migration 012: add structured supplier contact fields

alter table suppliers
  add column if not exists tax_id text,
  add column if not exists contact_number text,
  add column if not exists contact_email text;

update suppliers
  set tax_id = coalesce(tax_id, contact->>'taxId'),
      contact_number = coalesce(contact_number, contact->>'phone'),
      contact_email = coalesce(contact_email, contact->>'email')
  where contact is not null;

comment on column suppliers.tax_id is 'Registered tax identification number for the vendor.';
comment on column suppliers.contact_number is 'Primary phone number for the vendor contact.';
comment on column suppliers.contact_email is 'Primary email address for the vendor contact.';
