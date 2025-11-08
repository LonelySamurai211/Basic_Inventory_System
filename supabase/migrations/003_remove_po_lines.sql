-- Migration 003: Remove purchase_order_lines table
-- The app will track purchase orders at a summary level only; line-level detail is unnecessary.

drop table if exists purchase_order_lines;

-- Clean up any stray objects referencing purchase_order_lines if necessary.

-- End of migration
