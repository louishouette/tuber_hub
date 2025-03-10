class OrchardsController < ApplicationController
  before_action :set_orchard, only: [:show, :update, :destroy]
  before_action :set_farm

  def index
    @orchards = @farm.orchards.all
  end

  def show
  end

  def create
    @orchard = @farm.orchards.build(orchard_params)

    if @orchard.save
      redirect_to @orchard, notice: 'Orchard was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @orchard.update(orchard_params)
      redirect_to @orchard, notice: 'Orchard was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @orchard.destroy
    redirect_to farm_orchards_path(@farm), notice: 'Orchard was successfully deleted.'
  end

  private

  def set_orchard
    @orchard = Orchard.find(params[:id])
  end

  def set_farm
    @farm = Farm.find(params[:farm_id])
  end

  def orchard_params
    params.expect(orchard: [:name])
  end
end
