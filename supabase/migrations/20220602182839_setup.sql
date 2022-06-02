-- We need moddatetime to automatically set updated_at column for tables on UPDATEs
create extension if not exists moddatetime schema extensions;
-- Btree_gist allows us to perform interval constraint checks
create extension if not exists btree_gist schema extensions;

