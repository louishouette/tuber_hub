module Market
  class PricesController < BaseController
    before_action :set_price, only: [:show, :edit, :update, :destroy]
    before_action :set_channels, only: [:index, :new, :edit, :create, :update]
    before_action :set_markets, only: [:index]

    def index
      @prices = Price.includes(:channel)

      # Apply filters
      if params[:channel_id].present?
        @prices = @prices.where(channel_id: params[:channel_id])
      end

      if params[:market_id].present?
        market = MarketPlace.find(params[:market_id])
        @prices = @prices.joins(channel: :market_places).where(channels: { market_places: { id: market.id } })
      end

      case params[:date_range]
      when '7_days'
        @prices = @prices.where('applicable_at >= ?', 7.days.ago)
      when '30_days'
        @prices = @prices.where('applicable_at >= ?', 30.days.ago)
      when '90_days'
        @prices = @prices.where('applicable_at >= ?', 90.days.ago)
      end

      @prices = @prices.order(applicable_at: :desc)

      # Get latest prices by channel for the chart
      @latest_prices = Price.latest_by_channel.includes(:channel)
    end

    def show
      # Load historical prices for the timeline
      @historical_prices = @price.channel.prices.order(applicable_at: :asc)

      # Load related market price records if there are any market places
      if @price.channel.market_places.any?
        @market_price_records = MarketPriceRecord.joins(:market_place)
                                                .where(market_places: { id: @price.channel.market_places.pluck(:id) })
                                                .order(published_at: :desc)
                                                .limit(10)
      else
        @market_price_records = []
      end
    end

    def new
      @price = Price.new
      @price.applicable_at = Time.current
    end

    def edit
    end

    def create
      @price = Price.new(price_params)

      if @price.save
        redirect_to market_price_path(@price), notice: 'Price was successfully created.'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @price.update(price_params)
        redirect_to market_price_path(@price), notice: 'Price was successfully updated.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @price.destroy
      redirect_to market_prices_path, notice: 'Price was successfully deleted.'
    end

    private

    def set_price
      @price = Price.find(params[:id])
    end

    def set_channels
      @channels = MarketChannel.all.order(:name)
    end

    def set_markets
      @markets = MarketPlace.all.order(:name)
    end

    def price_params
      params.require(:price).permit(
        :applicable_at, :channel_id,
        :extra_price_per_kg, :c1_price_per_kg, :c2_price_per_kg, :c3_price_per_kg
      )
    end
  end
end
