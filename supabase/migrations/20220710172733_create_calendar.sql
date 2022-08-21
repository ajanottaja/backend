-- Create a calendar function joining the intervals and targets tables on the same day.
-- Returns records between startDate and startDate + duration at intervals of step.
-- Return empty days where there are no intervals or targets.
create function
  calendar(date_start date, duration interval, step interval) returns table (date date, target json, tracks json) as $$

select  dates.dates date
      , case when targets is not null then json_build_object('id', targets.id, 'date', targets.date, 'duration', targets.duration::json) else null end target
      , case when count(tracks.id) > 0 then json_agg((json_build_object('id', tracks.id, 'tracked', tracks.tracked::json))) else '[]'::json end  tracks
from generate_series(date_start, date_start + duration - '1 day'::interval, step) dates
         left join targets on targets.date = dates.date
         left join tracks on date(lower(tracks.tracked)) = dates.date
group by dates.dates, targets.id
order by dates.dates

$$ language sql;

-- Create a calendar function joining the intervals and targets tables on the same day.
-- Returns records between startDate and stopDate at intervals of step.
-- Return empty days where there are no intervals or targets.
create function
  calendar(date_start date, date_stop date, step interval) returns table (date date, target json, tracks json) as $$

select dates.dates date
     , json_build_object('id', targets.id, 'date', targets.date, 'duration', targets.duration::json) target
     , json_agg(json_build_object('id', tracks.id, 'tracked', tracks.tracked::json)) tracks
from generate_series(date_start, date_stop, step) dates
         left join targets on targets.date = dates.date
         left join tracks on date(lower(tracks.tracked)) = dates.date
group by dates.dates, targets.id
order by dates.dates

$$ language sql;