class TradesController < ApplicationController
  before_action :set_trade, only: [:edit, :update, :destroy, :inline_update]
  before_action :set_form_options, only: [:new, :edit, :index]

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
    @average_margin = @total_trades > 0 ? (completed_trades.sum(&:margin) / @total_trades).round(2) : 0
  end

  def new
    @trade = Current.session.user.trades.build(
      platform: "private",
      status: "COMPLETED",
      trade_type: "sell",
      time_created: Time.current,
      trading_fee: 0
    )
  end

  def edit
  end

  def create
    # Check if this is a file import or manual trade creation
    if params[:trade_file].present? || params[:csv_file].present?
      handle_file_import
    else
      handle_manual_create
    end
  end

  def update
    if @trade.update(trade_params)
      redirect_to trades_path, notice: "Trade updated successfully."
    else
      set_form_options
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @trade.destroy
    redirect_to trades_path, notice: "Trade deleted successfully."
  end

  def inline_update
    field = params[:field]
    value = params[:value]

    allowed_fields = %w[platform trade_type status counterparty cryptocurrency crypto_amount
                        local_currency local_currency_amount market_value trading_fee time_created]

    unless allowed_fields.include?(field)
      render json: { success: false, error: "Invalid field" }, status: :unprocessable_entity
      return
    end

    # Handle special formatting for certain fields
    if field == "time_created" && value.present?
      value = Time.zone.parse(value) rescue value
    end

    @trade.assign_attributes(field => value)
    if @trade.save(validate: false)
      # Recalculate time_completed if status changed to COMPLETED
      if field == "status" && value == "COMPLETED" && @trade.time_completed.nil?
        @trade.update(time_completed: @trade.time_created)
      end

      display_value = format_display_value(field, @trade.send(field))

      render json: {
        success: true,
        display_value: display_value,
        profit: @trade.profit,
        profit_display: format_currency(@trade.profit),
        margin: @trade.margin,
        margin_display: "#{@trade.margin >= 0 ? '+' : ''}#{@trade.margin}%"
      }
    else
      render json: { success: false, error: @trade.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  def counterparties
    counterparties = Current.session.user.trades
      .where.not(counterparty: [nil, ""])
      .distinct
      .pluck(:counterparty)
      .compact
      .sort

    render json: counterparties
  end

  def quick_create
    @trade = Current.session.user.trades.build(
      uuid: SecureRandom.uuid,
      platform: "private",
      trade_type: "sell",
      status: "COMPLETED",
      cryptocurrency: "USDT",
      crypto_amount: 0,
      local_currency: "USD",
      local_currency_amount: 0,
      market_value: 0,
      trading_fee: 0,
      time_created: Time.current,
      time_completed: Time.current
    )

    if @trade.save(validate: false)
      redirect_to trades_path, notice: "New trade row added. Click on cells to edit."
    else
      redirect_to trades_path, alert: "Failed to create trade row."
    end
  end

  private

  def format_display_value(field, value)
    case field
    when "platform"
      value.titleize
    when "trade_type"
      value.upcase
    when "status"
      value
    when "crypto_amount"
      "#{number_with_precision(value, precision: 2, delimiter: ',')} #{@trade.cryptocurrency}"
    when "local_currency_amount", "market_value"
      "$#{number_with_precision(value, precision: 2, delimiter: ',')}"
    when "time_created"
      value&.strftime("%b %d, %Y")
    else
      value.to_s
    end
  end

  def format_currency(amount)
    prefix = amount >= 0 ? "+$" : "-$"
    "#{prefix}#{number_with_precision(amount.abs, precision: 2, delimiter: ',')}"
  end

  def number_with_precision(number, options = {})
    ActionController::Base.helpers.number_with_precision(number, options)
  end

  def set_trade
    @trade = Current.session.user.trades.find(params[:id])
  end

  def set_form_options
    # Default platforms always available
    default_platforms = %w[private localcoinswap binance bybit kucoin okx]
    @available_platforms = default_platforms.sort_by { |p| p == "private" ? "zzz" : p }
  end

  def trade_params
    params.require(:trade).permit(
      :platform, :trade_type, :status, :cryptocurrency, :crypto_amount,
      :local_currency, :local_currency_amount, :market_value, :counterparty,
      :time_created, :time_completed, :trading_fee
    )
  end

  def handle_file_import
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

  def handle_manual_create
    @trade = Current.session.user.trades.build(trade_params)
    @trade.uuid = SecureRandom.uuid
    @trade.time_completed = @trade.time_created if @trade.status == "COMPLETED"

    if @trade.save
      redirect_to trades_path, notice: "Trade created successfully."
    else
      set_form_options
      render :new, status: :unprocessable_entity
    end
  end
end
