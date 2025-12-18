class TradesController < ApplicationController
  def index
    @trades = Current.session.user.trades.recent
    
    # Filters
    @trades = @trades.for_platform(params[:platform]) if params[:platform].present?
    @trades = @trades.send(params[:trade_type]) if params[:trade_type].in?(%w[buy sell])
    @trades = @trades.completed if params[:status] == "COMPLETED"
    @trades = @trades.cancelled if params[:status] == "CANCELLED"
    
    # Statistics
    completed_trades = Current.session.user.trades.completed
    @total_profit = completed_trades.sum(&:profit)
    @total_trades = completed_trades.count
    @unique_clients = completed_trades.distinct.pluck(:counterparty).compact.count
    @platforms = Current.session.user.trades.distinct.pluck(:platform).compact
  end

  def create
    uploaded_file = params[:trade_file] || params[:csv_file]
    
    unless uploaded_file.present?
      redirect_to dashboard_path, alert: "Please select a file to upload."
      return
    end

    result = TradeImportService.new(Current.session.user, uploaded_file).call

    if result[:success]
      message = "Successfully imported #{result[:imported]} trades from #{result[:platform].titleize}"
      message += ". #{result[:skipped]} trades were skipped." if result[:skipped] > 0
      redirect_to trades_path, notice: message
    else
      redirect_to dashboard_path, alert: result[:error]
    end
  end

  def destroy
    @trade = Current.session.user.trades.find(params[:id])
    @trade.destroy
    redirect_to trades_path, notice: "Trade deleted successfully."
  end
end

