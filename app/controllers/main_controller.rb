
# Controller responsible for providing login and logout processes 
# as well as displaying main page
class MainController < ApplicationController
  
  include MainHelper
  # check for authorization 
  before_filter      :authorize_for_user,      :except => [:login, :logout]

  #########################################################################
  # Authentication
  
  # Handles login requests; usually redirected here when trying to access 
  # the website and has not logged in yet, or session has expired.  User 
  # is redirected to main page if session is still active and valid.

  def login
  
    # redirect to main page if user is already logged in.
    if logged_in? && !request.post?
      if @current_user.student?
        redirect_to :controller => 'assignments', :action => 'index'
      else
        redirect_to :action => 'index' 
        return
      end
    end
    
    return unless request.post?
    
    # check for blank username and password
    blank_login = params[:user_login].blank?
    blank_pwd = params[:user_password].blank?
    flash[:login_notice] = get_blank_message(blank_login, blank_pwd)
    redirect_to(:action => 'login') && return if blank_login || blank_pwd
    
    # authenticate user
    if User.authenticated?(params[:user_login], params[:user_password])
      # sets this user as logged in if login is a user in MarkUs
      found_user = User.authorize(params[:user_login]) # if not nil, user authorized to enter MarkUs
      if found_user.nil?
        flash[:login_notice] = "Username not found."
        return
      end
    else
      flash[:login_notice] = "Username/password contains illegal characters."
      return
    end
    
    # Has this student been hidden?
    if found_user.student? && found_user.hidden
      flash[:login_notice] = "This account has been disabled"
      redirect_to(:action => 'login') && return
    end
    
    self.current_user = found_user
    
    if logged_in?
      uri = session[:redirect_uri]
      session[:redirect_uri] = nil
      refresh_timeout
      # redirect to last visited page or to main page
      redirect_to(uri || { :action => 'index' })
    else
      flash[:login_notice] = "Username and password do not match."
    end
  end
  
  # Clear the sesssion for current user and redirect to login page
  def logout
    clear_session
    cookies.delete :auth_token
    reset_session
    redirect_to :action => 'login'
  end
  
  def index
    @user = current_user
    if @user.student? or  @user.ta?
      redirect_to :controller => 'assignments', :action => 'index'
      return
    end
  end
  
end
