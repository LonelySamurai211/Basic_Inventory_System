-- Migration 018: fix supplier email constraint rejecting valid gmail/yahoo addresses

alter table suppliers
  drop constraint if exists chk_suppliers_contact_email_domain;

alter table suppliers
  add constraint chk_suppliers_contact_email_domain
    check (
      lower(contact_email) ~ '^[^@[:space:]]+@(gmail|yahoo)[.]com$'
    );
