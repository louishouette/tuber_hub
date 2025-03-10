class ParcelsController < ApplicationController
  before_action :set_parcel, only: [:show, :update, :destroy]
  before_action :set_orchard

  def index
    @parcels = @orchard.parcels.all
  end

  def show
  end

  def create
    @parcel = @orchard.parcels.build(parcel_params)

    if @parcel.save
      redirect_to [@orchard, @parcel], notice: 'Parcel was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @parcel.update(parcel_params)
      redirect_to [@orchard, @parcel], notice: 'Parcel was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @parcel.destroy
    redirect_to orchard_parcels_path(@orchard), notice: 'Parcel was successfully deleted.'
  end

  private

  def set_parcel
    @parcel = Parcel.find(params[:id])
  end

  def set_orchard
    @orchard = Orchard.find(params[:orchard_id])
  end

  def parcel_params
    params.expect(parcel: [:name])
  end
end
