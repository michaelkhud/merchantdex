class OkxImporter
  def initialize(user, csv_content)
    @user = user
    # Force UTF-8 encoding and remove BOM if present
    @csv_content = csv_content.dup.force_encoding("UTF-8")
    @csv_content = @csv_content.sub(/\A\xEF\xBB\xBF/, "")
    @imported_count = 0
    @skipped_count = 0
    @errors = []
  end

  def import
    rows = CSV.parse(@csv_content, headers: true)

    rows.each do |row|
      begin
        # Skip empty rows
        next if row["Order No"].blank?

        trade = build_trade_from_row(row)

        if trade.save
          @imported_count += 1
        else
          @skipped_count += 1
          @errors << "Row #{row['Order No']}: #{trade.errors.full_messages.join(', ')}"
        end
      rescue ActiveRecord::RecordNotSaved => e
        @skipped_count += 1
      rescue => e
        @skipped_count += 1
        @errors << "Row #{row['Order No']}: #{e.message}"
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
    order_no = row["Order No"]&.strip

    if @user.trades.exists?(platform: "okx", uuid: order_no)
      raise ActiveRecord::RecordNotSaved.new("Trade already exists")
    end

    # Parse trade type (Order type column: Buy/Sell)
    order_type = row["Order type"]&.strip&.downcase
    trade_type = order_type == "sell" ? "sell" : "buy"

    # Parse status (Fulfilled/Canceled)
    status = normalize_status(row["Status"]&.strip)

    # Parse amounts
    crypto_amount = parse_decimal(row["Volume"])
    local_currency_amount = parse_decimal(row["Amount"])

    # Get currencies
    cryptocurrency = row["Crypto"]&.strip&.upcase || "USDT"
    local_currency = row["Currency"]&.strip&.upcase || "USD"

    # Market value = crypto amount (for stablecoins like USDT)
    market_value = crypto_amount

    # Parse dates
    time_created = parse_date(row["Created date"])
    time_completed = parse_date(row["Updated date"]) || time_created

    # OKX doesn't have explicit fees in this export, set to 0
    trading_fee = BigDecimal("0")

    Trade.new(
      user: @user,
      platform: "okx",
      uuid: order_no,
      trade_type: trade_type,
      counterparty: row["Counterparty"]&.strip,
      status: status,
      crypto_amount: crypto_amount,
      cryptocurrency: cryptocurrency,
      local_currency_amount: local_currency_amount,
      local_currency: local_currency,
      market_value: market_value,
      trading_fee: trading_fee,
      time_created: time_created,
      time_completed: time_completed,
      offer_uuid: nil
    )
  end

  def normalize_status(status)
    case status&.downcase
    when "fulfilled"
      "COMPLETED"
    when "canceled", "cancelled"
      "CANCELLED"
    else
      "CANCELLED"
    end
  end

  def parse_date(date_string)
    return nil if date_string.blank?
    Time.zone.parse(date_string) rescue nil
  end

  def parse_decimal(value)
    return BigDecimal("0") if value.blank?
    BigDecimal(value.to_s.gsub(",", ""))
  rescue
    BigDecimal("0")
  end
end

