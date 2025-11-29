class DashboardController < ApplicationController
  def index
    @user = Current.session.user
  end
end



