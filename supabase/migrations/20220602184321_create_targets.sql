create table if not exists targets (
  id uuid primary key default uuid_generate_v4(),
  date date not null,
  account uuid references auth.users not null,
  duration interval not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(date, account)
);

create trigger handle_updated_at before update on targets
  for each row execute procedure moddatetime (updated_at);

alter table targets enable row level security;

create policy "Users can insert their own targets."
  on targets for insert
  with check ( auth.uid() = account );

create policy "Users can update own targets."
  on targets for update
  using ( auth.uid() = account );

create policy "Targets are viewable by users who created them."
  on targets for select
  using ( auth.uid() = account );