class CsvPlatformDetector
  SUPPORTED_PLATFORMS = %w[localcoinswap binance].freeze

  def self.detect(csv_content)
    return nil if csv_content.blank?

    # Get first line and normalize
    first_line = csv_content.lines.first&.strip&.downcase
    return nil if first_line.blank?

    # Check for LocalCoinSwap (has UUID, Buyer, Seller columns)
    if first_line.include?("uuid") && first_line.include?("buyer") && first_line.include?("seller")
      return "localcoinswap"
    end

    # Check for Binance P2P (has Order Number, Order Type columns)
    if first_line.include?("order number") && first_line.include?("order type") && first_line.include?("asset type")
      return "binance"
    end

    nil
  end

  def self.supported?(platform)
    SUPPORTED_PLATFORMS.include?(platform)
  end
end

