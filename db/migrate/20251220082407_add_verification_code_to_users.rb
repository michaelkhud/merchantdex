class AddVerificationCodeToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :email_verification_code, :string
    add_column :users, :email_verification_sent_at, :datetime
  end
end
