require 'xmlrpc/client'
require 'syslog'
require 'digest/md5'
class MainController < ApplicationController
  include AuthenticatedSystem
  before_filter :login_from_cookie

  def hello
    if params[:format]=='xml'
      #render :layout => false
      render :template => 'main/hello.html.erb'
    else
      render(:layout => 'mainlayer') if request.xhr?
    end
  end

  def contacts
    render(:layout => 'mainlayer') if request.xhr?
  end
  
  def deatt
    app_deatt()
    redirect_to :action=> 'loading'
  end
  
  def rebuild
    app_rebuild()
    redirect_to :action=> 'index'
  end

  def cancel
    user = User.find(current_user.id)
    user.update_attribute(:domain, '')
    user.update_attribute(:status, '2')
    Task.delete(:first,:conditions => {:user_id =>current_user.id, :status => 'attach_domain'})
    redirect_to :action=> 'index'
  end

  def reserve
    user = User.new
    user.login = params[:id]
    user.status = 'reserved'
    user.password = 'jhfkjsadhflskahflk'
    user.email = 'reserved@oxnull.net'
    user.password_confirmation = 'jhfkjsadhflskahflk'
    user.save!
    render :text =>'ok'
  end

  def error
    #render :text => 'У Вас закончилось место'
  end

  def video
    render(:layout => 'mainlayer') if request.xhr?
  end

  def invite
    #пароль - отзыв
    #здесь вербуют адептов
    #военкомат
    if params[:task] == 'new'
      inv = Invite.new()
      inv.user_id = current_user.id
      inv.invite_string = (Digest::MD5.hexdigest(Time.now.to_s)).upcase
      inv.save!
      @invites = Invite.find(:all,:conditions =>{:user_id => current_user.id})
      render :partial => "inv_list", :locals => { :invites => @invites}
    elsif params[:task] == 'del'
      Invite.delete_all({:user_id => current_user.id, :id => params[:id]})
      render :text => ''
    else
      @invites = Invite.find(:all,:conditions =>{:user_id => current_user.id})
      render(:layout => 'mainlayer') if request.xhr?
    end
  end


  def index
    if logged_in?
      get_my_site(current_user)
      findtasks(current_user)
      render(:layout => 'mainlayer') if request.xhr?
    else
      redirect_to :controller => 'account', :action =>'login'
    end
  end

  def taskdel
    Task.delete_all({:user_id => current_user.id, :id => params[:id]})
    Task.delete(params[:id])if current_user.login == 'neonix'
    render :text => ''
  end

  def tasklist
    findtasks(current_user)
    render :partial => "tasks", :locals => { :tasks => @tasks}
  end

  def staff
    #@user = User.find(current_user.id)
    if request.post?
      app_attach(params[:user][:domain])
      flash[:notice] = "Недопустимое имя домена!" if params[:user][:domain]!~/\A[A-Z0-9-]+\.[A-Z0-9-]{0,3}\.?[A-Z]{2,4}\Z/i
      redirect_to :controller => 'main', :action =>'index'
    else
      render(:layout => 'mainlayer') if request.xhr?
    end
  end

  def about
    #о настройках сервера
    render(:layout => 'mainlayer') if request.xhr?
  end

  def loading
    render(:layout => 'mainlayer') if request.xhr?
  end

  def create
    if current_user.status != '1'
      #sql = Pglink.connection()
      #sql.begin_db_transaction
      #current_user.update_attribute('status','1')
      #sql.execute("SELECT webhosting.create_user("+current_user.id.to_s+", '"+current_user.login+"')")
      #sql.commit_db_transaction
      #flash[:notice] = "Сайт создан успешно"
      redirect_to :action => 'index'
    else
      #current_user.update_attribute('status','0')
      #flash[:notice] = "Что-то пошло не так... обратитесь в службу тех.поддержки"
      redirect_to :action => 'index'
    end
  end
end
