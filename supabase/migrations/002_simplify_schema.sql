-- Migration 002: Simplify items schema for hotel inventory
-- Removes unnecessary columns and indices (category, metadata) from items.

alter table items
  drop column if exists category,
  drop column if exists metadata;

-- Drop the category index if it exists
drop index if exists idx_items_category;

-- If you want to add a simple 'type' or 'tag' later, create a small lookup table instead.

-- End of migration
