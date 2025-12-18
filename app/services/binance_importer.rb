class BinanceImporter
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
        trade = build_trade_from_row(row)

        if trade.save
          @imported_count += 1
        else
          @skipped_count += 1
          @errors << "Row #{row['Order Number']}: #{trade.errors.full_messages.join(', ')}"
        end
      rescue ActiveRecord::RecordNotSaved => e
        @skipped_count += 1
      rescue => e
        @skipped_count += 1
        @errors << "Row #{row['Order Number']}: #{e.message}"
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
    order_number = row["Order Number"]

    if @user.trades.exists?(platform: "binance", uuid: order_number)
      raise ActiveRecord::RecordNotSaved.new("Trade already exists")
    end

    order_type = row["Order Type"]&.downcase
    trade_type = order_type == "sell" ? "sell" : "buy"
    status = normalize_status(row["Status"])

    maker_fee = parse_decimal(row["Maker Fee"])
    taker_fee = parse_decimal(row["Taker Fee"])
    total_fee = (maker_fee || 0) + (taker_fee || 0)

    time_created = parse_date(row["Created Time"])
    quantity = parse_decimal(row["Quantity"])
    total_price = parse_decimal(row["Total Price"])

    # Market value = quantity (for stablecoins like USDT, 1 USDT = $1)
    market_value = quantity

    Trade.new(
      user: @user,
      platform: "binance",
      uuid: order_number,
      trade_type: trade_type,
      counterparty: row["Couterparty"],
      status: status,
      crypto_amount: quantity,
      cryptocurrency: row["Asset Type"],
      local_currency_amount: total_price,
      local_currency: row["Fiat Type"],
      market_value: market_value,
      trading_fee: total_fee,
      time_created: time_created,
      time_completed: time_created,
      offer_uuid: nil
    )
  end

  def normalize_status(status)
    case status&.downcase
    when "completed"
      "COMPLETED"
    when "cancelled", "canceled", "system cancelled"
      "CANCELLED"
    else
      "CANCELLED"
    end
  end

  def parse_date(date_string)
    return nil if date_string.blank?
    Time.zone.parse(date_string) || DateTime.parse(date_string)
  rescue
    nil
  end

  def parse_decimal(value)
    return BigDecimal("0") if value.blank?
    BigDecimal(value.to_s)
  rescue
    BigDecimal("0")
  end
end

