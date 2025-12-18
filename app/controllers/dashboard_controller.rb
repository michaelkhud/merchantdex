class DashboardController < ApplicationController
  def index
    @user = Current.session.user
    completed_trades = @user.trades.completed
    
    @total_profit = completed_trades.sum(&:profit)
    @total_trades = completed_trades.count
    @unique_clients = completed_trades.distinct.pluck(:counterparty).compact.count
    @platforms = @user.trades.distinct.pluck(:platform).compact
  end
end
