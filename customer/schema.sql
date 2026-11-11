-- Atlantic Taxi Connect: Supabase SQL schema
-- Run in Supabase SQL Editor after creating your project.
create table if not exists public.profiles (
 user_id uuid primary key references auth.users(id) on delete cascade,
 role text not null check (role in ('admin','driver','customer')),
 display_name text not null default '', phone text, vehicle text, created_at timestamptz not null default now()
);
create table if not exists public.rides (
 id uuid primary key default gen_random_uuid(), customer_id uuid not null references public.profiles(user_id),
 driver_id uuid not null references public.profiles(user_id), pickup text not null, dropoff text not null,
 estimated_miles numeric(8,2) not null default 0, estimated_fare numeric(10,2) not null,
 final_fare numeric(10,2), payment_method text not null default 'cash' check(payment_method='cash'),
 status text not null default 'assigned' check(status in ('assigned','en_route','arrived','in_progress','completed','cancelled')),
 created_by uuid not null references public.profiles(user_id), created_at timestamptz not null default now(), completed_at timestamptz
);
create table if not exists public.driver_locations (
 driver_id uuid primary key references public.profiles(user_id) on delete cascade,
 ride_id uuid not null references public.rides(id) on delete cascade,
 latitude double precision not null, longitude double precision not null, heading double precision,
 updated_at timestamptz not null default now()
);
create index if not exists rides_customer_idx on public.rides(customer_id,created_at desc);
create index if not exists rides_driver_idx on public.rides(driver_id,created_at desc);

create or replace function public.current_role() returns text language sql stable security definer set search_path=public as $$ select role from public.profiles where user_id=auth.uid() $$;
alter table public.profiles enable row level security;
alter table public.rides enable row level security;
alter table public.driver_locations enable row level security;
-- Profiles: a user sees own profile; admin can manage company profiles.
create policy "profile self read" on public.profiles for select to authenticated using(user_id=auth.uid() or public.current_role()='admin');
create policy "admin manage profiles" on public.profiles for all to authenticated using(public.current_role()='admin') with check(public.current_role()='admin');
create policy "customer can view assigned driver profile" on public.profiles for select to authenticated using(
 role='driver' and exists(select 1 from public.rides r where r.driver_id=profiles.user_id and r.customer_id=auth.uid() and r.status not in ('completed','cancelled'))
);
-- Rides: admin manages all; customer reads own; assigned driver reads and updates own assigned rides.
create policy "admin manage rides" on public.rides for all to authenticated using(public.current_role()='admin') with check(public.current_role()='admin');
create policy "customer read own rides" on public.rides for select to authenticated using(customer_id=auth.uid());
create policy "driver read assigned rides" on public.rides for select to authenticated using(driver_id=auth.uid());
create policy "driver update assigned rides" on public.rides for update to authenticated using(driver_id=auth.uid()) with check(driver_id=auth.uid());
-- Location is visible to admin and the customer on that specific ride; driver can update own location.
create policy "driver manage own location" on public.driver_locations for all to authenticated using(driver_id=auth.uid()) with check(driver_id=auth.uid());
create policy "admin read locations" on public.driver_locations for select to authenticated using(public.current_role()='admin');
create policy "customer read assigned driver location" on public.driver_locations for select to authenticated using(exists(select 1 from public.rides r where r.id=ride_id and r.customer_id=auth.uid()));
-- Enable realtime for rides and location updates.
alter publication supabase_realtime add table public.rides;
alter publication supabase_realtime add table public.driver_locations;
