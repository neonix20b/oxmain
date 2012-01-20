require 'net/http'
require 'uri'
class MainController < ApplicationController
  skip_filter :authenticate_profile!, :only => [:hello, :gmtoffset, :contacts, :go, :error, :video, :about]
  before_filter :find_last, :only =>[:index, :hello]
  before_filter :attach_mail, :only =>[:attach_yamail, :attach_gmail]
  before_filter :only_post, :only =>[:attach_yamail,:attach_gmail]
  
  def hello
    if params[:format]=='xml'
      #render :layout => false
      render :template => 'main/hello.html.erb'
    else
      render(:layout => 'mainlayer') if request.xhr?
    end
  end
  
  def attach_yamail
	addtask(@user.id,"attach_yamail",@user.domain)
	@user.attached_mail="yamail"
	@user.save!
	render :text=>'ok'
  end
  
  def attach_gmail
	addtask(@user.id,"attach_gmail",@user.domain)
	@user.attached_mail="gmail"
	@user.save!
	render :text=>'ok'
  end
  
  def my_old
	return render :text=>"11" if params[:id].nil? or params[:id].size < 1
	user=User.find(params[:id])
	user.profile=current_profile
	user.save!
	render :text=>'ok'
  end
  
  def mail_test
	if can_send_email?(current_profile)
		UserMailer.simple_mail(current_profile,"text").deliver 
		return render :text=>'ok'
	else
		return render :text=>'no'
	end
  end

  def gmtoffset
    session[:gmtoffset]= -1 * params[:id].to_i
    render(:layout => 'mainlayer')
  end

  def favorite
    return render :text=>"нельзя" if not request.post?
    ret = 'Теперь вы за ним не следите'
    tmp = Array.new()
    tmp = current_profile.favorite.split(',') if not current_profile.favorite.nil?
    if tmp.include?(params[:blog_id].to_s)
      tmp.delete(params[:blog_id].to_s)
      ret = 'Теперь вы за ним не следите'
    else
      tmp.insert(-1, params[:blog_id].to_s)
      ret = 'Теперь Вы следите за этим блогом'
    end
    current_profile.favorite=tmp.uniq.join(',')
    current_profile.save!
    render :text=>ret
  end

  def support_work
    return render :text=>"нельзя" if not request.post?
    support=Support.find(params[:id])
    ret="Готово!"
    if params[:do]=='get'
      return render :text=>"Есть не закрытая" if Support.where(:worker_id => current_profile.id, :status => ['open','share']).first
      return render :text=>"нельзя" if not support.worker_id.nil?
      support.worker_id=current_profile.id
      support.status='open'
      ret='Закреплено за Вами'
    elsif params[:do]=='del'
      return render :text=>"нельзя" if support.worker_id!=current_profile.id and current_profile.right!='admin'
      user = User.find(support.worker_id)
      user.ox_rank -= 1
      user.save!
      support.worker_id=nil
      support.status='open'
      ret='Заявка теперь свободная'
    elsif params[:do]=='share'
      return render :text=>"нельзя" if support.user_id != current_profile.id or support.status!='open'
      support.status='share'
    elsif params[:do]=='close'
      return render :text=>"нельзя" if support.worker_id != current_profile.id or (support.status=='open' and support.updated_at < 15.minutes.ago)
      support.status='close'
    elsif params[:do]=='accept'
      return render :text=>"нельзя" if support.user_id != current_profile.id and current_profile.right!='admin'
      user = User.find(support.worker_id)
      transfer_money(User.find(3), user, support.money.to_f)
      support.destroy
      user.ox_rank += 1
      user.save!
    elsif params[:do]=='nu_nah'
      return render :text=>"нельзя" if support.user_id != current_profile.id
      support.status='nu_nah'
    end
    support.save! if params[:do]!='accept'
    return render :text=>ret
  end

  def comment_work
	return render :text=>'А ты точно человек?' if not can_send_email?(current_profile)
    return render :text=>"нельзя" if not can_edit? or not request.post?
    if params.has_key?("comment") and params[:comment].has_key?("post_id")
      post_id = params[:comment][:post_id]
      blog_id = params[:blog][:id]
    end
    profile_id = params[:comment][:profile_id] if params.has_key?("comment") and params[:comment].has_key?("profile_id")
    if params[:do]=='add'
      comment = Comment.new(params[:comment])
	  return render :text=>'Подумайте о людях, им же это читать! Комментарий НЕ добавлен, его текст: '+comment.text if comment.text=~/(.)\1{5,}/ or comment.text.split(/[\s\.\:\-\/\?\&]/).sort_by{|i|i.size}.last.length > 60
      comment.profile_id=profile_id
	  block_profile(profile_id,"Спамер что ли?") if check_police("new_comment",profile_id,5.minutes.ago) > 5
      if comment.save
		flash[:notice] = "Комментарий успешно добавлен."
		if params[:comment].has_key?("post_id")
			post=Post.find(comment.post_id)
			post.last_comment = "Новые комментарии. Всего #{post.comments.size.to_s}шт."
			post.updated_at = Time.now.utc
			post.save!
			find_last_posts(current_profile)
			remove_from_last(current_profile, post.id.to_s)
			#UserMailer.new_comment(post.profile,comment).deliver if can_send_email?(post)
		elsif params[:comment].has_key?("invite_id")
			UserMailer.new_comment(comment.invite.profile,comment).deliver if can_send_email?(comment.invite.profile)
		end
		current_profile.last_comment_input = ""
		current_profile.save!
      else
		flash[:warning] = "Ошибка при добавлении комментария."
      end
    elsif params[:do]=='del'
      comment = Comment.find(params[:id])
	  prof = comment.profile
      txt = comment.text
      if can_edit?(comment)
        comment.destroy
		if post.comments.last.nil?
			post.updated_at=post.created_at
		else
			post.updated_at = post.comments.last.created_at
		end
		post.save!
        #flash[:notice] = "Комментарий успешно удален."
        return render :text=>"Комментарий #{profile_link(prof,false)} успешно удален. Его текст:<br/>#{txt}"
      else
        return render :text=>"Нельзя."
      end
    end
    if params[:comment].has_key?("post_id")
      redirect_to blog_post_url(blog_id,post_id,:anchor => "comment_try")
    else
      redirect_to :controller=>'invite',:action=>'show',:id=>(params[:comment][:invite_id])
    end
  end

  def comment_try
	return render :text=>'А ты точно человек?' if not can_send_email?(current_profile,2)
    return render :text=>"" if not request.post? or params[:text].size > 10000
	current_profile.updated_at=Time.now.utc if not current_profile.last_comment_input.nil? and current_profile.last_comment_input.size < 10 and params[:text].to_s.size > 10 or not current_profile.last_comment_input.nil? and current_profile.last_comment_input.size > 10 and params[:text].to_s.size < 10
	current_profile.last_comment_input = params[:text]
	current_profile.save!
    return render :text=>"" if params[:text].blank? or params[:text].size < 1
    @comment = Comment.new()
    @comment.updated_at = Time.now
    @comment.created_at = Time.now
    @comment.id = 46
    @comment.text = params[:text]
    @comment.ox_rank = 0
    @comment.count = -2 + rand(10)
	ss=@comment.text.split(/[\s\.\:\-\/\?\&]/).sort_by{|i|i.size}.last
	pos=@comment.text=~/(.)\1{5,}/
	warntxt="*Подумайте о людях, им же это читать! Комментарий НЕ будет добавлен, его текст:*"
	@comment.text=warntxt+"(#{@comment.text[pos..pos+5]}...)\n\n"+@comment.text+"\n\n"+warntxt if not pos.nil? and pos>0
	@comment.text=warntxt+"(#{ss})\n\n"+@comment.text+"\n\n"+warntxt if ss.length > 60
    render(:layout => 'mainlayer')
  end

  def unread_posts
    return render :text=>"нельзя" if not request.post?
	#current_profile.last_url = params[:last_url] if params[:last_url].scan(/^\/[\w\.\/0-9]*$/).size != 0
	#current_profile.save!
    @unread_posts=find_last_posts(current_profile,3)
	@pm=Privatemessage.where(:profile_to=>current_profile.id,:readed=>false).first
    render :partial => "unread_posts", :locals => { :posts => @unread_posts}
  end
  
  def vote_plus 
	return render :text=>"нельзя" if not request.post? or current_profile.ox_rank < 0
	return render :text=>"нельзя" if Poll.exists?(:obj_id=>params[:obj]+"_"+params[:id],:profile_id=>current_profile.id)
	@obj = params[:obj].camelize.constantize.find(params[:id])
	vote = Poll.new(:obj_id=>params[:obj]+"_"+params[:id],:vote=>1,:profile_id=>current_profile.id)
	vote.save!
	@obj.count +=1
	@obj.ox_rank += ox_power()
	@obj.ox_rank=(@obj.ox_rank.to_f*1000).round.to_f/1000
	if @obj.respond_to?('profile_id') and not @obj.profile.nil?
		user=@obj.profile
		user.ox_rank += ox_power()
		user.ox_rank=(user.ox_rank*1000).round.to_f/1000
		user.old_rank = user.ox_rank if user.old_rank != user.ox_rank and user.updated_at < 120.minutes.ago
		user.save!
	end
	@obj.old_rank = @obj.ox_rank if @obj.respond_to?('old_rank') and @obj.updated_at < 120.minutes.ago
	@obj.status="2" if @obj.respond_to?('status') and @obj.status=="vote" and @obj.ox_rank > 1
	@obj.last_comment='Мало комментариев!' if @obj.respond_to?('last_comment')
	@obj.save!
	if Poll.where("created_at < ?",28.days.ago).size > 1000
		Poll.where("created_at < ?",28.days.ago).map{|p| p.destroy}
	end
	return render :inline => "<%=raw vote_helper(@obj)%>"
	#render :template=>"users/vote"
  end
  
  def vote_minus
	return render :text=>"нельзя" if not request.post? or current_profile.ox_rank < 0
	return render :text=>"нельзя" if Poll.exists?(:obj_id=>params[:obj]+"_"+params[:id],:profile_id=>current_profile.id)
	@obj = params[:obj].camelize.constantize.find(params[:id])
	vote = Poll.new(:obj_id=>params[:obj]+"_"+params[:id],:vote=>-1,:profile_id=>current_profile.id)
	vote.save!
	@obj.count -=1
	@obj.ox_rank -= ox_power()
	@obj.ox_rank=(@obj.ox_rank.to_f*1000).round.to_f/1000
	if @obj.respond_to?('profile_id') and not @obj.profile.nil?
		user=@obj.profile
		user.ox_rank -= ox_power()
		user.ox_rank=(user.ox_rank*1000).round.to_f/1000
		user.old_rank = user.ox_rank if user.old_rank != user.ox_rank and user.updated_at < 120.minutes.ago
		user.save!
	end
	@obj.old_rank = @obj.ox_rank if @obj.respond_to?('old_rank') and @obj.updated_at < 120.minutes.ago
	@obj.last_comment='Мало комментариев!' if @obj.respond_to?('last_comment')
	@obj.save!
	if @obj.respond_to?('status') and @obj.status=="vote" and @obj.ox_rank < -3
		addtask(@obj.id,"remove_user") 
		return render :text => "Будет удален"
	end
	return render :inline => "<%=raw vote_helper(@obj)%>"
  end

  def ox_rank
    return render :text=>"нельзя" if not request.post? or current_profile.ox_rank < 0
    @obj = params[:obj].camelize.constantize.find(params[:id])
    if params[:do]=='minus'
      add_rank = -1*ox_power()
      add_count = -1
    else
      add_rank = ox_power()
      add_count = 1
    end
    if @obj.respond_to?('user_id')
      return render :text=>"нельзя" if current_profile.id == @obj.user_id
      user = User.find(@obj.user_id)
      tmp=[]
      tmp=user.last_vote.split(';') if not user.last_vote.nil?
      return render :text=>"Уже за него голосовал!" if not session["vote_#{user.id.to_s}"].nil? and not session["vote_#{user.id.to_s}"].to_time < 30.minutes.ago.utc.to_s.to_time
      session["vote_#{user.id.to_s}"] = Time.now.utc.to_s
      return render :text=>"Уже за него голосовал!" if current_profile.id.to_s == tmp[0] and not tmp[1].to_time < 30.minutes.ago.utc.to_s.to_time
      user.last_vote="#{current_profile.id.to_s};#{Time.now.utc.to_s}"
      user.old_rank = user.ox_rank if user.old_rank != user.ox_rank and user.updated_at < 120.minutes.ago
      @obj.count += add_count if @obj.respond_to?('count')
      @obj.ox_rank += add_rank
      user.ox_rank += add_rank
      if params[:do]=='plus' or #and transfer_money(current_profile, user, 0.01)) or
          params[:do]=='minus' #and transfer_money(current_profile, User.find(3), 0.01))
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
    #app_deatt()
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
	user=User.find(params[:user_id])
	return render :text =>'xxx' if not current_profile.adept? and user.profile!=current_profile
    user.update_attribute('wtf', params[:wtf])
    app_rebuild(user)
    flash[:notice] = "Пересоздание аккаунта скоро будет завершено"
    redirect_to :action=> 'index'
  end

  def show_password
    return unless request.post? or request.xhr?
    render :partial => "passwords"
  end

  def cancel
    user = User.find(current_profile.id)
    user.update_attribute(:domain, '')
    user.update_attribute(:status, '2')
    Task.delete(:first,:conditions => {:user_id =>current_profile.id, :status => 'attach_domain'})
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
	load_linkfeed()
    #render :text => 'У Вас закончилось место'
  end

  def video
    render(:layout => 'mainlayer') if request.xhr?
  end

  def invite
    return unless request.post? or request.xhr?

    if params[:task] == 'new' and current_profile.right!='user'
      inv = Invite.new()
      inv.user_id = current_profile.id
      inv.invite_string = (Digest::MD5.hexdigest(Time.now.to_s)).upcase
      inv.save!
	  #inv.invite_string="Регистрация отключена"
      @invites = Invite.where(:user_id => current_profile.id)
      #render :partial => "inv_list", :locals => { :invites => @invites}
      return render :text => "<a href='http://oxnull.net/#hello=#{inv.invite_string}'>Скопируйте эту ссылку</a>"  if request.xhr?
      #render :text => inv.invite_string
	elsif params[:task] == 'new'
		return render :text => 'Вы не можете создавать приглашения'
    elsif params[:task] == 'del'
      Invite.delete_all({:user_id => current_profile.id, :id => params[:id]})
      render :text => ''
    else
      @invites = Invite.where(:user_id => current_profile.id)
      render(:layout => 'mainlayer') if request.xhr?
    end
  end


  def index
	  update_online_url()
      #findtasks(current_profile)
	  if not params[:id].nil? and current_profile.adept? and params[:id].size>2
		if params[:id]=~/^\d+$/
			@users = [User.find(params[:id])]
		else
			@users =  User.where("domain LIKE ? or oxdomain LIKE ?","%"+params[:id]+"%","%"+params[:id]+"%")
		end
		@users.each do |user|
			@users-=[user] if not user.profile.nil? and user.profile.adept? and not current_profile.admin? or (user.status!='2' and user.status!='vote') or not current_profile.adept?
		end
		
	  else
		@users = User.where(:profile_id=>current_profile.id).where('status="2" or status="1" or status="0" or status="vote"')#current_profile.users
	  end
	  @users.map{|user| service_prerender(user)}
	  @invites = Invite.where(" profile_id = ? AND status <>'ok' and status <>'revoke'",current_profile.id)
	  @invites += Invite.where(:profile_id=>current_profile.id,:status =>'ok',:invited_user=>nil)
      render(:layout => 'mainlayer') if request.xhr?
  end
  
  def set_master
	return render :text => '11' if not current_profile.adept?
	user=User.find(params[:user_id])
	user.profile_id = params[:profile_id].to_i
	user.save!
	render :text => user.to_xml
  end
  
  def set_master_comment
	return render :text => '11' if not current_profile.adept?
	#return render :text => params.to_xml
	comm=Comment.find(params[:comment_id])
	return render :text => '11' if not comm.profile.nil?
	comm.profile_id = params[:profile_id].to_i
	comm.save!
	render :text => comm.to_xml
  end

  def taskdel
    return unless request.post? or request.xhr?
    current_profile.update_attribute('status','2') if Task.find(params[:id]).status=="rebuild"
    Task.delete_all({:user_id => current_profile.id, :id => params[:id]})
    Task.delete(params[:id])if current_profile.login == 'neonix'
    render :text => ''
  end

  def tasklist
    return unless request.post?
    findtasks(current_profile) if logged_in?
    render :partial => "tasks", :locals => { :tasks => @tasks}
  end

  def staff
    user = User.find(params[:user_id])
	return render :text =>'xxx' if not current_profile.adept? and user.profile!=current_profile
    if request.post? and not params[:user].nil?
      #render :text => params[:user][:domain]
      app_attach(params[:user][:domain],user)
      flash[:warning] = "Недопустимое имя домена!" if params[:user][:domain]!~/\A[A-Z0-9-]+\.[A-Z0-9-]{0,3}\.?[A-Z]{2,4}\Z/i
      redirect_to :controller => 'main', :action =>'index'
    elsif request.post? and params[:user].nil?
      app_deatt(user)
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
    #findtasks(current_profile)
    render(:layout => 'mainlayer') if request.xhr? or params[:xhr]=='true'
  end

  def create
    if current_profile.status != '1'
      #sql = Pglink.connection()
      #sql.begin_db_transaction
      #current_profile.update_attribute('status','1')
      #sql.execute("SELECT webhosting.create_user("+current_profile.id.to_s+", '"+current_profile.login+"')")
      #sql.commit_db_transaction
      #flash[:notice] = "Сайт создан успешно"
      redirect_to :action => 'index'
    else
      #current_profile.update_attribute('status','0')
      #flash[:warning] = "Что-то пошло не так... обратитесь в службу тех.поддержки"
      redirect_to :action => 'index'
    end
  end

  private
  def attach_mail
	@user=User.find(params[:id])
	return render :text=>'err1' if @user.profile!=current_profile
	return render :text=>'err2' if not @user.domain=~/\A[A-Z0-9-]+\.[A-Z]{2,4}\Z/i
	return render :text=>'err3' if not @user.attached_mail.nil?
  end
end
