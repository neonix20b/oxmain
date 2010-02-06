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
    ret = '[+]'
    tmp = Array.new()
    tmp = current_user.favorite.split(',') if not current_user.favorite.nil?
    if tmp.include?(params[:blog_id].to_s)
      tmp.delete(params[:blog_id].to_s)
      ret = '[+]'
    else
      tmp.insert(-1, params[:blog_id].to_s)
      ret = '[-]'
    end
    current_user.favorite=tmp.uniq.join(',')
    current_user.save!
    render :text=>ret
  end

  def support_work
    return render :text=>"нельзя" if not logged_in? or not request.post?
    if params[:do]=='get'
      return render :text=>"нельзя" if Support.find(:first, :conditions => {:worker_id => current_user.id})
      support=Support.find(params[:id])
      support.worker_id=current_user.id
      support.save!
      return render :text => 'Закреплено за Вами'
    elsif params[:do]=='del'
      support=Support.find(params[:id])
      support.worker_id=nil
      support.save!
      return render :text => 'Заявка стала свободной'
    end
  end

  def comment_work
    return render :text=>"нельзя" if not can_edit? or not request.post?
    if params[:comment].has_key?("post_id")
      post_id = params[:comment][:post_id]
      blog_id = params[:blog][:id]
    end
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
      if can_edit?(comment)
        comment.destroy
        flash[:notice] = "Комментарий успешно удален."
      end
    end
    if params[:comment].has_key?("post_id")
      redirect_to blog_post_url(blog_id,post_id)
    else
      redirect_to support_url(params[:comment][:support_id])
    end
  end

  def ox_rank
    return render :text=>"нельзя" if not logged_in? or not request.post?
    @obj = params[:obj].camelize.constantize.find(params[:id])
    if params[:do]=='minus'
      add_rank = -1.0
      add_count = -1
    else
      add_rank = 1.0
      add_count = 1
    end
    if @obj.respond_to?('user_id')
      return render :text=>"нельзя" if current_user.id == @obj.user_id
      user = User.find(@obj.user_id)
      @obj.count += add_count if @obj.respond_to?('count')
      @obj.ox_rank += add_rank
      user.ox_rank += add_rank
      if (params[:do]=='plus' and transfer_money(current_user, user, 1)) or
          (params[:do]=='minus' and transfer_money(current_user, User.find(3), 1))
        @obj.save!
        user.save!
      else
        return render :text=>"нельзя"
      end
    end
    render :layout => false
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
