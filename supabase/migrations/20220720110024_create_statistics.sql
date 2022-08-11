-- Create a statistics function joining the tracked times and targets tables on the same day.
-- Returns table of day, target interval, tracked interval, diff interval.
create
or replace function stats(date_start date, duration interval, step interval) returns table (date date, target interval, tracked interval, diff interval) as $$
    select dates.date date
      , coalesce(targets.duration, 'PT0'::interval) target
      , coalesce(sum(tracks.tracked::interval), 'PT0'::interval) tracked
      , coalesce(sum(tracks.tracked::interval), 'PT0'::interval) - coalesce(targets.duration, 'PT0'::interval) diff
    from generate_series(date_start, date_start + duration - '1 day'::interval, step) dates
            left join targets on targets.date = dates.date
            left join tracks on date(lower(tracks.tracked)) = dates.date
    group by dates.date
          , targets.id
$$ language sql;

create view
  accumulated_stats as (
    with
      tracks_summed as (
        select
          date(lower(tracked))     date
        , sum(tracked :: interval) tracked
        from
          tracks
        where
          account = auth.uid()
        group by
          date(lower(tracked))
      )
    , diffed as (
        select
          coalesce(targets.date, ts.date) date
        , coalesce(targets.duration, 'PT0' :: interval) target
        , coalesce(ts.tracked, 'PT0' :: interval) tracked
        , coalesce(ts.tracked, 'PT0' :: interval) - coalesce(targets.duration, 'PT0' :: interval) diff
        from
          targets
          full outer join tracks_summed ts on ts.date = targets.date
        where
          targets.account = auth.uid()
      )
    select
      diffed.date
    , min(diffed.target)    target
    , min(diffed.tracked)   tracked
    , min(diffed.diff)      diff
    , sum(diffed.diff) over (
        order by
          diffed.date asc rows between unbounded preceding
          and current row
      ) cumulative_diff
    from
      diffed
    group by
      diffed.date
    , diffed.diff
  );