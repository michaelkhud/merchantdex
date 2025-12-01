class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  layout "authentication"

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)
    
    if @user.save
      EmailVerificationMailer.verify(@user).deliver_later
      redirect_to new_email_verification_path(email: @user.email_address), notice: "Verification email sent! Please check your inbox."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def registration_params
      params.require(:user).permit(:email_address, :password, :password_confirmation)
    end
end

