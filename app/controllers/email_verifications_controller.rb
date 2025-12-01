class EmailVerificationsController < ApplicationController
  allow_unauthenticated_access
  layout "authentication"

  # GET /email_verification/new - show "check your email" page
  def new
    @email = params[:email]
  end

  # GET /email_verification/:token
  def show
    @user = User.find_by_token_for(:email_verification, params[:token])
    
    if @user.nil?
      redirect_to new_session_path, alert: "Verification link is invalid or has expired."
    elsif @user.email_verified?
      redirect_to new_session_path, notice: "Email is already verified. Please sign in."
    else
      @user.verify_email!
      redirect_to new_session_path, notice: "Email verified successfully! Please sign in."
    end
  end

  # POST /email_verification - resend verification email
  def create
    if user = User.find_by(email_address: params[:email_address])
      if user.email_verified?
        redirect_to new_session_path, notice: "Email is already verified. Please sign in."
      else
        EmailVerificationMailer.verify(user).deliver_later
        redirect_to new_email_verification_path(email: user.email_address), notice: "Verification email sent!"
      end
    else
      redirect_to new_session_path, notice: "If an account exists with that email, you will receive verification instructions."
    end
  end
end

