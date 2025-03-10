# Groupdate

## Installation

Add this line to your application’s Gemfile:

```ruby
gem "groupdate"
```

## Getting Started

```ruby
User.group_by_day(:created_at).count
# {
#   Wed, 01 Jan 2025 => 50,
#   Thu, 02 Jan 2025 => 100,
#   Fri, 03 Jan 2025 => 34
# }
```

Results are returned in ascending order by default, so no need to sort.

You can group by:

- second
- minute
- hour
- day
- week
- month
- quarter
- year

and

- minute_of_hour
- hour_of_day
- day_of_week (Sunday = 0, Monday = 1, etc)
- day_of_month
- day_of_year
- month_of_year

Use it anywhere you can use `group`. Works with `count`, `sum`, `minimum`, `maximum`, and `average`. For `median` and `percentile`, check out [ActiveMedian](https://github.com/ankane/active_median).

### Time Zones

The default time zone is `Time.zone`.  Change this with:

```ruby
Groupdate.time_zone = "Pacific Time (US & Canada)"
```

or

```ruby
User.group_by_week(:created_at, time_zone: "Pacific Time (US & Canada)").count
# {
#   Sun, 05 Jan 2025 => 70,
#   Sun, 12 Jan 2025 => 54,
#   Sun, 19 Jan 2025 => 80
# }
```

Time zone objects also work. To see a list of available time zones in Rails, run `rake time:zones:all`.

### Week Start

Weeks start on Sunday by default. Change this with:

```ruby
Groupdate.week_start = :monday
```

or

```ruby
User.group_by_week(:created_at, week_start: :monday).count
```

### Day Start

You can change the hour days start with:

```ruby
Groupdate.day_start = 2 # 2 am - 2 am
```

or

```ruby
User.group_by_day(:created_at, day_start: 2).count
```

### Time Range

To get a specific time range, use:

```ruby
User.group_by_day(:created_at, range: 2.weeks.ago.midnight..Time.now).count
```

To expand the range to the start and end of the time period, use:

```ruby
User.group_by_day(:created_at, range: 2.weeks.ago..Time.now, expand_range: true).count
```

To get the most recent time periods, use:

```ruby
User.group_by_week(:created_at, last: 8).count # last 8 weeks
```

To exclude the current period, use:

```ruby
User.group_by_week(:created_at, last: 8, current: false).count
```

### Order

You can order in descending order with:

```ruby
User.group_by_day(:created_at, reverse: true).count
```

### Keys

Keys are returned as date or time objects for the start of the period.

To get keys in a different format, use:

```ruby
User.group_by_month(:created_at, format: "%b %Y").count
# {
#   "Jan 2025" => 10
#   "Feb 2025" => 12
# }
```

or

```ruby
User.group_by_hour_of_day(:created_at, format: "%-l %P").count
# {
#    "12 am" => 15,
#    "1 am"  => 11
#    ...
# }
```

Takes a `String`, which is passed to [strftime](http://strfti.me/), or a `Symbol`, which is looked up by `I18n.localize` in `i18n` scope 'time.formats', or a `Proc`.  You can pass a locale with the `locale` option.

### Series

The entire series is returned by default. To exclude points without data, use:

```ruby
User.group_by_day(:created_at, series: false).count
```

Or change the default value with:

```ruby
User.group_by_day(:created_at, default_value: "missing").count
```

### Dynamic Grouping

```ruby
User.group_by_period(:day, :created_at).count
```

Limit groupings with the `permit` option.

```ruby
User.group_by_period(params[:period], :created_at, permit: ["day", "week"]).count
```

Raises an `ArgumentError` for unpermitted periods.

### Custom Duration

To group by a specific number of minutes or seconds, use:

```ruby
User.group_by_minute(:created_at, n: 10).count # 10 minutes
```

### Date Columns

If grouping on date columns which don’t need time zone conversion, use:

```ruby
User.group_by_week(:created_on, time_zone: false).count
```

### Default Scopes

If you use Postgres and have a default scope that uses `order`, you may get a `column must appear in the GROUP BY clause` error (just like with Active Record’s `group` method). Remove the `order` scope with:

```ruby
User.unscope(:order).group_by_day(:count).count
```

## Arrays and Hashes

```ruby
users.group_by_day { |u| u.created_at } # or group_by_day(&:created_at)
```

Supports the same options as above

```ruby
users.group_by_day(time_zone: time_zone) { |u| u.created_at }
```

Get the entire series with:

```ruby
users.group_by_day(series: true) { |u| u.created_at }
```

Count

```ruby
users.group_by_day { |u| u.created_at }.to_h { |k, v| [k, v.count] }
```