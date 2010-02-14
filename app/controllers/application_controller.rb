require 'digest/md5' if RUBY_PLATFORM.downcase.include?("linux")
require 'syslog' if RUBY_PLATFORM.downcase.include?("linux")
require 'redcloth'
require 'xmlrpc/client' if RUBY_PLATFORM.downcase.include?("linux")
require 'net/http'

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  require 'helpers/application_helper'
  include ApplicationHelper
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery #:secret => 'f7c15baf4ab5a0e89d552d9b49e0ff95'
  def default_url_options(options=nil)
    { :format => 'html' }
  end
  private

  
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
  
  def service_prerender
    server = XMLRPC::Client.new2("http://89.208.146.80:1979")
    @service_pay = Array.new()
    @service_free = Array.new()
    @discription = server.call("service_bridge",'service_list',1,1,1)
    @discription.each do |d|
      #d[0]=title
      #d[1]=id
      #d[2]=description
      #d[3]=cost
      #@service_pay[-1] = d
      d[4]=server.call("service_bridge",'service_stat', current_user.id.to_s, d[1].to_s,1)
      if d[4]=='0'
        d[5]='add'
      else
        d[5]='del'
      end
      session[d[1].to_s] = d[4]
      session[:price] = Hash.new if session[:price].nil?
      session[:price][d[1].to_s] = d[3].to_s.to_i
    end
    current_user.money = server.call("get_balance", current_user.id)
    current_user.save!
  end
  
  def app_rebuild(user=current_user)
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

  def app_deatt(user=current_user)
    tsk = Task.find(:first, :conditions =>{:user_id =>user.id, :status =>'attach_domain'})
    if tsk.nil?
      addtask(user.id,"deattach_domain")
      user.update_attribute('domain', '')
    else
      Task.delete_all({:user_id => user.id, :status => 'attach_domain'})
    end
  end

  def app_attach(domain,user=current_user)
    if domain=~/\A[A-Z0-9-]+\.[A-Z0-9-]{0,3}\.?[A-Z]{2,4}\Z/i
      addtask(user.id,"attach_domain",domain)
      user.update_attribute('domain', domain)
    end
    user.update_attribute('status', '2')
  end

  def addtask(id,status,domain='')
    task=Task.new()
    task.user_id = id
    task.status = status
    task.domain = domain
    task.save!
  end

  def get_my_site(user=current_user)
    begin
      @invites = Invite.find(:all,:conditions =>{:user_id => user.id})
      inv = Invite.find(:first,:conditions =>{:invited_user => user.id})
      if inv.nil?
        @master = 'oxnull.net'
      else
        inv = User.find(inv.user_id)
        @master = inv.login + '.oxnull.net'
        @master = inv.domain if inv.domain
      end
      server = XMLRPC::Client.new2("http://89.208.146.80:1979")
      (@disk_current_size,@disk_max_size,@mysql_current_size,@mysql_max_size) = server.call("user_quotas", user.id)
      t = server.call("last_update", user.id)
      @last_upd = t.to_datetime.strftime("%d.%m.%Y в %H:%M")
      #@last_upd=@last_upd.to_date.to_s
      @disk_current_size = @disk_current_size.to_i
      @disk_max_size = @disk_max_size.to_i
      @mysql_current_size = @mysql_current_size.to_i
      @mysql_max_size = @mysql_max_size.to_i
    rescue Exception=>e
      @disk_current_size = 0
      @disk_max_size = 300
      @mysql_current_size = 0
      @mysql_max_size = 100
      @last_upd = 'Не известно'
      Syslog.open('oxmaind')
      Syslog.crit("Get qoutas error: #{$!}")
      Syslog.close
    end
  end
  
  def findtasks(user=current_user)
    @tasks = Task.find(:all,:conditions => {:user_id =>user.id})
    legend = {'create'=>'Создание сайта','rebuild'=>'Пересоздание сайта','attach_domain'=>'Присоединение домена','deattach_domain'=>'Отсоединение домена'}
    if user.login == 'neonix'
      @tasks = Task.find(:all)
      @tasks.each do |t|
        t.status = t.user_id.to_s + ' ' + legend[t.status]
      end
    else
      @tasks.each do |t|
        t.status = legend[t.status]
      end
    end
  end
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password
end
