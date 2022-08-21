create table
  profiles (
    id uuid primary key references auth.users not null
  , nick text
  , created_at timestamptz not null default now()
  , updated_at timestamptz not null default now()
  );

create trigger
  handle_updated_at before
update
  on profiles for each row
execute
  procedure moddatetime(updated_at);

alter table
  profiles enable row level security;

create policy
  "Users can insert their own profile." on profiles for
insert
with
  check (auth.uid() = id);

create policy
  "Users can update own profile." on profiles for
update
  using (auth.uid() = id);

create policy
  "Profiles are viewable by users who created them." on profiles for
select
  using (auth.uid() = id);

-- inserts a row into public.profiles
create function public.handle_new_user() 
returns trigger 
language plpgsql 
security definer set search_path = public
as $$
begin
  insert into profiles (id, nick)
  values (new.id, '');
  return new;
end;
$$;

-- trigger the function every time a user is created
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();