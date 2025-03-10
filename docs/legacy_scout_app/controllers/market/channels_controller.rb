module Market
  class ChannelsController < BaseController
    before_action :set_channel, only: [:show, :edit, :update, :destroy]
    before_action :set_market_segments, only: [:new, :edit, :create, :update]

    def index
      @channels = MarketChannel.includes(:market_segment).all

      # Apply activity filter
      @channels = @channels.with_recent_activity if params[:recent_activity] == 'true'

      # Apply sorting
      case params[:sort]
      when 'name_asc'
        @channels = @channels.order(name: :asc)
      when 'name_desc'
        @channels = @channels.order(name: :desc)
      when 'recent_activity'
        @channels = @channels.order(last_activity_at: :desc)
      else
        @channels = @channels.order(name: :asc)
      end
    end

    def show
      @market_segment = @channel.market_segment
    end

    def new
      @channel = MarketChannel.new
    end

    def edit
    end

    def create
      @channel = MarketChannel.new(channel_params.except(:market_place_ids))

      if @channel.save
        if channel_params[:market_place_ids].present?
          @channel.market_place_ids = channel_params[:market_place_ids]
        end
        @channel.update_metrics!
        redirect_to market_channel_path(@channel), notice: 'Channel was successfully created.'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @channel.update(channel_params.except(:market_place_ids))
        if channel_params[:market_place_ids].present?
          @channel.market_place_ids = channel_params[:market_place_ids]
        end
        @channel.update_metrics!
        redirect_to market_channel_path(@channel), notice: 'Channel was successfully updated.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @channel.destroy
      redirect_to market_channels_path, notice: 'Channel was successfully deleted.'
    end

    private

    def set_channel
      @channel = MarketChannel.includes(:market_segment).find(params[:id])
    end

    def set_market_segments
      @market_segments = MarketSegment.all.order(:name)
    end

    def channel_params
      params.require(:market_channel).permit(
        :name,
        :description,
        :market_segment_id
      )
    end
  end
end
