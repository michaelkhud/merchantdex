class BybitImporter
  def initialize(user, file_path)
    @user = user
    @file_path = file_path
    @imported_count = 0
    @skipped_count = 0
    @errors = []
  end

  def import
    spreadsheet = Roo::Spreadsheet.open(@file_path)
    headers = spreadsheet.row(1).map { |h| h&.to_s&.strip }

    (2..spreadsheet.last_row).each do |row_num|
      begin
        row_data = spreadsheet.row(row_num)
        row = Hash[headers.zip(row_data)]

        trade = build_trade_from_row(row)

        if trade.save
          @imported_count += 1
        else
          @skipped_count += 1
          @errors << "Row #{row_num}: #{trade.errors.full_messages.join(', ')}"
        end
      rescue ActiveRecord::RecordNotSaved => e
        @skipped_count += 1
      rescue => e
        @skipped_count += 1
        @errors << "Row #{row_num}: #{e.message}"
      end
    end

    {
      imported: @imported_count,
      skipped: @skipped_count,
      errors: @errors
    }
  end

  private

  def build_trade_from_row(row)
    order_number = row["Order No."]&.to_s

    if @user.trades.exists?(platform: "bybit", uuid: order_number)
      raise ActiveRecord::RecordNotSaved.new("Trade already exists")
    end

    # Bybit uses "BUY" / "SELL" in "Type" column (separate from "p2p-convert")
    order_type = row["Type"]&.to_s&.downcase
    trade_type = order_type == "sell" ? "sell" : "buy"

    status = normalize_status(row["Status"]&.to_s)

    # Parse amounts
    fiat_amount = parse_decimal(row["Fiat Amount"])
    crypto_amount = parse_decimal(row["Coin Amount"])
    trading_fee = parse_decimal(row["Transaction Fees"])  # Note: "Fees" not "Fee"

    # Get currencies - Currency appears twice, first is for fiat
    local_currency = row["Currency"]&.to_s&.strip || "USD"
    cryptocurrency = row["Cryptocurrency"]&.to_s&.strip || "USDT"

    # Market value = crypto amount (for stablecoins like USDT, 1 USDT = $1)
    market_value = crypto_amount

    # Parse time
    time_value = parse_date(row["Time"])

    Trade.new(
      user: @user,
      platform: "bybit",
      uuid: order_number,
      trade_type: trade_type,
      counterparty: row["Counterparty"]&.to_s&.strip,
      status: status,
      crypto_amount: crypto_amount,
      cryptocurrency: cryptocurrency,
      local_currency_amount: fiat_amount,
      local_currency: local_currency,
      market_value: market_value,
      trading_fee: trading_fee || 0,
      time_created: time_value,
      time_completed: time_value,
      offer_uuid: nil
    )
  end

  def normalize_status(status)
    case status&.downcase
    when "completed"
      "COMPLETED"
    when "cancelled", "canceled"
      "CANCELLED"
    else
      "CANCELLED"
    end
  end

  def parse_date(date_value)
    return nil if date_value.blank?

    if date_value.is_a?(DateTime) || date_value.is_a?(Time)
      date_value.to_time
    elsif date_value.is_a?(Date)
      date_value.to_time
    else
      Time.zone.parse(date_value.to_s) rescue nil
    end
  end

  def parse_decimal(value)
    return BigDecimal("0") if value.blank?

    if value.is_a?(Numeric)
      BigDecimal(value.to_s)
    else
      BigDecimal(value.to_s.gsub(/[^\d.-]/, ""))
    end
  rescue
    BigDecimal("0")
  end
end

