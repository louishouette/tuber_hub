module Market
  class SegmentsController < BaseController
    include WeekFormattable
    before_action :set_segment, only: [:show, :edit, :update, :destroy]

    def index
      @segments = MarketSegment.all
      @weekly_stats = {}
      
      @segments.each do |segment|
        # Get records for the current season
        current_season_records = MarketPriceRecord.joins(:market_place)
                                                .where(market_place: { market_segment_id: segment.id })
                                                .in_current_season

        if current_season_records.exists?
          # Group by week and calculate average prices
          # Get the data grouped by week
          weekly_data = current_season_records
                          .select(
                            "DATE_TRUNC('week', published_at) as week,
                             AVG(avg_price_per_kg) as avg_price"
                          )
                          .group("DATE_TRUNC('week', published_at)")
                          .order("week ASC")

          # Store with full dates first to ensure proper sorting
          dated_prices = {}
          weekly_data.each do |data|
            dated_prices[data.week.to_date] = data.avg_price.round(2) if data.avg_price.present?
          end

          # Convert to week format maintaining the order
          prices_by_week = dated_prices.transform_keys { |date| format_week(date) }

          @weekly_stats[segment.id] = {
            prices: prices_by_week,
            has_data: true
          }
        else
          @weekly_stats[segment.id] = { has_data: false }
        end
      end
    end

    def new
      @segment = MarketSegment.new
    end

    def create
      @segment = MarketSegment.new(segment_params)

      if @segment.save
        redirect_to market_segments_path, notice: 'Market segment was successfully created.'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def show
      # Get records for current season
      @current_season_records = MarketPriceRecord.joins(:market_place)
                                               .where(market_place: { market_segment_id: @segment.id })
                                               .in_current_season

      # Prepare weekly stats for price and volume evolution
      if @current_season_records.exists?
        # Current season data
        weekly_data = @current_season_records
                        .select(
                          "DATE_TRUNC('week', published_at) as week,
                           AVG(avg_price_per_kg) as avg_price,
                           SUM(quantities_presented_per_kg) as total_volume,
                           COUNT(DISTINCT market_place_id) as active_markets"
                        )
                        .group("DATE_TRUNC('week', published_at)")
                        .order("week ASC")

        @weekly_stats = weekly_data.each_with_object({ prices: {}, volumes: {}, active_markets: {} }) do |data, stats|
          week = format_week(data.week.to_date)
          stats[:prices][week] = data.avg_price.round(2) if data.avg_price.present?
          stats[:volumes][week] = data.total_volume.round(0) if data.total_volume.present?
          stats[:active_markets][week] = data.active_markets if data.active_markets.present?
        end

        # Historical trend (past 3 seasons)
        historical_data = MarketPriceRecord.joins(:market_place)
                           .where(market_place: { market_segment_id: @segment.id })
                           .where('published_at >= ?', 3.years.ago)
                           .where('published_at < ?', MarketPriceRecord.current_season_start)
                           .select(
                             "DATE_TRUNC('week', published_at) as week,
                              AVG(avg_price_per_kg) as avg_price"
                           )
                           .group("DATE_TRUNC('week', published_at)")
                           .order("week ASC")

        # Transform historical data to match current season's weeks
        historical_trend_data = []
        current_season_start = MarketPriceRecord.current_season_start.to_date
        current_season_end = MarketPriceRecord.current_season_end.to_date
        
        # Helper to check if a week number is in the excluded range (W10-W46)
        def week_in_excluded_range?(week_key)
          week_num = week_key.match(/W(\d+)/)[1].to_i
          week_num >= 10 && week_num <= 46
        end
        
        # Create a mapping of week numbers to ensure proper ordering
        week_order = {}
        date = current_season_start
        index = 0
        while date <= current_season_end
          week_key = format_week(date)
          week_order[week_key] = index unless week_in_excluded_range?(week_key)
          date += 1.week
          index += 1
        end
        
        historical_data.each do |data|
          historical_date = data.week.to_date
          historical_month = historical_date.month
          
          # Map the historical date to the equivalent date in current season
          current_date = if historical_month >= Seasonable::SEASON_START_MONTH
            # Sept-Dec: Use current season start year
            historical_date.change(year: current_season_start.year)
          else
            # Jan-Mar: Use current season end year
            historical_date.change(year: current_season_end.year)
          end
          
          # Only include dates within the current season bounds and not in excluded range
          week_key = format_week(current_date)
          if current_date >= current_season_start && 
             current_date <= current_season_end && 
             !week_in_excluded_range?(week_key)
            historical_trend_data << {
              date: current_date,
              week_key: week_key,
              price: data.avg_price
            }
          end
        end
        
        # Group by week and calculate averages, round to integers
        @historical_trend = historical_trend_data
          .group_by { |data| data[:week_key] }
          .transform_values { |group| (group.pluck(:price).sum / group.size).round }
          .sort_by { |week_key, _| week_order[week_key] || 999 }  # Sort using our week mapping
          .to_h
          
        # Also ensure current season data is properly ordered, filtered and rounded
        @weekly_stats[:prices] = @weekly_stats[:prices]
          .reject { |week_key, _| week_in_excluded_range?(week_key) }
          .transform_values(&:round)
          .sort_by { |week_key, _| week_order[week_key] || 999 }
          .to_h
        @weekly_stats[:volumes] = @weekly_stats[:volumes]
          .reject { |week_key, _| week_in_excluded_range?(week_key) }
          .transform_values(&:round)
          .sort_by { |week_key, _| week_order[week_key] || 999 }
          .to_h

        # Calculate overall stats
        @stats = {
          total_markets: @segment.market_places.count,
          active_markets: @segment.market_places.with_recent_activity.count,
          total_channels: @segment.market_channels.count,
          active_channels: @segment.market_channels.with_recent_activity.count,
          total_volume: @current_season_records.sum(:quantities_presented_per_kg).round(0),
          avg_price: @current_season_records.average(:avg_price_per_kg).to_f.round(2),
          min_price: @current_season_records.minimum(:avg_price_per_kg).to_f.round(2),
          max_price: @current_season_records.maximum(:avg_price_per_kg).to_f.round(2)
        }
      end
    end

    def edit
    end

    def update
      if @segment.update(segment_params)
        redirect_to market_segments_path, notice: 'Market segment was successfully updated.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @segment.destroy
      redirect_to market_segments_path, notice: 'Market segment was successfully deleted.'
    end

    private

    def set_segment
      @segment = MarketSegment.find(params[:id])
    end

    def segment_params
      params.require(:market_segment).permit(:name, :description, :code)
    end
  end
end
