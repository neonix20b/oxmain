class MainController < ApplicationController
  include AuthenticatedSystem
  before_filter :login_from_cookie, :except =>[:go, :tasklist]
  before_filter :login_required, :except => [:hello, :gmtoffset, :contacts, :go, :error, :video, :about]
  before_filter :find_last, :only =>[:index, :hello]

  def hello
    if params[:format]=='xml'
      #render :layout => false
      render :template => 'main/hello.html.erb'
    else
      render(:layout => 'mainlayer') if request.xhr?
    end
  end

  def gmtoffset
    session[:gmtoffset]= -1 * params[:id].to_i
    if logged_in? and current_user.gmtoffset != session[:gmtoffset].to_i
      current_user.gmtoffset = session[:gmtoffset].to_i
      current_user.save!
    end
    render :text=>Russian::strftime(Time.now.utc.in_time_zone(session[:gmtoffset].to_i.minutes), "%d %B %Y, %H:%M")
  end

  def favorite
    return render :text=>"нельзя" if not request.post?
    ret = 'Теперь вы за ним не следите'
    tmp = Array.new()
    tmp = current_user.favorite.split(',') if not current_user.favorite.nil?
    if tmp.include?(params[:blog_id].to_s)
      tmp.delete(params[:blog_id].to_s)
      ret = 'Теперь вы за ним не следите'
    else
      tmp.insert(-1, params[:blog_id].to_s)
      ret = 'Теперь Вы следите за этим блогом'
    end
    current_user.favorite=tmp.uniq.join(',')
    current_user.save!
    render :text=>ret
  end

  def support_work
    return render :text=>"нельзя" if not request.post?
    support=Support.find(params[:id])
    ret="Готово!"
    if params[:do]=='get'
      return render :text=>"Есть не закрытая" if Support.find(:first, :conditions => {:worker_id => current_user.id, :status => ['open','share']})
      return render :text=>"нельзя" if not support.worker_id.nil?
      support.worker_id=current_user.id
      support.status='open'
      ret='Закреплено за Вами'
    elsif params[:do]=='del'
      return render :text=>"нельзя" if support.worker_id!=current_user.id and current_user.right!='admin'
      user = User.find(support.worker_id)
      user.ox_rank -= 1
      user.save!
      support.worker_id=nil
      support.status='open'
      ret='Заявка теперь свободная'
    elsif params[:do]=='share'
      return render :text=>"нельзя" if support.user_id != current_user.id or support.status!='open'
      support.status='share'
    elsif params[:do]=='close'
      return render :text=>"нельзя" if support.worker_id != current_user.id or (support.status=='open' and support.updated_at < 15.minutes.ago)
      support.status='close'
    elsif params[:do]=='accept'
      return render :text=>"нельзя" if support.user_id != current_user.id and current_user.right!='admin'
      user = User.find(support.worker_id)
      transfer_money(User.find(3), user, support.money.to_f)
      support.destroy
      user.ox_rank += 1
      user.save!
    elsif params[:do]=='nu_nah'
      return render :text=>"нельзя" if support.user_id != current_user.id
      support.status='nu_nah'
    end
    support.save! if params[:do]!='accept'
    return render :text=>ret
  end

  def comment_work
    return render :text=>"нельзя" if not can_edit? or not request.post?
    if params.has_key?("comment") and params[:comment].has_key?("post_id")
      post_id = params[:comment][:post_id]
      blog_id = params[:blog][:id]
    end
    user_id = params[:comment][:user_id] if params.has_key?("comment") and params[:comment].has_key?("user_id")
    if params[:do]=='add'
      comment = Comment.new(params[:comment])
      comment.user_id=user_id
      if comment.save
        flash[:notice] = "Комментарий успешно добавлен."
        post=Post.find(comment.post_id)
        post.last_comment = "Новые комментарии. Всего #{post.comments.size.to_s}шт."
        post.save!
        find_last_posts(current_user)
        remove_from_last(current_user, post.id.to_s)
      else
        flash[:warning] = "Ошибка при добавлении комментария."
      end
    elsif params[:do]=='del'
      comment = Comment.find(params[:id])
      txt = comment.text
      if can_edit?(comment)
        comment.destroy
        #flash[:notice] = "Комментарий успешно удален."
        return render :text=>"Комментарий успешно удален. Его текст:<br/>#{txt}"
      else
        return render :text=>"Нельзя."
      end
    end
    if params[:comment].has_key?("post_id")
      redirect_to blog_post_url(blog_id,post_id)
    else
      redirect_to support_url(params[:comment][:support_id])
    end
  end

  def comment_try
    return render :text=>"нельзя" if not request.post?
    return render :text=>"" if params[:text].blank? or params[:text].size < 1
    @comment = Comment.new
    @comment.updated_at = Time.now
    @comment.created_at = Time.now
    @comment.id = 46
    @comment.text = params[:text]
    @comment.ox_rank = 0
    @comment.count = -2 + rand(10)
    render(:layout => 'mainlayer')
  end

  def unread_posts
    return render :text=>"нельзя" if not request.post?
    @unread_posts=find_last_posts(current_user,4)
    render :partial => "unread_posts", :locals => { :posts => @unread_posts}
  end

  def ox_rank
    return render :text=>"нельзя" if not request.post? or current_user.ox_rank < 0
    @obj = params[:obj].camelize.constantize.find(params[:id])
    max =  User.maximum('ox_rank')#User.find(:first,:order=>'ox_rank DESC').ox_rank
    if params[:do]=='minus'
      add_rank = -0.1
      add_rank -= current_user.ox_rank/max
      add_count = -1
    else
      add_rank = 0.1
      add_rank += current_user.ox_rank/max
      add_count = 1
    end
    if @obj.respond_to?('user_id')
      return render :text=>"нельзя" if current_user.id == @obj.user_id
      user = User.find(@obj.user_id)
      tmp=[]
      tmp=user.last_vote.split(';') if not user.last_vote.nil?
      return render :text=>"Уже за него голосовал!" if not session["vote_#{user.id.to_s}"].nil? and not session["vote_#{user.id.to_s}"].to_time < 30.minutes.ago.utc.to_s.to_time
      session["vote_#{user.id.to_s}"] = Time.now.utc.to_s
      return render :text=>"Уже за него голосовал!" if current_user.id.to_s == tmp[0] and not tmp[1].to_time < 30.minutes.ago.utc.to_s.to_time
      user.last_vote="#{current_user.id.to_s};#{Time.now.utc.to_s}"
      user.old_rank = user.ox_rank if user.old_rank != user.ox_rank and user.updated_at < 120.minutes.ago
      @obj.count += add_count if @obj.respond_to?('count')
      @obj.ox_rank += add_rank
      user.ox_rank += add_rank
      if params[:do]=='plus' or #and transfer_money(current_user, user, 0.01)) or
          params[:do]=='minus' #and transfer_money(current_user, User.find(3), 0.01))
        @obj.last_comment='Мало комментариев!' if @obj.respond_to?('last_comment')
        @obj.save!
        user.save!
      else
        return render :text=>"нельзя"
      end
    end
    render :layout => false
    
  end

  def ox_rank_helper
    @obj = params[:obj].camelize.constantize.find(params[:id])
    render :layout => 'popup'
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
    return unless request.post? or request.xhr?
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
      return render :text => "<a href='http://oxnull.net/#hello=#{inv.invite_string}'>Скопируйте эту ссылку</a>"  if request.xhr?
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
    if current_user.status!='0' and current_user.status!='1'
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
      flash[:warning] = "Недопустимое имя домена!" if params[:user][:domain]!~/\A[A-Z0-9-]+\.[A-Z0-9-]{0,3}\.?[A-Z]{2,4}\Z/i
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
      #flash[:warning] = "Что-то пошло не так... обратитесь в службу тех.поддержки"
      redirect_to :action => 'index'
    end
  end

end
