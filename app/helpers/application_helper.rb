module ApplicationHelper

  def current_user
    if session["user_email"].nil? || session["user_email"] =~ /@ataxo.com$/
      session["user_email"]
    else
      nil
    end
  end

  def sign_in
    oc = OauthController.new
    oc.redirect_url = oauth_callback_url
    oc.oauth_login
  end
end
