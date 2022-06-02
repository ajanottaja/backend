# backend

Experimental [supabase](https://supabase.com) backend for Ajanottaja.

## Development

[Install Supabase CLI](https://supabase.com/docs/reference/cli/installing-and-updating) and any other dependencies.

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