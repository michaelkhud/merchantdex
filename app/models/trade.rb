class Trade < ApplicationRecord
  belongs_to :user

  validates :uuid, presence: true, uniqueness: { scope: [:user_id, :platform] }
  validates :platform, presence: true
  validates :trade_type, presence: true
  validates :status, presence: true
  validates :crypto_amount, presence: true, numericality: { greater_than: 0 }
  validates :cryptocurrency, presence: true
  validates :local_currency_amount, presence: true, numericality: { greater_than: 0 }
  validates :local_currency, presence: true
  validates :market_value, presence: true, numericality: { greater_than: 0 }
  validates :trading_fee, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :time_created, presence: true

  scope :completed, -> { where(status: "COMPLETED") }
  scope :cancelled, -> { where(status: "CANCELLED") }
  scope :buy, -> { where(trade_type: "buy") }
  scope :sell, -> { where(trade_type: "sell") }
  scope :for_platform, ->(platform) { where(platform: platform) }
  scope :recent, -> { order(time_completed: :desc) }

  def profit
    return 0 unless status == "COMPLETED"
    
    case trade_type
    when "buy"
      # Bought crypto below market value = profit
      market_value - local_currency_amount - trading_fee
    when "sell"
      # Sold crypto above market value = profit
      local_currency_amount - market_value - trading_fee
    else
      0
    end
  end
end

