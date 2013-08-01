class RpMailer < ActionMailer::Base
  # default from: "rpm@recipepower.com"
  add_template_helper(UsersHelper)
  
  def feedback(feedback)
    recipients  = 'recipepowerfeedback@gmail.com'
    subject     = "#{feedback.subject} ##{feedback.id}"

    @feedback = feedback
    mail :to => recipients, :subject => subject
  end
  
  def welcome_email(user)
    return unless @inviter = User.where(id: user.invited_by).first
    @user = user
    @profile_url = "http://www.recipepower.com/users/profile"
    @login_url  = "http://recipepower.com/login"
    mail :to => @user.email, :subject => "Welcome to RecipePower"
  end
    
  def invitation_accepted_email(invitee)
    return unless @user = User.where(id: invitee.invited_by).first
    @invitee = invitee
    @profile_url = "http://www.recipepower.com/users/profile"
    mail to: @user.email, :subject => "Your invitation was accepted"
  end
  
  # Notify the user via email of a recipe share
  def sharing_notice(notification, opts={})
    @notification = notification
    @recipe = Recipe.find(notification.info[:what])
    mail to: notification.target.email, 
      from: notification.source.polite_name+" on RecipePower <support@recipepower.com>",
      subject: notification.source.polite_name+" has something tasty for you"
  end
end
