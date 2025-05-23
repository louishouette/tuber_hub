# Chartkick

Create beautiful JavaScript charts.

## Quick Start

Add this line to your application’s Gemfile:

```ruby
gem "chartkick"
```

Then in `config/importmap.rb`, add:

```ruby
pin "chartkick", to: "chartkick.js"
pin "Chart.bundle", to: "Chart.bundle.js"
```

And in `app/javascript/application.js`, add:

```js
import "chartkick"
import "Chart.bundle"
```

## Charts

Line chart

```erb
<%= line_chart User.group_by_day(:created_at).count %>
```

Pie chart

```erb
<%= pie_chart Goal.group(:name).count %>
```

Column chart

```erb
<%= column_chart Task.group_by_hour_of_day(:created_at, format: "%l %P").count %>
```

Bar chart

```erb
<%= bar_chart Shirt.group(:size).sum(:price) %>
```

Area chart

```erb
<%= area_chart Visit.group_by_minute(:created_at).maximum(:load_time) %>
```

Scatter chart

```erb
<%= scatter_chart City.pluck(:size, :population) %>
```

Geo chart - *Google Charts*

```erb
<%= geo_chart Medal.group(:country).count %>
```

Timeline - *Google Charts*

```erb
<%= timeline [
  ["Washington", "1789-04-29", "1797-03-03"],
  ["Adams", "1797-03-03", "1801-03-03"],
  ["Jefferson", "1801-03-03", "1809-03-03"]
] %>
```

Multiple series

```erb
<%= line_chart [
  {name: "Workout", data: {"2025-01-01" => 3, "2025-01-02" => 4}},
  {name: "Call parents", data: {"2025-01-01" => 5, "2025-01-02" => 3}}
] %>
```

or

```erb
<%= line_chart Feat.group(:goal_id).group_by_week(:created_at).count %>
```

## Data

Data can be a hash, array, or URL.

#### Hash

```erb
<%= line_chart({"2025-01-01" => 2, "2025-01-02" => 3}) %>
```

#### Array

```erb
<%= line_chart [["2025-01-01", 2], ["2025-01-02", 3]] %>
```

#### URL

Make your pages load super fast and stop worrying about timeouts. Give each chart its own endpoint.

```erb
<%= line_chart completed_tasks_charts_path %>
```

And in your controller, pass the data as JSON.

```ruby
class ChartsController < ApplicationController
  def completed_tasks
    render json: Task.group_by_day(:completed_at).count
  end
end
```

For multiple series, add `chart_json` at the end.

```ruby
render json: Task.group(:goal_id).group_by_day(:completed_at).count.chart_json
```

## Options

Id, width, and height

```erb
<%= line_chart data, id: "users-chart", width: "800px", height: "500px" %>
```

Min and max values

```erb
<%= line_chart data, min: 1000, max: 5000 %>
```

`min` defaults to 0 for charts with non-negative values. Use `nil` to let the charting library decide.

Min and max for x-axis - *Chart.js*

```erb
<%= line_chart data, xmin: "2025-01-01", xmax: "2025-02-01" %>
```

Colors

```erb
<%= line_chart data, colors: ["#b00", "#666"] %>
```

Stacked columns or bars

```erb
<%= column_chart data, stacked: true %>
```

Discrete axis

```erb
<%= line_chart data, discrete: true %>
```

Label (for single series)

```erb
<%= line_chart data, label: "Value" %>
```

Axis titles

```erb
<%= line_chart data, xtitle: "Time", ytitle: "Population" %>
```

Straight lines between points instead of a curve

```erb
<%= line_chart data, curve: false %>
```

Hide points

```erb
<%= line_chart data, points: false %>
```

Show or hide legend

```erb
<%= line_chart data, legend: false %>
```

Specify legend position

```erb
<%= line_chart data, legend: "bottom" %>
```

Donut chart

```erb
<%= pie_chart data, donut: true %>
```

Prefix, useful for currency - *Chart.js, Highcharts*

```erb
<%= line_chart data, prefix: "$" %>
```

Suffix, useful for percentages - *Chart.js, Highcharts*

```erb
<%= line_chart data, suffix: "%" %>
```

Set a thousands separator - *Chart.js, Highcharts*

```erb
<%= line_chart data, thousands: "," %>
```

Set a decimal separator - *Chart.js, Highcharts*

```erb
<%= line_chart data, decimal: "," %>
```

Set significant digits - *Chart.js, Highcharts*

```erb
<%= line_chart data, precision: 3 %>
```

Set rounding - *Chart.js, Highcharts*

```erb
<%= line_chart data, round: 2 %>
```

Show insignificant zeros, useful for currency - *Chart.js, Highcharts*

```erb
<%= line_chart data, round: 2, zeros: true %>
```

Friendly byte sizes - *Chart.js*

```erb
<%= line_chart data, bytes: true %>
```

Specify the message when data is loading

```erb
<%= line_chart data, loading: "Loading..." %>
```

Specify the message when data is empty

```erb
<%= line_chart data, empty: "No data" %>
```

Refresh data from a remote source every `n` seconds

```erb
<%= line_chart url, refresh: 60 %>
```

You can pass options directly to the charting library with:

```erb
<%= line_chart data, library: {backgroundColor: "#eee"} %>
```

See the documentation for [Chart.js](https://www.chartjs.org/docs/), [Google Charts](https://developers.google.com/chart/interactive/docs/gallery), and [Highcharts](https://api.highcharts.com/highcharts) for more info. For Chart.js plugins, check out [this guide](guides/Chartjs-Plugins.md).

To customize datasets in Chart.js, use:

```erb
<%= line_chart data, dataset: {borderWidth: 10} %>
```

You can pass this option to individual series as well.

### Global Options

To set options for all of your charts, create an initializer `config/initializers/chartkick.rb` with:

```ruby
Chartkick.options = {
  height: "400px",
  colors: ["#b00", "#666"]
}
```

Customize the html

```ruby
Chartkick.options[:html] = '<div id="%{id}" style="height: %{height};">%{loading}</div>'
```

You capture the JavaScript in a content block with:

```ruby
Chartkick.options[:content_for] = :charts_js
```

Then, in your layout, use:

```erb
<%= yield :charts_js %>
```

For Padrino, use `yield_content` instead of `yield`.

This is great for including all of your JavaScript at the bottom of the page.

### Multiple Series

You can pass a few options with a series:

- `name`
- `data`
- `color`
- `dataset` - *Chart.js only*
- `points` - *Chart.js only*
- `curve` - *Chart.js only*

### Code

If you want to use the charting library directly, get the code with:

```erb
<%= line_chart data, code: true %>
```

The code will be logged to the JavaScript console. JavaScript functions cannot be logged, so it may not be identical.

### Download Charts

*Chart.js only*

Give users the ability to download charts. It all happens in the browser - no server-side code needed.

```erb
<%= line_chart data, download: true %>
```

Safari will open the image in a new window instead of downloading.

Set the filename

```erb
<%= line_chart data, download: {filename: "boom"} %>
```

Set the background color

```erb
<%= line_chart data, download: {background: "#ffffff"} %>
```

Set title

```erb
<%= line_chart data, title: "Awesome chart" %>
```

## Additional Charting Libraries

- [Google Charts](#google-charts)
- [Highcharts](#highcharts)

### Google Charts

In your layout or views, add:

```erb
<%= javascript_include_tag "https://www.gstatic.com/charts/loader.js" %>
```

For Importmap (Rails 8 default), in `config/importmap.rb`, add:

```ruby
pin "chartkick", to: "chartkick.js"
```

And in `app/javascript/application.js`, add:

```js
import "chartkick"
```

To specify a language or Google Maps API key, use:

```js
Chartkick.configure({language: "de", mapsApiKey: "..."})
```

before your charts.

### Highcharts

For Importmap (Rails 8 default), run:

```sh
bin/importmap pin highcharts --download
```

And in `config/importmap.rb`, add:

```ruby
pin "chartkick", to: "chartkick.js"
```

And in `app/javascript/application.js`, add:

```js
import "chartkick"
import Highcharts from "highcharts"

window.Highcharts = Highcharts
```

### Multiple Libraries

If more than one charting library is loaded, choose between them with:

```erb
<%= line_chart data, adapter: "google" %> <!-- or highcharts or chartjs -->
```

## JavaScript API

Access a chart with:

```javascript
var chart = Chartkick.charts["chart-id"]
```

Get the underlying chart object with:

```javascript
chart.getChartObject()
```

You can also use:

```javascript
chart.getElement()
chart.getData()
chart.getOptions()
chart.getAdapter()
```

Update the data with:

```javascript
chart.updateData(newData)
```

You can also specify new options:

```javascript
chart.setOptions(newOptions)
// or
chart.updateData(newData, newOptions)
```

Refresh the data from a remote source:

```javascript
chart.refreshData()
```

Redraw the chart with:

```javascript
chart.redraw()
```

Destroy the chart with:

```javascript
chart.destroy()
```

Loop over charts with:

```javascript
Chartkick.eachChart(function (chart) {
  // do something
})
```

## Content Security Policy (CSP)

Check out [how to configure CSP](https://github.com/ankane/chartkick/blob/master/guides/Content-Security-Policy.md)

## Tutorials

- [Charts with Chartkick and Groupdate](https://gorails.com/episodes/charts-with-chartkick-and-groupdate)
- [Creando gráficos en Ruby on Rails con Chartkick y Chart.js](https://www.youtube.com/watch?v=W92AlkwQn3M)
- [Make Easy Graphs and Charts on Rails with Chartkick](https://www.sitepoint.com/make-easy-graphs-and-charts-on-rails-with-chartkick/)
- [Practical Graphs on Rails: Chartkick in Practice](https://www.sitepoint.com/graphs-on-rails-chartkick-in-practice/)
