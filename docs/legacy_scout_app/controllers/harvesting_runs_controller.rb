class HarvestingRunsController < ApplicationController
  before_action :set_harvesting_run, only: %i[ show edit update stop ]
  before_action :load_harvesting_sectors, only: %i[ new edit create update index ]
  before_action :load_users, only: %i[ new edit create update index ]
  before_action :load_dogs, only: %i[ new edit create update index ]
  before_action :load_parcels, only: %i[ new edit create update index ]
  before_action :load_available_weeks, only: %i[ index ]

  # GET /harvesting_runs or /harvesting_runs.json
  def index
    @active_runs = HarvestingRun.active.order(started_at: :desc)
    @completed_runs = HarvestingRun.completed.order(stopped_at: :desc)
    
    @search_results = if search_params_present?
      Rails.logger.debug "Search params: #{params.inspect}"
      scope = HarvestingRun.active_and_completed.includes(:dog, :harvester, :harvesting_sector)
      scope = scope.where(harvester_id: params[:harvester_id]) if params[:harvester_id].present?
      scope = scope.where(dog_id: params[:dog_id]) if params[:dog_id].present?
      scope = scope.where(harvesting_sector_id: params[:harvesting_sector_id]) if params[:harvesting_sector_id].present?

      if params[:date].present?
        date = Date.parse(params[:date])
        scope = scope.where(started_at: date.beginning_of_day..date.end_of_day)
      end

      if params[:week].present?
        week_str = params[:week]
        Rails.logger.debug "Week string: #{week_str}"
        
        if week_match = week_str.match(/W(\d{2})-?(\d{2})/)
          week, year = week_match.captures.map(&:to_i)
          year = 2000 + year
          Rails.logger.debug "Parsed week: #{week}, year: #{year}"
          
          start_date = Date.commercial(year, week, 1)
          end_date = Date.commercial(year, week, 7)
          Rails.logger.debug "Date range: #{start_date} to #{end_date}"
          
          scope = scope.where(started_at: start_date.beginning_of_day..end_date.end_of_day)
          Rails.logger.debug "SQL: #{scope.to_sql}"
          Rails.logger.debug "Found #{scope.count} runs"
        else
          Rails.logger.error "Failed to parse week format: #{week_str}"
        end
      end

      if params[:parcel_id].present?
        Rails.logger.debug "Finding runs for parcel_id: #{params[:parcel_id]}"
        Rails.logger.debug "Before parcel filter: #{scope.count} runs"
        
        scope = scope.joins(:harvesting_sector)
                     .where(harvesting_sectors: { parcel_id: params[:parcel_id] })
        
        Rails.logger.debug "After parcel filter: #{scope.count} runs"
        Rails.logger.debug "SQL: #{scope.to_sql}"
      end

      if params[:has_comment].present?
        scope = if params[:has_comment] == "true"
          scope.where.not(comment: [nil, ""])
        else
          scope.where(comment: [nil, ""])
        end
      end

      scope = case params[:sort_by]
      when "date"
        scope.order(started_at: params[:direction] || :desc)
      when "duration"
        scope.order(Arel.sql("EXTRACT(EPOCH FROM (stopped_at - started_at)) #{params[:direction] || 'DESC'}"))
      when "run_raw_weight"
        scope.order(run_raw_weight: params[:direction] || :desc)
      when "run_net_weight"
        scope.order(run_net_weight: params[:direction] || :desc)
      when "findings_count"
        scope.left_joins(:findings)
             .group(:id)
             .order(Arel.sql("COUNT(findings.id) #{params[:direction] || 'DESC'}"))
      else
        scope.order(started_at: :desc)
      end

      scope
    else
      HarvestingRun.none
    end
  end

  # GET /harvesting_runs/1 or /harvesting_runs/1.json
  def show
    @findings = @harvesting_run.findings.order(created_at: :desc)
  end

  # GET /harvesting_runs/new
  def new
    @harvesting_run = HarvestingRun.new(
      surveyor: Current.user,
      started_at: Time.zone.now
    )
  end

  # GET /harvesting_runs/1/edit
  def edit
  end

  # POST /harvesting_runs or /harvesting_runs.json
  def create
    @harvesting_run = HarvestingRun.new(harvesting_run_params)
    @harvesting_run.surveyor = Current.user

    if @harvesting_run.save
      redirect_to @harvesting_run, notice: "Harvesting run started successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /harvesting_runs/1 or /harvesting_runs/1.json
  def update
    if @harvesting_run.update(harvesting_run_params)
      redirect_to @harvesting_run, notice: "Harvesting run was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def stop
    if @harvesting_run.update(stopped_at: Time.zone.now)
      redirect_to @harvesting_run, notice: 'Harvesting run stopped successfully.'
    else
      redirect_to @harvesting_run, alert: 'Failed to stop harvesting run.'
    end
  end

  private

    def load_parcels
      @parcels = Parcel.joins(:harvesting_sectors)
                       .joins('INNER JOIN harvesting_runs ON harvesting_runs.harvesting_sector_id = harvesting_sectors.id')
                       .distinct
                       .order(:name)
    end
    # Use callbacks to share common setup or constraints between actions.
    def set_harvesting_run
      @harvesting_run = HarvestingRun.find(params[:id])
    end

    def load_harvesting_sectors
      @harvesting_sectors = HarvestingSector.includes(parcel: { orchard: :farm })
                                          .order('farms.name, orchards.name, parcels.name, harvesting_sectors.name')
    end

    def load_users
      @harvesters = User.active.can_harvest.order(:first_name, :last_name)
      @non_harvesters = User.active.where(can_harvest: false).order(:first_name, :last_name)
    end

    def load_dogs
      @dogs = Dog.with_findings_count.order(:name)
    end

    def load_available_weeks
      @available_weeks = HarvestingRun.select("DISTINCT date_trunc('week', started_at) as week_start")
                                     .order("week_start DESC")
                                     .map { |run| 
                                       date = run.week_start.to_date
                                       # Use %G to get the ISO 8601 year number and %V for the week number
                                       # %G gives us the year that the week belongs to (important for weeks spanning years)
                                       year = date.strftime('%G').last(2)
                                       week_number = date.strftime('%V')
                                       ["W#{week_number}-#{year}", "W#{week_number}-#{year}"]
                                     }
    end

    # Only allow a list of trusted parameters through.
    def harvesting_run_params
      params.require(:harvesting_run).permit( :dog_id, :harvester_id, :surveyor_id, :started_at, :stopped_at, :harvesting_sector_id, :comment, :run_raw_weight, :run_net_weight )
    end

    def search_params_present?
      params[:harvester_id].present? || 
      params[:dog_id].present? || 
      params[:harvesting_sector_id].present? || 
      params[:date].present? || 
      params[:week].present? || 
      params[:has_comment].present? ||
      params[:parcel_id].present?
    end
end
