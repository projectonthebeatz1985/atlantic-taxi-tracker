-- Atlantic Taxi Connect: allow drivers to share location without an active ride
-- Run this ONCE in Supabase SQL Editor for the existing project.
-- Existing ride-linked location rows are preserved.
alter table public.driver_locations
  alter column ride_id drop not null;

comment on column public.driver_locations.ride_id is
  'NULL when a driver is sharing general availability/location without an active ride; set to a ride id while sharing for an active ride.';
