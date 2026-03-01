-- Migration 022: Align inventory schema with Flutter projection
-- Context: Recent UI changes stopped using the legacy metadata/category fields, yet
-- some environments still have the columns which break read queries when they are
-- referenced accidentally. This migration idempotently removes the unused fields
-- so the column list matches what the app selects.

begin;

alter table if exists public.items
  drop column if exists metadata,
  drop column if exists category;

commit;
