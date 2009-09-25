require 'xmlrpc/client'
require "base64"
class AccountController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem
  protect_from_forgery :except => [:login, :signup, :logout, :whoiam, :index, :check_login]
  # If you want "remember me" functionality, add this before_filter to Application Controller
  before_filter :login_from_cookie

  # say something nice, you goof!  something sweet.
  def index
    redirect_to(:action => 'signup') unless logged_in? || User.count > 0
  end

  def list
	if logged_in? and current_user.right != 'user'
		@users = User.find(:all)
	else
		render :text => 'ку'
	end
  end

  def whoiam
    return unless request.post?
    if logged_in?
      if current_user.right == 'admin' and params[:user_id]
        user = User.find(params[:user_id])
      else
        user = current_user
      end
      user.ftppass = Base64.encode64(user.ftppass)
      user.mysqlpass = Base64.encode64(user.mysqlpass)
      user.crypted_password = 'супер_секретный_пароль'
      user.remember_token = Base64.encode64('супер_секретный_пароль')
      user.remember_token_expires_at = Time.now.to_s
      user.salt = '11'
      render :text => user.to_xml
    else
      render :text => 'error'
    end
  end

  def login
    if request.post?
      self.current_user = User.authenticate(Base64.decode64(params[:ln]),Base64.decode64(params[:pd]))
      if logged_in?
        if params[:remember_me] == "true"
          self.current_user.remember_me
          cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
        end
        if(params[:format]!='xml')
          redirect_back_or_default(:controller => '/main', :action => 'index')
          flash[:notice] = "Вход выполнен"
        else
          current_user.ftppass = Base64.encode64(current_user.ftppass)
          current_user.mysqlpass = Base64.encode64(current_user.mysqlpass)
          current_user.crypted_password = 'супер_секретный_пароль'
          current_user.remember_token = Base64.encode64('супер_секретный_пароль')
          current_user.remember_token_expires_at = Time.now.to_s
          current_user.salt = '11'
          render :text => current_user.to_xml
        end
      else
        render :text => 'error' if params[:format]=='xml'
      end
    else
      #render(:layout => 'mainlayer') if request.xhr?
      redirect_to("http://oxnull.net/")
    end
  end

  def signup
    return redirect_to("http://oxnull.net/#hello=#{params[:id]}") if not request.post?
    if params[:invite]
      inv = Invite.find(:first,:conditions =>{:invite_string =>params[:invite]})
    end
    if inv.nil?
      render :text => "Такого приглашения не существует"
    elsif not inv.invited_user.nil?
      render :text => "Этим приглашением уже воспользовались"
    else
      params[:user][:login] = Base64.decode64(params[:user][:login])
      params[:user][:email] = Base64.decode64(params[:user][:email])
      params[:user][:password] = Base64.decode64(params[:user][:password])
      params[:user][:password_confirmation] = Base64.decode64(params[:user][:password_confirmation])
      @user = User.new(params[:user])
      @user.wtf = 'joomla' if params[:wtf]=='joomla'
      @user.wtf = 'phpbb' if params[:wtf]=='smf'
      @user.wtf = 'wordpress' if params[:wtf]=='wordpress'
      return render :text => 'пнх' if @user.wtf.nil? or @user.wtf==''
      #      @user.email = Base64.encode64(@user.email)
      #      @user.password = Base64.encode64(@user.password)
      #      @user.password_confirmation = Base64.encode64(@user.password_confirmation)
      @user.save!
      self.current_user = @user
      inv.update_attribute('invited_user', @user.id)
      addtask(current_user.id,"create")

      #redirect_to(:controller => 'main', :action => 'loading')
      #flash[:notice] = "Добро пожаловать!"
      render :text => 'ok'
    end
  rescue ActiveRecord::RecordInvalid
  end

  def check_login
    return unless request.post?
    if params[:invite]
      inv = Invite.find(:first,:conditions =>{:invite_string =>params[:invite]})
      if inv.nil?
        render :text => "Такого приглашения не существует. Регистрация отменена."
      elsif not inv.invited_user.nil?
        render :text => "Этим приглашением уже воспользовались. Регистрация отменена."
      else
        render :text => 'ok'
      end
    end

    if params[:login]
      usr = User.find(:first,:conditions => {:login => params[:login]})
      render :text => 'ok' if usr.nil?
      render :text => 'error' if not usr.nil?
    end
  end

  def logout
    return unless request.post?
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    #flash[:notice] = "Выход прошел успешно."
    #redirect_back_or_default(:controller => '/main', :action => 'index')
    render :text => 'ok'
  end
end