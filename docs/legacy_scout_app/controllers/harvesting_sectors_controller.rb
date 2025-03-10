class HarvestingSectorsController < ApplicationController
  before_action :set_harvesting_sector, only: [:show, :update, :destroy]
  before_action :set_parcel

  def index
    @harvesting_sectors = @parcel.harvesting_sectors.all
  end

  def show
  end

  def create
    @harvesting_sector = @parcel.harvesting_sectors.build(harvesting_sector_params)

    if @harvesting_sector.save
      redirect_to [@parcel, @harvesting_sector], notice: 'Harvesting sector was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @harvesting_sector.update(harvesting_sector_params)
      redirect_to [@parcel, @harvesting_sector], notice: 'Harvesting sector was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @harvesting_sector.destroy
    redirect_to parcel_harvesting_sectors_path(@parcel), notice: 'Harvesting sector was successfully deleted.'
  end

  private

  def set_harvesting_sector
    @harvesting_sector = HarvestingSector.find(params[:id])
  end

  def set_parcel
    @parcel = Parcel.find(params[:parcel_id])
  end

  def harvesting_sector_params
    params.expect(harvesting_sector: [:name])
  end
end
