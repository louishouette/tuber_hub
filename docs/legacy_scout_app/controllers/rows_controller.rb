class RowsController < ApplicationController
  before_action :set_row, only: [:show, :update, :destroy]
  before_action :set_parcel
  before_action :set_harvesting_sector

  def index
    @rows = @harvesting_sector.rows.all
  end

  def show
  end

  def create
    @row = @harvesting_sector.rows.build(row_params.merge(parcel: @parcel))

    if @row.save
      redirect_to [@parcel, @row], notice: 'Row was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @row.update(row_params)
      redirect_to [@parcel, @row], notice: 'Row was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @row.destroy
    redirect_to parcel_rows_path(@parcel), notice: 'Row was successfully deleted.'
  end

  private

  def set_row
    @row = Row.find(params[:id])
  end

  def set_parcel
    @parcel = Parcel.find(params[:parcel_id])
  end

  def set_harvesting_sector
    @harvesting_sector = HarvestingSector.find(params[:harvesting_sector_id])
  end

  def row_params
    params.expect(row: [:name])
  end
end
