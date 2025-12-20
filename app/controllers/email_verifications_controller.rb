class EmailVerificationsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user, only: [:new, :verify, :resend]
  rate_limit to: 5, within: 1.minute, only: [:verify, :resend], with: -> { redirect_to new_email_verification_path(email: params[:email]), alert: "Too many attempts. Please wait a moment." }
  layout "authentication"

  # GET /email_verification/new - show code input form
  def new
    if @user.nil?
      redirect_to signup_path, alert: "Please sign up first."
    elsif @user.email_verified?
      redirect_to login_path, notice: "Email is already verified. Please sign in."
    end
  end

  # POST /email_verification/verify - verify the 6-digit code
  def verify
    if @user.nil?
      redirect_to signup_path, alert: "User not found. Please sign up."
      return
    end

    code = params[:code].to_s.gsub(/\s/, "")

    if @user.verification_code_valid?(code)
      @user.verify_email!
      start_new_session_for(@user)
      redirect_to dashboard_path, notice: "Email verified successfully! Welcome to MerchantDex."
    else
      redirect_to new_email_verification_path(email: @user.email_address), alert: "Invalid or expired code. Please try again."
    end
  end

  # POST /email_verification/resend - resend verification code
  def resend
    if @user.nil?
      redirect_to signup_path, alert: "User not found. Please sign up."
      return
    end

    if @user.email_verified?
      redirect_to login_path, notice: "Email is already verified. Please sign in."
      return
    end

    code = @user.generate_verification_code!
    EmailVerificationMailer.verify(@user, code).deliver_now
    redirect_to new_email_verification_path(email: @user.email_address), notice: "New verification code sent!"
  end

  private

  def set_user
    email = params[:email] || params[:email_address]
    @user = User.find_by(email_address: email) if email.present?
    @email = email
  end
end
