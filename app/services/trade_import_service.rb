class TradeImportService
  def initialize(user, uploaded_file)
    @user = user
    @uploaded_file = uploaded_file
  end

  def call
    filename = @uploaded_file.original_filename

    if PlatformDetector.excel_file?(filename)
      import_excel_file
    else
      import_csv_file
    end
  rescue => e
    {
      success: false,
      error: "Import failed: #{e.message}"
    }
  end

  private

  def import_excel_file
    # Save uploaded file temporarily for roo to read
    # Important: extension must be preserved for roo to detect file type
    extension = File.extname(@uploaded_file.original_filename)
    temp_file = Tempfile.new(["trade_import", extension])
    temp_file.binmode
    temp_file.write(@uploaded_file.read)
    temp_file.close  # Close to flush content

    Rails.logger.info "TradeImportService: Temp file path: #{temp_file.path}"
    Rails.logger.info "TradeImportService: File exists: #{File.exist?(temp_file.path)}"
    Rails.logger.info "TradeImportService: File size: #{File.size(temp_file.path)}"

    begin
      platform = PlatformDetector.detect_from_excel(temp_file.path)
      Rails.logger.info "TradeImportService: Detected platform: #{platform.inspect}"
    rescue => e
      Rails.logger.error "TradeImportService: Detection error: #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
      temp_file.unlink
      return {
        success: false,
        error: "Detection error: #{e.message}"
      }
    end

    if platform.nil?
      temp_file.unlink
      return {
        success: false,
        error: "Unable to detect platform from Excel file. Supported platforms: Bybit P2P"
      }
    end

    unless PlatformDetector.supported?(platform)
      temp_file.unlink
      return {
        success: false,
        error: "Platform '#{platform}' is not supported"
      }
    end

    importer = case platform
    when "bybit"
      BybitImporter.new(@user, temp_file.path)
    else
      temp_file.unlink
      return { success: false, error: "Unknown platform for Excel file" }
    end

    result = importer.import

    temp_file.unlink

    {
      success: true,
      platform: platform,
      imported: result[:imported],
      skipped: result[:skipped],
      errors: result[:errors]
    }
  end

  def import_csv_file
    csv_content = @uploaded_file.read
    @uploaded_file.rewind

    platform = PlatformDetector.detect_from_csv(csv_content)

    if platform.nil?
      return {
        success: false,
        error: "Unable to detect platform from CSV. Supported platforms: LocalCoinSwap, Binance P2P, KuCoin, OKX"
      }
    end

    unless PlatformDetector.supported?(platform)
      return {
        success: false,
        error: "Platform '#{platform}' is not supported"
      }
    end

    importer = case platform
    when "localcoinswap"
      LocalCoinSwapImporter.new(@user, csv_content)
    when "binance"
      BinanceImporter.new(@user, csv_content)
    when "kucoin"
      KucoinImporter.new(@user, csv_content)
    when "okx"
      OkxImporter.new(@user, csv_content)
    else
      return { success: false, error: "Unknown platform" }
    end

    result = importer.import

    {
      success: true,
      platform: platform,
      imported: result[:imported],
      skipped: result[:skipped],
      errors: result[:errors]
    }
  end
end
