class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  before_action :redirect_if_authenticated
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to signup_path, alert: "Too many attempts. Please try again later." }
  layout "authentication"

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      code = @user.generate_verification_code!
      EmailVerificationMailer.verify(@user, code).deliver_now
      redirect_to new_email_verification_path(email: @user.email_address), notice: "We've sent a 6-digit code to your email."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end

  def redirect_if_authenticated
    redirect_to dashboard_path if authenticated?
  end
end


