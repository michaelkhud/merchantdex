require "csv"

class LocalCoinSwapImporter
  def initialize(user, csv_content)
    @user = user
    @csv_content = csv_content
    @imported_count = 0
    @skipped_count = 0
    @errors = []
  end

  def import
    rows = CSV.parse(@csv_content, headers: true)
    
    # Determine user's username by finding most frequent in Buyer/Seller columns
    username = determine_user_username(rows)
    
    if username.nil?
      raise "Unable to determine user's username from CSV. Make sure Buyer and Seller columns contain valid usernames."
    end
    
    rows.each do |row|
      begin
        trade = build_trade_from_row(row, username)
        
        if trade.save
          @imported_count += 1
        else
          @skipped_count += 1
          @errors << "Row #{row['UUID']}: #{trade.errors.full_messages.join(', ')}"
        end
      rescue ActiveRecord::RecordNotSaved => e
        # Trade already exists, skip silently
        @skipped_count += 1
      rescue => e
        @skipped_count += 1
        @errors << "Row #{row['UUID']}: #{e.message}"
      end
    end

    {
      imported: @imported_count,
      skipped: @skipped_count,
      errors: @errors
    }
  end

  private

  def determine_user_username(rows)
    buyer_seller_counts = Hash.new(0)
    
    rows.each do |row|
      buyer_seller_counts[row["Buyer"]] += 1 if row["Buyer"].present?
      buyer_seller_counts[row["Seller"]] += 1 if row["Seller"].present?
    end
    
    buyer_seller_counts.max_by { |_, count| count }&.first
  end

  def build_trade_from_row(row, username)
    uuid = row["UUID"]
    
    # Check if trade already exists (skip duplicates)
    if @user.trades.exists?(platform: "localcoinswap", uuid: uuid)
      raise ActiveRecord::RecordNotSaved.new("Trade already exists")
    end

    # Determine trade type and counterparty
    if row["Buyer"] == username
      trade_type = "buy"
      counterparty = row["Seller"]
    elsif row["Seller"] == username
      trade_type = "sell"
      counterparty = row["Buyer"]
    else
      raise "Username not found in Buyer or Seller columns"
    end

    # Parse dates
    time_created = parse_date(row["Time created"])
    time_completed = parse_date(row["Time completed"])

    Trade.new(
      user: @user,
      platform: "localcoinswap",
      uuid: uuid,
      trade_type: trade_type,
      counterparty: counterparty,
      status: row["Status"],
      crypto_amount: parse_decimal(row["Crypto Amount"]),
      cryptocurrency: row["Cryptocurrency"],
      local_currency_amount: parse_decimal(row["Local Currency Amount"]),
      local_currency: row["Local Currency"],
      market_value: parse_decimal(row["Market Value"]),
      trading_fee: parse_decimal(row["Trading Fee"]),
      time_created: time_created,
      time_completed: time_completed,
      offer_uuid: row["Offer UUID"]
    )
  end

  def parse_date(date_string)
    return nil if date_string.blank?
    
    # Parse format like "2025-12-12 14:10:27 PST-0800" or "2025-10-28 14:51:29 PDT-0700"
    # Try to parse with timezone
    begin
      # Remove timezone suffix and parse
      cleaned = date_string.strip
      Time.zone.parse(cleaned) || DateTime.parse(cleaned)
    rescue
      nil
    end
  end

  def parse_decimal(value)
    return nil if value.blank?
    BigDecimal(value.to_s)
  rescue
    nil
  end
end

