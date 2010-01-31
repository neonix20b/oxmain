require 'xmlrpc/client'
require 'syslog'
require 'digest/md5'
class MainController < ApplicationController
  include AuthenticatedSystem
  before_filter :login_from_cookie, :except =>[:go, :tasklist]

  def hello
    if params[:format]=='xml'
      #render :layout => false
      render :template => 'main/hello.html.erb'
    else
      render(:layout => 'mainlayer') if request.xhr?
    end
  end

  def favorite
    return render :text=>"нельзя" if not logged_in? or not request.post?
    tmp = Array.new()
    tmp = current_user.favorite.split(',') if not current_user.favorite.nil?
    tmp.insert(-1, params[:blog_id].to_s)
    current_user.favorite=tmp.uniq.join(',')
    current_user.save!
    render :text=>"[в избранном]"
  end

  def comment_work
    return render :text=>"нельзя" if not can_comment? or not request.post?
    post_id = params[:comment][:post_id]
    blog_id = params[:blog][:id]
    user_id = params[:comment][:user_id]
    if params[:do]=='add'
      comment = Comment.new(params[:comment])
      comment.user_id=user_id
      if comment.save
        flash[:notice] = "Комментарий успешно добавлен."
      else
        flash[:notice] = "Ошибка при добавлении комментария."
      end
    elsif params[:do]=='del'
      comment = Comment.find(params[:id])
      if can_comment?(comment)
        comment.destroy
        flash[:notice] = "Комментарий успешно удален."
      end
    end
    redirect_to blog_post_url(blog_id,post_id)
  end

  def ox_rank
    return render :text=>"нельзя" if not logged_in?
    
    render :text => '0'
  end

  def contacts
    render(:layout => 'mainlayer') if request.xhr?
  end

  def deatt
    return unless request.post?
    app_deatt()
  end
  
  def go
    if params[:id]=='hostmonster'
      redirect_to 'http://www.hostmonster.com/track/cavernxxx'
    elsif params[:id]=='sape'
      redirect_to 'http://www.sape.ru/r.mDoCXqTiLZ.php'
    elsif params[:id]=='sweb'
      redirect_to 'http://sweb.ru/p14277'
    end
  end
  
  def rebuild
    return unless request.post?
    current_user.update_attribute('wtf', params[:wtf])
    app_rebuild()
    flash[:notice] = "Пересоздание аккаунта скоро будет завершено"
    redirect_to :action=> 'loading'
  end

  def show_password
    return unless request.post? or request.xhr?
    render :partial => "passwords"
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
    user.password = "jhfkjsadhflskahflk#{Time.now.to_s}"
    user.email = 'reserved@oxnull.net'
    user.password_confirmation = user.password
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
      #@invites = Invite.find(:all,:conditions =>{:user_id => current_user.id})
      #render :partial => "inv_list", :locals => { :invites => @invites}
      render :text => inv.invite_string
    elsif params[:task] == 'del'
      Invite.delete_all({:user_id => current_user.id, :id => params[:id]})
      render :text => ''
    else
      @invites = Invite.find(:all,:conditions =>{:user_id => current_user.id})
      render(:layout => 'mainlayer') if request.xhr?
    end
  end


  def index
    if logged_in? and current_user.status!='0' and current_user.status!='1'
      get_my_site(current_user)
      findtasks(current_user)
      service_prerender()
      render(:layout => 'mainlayer') if request.xhr?
    elsif logged_in?
      redirect_to :action=> 'loading', :xhr=>'true'
    else
      redirect_to :controller => 'account', :action =>'login'
    end
  end

  def taskdel
    return unless request.post? or request.xhr?
    current_user.update_attribute('status','2') if Task.find(params[:id]).status=="rebuild"
    Task.delete_all({:user_id => current_user.id, :id => params[:id]})
    Task.delete(params[:id])if current_user.login == 'neonix'
    render :text => ''
  end

  def tasklist
    return unless request.post?
    findtasks(current_user) if logged_in?
    render :partial => "tasks", :locals => { :tasks => @tasks}
  end

  def staff
    #@user = User.find(current_user.id)
    if request.post? and not params[:user].nil?
      #render :text => params[:user][:domain]
      app_attach(params[:user][:domain])
      flash[:notice] = "Недопустимое имя домена!" if params[:user][:domain]!~/\A[A-Z0-9-]+\.[A-Z0-9-]{0,3}\.?[A-Z]{2,4}\Z/i
      redirect_to :controller => 'main', :action =>'index'
    elsif request.post? and params[:user].nil?
      app_deatt()
      flash[:notice] = "Домен успешно отсоединен"
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
    findtasks(current_user)
    render(:layout => 'mainlayer') if request.xhr? or params[:xhr]=='true'
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
