-- We need moddatetime to automatically set updated_at column for tables on UPDATEs
create extension
  if not exists moddatetime schema extensions;

-- Btree_gist allows us to perform interval constraint checks
create extension
  if not exists btree_gist schema extensions;

-- Show intervals as ISO durations for easier parsing in frontends
alter user
  postgres
set
  intervalstyle to 'iso_8601';

-- Add new custom json converter for tstzrange
create function
  tsrange_to_json(tsrange) returns json as $$
select json_build_object('lower', lower($1), 'upper',upper($1),'lowerInclusive',lower_inc($1),'upperInclusive'
                       , upper_inc($1));
$$ language sql;

create cast
  (tsrange as json)
with
  function tsrange_to_json(tsrange) as assignment;

create function
  tstzrange_to_json(tstzrange) returns json as $$
select json_build_object('lower', lower($1), 'upper',upper($1),'lowerInclusive',lower_inc($1),'upperInclusive'
                       , upper_inc($1));
$$ language sql;

create cast
  (tstzrange as json)
with
  function tstzrange_to_json(tstzrange) as assignment;

-- Add a helper function to calculate the duration of a time range
-- If the upper bound is not included, it is assumed to be now()
create function
  tsrange_to_interval(tsrange) returns interval as $$
select (coalesce(upper($1), now()) - lower($1));
$$ language sql;

create cast
  (tsrange as interval)
with
  function tsrange_to_interval(tsrange) as assignment;

create function
  tstzrange_to_interval(tstzrange) returns interval as $$
select (coalesce(upper($1), now()) - lower($1));
$$ language sql;

create cast
  (tstzrange as interval)
with
  function tstzrange_to_interval(tstzrange) as assignment;

-- Add helper function to aggregate range values
create aggregate
  range_merge(anyrange) (sfunc = range_merge, stype = anyrange);