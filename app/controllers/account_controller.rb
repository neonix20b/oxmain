require "base64"
class AccountController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  protect_from_forgery :except => [:login, :signup, :logout, :whoiam, :index, :check_login]
  # If you want "remember me" functionality, add this before_filter to Application Controller
  skip_filter :authenticate_profile!, :only =>[:profile,:signup]
  #FIXME удалить строчку ниже когда станем популярными :)
  before_filter :find_last, :only =>[:whoiam]

#@user.wtf = 'joomla' if params[:wtf]=='joomla'
#@user.wtf = 'phpbb' if params[:wtf]=='smf'
#@user.wtf = 'wordpress' if params[:wtf]=='wordpress'
#@user.wtf = 'none' if params[:wtf]=='none'
#addtask(current_profile.id,"create")
  
  def list
    if logged_in? and current_profile.adept?
      @users = User.order("id")
    else
      render :text => 'ку'
    end
  end
  
  def profiles
	if logged_in? and current_profile.adept?
      @profiles = Profile.order("id DESC")
    else
      render :text => 'ку'
    end
  end

  def profile_ajax
	return render :text=>"" if not request.post?
	find_chats()
	return render :text=>"" if @chat_list.nil? or @chat_list.size == 0
	if session[:last_pm]==@chat_list.first.id
		@chat_list=nil 
	else
		session[:last_pm]=@chat_list.first.id
		session[:do_not_read] = Array.new
		@chat_list.each do |cl|
			session[:do_not_read] += [cl.id] if not cl.readed
		end
	end
	@chat_list_read=Privatemessage.where(:profile_from=>current_profile.id, :id=>session[:do_not_read], :readed=>true)
	@chat_list_read.each do |cl|
		session[:do_not_read] -= [cl.id]
	end
	render(:layout => 'mainlayer')
  end

  def profile
	load_linkfeed()
  	update_online_url()
    show_name = params[:id]
    @user = Profile.where(:show_name => show_name).first
	if not @user.nil?
		@user.created_at = Time.now if @user.created_at.nil?
		if @user.old_rank != @user.ox_rank and @user.updated_at < 120.minutes.ago
		  @user.old_rank = @user.ox_rank
		  @user.save!
		end
		tmp = []
		@blogs = []
		tmp = @user.favorite.split(',') if  not @user.favorite.nil?
		@blogs = Blog.order('name ASC').find(tmp) if not tmp.empty?
		if logged_in? and current_profile==@user
			find_chats()
			session[:last_pm]=@chat_list.first.id if not @chat_list.nil? and @chat_list.size > 0
			session[:do_not_read] = Array.new
			@chat_list.each do |cl|
				session[:do_not_read] += [cl.id] if not cl.readed
			end
		end
		@user.save!
	end
	
  end

  def edit
	@avatars = (Dir.new(Rails.root.to_s+'/public/images/avatars/').entries - [".", ".."]).map{|ava| '/images/avatars/'+ava}
	if request.post? and params.has_key?('profile')
      @profile = current_profile
	  txt_url=params[:profile][:avatar]
	  if(not txt_url.index("http").nil? and txt_url.index("http")==0)
		url = URI.parse(txt_url)
		req = Net::HTTP::Get.new(url.path)
		res = Net::HTTP.start(url.host, url.port) {|http| http.request(req) }
		flash[:notice] = ''
		if res.body.size > 40000
			params[:profile][:avatar]='http://oxnull.net/images/noavatar.png'
			flash[:warning] = "ВНЕЗАПНО аватар оказался больше чем хотелось бы, поэтому удален. "
		  end
	  end
      if @profile.update_attributes(params[:profile])
        flash[:notice] = "Профиль успешно обновлен."
        redirect_to :controller =>'account', :action=>'profile',:id=>current_profile.show_name
      end
    else
      @profile = current_profile
      render(:layout => 'mainlayer') if request.xhr?
    end
  end
  
  def new
    
  end

  def create
    # add custom create logic here
	render :text=>"wow"
  end

  def update
    
  end
  
  private
  def find_chats
  		@chat_list = Array.new
		id_list = Privatemessage.where(:profile_to=>current_profile.id).select("DISTINCT profile_to,profile_from").map{|c| c.profile_from}
		id_list += Privatemessage.where(:profile_from=>current_profile.id).select("DISTINCT profile_to,profile_from").map{|c| c.profile_to}
		id_list.uniq!
		#return render :text=>id_list.join(";")
		id_list=id_list.sort_by do |ff|
			Privatemessage.where("(profile_to=? AND profile_from=?) OR (profile_to=? AND profile_from=?)",current_profile.id,ff,ff,current_profile.id).order("created_at DESC").first.created_at
		end
		id_list.reverse!
		id_list.each do |ff|
			@chat_list+=[Privatemessage.where("(profile_to=? AND profile_from=?) OR (profile_to=? AND profile_from=?)",current_profile.id,ff,ff,current_profile.id).order("created_at DESC").first]
		end
		#@chat_list=Comment.find(:all,:order=>"created_at DESC")
		#  = Comment.find_all_by_user_id(:order=>"created_at DESC")
  end
end
