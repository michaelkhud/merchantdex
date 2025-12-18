class PlatformDetector
  SUPPORTED_PLATFORMS = %w[localcoinswap binance bybit kucoin okx].freeze

  EXCEL_EXTENSIONS = %w[.xls .xlsx].freeze
  CSV_EXTENSIONS = %w[.csv].freeze

  def self.excel_file?(filename)
    ext = File.extname(filename.to_s).downcase
    EXCEL_EXTENSIONS.include?(ext)
  end

  def self.csv_file?(filename)
    ext = File.extname(filename.to_s).downcase
    CSV_EXTENSIONS.include?(ext)
  end

  # Detect platform from CSV content (string)
  def self.detect_from_csv(csv_content)
    return nil if csv_content.blank?

    first_line = csv_content.lines.first&.strip&.downcase
    return nil if first_line.blank?

    # LocalCoinSwap: has UUID, Buyer, Seller columns
    if first_line.include?("uuid") && first_line.include?("buyer") && first_line.include?("seller")
      return "localcoinswap"
    end

    # Binance P2P: has Order Number, Order Type, Asset Type columns
    if first_line.include?("order number") && first_line.include?("order type") && first_line.include?("asset type")
      return "binance"
    end

    # KuCoin P2P: has TIME, SIDE, STATUS, LEGAL/CURRENCY, ORDER_ID columns
    if first_line.include?("time") && first_line.include?("side") && first_line.include?("legal/currency") && first_line.include?("order_id")
      return "kucoin"
    end

    # OKX P2P: has Order No, Order type, Crypto, Currency, Volume, Amount columns
    if first_line.include?("order no") && first_line.include?("order type") && first_line.include?("crypto") && first_line.include?("volume")
      return "okx"
    end

    nil
  end

  # Detect platform from Excel file (using roo)
  def self.detect_from_excel(file_path)
    spreadsheet = Roo::Spreadsheet.open(file_path)
    headers = spreadsheet.row(1).map { |h| h&.to_s&.strip&.downcase }

    return nil if headers.blank?

    # Bybit P2P: has "Order No.", "Type" (BUY/SELL), "Fiat Amount", "Coin Amount"
    # Note: Bybit splits headers - "p2p-convert" and "Type" are separate columns
    if headers.include?("order no.") && headers.include?("type") && headers.include?("fiat amount") && headers.include?("coin amount")
      return "bybit"
    end

    # Could also have Binance in Excel format
    if headers.include?("order number") && headers.include?("order type") && headers.include?("asset type")
      return "binance"
    end

    nil
  rescue => e
    Rails.logger.error "PlatformDetector Excel error: #{e.message}"
    nil
  end

  def self.supported?(platform)
    SUPPORTED_PLATFORMS.include?(platform)
  end
end

