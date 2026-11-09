-- Atlantic Taxi Connect: customer ride-code access migration
-- Run ONCE in Supabase SQL Editor after the original schema.sql.
-- Customers do not need Supabase Auth accounts or public profiles.

create extension if not exists pgcrypto with schema extensions;

-- Customer rides are now phone bookings, not linked to customer login accounts.
alter table public.rides alter column customer_id drop not null;

create table if not exists public.ride_access_codes (
  ride_id uuid primary key references public.rides(id) on delete cascade,
  code_hash text not null unique,
  expires_at timestamptz not null default (now() + interval '24 hours'),
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.ride_access_codes enable row level security;
revoke all on public.ride_access_codes from anon, authenticated;

-- Only an authenticated company admin can create/replace a ride code.
create or replace function public.create_ride_access_code(p_ride_id uuid, p_code text)
returns boolean
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  if auth.uid() is null or public.current_role() <> 'admin' then
    raise exception 'Only an Atlantic Taxi admin can create ride codes';
  end if;
  if p_code is null or p_code !~ '^[0-9]{8}$' then
    raise exception 'Ride code must contain exactly 8 digits';
  end if;
  if not exists (select 1 from public.rides r where r.id = p_ride_id) then
    raise exception 'Ride not found';
  end if;
  insert into public.ride_access_codes(ride_id, code_hash, expires_at, revoked_at)
  values (p_ride_id, encode(extensions.digest(p_code, 'sha256'), 'hex'), now() + interval '24 hours', null)
  on conflict (ride_id) do update
    set code_hash = excluded.code_hash,
        expires_at = excluded.expires_at,
        revoked_at = null,
        created_at = now();
  return true;
end;
$$;

-- Public, read-only lookup: a valid private code reveals only that one ride,
-- its assigned driver's display/vehicle details, and the driver's current GPS.
create or replace function public.get_ride_by_code(p_code text)
returns jsonb
language sql
security definer
set search_path = public, extensions
as $$
  select jsonb_build_object(
    'ride', jsonb_build_object(
      'id', r.id,
      'pickup', r.pickup,
      'dropoff', r.dropoff,
      'status', r.status,
      'estimated_fare', r.estimated_fare,
      'created_at', r.created_at
    ),
    'driver', jsonb_build_object(
      'display_name', coalesce(nullif(p.display_name, ''), 'Your Atlantic Taxi driver'),
      'vehicle', coalesce(p.vehicle, '')
    ),
    'location', case when dl.ride_id is null then null else jsonb_build_object(
      'latitude', dl.latitude,
      'longitude', dl.longitude,
      'heading', dl.heading,
      'updated_at', dl.updated_at
    ) end,
    'expires_at', ac.expires_at
  )
  from public.ride_access_codes ac
  join public.rides r on r.id = ac.ride_id
  join public.profiles p on p.user_id = r.driver_id
  left join public.driver_locations dl on dl.ride_id = r.id
  where p_code ~ '^[0-9]{8}$'
    and ac.code_hash = encode(extensions.digest(p_code, 'sha256'), 'hex')
    and ac.revoked_at is null
    and ac.expires_at > now()
    and r.status <> 'cancelled'
  limit 1;
$$;

revoke all on function public.create_ride_access_code(uuid, text) from public, anon;
revoke all on function public.get_ride_by_code(text) from public;
grant execute on function public.create_ride_access_code(uuid, text) to authenticated;
grant execute on function public.get_ride_by_code(text) to anon, authenticated;

-- Keep direct table access locked down; the public code lookup is via the RPC only.
