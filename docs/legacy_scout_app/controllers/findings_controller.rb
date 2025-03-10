class FindingsController < ApplicationController
  before_action :set_finding, only: %i[ show edit update destroy ]
  before_action :set_harvesting_run, only: %i[ new create ], if: -> { params[:harvesting_run_id] }

  # GET /findings or /findings.json
  def index
    @findings = Finding.includes(:dog, :harvester, :location)
                    .where(harvesting_run_id: nil)
                    .where("finding_raw_weight IS NULL OR finding_raw_weight = 0 OR finding_net_weight IS NULL OR finding_net_weight = 0")
                    .order(created_at: :desc)
  end

  # GET /findings/1 or /findings/1.json
  def show
  end

  # GET /findings/new
  def new
    @finding = if @harvesting_run
      @finding = @harvesting_run.findings.build(
        surveyor: Current.user,
        harvester: @harvesting_run.harvester,
        dog: @harvesting_run.dog,
        depth: :intermediate,
        created_at: default_created_at_for_run(@harvesting_run)
      )
    else
      Finding.new(
        surveyor: Current.user,
        harvester: Current.user,
        dog: Current.user.default_dog ? Dog.find(Current.user.default_dog) : nil,
        depth: :intermediate,
        created_at: Time.zone.now
      )
    end
  end

  # GET /findings/1/edit
  def edit
  end

  # POST /findings or /findings.json
  def create
    @finding = if @harvesting_run
      finding = @harvesting_run.findings.build(finding_params_nested)
      finding.dog = @harvesting_run.dog
      finding.harvester = @harvesting_run.harvester
      finding
    else
      Finding.new(finding_params_standalone)
    end

    @finding.surveyor = Current.user

    if @finding.save
      if @harvesting_run
        redirect_to harvesting_run_url(@harvesting_run), notice: "Finding was successfully created."
      else
        redirect_to finding_url(@finding), notice: "Finding was successfully created."
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /findings/1 or /findings/1.json
  def update
    if @finding.update(finding_params_for_update)
      if @finding.harvesting_run
        redirect_to harvesting_run_url(@finding.harvesting_run), notice: "Finding was successfully updated."
      else
        redirect_to finding_url(@finding), notice: "Finding was successfully updated."
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    harvesting_run = @finding.harvesting_run
    @finding.destroy
    
    if harvesting_run
      redirect_to harvesting_run_url(harvesting_run), notice: "Finding was successfully deleted."
    else
      redirect_to findings_url, notice: "Finding was successfully deleted."
    end
  end

  private

  def default_created_at_for_run(run)
    # If we're within 3 hours of start and run is not stopped, use current time
    time_difference = ((Time.zone.now - run.started_at) / 1.hour).abs
    return Time.zone.now if time_difference <= 3 && !run.stopped_at

    # Otherwise use earliest finding time if there are findings, or run's start time
    run.findings.minimum(:created_at) || run.started_at
  end

  def set_finding
    @finding = Finding.find(params.require(:id))
  end

  def set_harvesting_run
    @harvesting_run = HarvestingRun.find(params[:harvesting_run_id])
  end

  # For findings nested in a harvesting run, we only allow:
  # - location (where the truffle was found)
  # - depth
  # - observation
  def finding_params_nested
    params.require(:finding).permit(:location_id, :depth, :observation, :created_at)
  end

  # For standalone findings, we allow all fields:
  # - dog
  # - harvester
  # - location
  # - depth
  # - observation
  # - weights
  def finding_params_standalone
    params.require(:finding).permit(
      :dog_id,
      :harvester_id,
      :location_id,
      :depth,
      :observation,
      :finding_raw_weight,
      :finding_net_weight,
      :created_at
    )
  end

  # Use the appropriate params based on whether the finding is part of a run
  def finding_params_for_update
    if @finding.harvesting_run
      finding_params_nested
    else
      finding_params_standalone
    end
  end
end
