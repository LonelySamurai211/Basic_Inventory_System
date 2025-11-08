-- Ensure a public storage bucket for profile avatars exists.

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update set public = true;

-- Allow read access to anyone, since avatars are non-sensitive.
drop policy if exists "Public avatars read" on storage.objects;
create policy "Public avatars read"
  on storage.objects
  for select
  using (bucket_id = 'avatars');

-- Allow unauthenticated clients (anon key) to upload and update avatars.
drop policy if exists "Public avatars upload" on storage.objects;
create policy "Public avatars upload"
  on storage.objects
  for insert
  with check (bucket_id = 'avatars');

drop policy if exists "Public avatars update" on storage.objects;
create policy "Public avatars update"
  on storage.objects
  for update
  using (bucket_id = 'avatars')
  with check (bucket_id = 'avatars');

-- Allow deleting avatars in case a staff member resets their photo.
drop policy if exists "Public avatars delete" on storage.objects;
create policy "Public avatars delete"
  on storage.objects
  for delete
  using (bucket_id = 'avatars');
