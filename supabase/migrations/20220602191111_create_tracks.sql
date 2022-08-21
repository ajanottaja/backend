create table
  if not exists tracks (
    id uuid primary key default uuid_generate_v4()
  , tracked tstzrange not null default tstzrange(now(), null, '[)')
  , account uuid references auth.users not null default auth.uid()
  , created_at timestamptz not null default now()
  , updated_at timestamptz not null default now()
  , multiplier double precision not null default 1.0
  , unique (account, tracked)
  , constraint tracked_lower_not_null_ck check (lower(tracked) is not null)
  , constraint tracked_lower_not_infinity_ck check (lower(tracked) > '-infinity')
  , constraint tracked_upper_not_infinity_ck check (lower(tracked) < 'infinity')
  , constraint tracked_non_overlapping_tracks exclude using gist (
      account
      with
        =
      , tracked
      with
        &&
    )
  );

create trigger
  handle_updated_at before
update
  on tracks for each row
execute
  procedure moddatetime(updated_at);

alter table
  tracks enable row level security;

create policy
  "Users can insert their own tracks." on tracks for
insert
with
  check (auth.uid() = account);

create policy
  "Users can update own tracks." on tracks for
update
  using (auth.uid() = account);

create policy
  "Users can delete own tracks." on tracks for
delete
  using (auth.uid() = account);

create policy
  "Tracks are viewable by users who created them." on tracks for
select
  using (auth.uid() = account);

-- We need a view to get the active track as Postgrest
-- and thus Supabase does not support @> operator in queries
create view
  tracks_active as
select
  *
from
  tracks
where
  tracked @> now();

alter view
  tracks_active owner to authenticated;

-- Convenience functions to start and stop an active track
-- For start function we can get the account from the auth.uid helper function
-- For stop we only need to get the id of the track from the calling client
create
or replace function track_start(multiplier double precision default 1.0) returns setof tracks as $$
    insert into tracks (tracked, multiplier, account)
    values (tstzrange(now(), null), $1, auth.uid())
    returning *;
$$ language sql;

create
or replace function track_stop(id uuid) returns setof tracks as $$
    update tracks
    set tracked = tstzrange(lower(tracked), now())
    where id = $1
    returning *;
$$ language sql;

create
or replace function track_insert(range_start timestamptz, range_end timestamptz) returns setof tracks as $$
    insert into tracks (tracked, multiplier, account)
    values (tstzrange(range_start, range_end), 1.0, auth.uid())
    returning *;
$$ language sql;