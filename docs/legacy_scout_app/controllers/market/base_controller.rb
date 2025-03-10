module Market
  class BaseController < ApplicationController
    before_action :set_active_menu

    private

    def set_active_menu
      @active_menu = 'market'
    end
  end
end
