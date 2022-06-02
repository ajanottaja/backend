create table if not exists intervals (
    id uuid primary key default uuid_generate_v4(),
    interval tstzrange,
    account uuid references auth.users not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
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

create policy "Intervals are viewable by users who created them."
  on intervals for select
  using ( auth.uid() = account );