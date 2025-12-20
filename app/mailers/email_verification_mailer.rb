class EmailVerificationMailer < ApplicationMailer
  def verify(user, code)
    @user = user
    @code = code
    mail subject: "Your verification code: #{code}", to: user.email_address
  end
end
