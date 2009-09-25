require 'digest/md5'
require 'syslog'
class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery #:secret => 'f7c15baf4ab5a0e89d552d9b49e0ff95'

  private
  def app_rebuild(user)
    if user.status =='removed'
      user.update_attribute('status', '0')
    else
      user.update_attribute('status', '1')
      addtask(user.id,"rebuild")
    end
  end

  def app_deatt(user)
    tsk = Task.find(:first, :conditions =>{:user_id =>user.id, :status =>'attach_domain'})
    if tsk.nil?
      addtask(user.id,"deattach_domain")
      user.update_attribute('domain', '')
    else
      Task.delete_all({:user_id => user.id, :status => 'attach_domain'})
    end
  end

  def app_attach(domain,user)
    addtask(user.id,"attach_domain",domain)if domain=~/\A[A-Z0-9-]+\.[A-Z0-9-]{0,3}\.?[A-Z]{2,4}\Z/i
    user.update_attribute('domain', domain) if domain=~/\A[A-Z0-9-]+\.[A-Z0-9-]{0,3}\.?[A-Z]{2,4}\Z/i
    user.update_attribute('status', '2')
  end

  def addtask(id,status,domain='')
    task=Task.new()
    task.user_id = id
    task.status = status
    task.domain = domain
    task.save!
  end

  def get_my_site(user)
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
  
  def findtasks(user)
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
