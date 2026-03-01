-- Drop per-item date metadata so that lifecycle tracking lives exclusively in transactions.
alter table if exists public.items
  drop column if exists manufactured_on;

alter table if exists public.items
  drop column if exists delivered_on;

alter table if exists public.items
  drop column if exists expiry_on;
