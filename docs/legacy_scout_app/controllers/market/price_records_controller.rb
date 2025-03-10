module Market
  class PriceRecordsController < BaseController
    before_action :set_market_place
    before_action :set_price_record, only: [:show, :edit, :update, :destroy]

    def index
      @price_records = @market_place.market_price_records.includes(:market_place)
                                   .order(published_at: :desc)

      if params[:season].present?
        @price_records = @price_records.in_season(params[:season].to_i)
      else
        @price_records = @price_records.in_current_season
      end

      @price_records = @price_records.order(published_at: :desc)

      respond_to do |format|
        format.html
        format.turbo_stream do
          Rails.logger.debug "Rendering turbo stream response with #{@price_records.count} records"
          render turbo_stream: turbo_stream.update(
            'price_records_table',
            partial: 'price_records_table',
            locals: { place: @market_place, price_records: @price_records }
          )
        end
      end
    end

    def show
      respond_to do |format|
        format.html
      end
    end

    def new
      @price_record = @market_place.market_price_records.build
      respond_to do |format|
        format.html
      end
    end

    def edit
      respond_to do |format|
        format.html
      end
    end

    def create
      @price_record = @market_place.market_price_records.build(price_record_params)

      if @price_record.save
        redirect_to market_place_price_record_path(@market_place, @price_record),
                    notice: 'Market price record was successfully created.'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @price_record.update(price_record_params)
        redirect_to market_place_price_record_path(@market_place, @price_record),
                    notice: 'Market price record was successfully updated.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @price_record.destroy
      redirect_to market_place_price_records_path(@market_place),
                  notice: 'Market price record was successfully deleted.'
    end

    private

    def set_market_place
      @market_place = MarketPlace.find(params[:place_id])
    end

    def set_price_record
      @price_record = @market_place.market_price_records.find(params[:id])
    end

    def price_record_params
      params.require(:market_price_record).permit(
        :published_at,
        :source,
        :min_price_per_kg,
        :avg_price_per_kg,
        :max_price_per_kg,
        :extra_price_per_kg,
        :c1_price_per_kg,
        :c2_price_per_kg,
        :c3_price_per_kg,
        :quantities_presented_per_kg,
        :quantities_sold_per_kg
      )
    end
  end
end
