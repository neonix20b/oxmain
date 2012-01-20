require 'digest/md5' if RUBY_PLATFORM.downcase.include?("linux")
require 'syslog' if RUBY_PLATFORM.downcase.include?("linux")
require 'redcloth'
require 'xmlrpc/client' if RUBY_PLATFORM.downcase.include?("linux")
require 'net/http'
require 'lf_linkshow'

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  include ApplicationHelper
  before_filter :authenticate_profile!
  before_filter :load_online
  
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery #:secret => 'f7c15baf4ab5a0e89d552d9b49e0ff95'
  def logged_in?
	return profile_signed_in?
  end
  
  def can_send_email?(obj,sign_in_count=1)
	return false if obj.nil?
	profile=nil
	if obj.respond_to?("profile_id") and not obj.profile.nil?
		profile = obj.profile 
	elsif obj.class.name == "Profile"
		profile = obj
	end
	return false if profile.nil? or profile.email.nil? or profile.email.size < 5
	return true if profile.adept?
	return false if profile.sign_in_count < sign_in_count
	return false if profile.confirmed_at.nil?
	return true
  end
  
  def check_police(var,value,time)
	p=Police.new(:var=>var,:value=>value)
	p.save!
	Police.where("created_at < ?",time).each do |clean|
		clean.destroy
	end
	return Police.where(:var=>var,:value=>value).count
  end
  
  def block_profile(profile,reson=nil)
	profile=Profile.find(profile)
	return true if profile.adept?
	profile.locked_at=Time.now
	profile.unlock_token=(Digest::MD5.hexdigest(Time.now.to_s)).upcase
	profile.save!
	if profile.ox_rank < 5
		Invite.where(:profile_id=>profile.id).where("created_at > ?",1.days.ago).each{|c|c.destroy}
		Comment.where(:profile_id=>profile.id).where("created_at > ?",1.days.ago).each do |c|
			if not c.post.nil?
				post=c.post
				if post.comments.last.nil?
					post.updated_at=post.created_at
				else
					post.updated_at = post.comments.last.created_at
				end
				post.save!
			end
			c.destroy
		end
	end
	if not reson.nil?
		return render :text=> reson+" Аккаунт заблокирован. Для разблокировки запросите инструкции в соответствующем разделе."
	end
  end
  
#  def current_user
#	return current_profile
#  end
  
  def default_url_options(options=nil)
    { :format => 'html' }
  end
  private
  
  def load_linkfeed
	if not  profile_signed_in?
		@lf=LFLinkShow::LFClient.new('f7ae879ab9d29f9666dccd2a4a6019e5dba01b61',request).return_links
	end
  end
  
  def load_online
	Profile.find_all_by_show_name([nil,""]).each{|p| profile_link(p,false)}
	if profile_signed_in? and not current_profile.updated_at.nil? and 
		current_profile.updated_at < 10.minutes.ago and 
		current_profile.last_url!="forget_close"
		#current_profile.updated_at = Time.now.utc
		current_profile.last_url="forget_close" if not current_profile.last_comment_input.nil? and current_profile.last_comment_input.size < 10
		current_profile.save!
	end
	@online = Profile.where("last_view > ?",1.minutes.ago).order('updated_at DESC')
  end
  
  def update_online_url
	if profile_signed_in?
	    if current_profile.gmtoffset != session[:gmtoffset].to_i
			current_profile.gmtoffset = session[:gmtoffset].to_i
		end
		current_profile.updated_at = Time.now.utc
		current_profile.last_url = request.request_uri 
		current_profile.save!
	end
  end

  def set_gmtoffset
    session[:gmtoffset] = current_profile.gmtoffset if logged_in?
  end
  
  def my_conf(var,default)
    conf = Conf.where(:var => var).first
    if conf.nil?
		conf = Conf.new({:var => var})
		conf.value=default
		conf.save!
	else
		conf.value=default
		conf.save!
	end
    return conf.value
  end

  def find_last
    if logged_in?
      remove_from_last(current_profile, params[:id]) if not params[:id].blank? and params[:action]=='show'
      @unread_posts=find_last_posts(current_profile,3)
	  @pm=Privatemessage.where(:profile_to=>current_profile.id,:readed=>false).first
    end
  end

  def transfer_money(from_user, to_user, money=1)
    money = money.abs
    server = XMLRPC::Client.new2("http://89.208.146.80:1979")
    from_user.money = server.call("get_balance", from_user.id)
    from_user.save!
    #to_user.money = server.call("get_balance", to_user.id)
    if from_user.money > 5+money
      server.call("add_balance",from_user.id,-1*money)
      from_user.money -= money
      from_user.save!
      server.call("add_balance",to_user.id,money)
      to_user.money += money
      to_user.save!
      return true
    else
      return false
    end
  end
  
  def service_prerender(user)
#    server = XMLRPC::Client.new2("http://89.208.146.80:1979")
#    @service_pay = Array.new()
#    @service_free = Array.new()
#    @discription = server.call("service_bridge",'service_list',1,1,1)
#    @discription.each do |d|
      #d[0]=title
      #d[1]=id
      #d[2]=description
      #d[3]=cost
      #@service_pay[-1] = d
#      d[4]=server.call("service_bridge",'service_stat', current_profile.id.to_s, d[1].to_s,1)
#      if d[4]=='0'
#        d[5]='add'
#      else
#        d[5]='del'
#      end
#      session[d[1].to_s] = d[4]
      session['ox'+user.id.to_s] = Hash.new if session['ox'+user.id.to_s].nil?
      session['ox'+user.id.to_s]['1'] = Hash.new
	  session['ox'+user.id.to_s]['1']['qtt'] = (rand()*100).to_i
	  session['ox'+user.id.to_s]['1']['sw'] = 'add'
#    end
#    current_profile.money = server.call("get_balance", current_profile.id)
#    current_profile.save!
  end
   
  def app_rebuild(user)
	user.email=current_profile.email
	user.email=user.profile.email if not user.profile.nil?
	user.save!
    wtf='none'
    wtf=user.wtf if user.wtf=='joomla' or user.wtf=='phpbb' or user.wtf=='wordpress'
    user.update_attribute('wtf', wtf) if wtf!=user.wtf
    if user.status =='removed'
      user.update_attribute('status', '0')
    else
      user.update_attribute('status', '1')
      addtask(user.id,"rebuild")
    end
  end

  def app_deatt(user)
  	user.email=current_profile.email
	user.email=user.profile.email if not user.profile.nil?
	user.save!
    tsk = Task.where(:user_id =>user.id, :status =>'attach_domain').first
    if tsk.nil?
      addtask(user.id,"deattach_domain")
      user.update_attribute('domain', nil)
    else
      Task.delete_all({:user_id => user.id, :status => 'attach_domain'})
    end
  end

  def app_attach(domain,user)
  	user.email=current_profile.email
	user.email=user.profile.email if not user.profile.nil?
	user.save!
    if domain=~/\A[A-Z0-9-]+\.[A-Z0-9-]{0,3}\.?[A-Z]{2,4}\Z/i
      addtask(user.id,"attach_domain",domain)
      user.update_attribute('domain', domain)
    end
    user.update_attribute('status', '2')
  end

  def addtask(id,statuss,domain='')
	task=Task.where(:user_id=>id,:status=>statuss).first
	return true if not task.nil? or User.find(id).status=="removed"
	if statuss=="remove_user"
		user=User.find(id)
		user.domain=nil
		user.save!
	end
    task=Task.new()
    task.user_id = id
    task.status = statuss
    task.domain = domain
    task.save!
  end
 
  def findtasks(user)
    @tasks = Task.where(:user_id =>p.users.map{|u|u.id})
    legend = {'create'=>'Создание сайта','rebuild'=>'Пересоздание сайта','attach_domain'=>'Присоединение домена','deattach_domain'=>'Отсоединение домена'}
    @tasks.each do |t|
      t.status = legend[t.status]
    end
  end
  
  def ox_power(user=current_profile)
	return 0.0 if user.ox_rank < 1.0
	max = 0.0
	max = Profile.maximum('ox_rank').to_f
	if max > 0
		return user.ox_rank/max  + 0.001
	else
		return 1.0
	end
  end
  
	def only_post
		return render :text=>'err' if not profile_signed_in? or not request.post?
	end
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password
end
