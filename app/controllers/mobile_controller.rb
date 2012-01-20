require 'xmlrpc/client'
require 'syslog'
require 'digest/md5'
class MobileController < ApplicationController
  skip_filter :authenticate_profile!, :only => [:show, :index, :hello, :about]

  def hello
      render(:layout => 'mainlayer') if request.xhr?
	  #render :text => '11'
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

  def invite
    if params[:task] == 'new'
      inv = Invite.new()
      inv.user_id = current_user.id
      inv.invite_string = (Digest::MD5.hexdigest(Time.now.to_s)).upcase
      inv.save!
      @invites = Invite.where(:user_id => current_user.id)
      render :partial => "inv_list", :locals => { :invites => @invites}
    elsif params[:task] == 'del'
      Invite.delete_all({:user_id => current_user.id, :id => params[:id]})
      render :text => ''
    else
      @invites = Invite.where(:user_id => current_user.id)
      render(:layout => 'mainlayer') if request.xhr?
    end
  end


  def index
    if logged_in?
      get_my_site(current_user)
      findtasks(current_user)
      render(:layout => 'mainlayer') if request.xhr?
    else
      redirect_to :action =>'hello'
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
    if request.post?
      app_attach(params[:user][:domain])
      flash[:notice] = "Недопустимое имя домена!" if params[:user][:domain]!~/\A[A-Z0-9-]+\.[A-Z0-9-]{0,3}\.?[A-Z]{2,4}\Z/i
      redirect_to :controller => 'main', :action =>'index'
    else
      render(:layout => 'mainlayer') if request.xhr?
    end
  end

  def about
    render(:layout => 'mainlayer') if request.xhr?
  end

  def loading
    render(:layout => 'mainlayer') if request.xhr?
  end

  def create
    if current_user.status != '1'
      redirect_to :action => 'index'
    else
      redirect_to :action => 'index'
    end
  end
end
