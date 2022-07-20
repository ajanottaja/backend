-- Create a statistics function joining the tracked times and targets tables on the same day.
-- Returns table of day, target interval, tracked interval, diff interval.

create or replace function stats_by_interval(start date, step interval)
    returns table(date date, target interval, tracked interval, diff interval)
as
$$
select
    dates.date date,
    coalesce(targets.duration, 'PT0'::interval) target,
    coalesce(sum(tracks.tracked::interval), 'PT0'::interval) tracked,
    coalesce(sum(tracks.tracked::interval), 'PT0'::interval) - coalesce(targets.duration, 'PT0'::interval) diff
from generate_series($1, $1 + step - '1 day'::interval, '1 day'::interval) dates
    left join targets on targets.date = dates.date
    left join tracks on date(lower(tracks.tracked)) = dates.date
group by dates.date, targets.id
$$
    language sql;


create view stats as (
    select
        targets.date date,
        coalesce(targets.duration, 'PT0'::interval) target,
        coalesce(sum(tracks.tracked::interval), 'PT0'::interval) tracked,
        coalesce(sum(tracks.tracked::interval), 'PT0'::interval) - coalesce(targets.duration, 'PT0'::interval) diff
    from
        targets
        full outer join tracks on date(lower(tracks.tracked)) = targets.date
    group by targets.date, targets.id
);


create view accumulated_stats as
    with
        first_target as (select date from targets order by targets.date asc limit 1),
        first_track as (select date(lower(tracks.tracked)) date from tracks order by tracks.tracked asc limit 1),
        summary as (select * from stats),
        stats as (
            select *, 'PT0'::interval test, sum(summary.diff) over (order by summary.date asc rows between unbounded preceding and current row) cumulative_diff
            from summary
        )
    select dates.date, stats.target, stats.tracked, stats.diff, stats.cumulative_diff
    from
        first_target,
        first_track,
        generate_series(least(first_target.date, first_track.date), now(), '1 day'::interval) dates
    left join stats on stats.date = dates.date;