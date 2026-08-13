-- =========================================================
-- SmartCity Connect — profiles table + Row Level Security
-- Run this in Supabase: Dashboard -> SQL Editor -> New query
-- =========================================================

-- 1. The profiles table.
-- id references auth.users.id, so each profile is tied 1-to-1 to a
-- Supabase Auth user. There is NO password column here on purpose —
-- Supabase Auth stores credentials separately and securely.
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null,
  email text not null,
  role text not null default 'citizen' check (role in ('citizen', 'admin')),
  created_at timestamptz not null default now()
);

-- 2. Enable Row Level Security.
-- Without this, RLS policies below don't apply and the table would
-- be open (or closed) by default depending on project settings —
-- always enable it explicitly.
alter table public.profiles enable row level security;

-- 3. Policy: a logged-in user can read their OWN profile row.
-- This is what lets the app check "am I a citizen or an admin?"
-- right after login.
create policy "Users can view their own profile"
on public.profiles
for select
using ( auth.uid() = id );

-- 4. Policy: a logged-in user can create their OWN profile row
-- (used right after signup / first Google login).
-- Note this does NOT let them set role = 'admin' for themselves in
-- a way that matters, because the frontend code always sends
-- role = 'citizen' on public signup, and admins are created manually
-- by the team directly in the database (see README). If you want to
-- be extra strict, you can additionally restrict this policy with
-- `with check (role = 'citizen')` so the database itself refuses any
-- attempt to self-insert as admin.
create policy "Users can create their own profile"
on public.profiles
for insert
with check ( auth.uid() = id and role = 'citizen' );

-- 5. Policy: a logged-in user can update their OWN profile — but
-- NOT their own role. This stops a citizen from editing their row
-- in the database and promoting themselves to admin.
create policy "Users can update their own profile (not their role)"
on public.profiles
for update
using ( auth.uid() = id )
with check ( auth.uid() = id and role = (select role from public.profiles where id = auth.uid()) );

-- =========================================================
-- Optional but recommended: auto-create a profile row whenever a
-- new user signs up (covers both email/password and Google signups
-- automatically, even if the frontend call is ever skipped).
-- =========================================================

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, name, email, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.email),
    new.email,
    'citizen' -- every new signup starts as a citizen, no exceptions
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- =========================================================
-- How to create your FIRST ADMIN (do this manually, once):
--
-- 1. Create the user normally (sign up through the app, or add them
--    in Supabase Dashboard -> Authentication -> Users -> Add user).
-- 2. Then run:
--
--    update public.profiles
--    set role = 'admin'
--    where email = 'admin@example.com';
--
-- This is the ONLY way an admin account should ever be created.
-- =========================================================
