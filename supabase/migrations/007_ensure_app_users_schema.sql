-- Ensure the custom authentication tables exist even if earlier migrations ran before they were added.

create extension if not exists "pgcrypto";

create table if not exists app_users (
    id uuid primary key default gen_random_uuid(),
    email text not null unique,
    password text not null,
    full_name text not null,
    age integer,
    position text,
    role text not null default 'staff',
    avatar_url text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index if not exists idx_app_users_role on app_users(role);

create or replace function touch_updated_at()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

drop trigger if exists trg_touch_app_users on app_users;
create trigger trg_touch_app_users
    before update on app_users
    for each row
    execute procedure touch_updated_at();

create table if not exists notifications (
    id uuid primary key default gen_random_uuid(),
    title text not null,
    message text not null,
    category text,
    is_read boolean not null default false,
    recipient_id uuid references app_users(id) on delete cascade,
    created_at timestamptz not null default now()
);

alter table notifications
    add column if not exists recipient_id uuid references app_users(id) on delete cascade;

create index if not exists idx_notifications_recipient
    on notifications(recipient_id, is_read);

create table if not exists reports (
    id uuid primary key default gen_random_uuid(),
    title text not null,
    summary text,
    details text,
    created_by uuid references app_users(id) on delete set null,
    created_at timestamptz not null default now()
);

alter table reports
    add column if not exists created_by uuid references app_users(id) on delete set null;

create index if not exists idx_reports_created_by
    on reports(created_by);

insert into app_users (email, password, full_name, role, position)
select 'admin@cocoolhotel.test', 'admin123', 'Default Administrator', 'admin', 'Hotel Administrator'
where not exists (
    select 1 from app_users where role = 'admin'
);
