class CreateTrades < ActiveRecord::Migration[8.1]
  def change
    create_table :trades do |t|
      t.references :user, null: false, foreign_key: true
      t.string :platform
      t.string :uuid
      t.string :trade_type
      t.string :counterparty
      t.string :status
      t.decimal :crypto_amount
      t.string :cryptocurrency
      t.decimal :local_currency_amount
      t.string :local_currency
      t.decimal :market_value
      t.decimal :trading_fee
      t.datetime :time_created
      t.datetime :time_completed
      t.string :offer_uuid

      t.timestamps
    end
  end
end
