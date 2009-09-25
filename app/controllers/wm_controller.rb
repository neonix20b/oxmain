require 'xmlrpc/client'
require 'syslog'
require 'digest/md5'
class WmController < ApplicationController
  include AuthenticatedSystem
  before_filter :login_from_cookie, :except => [:ahuetdaitedve, :success, :fail]
  protect_from_forgery :except => [:ahuetdaitedve, :success, :fail] 
  def ahuetdaitedve
    if User.exists?(params[:oxid])

      user = User.find(params[:oxid])
      money = (params[:LMI_PAYMENT_AMOUNT]).to_f# + user.money
      domain = user.login+'.oxnull.net'
      domain = user.domain if not user.domain.nil? and user.domain.size > 3
      
      ourhash = params[:LMI_PAYEE_PURSE]+params[:LMI_PAYMENT_AMOUNT]+params[:LMI_PAYMENT_NO]+params[:LMI_MODE]+params[:LMI_SYS_INVS_NO]+params[:LMI_SYS_TRANS_NO]+params[:LMI_SYS_TRANS_DATE]+'tu4gou8aihiquoo2aisied8kieth7Iez1vo8xaeHoo6eenguvu'+params[:LMI_PAYER_PURSE]+params[:LMI_PAYER_WM]
      ourhash = (Digest::MD5.hexdigest(ourhash)).upcase

      if(ourhash == params[:LMI_HASH])
        Syslog.open('oxmaind')
        Syslog.crit("WEBMONEY add #{money.to_s}wmr to id=#{params[:oxid]}(#{domain}). WMID=#{params[:LMI_PAYER_WM]} LMI_SYS_TRANS_NO=#{params[:LMI_SYS_TRANS_NO]}")
        Syslog.close

        server = XMLRPC::Client.new2("http://89.208.146.80:1979")
        server.call("add_balance",user.id,money)
        server = XMLRPC::Client.new2("http://89.208.146.83:1979")
        server.call("register_payment",domain, money.to_s )
        
      else
        Syslog.open('oxmaind')
        Syslog.crit("WEBMONEY add #{money.to_s}wmr to id=#{params[:oxid]}(#{domain}). WMID=#{params[:LMI_PAYER_WM]}")
        Syslog.crit("BAD Hash!!! our = #{ourhash} but wm=#{params[:LMI_HASH]}")
        Syslog.close
      end
      
    else
      #render :text => 'ok'
      #redirect_to :action => 'success'
    end
    render :action => 'success'
  end

  def index
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
    render(:layout => 'mainlayer') if request.xhr?
  end

  def add_service
    server = XMLRPC::Client.new2("http://89.208.146.80:1979")
    if params[:mydo]=='add'
      server.call("service_bridge",'service_add', current_user.id.to_s, params[:id],'1')
      session[params[:id].to_s] = 1
      params[:mydo]='del'
    else
      server.call("service_bridge",'service_del', current_user.id.to_s, params[:id],'1')
      session[params[:id].to_s] = 0
      params[:mydo]='add'
    end
    @service_size = session[params[:id].to_s]
    current_user.money = server.call("get_balance", current_user.id)
    render :layout => false
  end

  def math_service
    #
    #@service_size=server.call("service_bridge",'service_stat', current_user.id.to_s, params[:id],1)
    #@service_size = @service_size.to_s.to_i
    @service_size = 0
    ss = '0'
    ss = params[:id].to_s if params[:id]=='0' or params[:id]=='1' or params[:id]=='2'
    @service_size = session[ss].to_s.to_i if not session[ss].nil? and session[ss].size > 0
    @service_size += 1 if(params[:math]=='plus')
    @service_size -= 1 if(params[:math]=='minus')
    if(params[:math]=='accept')
      server = XMLRPC::Client.new2("http://89.208.146.80:1979")
      old_size=server.call("service_bridge",'service_stat', current_user.id.to_s, params[:id],1)
      old_size = old_size.to_s.to_i
      if(old_size > 0)
        server.call("service_bridge",'service_del', current_user.id.to_s, params[:id],'1')
      end
      if(@service_size >0)
        server.call("service_bridge",'service_add', current_user.id.to_s, params[:id],@service_size)
      end
      current_user.money = server.call("get_balance", current_user.id)
    end
    session[ss] = @service_size.to_s
    #current_user.money = server.call("get_balance", current_user.id)
    render :layout => false
  end

  def pay
    render(:layout => 'mainlayer') if request.xhr?
  end

  def success
    redirect_to("http://oxnull.net/#pay=ok")
  end

  def fail
    
  end
end
