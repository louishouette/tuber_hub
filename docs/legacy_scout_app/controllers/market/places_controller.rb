module Market
  class PlacesController < BaseController
    include WeekFormattable
    include Seasonable
    
    before_action :set_place, only: [:show, :edit, :update]

    def index
      @places = MarketPlace.all

      # Apply search filter
      if params[:search].present?
        search_term = "%#{params[:search].downcase}%"
        @places = @places.where(
          'LOWER(name) LIKE ? OR LOWER(description) LIKE ?',
          search_term, search_term
        )
      end

      # Apply country filter
      @places = @places.where(country: params[:country]) if params[:country].present?
      
      # Apply region filter
      @places = @places.where(region: params[:region]) if params[:region].present?

      # Apply segment filter
      @places = @places.where(market_segment_id: params[:segment]) if params[:segment].present?

      # Apply sorting
      @places = case params[:sort]
        when 'activity_asc'
          @places.left_joins(:market_price_records)
                .group('market_places.id')
                .order('MAX(market_price_records.published_at) ASC NULLS LAST')
        when 'activity_desc'
          @places.left_joins(:market_price_records)
                .group('market_places.id')
                .order('MAX(market_price_records.published_at) DESC NULLS LAST')
        else
          @places.order(:name)
        end

      # Load segments for filter
      @segments = MarketSegment.order(:name)
    end

    def show
      # Get records for the current season
      @current_season_records = @place.market_price_records.in_current_season
      
      # Check if we have any data for the current season
      @has_current_season_data = @current_season_records.exists?
      
      if @has_current_season_data
        # Group by week and calculate average prices and total volumes
        weekly_data = @current_season_records
                        .select(
                          "DATE_TRUNC('week', published_at) as week,
                           SUM(quantities_presented_per_kg) as total_volume,
                           AVG(avg_price_per_kg) as avg_price"
                        )
                        .group("DATE_TRUNC('week', published_at)")
                        .order("week DESC")

        volumes_by_week = {}
        prices_by_week = {}

        weekly_data.each do |data|
          week = format_week(data.week.to_date)
          volumes_by_week[week] = data.total_volume if data.total_volume.present? && data.total_volume > 0
          prices_by_week[week] = data.avg_price.round(2) if data.avg_price.present?
        end

        # Get the records for display, ordered by published_at
        @current_season_records = @current_season_records.order(published_at: :desc)

        @weekly_stats = {
          volumes: volumes_by_week,
          prices: prices_by_week
        }
      end

      # Calculate historical season stats for the last 3 completed seasons
      @season_stats = {}
      
      current_year = Time.current.year
      current_month = Time.current.month
      
      # If we're past the season end month, the current season is current_year
      # If we're before or in the season end month, the current season started in previous year
      current_season_year = current_month > MarketPriceRecord::SEASON_END_MONTH ? current_year : current_year - 1
      
      # Get the last 3 completed seasons
      3.times do |i|
        year = current_season_year - (i + 1)
        season_records = @place.market_price_records.in_season(year)
        next unless season_records.exists?
        
        prices = season_records.pluck(:avg_price_per_kg).compact
        next if prices.empty?
        
        sorted_prices = prices.sort
        median_index = sorted_prices.length / 2
        median_price = sorted_prices.length.odd? ? sorted_prices[median_index] : (sorted_prices[median_index - 1] + sorted_prices[median_index]) / 2.0
        
        @season_stats["#{year}-#{year + 1}"] = {
          avg_price: prices.sum / prices.length,
          median_price: median_price,
          total_volume: season_records.sum(:quantities_presented_per_kg),
          market_count: season_records.count,
          year: year
        }
      end
      
      # Sort by year descending
      @season_stats = @season_stats.sort_by { |_, stats| -stats[:year] }.to_h
    end

    def new
      @place = MarketPlace.new
      load_form_options
    end

    def edit
      load_form_options
    end

    def create
      @place = MarketPlace.new(place_params)

      if @place.save
        redirect_to market_place_path(@place), notice: 'Market place was successfully created.'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @place.update(place_params)
        redirect_to market_place_path(@place), notice: 'Market place was successfully updated.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @place.destroy
      redirect_to market_places_path, notice: 'Market place was successfully deleted.'
    end

    private

    def set_place
      @place = MarketPlace.includes(market_price_records: [:market_place]).find(params[:id])
    end

    def load_form_options
      @existing_countries = MarketPlace.distinct.pluck(:country).compact
      @existing_regions = MarketPlace.distinct.pluck(:region).compact
    end

    def place_params
      params.require(:market_place).permit(:name, :description, :market_segment_id, :region, :country)
    end
  end
end
