class FarmsController < ApplicationController
  before_action :set_farm, only: [:show, :edit, :update, :destroy]

  def index
    @farms = Farm.all
  end

  def show
  end

  def new
    @farm = Farm.new
  end

  def edit
  end

  def create
    @farm = Farm.new(farm_params)

    if @farm.save
      redirect_to @farm, notice: 'Farm was successfully created.'
    else
      render :new
    end
  end

  def update
    if @farm.update(farm_params)
      redirect_to @farm, notice: 'Farm was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @farm.destroy
    redirect_to farms_url, notice: 'Farm was successfully destroyed.'
  end

  private

  def set_farm
    @farm = Farm.find(params[:id])
  end

  def farm_params
    params.expect(farm: [:name])
  end
end
