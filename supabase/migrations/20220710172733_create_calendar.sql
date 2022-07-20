-- Create a calendar function joining the intervals and targets tables on the same day.
-- Return empty days where there are no intervals or targets.

create or replace function calendar(start date, step interval)
    returns table(date date, target json, tracked json)
as
$$

select
    dates.dates date,
    json_build_object(
        'id', targets.id,
        'date', targets.date,
        'duration', targets.duration
    ) target,
    json_agg(
        json_build_object(
            'id', tracks.id,
            'tracked', tracks.tracked::json
        )
    ) tracks
from generate_series($1, $1 + step - '1 day'::interval, '1 day'::interval) dates
    left join targets on targets.date = dates.date
    left join tracks on date(lower(tracks.tracked)) = dates.date
group by dates.dates, targets.id

$$
    language sql;

