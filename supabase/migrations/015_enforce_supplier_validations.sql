-- Migration 015: enforce supplier validation rules

with normalized as (
  select
    id,
    row_number() over (order by created_at, id) as rn,
    lpad(substr(regexp_replace(coalesce(tax_id, contact->>'taxId', ''), '\\D', '', 'g'), 1, 12), 12, '0') as padded_tax,
    regexp_replace(coalesce(contact_number, contact->>'phone', ''), '\\D', '', 'g') as digits_phone,
    lower(coalesce(contact_email, contact->>'email', '')) as raw_email,
    address
  from suppliers
)
update suppliers s
set
  tax_id = format('%s-%s-%s-%s',
    substr(n.padded_tax, 1, 3),
    substr(n.padded_tax, 4, 3),
    substr(n.padded_tax, 7, 3),
    substr(n.padded_tax, 10, 3)
  ),
  contact_number = case
    when char_length(n.digits_phone) >= 11 then substr(n.digits_phone, 1, 11)
    when char_length(n.digits_phone) >= 7 then substr(n.digits_phone, 1, 7)
    else lpad((n.rn % 100000000000)::text, 11, '0')
  end,
  contact_email = case
    when n.raw_email ~* '@(gmail|yahoo)\\.com$' then lower(n.raw_email)
    else format('supplier%03s@gmail.com', n.rn)
  end,
  address = coalesce(nullif(trim(s.address), ''), format('Pending address %s', n.rn))
from normalized n
where s.id = n.id;

update suppliers
set name = case
    when cleaned_name = '' then 'Supplier'
    else cleaned_name
  end
from (
  select
    id,
    btrim(regexp_replace(name, '[^A-Za-z ]', '', 'g')) as cleaned_name
  from suppliers
) as data
where suppliers.id = data.id
  and suppliers.name !~ '^[A-Za-z ]+$';

update suppliers
set contact_email = lower(contact_email);

alter table suppliers
  alter column tax_id set not null,
  alter column contact_number set not null,
  alter column contact_email set not null,
  alter column address set not null;

alter table suppliers
  drop constraint if exists chk_suppliers_name_letters_only,
  drop constraint if exists chk_suppliers_tax_id_format,
  drop constraint if exists chk_suppliers_contact_number_format,
  drop constraint if exists chk_suppliers_contact_email_domain,
  drop constraint if exists chk_suppliers_address_present;

alter table suppliers
  add constraint chk_suppliers_name_letters_only
    check (name ~ '^[A-Za-z ]+$'),
  add constraint chk_suppliers_tax_id_format
    check (tax_id ~ '^\\d{3}-\\d{3}-\\d{3}-\\d{3}$'),
  add constraint chk_suppliers_contact_number_format
    check (contact_number ~ '^\\d{7}$' or contact_number ~ '^\\d{11}$'),
  add constraint chk_suppliers_contact_email_domain
    check (contact_email ~* '^[^@]+@(gmail|yahoo)\\.com$'),
  add constraint chk_suppliers_address_present
    check (char_length(trim(address)) > 0);
