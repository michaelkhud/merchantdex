class KucoinImporter
  def initialize(user, csv_content)
    @user = user
    @csv_content = csv_content
    @imported_count = 0
    @skipped_count = 0
    @errors = []
  end

  def import
    rows = CSV.parse(@csv_content, headers: true)

    rows.each do |row|
      begin
        # Skip empty rows
        next if row["ORDER_ID"].blank?

        trade = build_trade_from_row(row)

        if trade.save
          @imported_count += 1
        else
          @skipped_count += 1
          @errors << "Row #{row['ORDER_ID']}: #{trade.errors.full_messages.join(', ')}"
        end
      rescue ActiveRecord::RecordNotSaved => e
        @skipped_count += 1
      rescue => e
        @skipped_count += 1
        @errors << "Row #{row['ORDER_ID']}: #{e.message}"
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
    order_id = row["ORDER_ID"]&.strip

    if @user.trades.exists?(platform: "kucoin", uuid: order_id)
      raise ActiveRecord::RecordNotSaved.new("Trade already exists")
    end

    # Parse trade type (SIDE column: BUY/SELL)
    side = row["SIDE"]&.strip&.downcase
    trade_type = side == "sell" ? "sell" : "buy"

    # Parse status (DONE/CANCELED)
    status = normalize_status(row["STATUS"]&.strip)

    # Parse currency pair (LEGAL/CURRENCY column: "USD/USDT")
    currency_pair = row["LEGAL/CURRENCY"]&.strip || "USD/USDT"
    local_currency, cryptocurrency = parse_currency_pair(currency_pair)

    # Parse amounts
    local_currency_amount = parse_decimal(row["LEGAL_AMOUNT"])
    crypto_amount = parse_decimal(row["CURRENCY_AMOUNT"])

    # Market value = crypto amount (for stablecoins like USDT)
    market_value = crypto_amount

    # Parse time
    time_value = parse_date(row["TIME"])

    # KuCoin doesn't have explicit fees in this export, set to 0
    trading_fee = BigDecimal("0")

    Trade.new(
      user: @user,
      platform: "kucoin",
      uuid: order_id,
      trade_type: trade_type,
      counterparty: row["OP_TRADER_NAME"]&.strip,
      status: status,
      crypto_amount: crypto_amount,
      cryptocurrency: cryptocurrency,
      local_currency_amount: local_currency_amount,
      local_currency: local_currency,
      market_value: market_value,
      trading_fee: trading_fee,
      time_created: time_value,
      time_completed: time_value,
      offer_uuid: nil
    )
  end

  def parse_currency_pair(pair)
    parts = pair.split("/")
    if parts.length == 2
      [parts[0].strip, parts[1].strip]
    else
      ["USD", "USDT"]
    end
  end

  def normalize_status(status)
    case status&.upcase
    when "DONE"
      "COMPLETED"
    when "CANCELED", "CANCELLED"
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
    BigDecimal(value.to_s)
  rescue
    BigDecimal("0")
  end
end





