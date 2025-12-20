class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :trades, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true,
                            uniqueness: { case_sensitive: false },
                            format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }
  validates :password, length: { minimum: 8 }, if: -> { new_record? || password.present? }

  generates_token_for :password_reset, expires_in: 15.minutes do
    password_salt&.last(10)
  end

  # Email verification with 6-digit code
  def generate_verification_code!
    code = SecureRandom.random_number(1_000_000).to_s.rjust(6, "0")
    update!(
      email_verification_code: code,
      email_verification_sent_at: Time.current
    )
    code
  end

  def verification_code_valid?(code)
    return false if email_verification_code.blank?
    return false if email_verification_sent_at.blank?
    return false if email_verification_sent_at < 15.minutes.ago

    email_verification_code == code.to_s.strip
  end

  def email_verified?
    email_verified_at.present?
  end

  def verify_email!
    update!(
      email_verified_at: Time.current,
      email_verification_code: nil,
      email_verification_sent_at: nil
    )
  end
end
