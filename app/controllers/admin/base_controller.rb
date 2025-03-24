# frozen_string_literal: true

module Admin
  # Controller for Base
  class BaseController < ApplicationController
    include AuthorizationConcern


    before_action :set_base, only: [:show, :edit, :update, :destroy]



    # GET /admin/base
    def index
      @base = policy_scope(Base).page(params[:page])
    end



    # GET /admin/base/1
    def show
      authorize @base
    end



    # GET /admin/base/new
    def new
      @base = Base.new

      authorize @base
    end



    # GET /admin/base/1/edit
    def edit
      authorize @base
    end



    # POST /admin/base
    def create
      @base = Base.new(base_params)

      authorize @base

      if @base.save
        redirect_to admin_base_path(@base), notice: 'Base was successfully created.'
      else
        render :new, status: :unprocessable_entity
      end
    end



    # PATCH/PUT /admin/base/1
    def update
      authorize @base
      
      if @base.update(base_params)
        redirect_to admin_base_path(@base), notice: 'Base was successfully updated.'
      else
        render :edit, status: :unprocessable_entity
      end
    end



    # DELETE /admin/base/1
    def destroy
      authorize @base
      @base.destroy

      redirect_to admin_base_path, notice: 'Base was successfully destroyed.'
    end


    private


    # Use callbacks to share common setup or constraints between actions.
    def set_base
      @base = Base.find(params[:id])
    end


    # Only allow a list of trusted parameters through.
    def base_params
      # Use Rails 8 params.expect method for more concise parameter sanitization
      params.expect(:base, fields: [:name, :description])
    end

  end
end
