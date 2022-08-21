# backend

Experimental [supabase](https://supabase.com) backend for Ajanottaja.

## Getting up an running on Supabase

Create new [Supabase](https://app.supabase.com/) organization (if you don't already have one) and project.
Wait for project to finish setting up, this can take a bit of time.
Go to SQL Editor, create new query and [make the postgres user a superuser so it has appropriate rights during migration](https://github.com/supabase/supabase/discussions/6326).

```sql
alter role postgres SUPERUSER
```

Link your Supabase command line to your Supabase project (see Reference ID on settings page) and push migrations:

```sh
supabase link --project-ref <yourref>
supabase db push
```

Finally remove the superuser grant from the postgres user:

```sql
alter role postgres NOSUPERUSER
```

Your Supabase backend should now be fully up and running and you can connect frontends to it.

## Development

[Install Supabase CLI](https://supabase.com/docs/guides/cli) and any other dependencies.

```bash
supabase start
```

To create a new database migration run:

```bash
supabase migration new <name-of-migration>
```

After creating a new migration you need to reset the local db:

```bash
supabase db reset
```

## Usage

The API can be consumed using any of the [Supabase client integration libraries](https://supabase.com/docs/#start-with-a-framework).

### Handling Date, timestamptz, tstzrange, interval

Ajanottaja makes use of the timestamptz, tstzrange, and interval types to handle time related data.
By default Postgres (and thus Supabase) will return these in the SQL (Postgres) format.

For simple columns Ajanottaja will not automatically convert to ISO8601.
To convert values to the ISO format you can cast to json, e.g. `.select("target::json")`.
For JSON-aggregated columns like `target` and `tracks` in the `calendar` function values are already converted to ISO8601.
This seems to be a nice compromise.

Unfortunately setting `intervalStyle` seem to behave differently between self-hosted (dev) and Supabase production environments.
It is also better to be more explicit when values are converted or not.


## License

The DB migration scripts and any other project source code files are licensed under AGPLV3.
See [LICENSE](/LICENSE) for details.
