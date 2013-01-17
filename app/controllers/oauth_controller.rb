# -*- encoding : utf-8 -*-
class OauthController < ApplicationController

  def oauth_config
    @config ||= YAML.load_file('config/oauth_auth.yml').symbolize_keys # rescue jen aby sel ten gist bez config soubru
  end

  def oauth_doorman
    OauthDoorman::Api.new(
      client_id: oauth_config[:client_id], 
      client_secret: oauth_config[:client_secret], 
      state: "CopyCopter",
      scopes: scopes,
      redirect_uri: @redirect_url || oauth_callback_url, 
    )
  end

  def redirect_url= url
    @redirect_url = url
  end

  def scopes
    ["https://www.googleapis.com/auth/userinfo.email","https://www.googleapis.com/auth/userinfo.profile"]
  end

  def oauth_login
    oauth_doorman.compose_authentification_request_url(false)
  end

  def sign_out
    sign_out_user
    flash.now[:failure] = "You were signed out."
    render :template => "oauth/invalid", :status => :unauthorized
  end

  def flash_failure_after_create
    flash.now[:failure] = translate(:invalid_email,
      :default => %{Invalid login email. Must be @ataxo.com}.html_safe)
  end

  def oauth_callback
    door = oauth_doorman
    begin 
      door.init_connection_by_code(request.params[:code])
      puts door.refresh_token
    rescue OauthError => e
      flash.now[:failure] = e.message
      render :template => "oauth/invalid", :status => :unauthorized
    end
    user_email = door.get_user_email
    if user_email !~ /@ataxo.com$/
      flash_failure_after_create
      render :template => "oauth/invalid", :status => :unauthorized
    else
      groups_api = oauth_doorman
      groups_api.init_connection_by_refresh_token(oauth_config[:provisioning_refresh_token])
      groups = groups_api.get_user_groups("ataxo.com", user_email)
      if groups.include?("vyvoj@ataxo.com")
        sign_in user_email
        redirect_to root_url
      else
        flash.now[:failure] = "You have valid email but you don't have permissions to view this site."
        render :template => "oauth/invalid", :status => :unauthorized
      end
    end
  end

end