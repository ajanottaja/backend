-- Convenience function for generating summaries for various time periods
-- Period: week 'yyyy-IW', month 'yyyy-mm', etc
create or replace function summary(title text, period text, date timestamptz)
  returns table (title text, period text, target interval, tracked interval, diff interval)
as
$body$
  with target as (
    select
      $1 title,
      to_char(date, $2) period,
      coalesce(sum(duration), 'PT0'::interval) target
    from
      targets
    where
      to_char(date, $2) = to_char($3, $2)
    group by
      to_char(date, $2)
  ), tracked as (
    select
      $1 title,
      to_char(date(min(lower(interval))), $2) period,
      coalesce(sum(coalesce(upper(interval), now()) - lower(interval)), 'PT0'::interval) tracked
    from
      intervals
    where
      to_char(date(lower(interval)), $2) = to_char($3, $2)
  )
    
  select
    $1 title,
    target.period,
    target,
    tracked,
    tracked - target diff 
  from
    target
  join
    tracked on target.title = tracked.title
$body$
language sql;

-- A View exposing summary values for day, week, month, year, and all time
create or replace view summary as
  select *
  from summary('day', 'yyyy-mm-dd', now())
  union all
  select *
  from summary('week', 'yyyy-IW', now())
  union all
  select *
  from summary('month', 'yyyy-mm', now())
  union all
  select *
  from summary('year', 'yyyy', now())
  union all
  select *
  from summary('all', 'AD', now());
