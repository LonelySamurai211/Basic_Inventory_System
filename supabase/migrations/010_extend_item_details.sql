-- Migration 010: Extend item details for richer inventory metadata
-- Adds descriptive fields and supply tracking columns expected by the Flutter UI.

alter table items
  add column if not exists description text,
  add column if not exists manufactured_on date,
  add column if not exists delivered_on date,
  add column if not exists expiry_on date,
  add column if not exists barcode text,
  add column if not exists food_section text check (food_section in ('wet','dry'));

comment on column items.description is 'Optional long-form description for the catalog entry.';
comment on column items.manufactured_on is 'Manufacturing/production date for perishable goods.';
comment on column items.delivered_on is 'Most recent delivery date recorded for the item.';
comment on column items.expiry_on is 'Expiry or best-before date when applicable.';
comment on column items.barcode is 'Human readable barcode or SKU code for labeling/scanning.';
comment on column items.food_section is 'Food storage classification, e.g. wet or dry pantry section.';
