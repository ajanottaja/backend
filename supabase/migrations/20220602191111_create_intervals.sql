create table if not exists intervals (
    id uuid primary key default uuid_generate_v4(),
    interval tstzrange,
    account uuid references auth.users not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    multiplier double precision not null default 1.0,
    unique(account, interval),
    constraint interval_lower_not_null_ck check (lower(interval) is not null),
    constraint interval_lower_not_infinity_ck check ( lower(interval) > '-infinity' ),
    constraint interval_upper_not_infinity_ck check ( lower(interval) < 'infinity' ),
    constraint interval_non_overlapping_intervals exclude using gist (
        account with =,
        interval with &&
    )
);

create trigger handle_updated_at before update on intervals
  for each row execute procedure moddatetime (updated_at);

alter table intervals enable row level security;

create policy "Users can insert their own intervals."
  on intervals for insert
  with check ( auth.uid() = account );

create policy "Users can update own intervals."
  on intervals for update
  using ( auth.uid() = account );

create policy "Users can delete own intervals."
  on intervals for delete
  using ( auth.uid() = account );

create policy "Intervals are viewable by users who created them."
  on intervals for select
  using ( auth.uid() = account );

-- We need a view to get the active interval as Postgrest
-- and thus Supabase does not support @> operator in queries

create view intervals_active as
  select * from intervals
  where interval @> now();

-- Convenience functions to start and stop an active interval
-- For start function we can get the account from the auth.uid helper function
-- For stop we only need to get the id of the interval from the calling client

create or replace function interval_start(multiplier double precision default 1.0)
  returns setof intervals
as $$
  insert into intervals (interval, multiplier, account)
  values (tstzrange(now(), NULL), multiplier, auth.uid()) returning *;
$$
language sql;

create or replace function interval_stop(id uuid)
  returns setof intervals
as $$
  update intervals set interval = tstzrange(lower(interval), now())
  where id = $1 returning *;
$$
language sql;

