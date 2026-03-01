-- Migration 023: Add supply_limit and reorder_level columns to items table

alter table items
  add column if not exists supply_limit integer,
  add column if not exists reorder_level integer;
