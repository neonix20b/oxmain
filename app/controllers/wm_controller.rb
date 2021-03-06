class WmController < ApplicationController
  skip_filter :authenticate_profile!, :only => [:ahuetdaitedve, :success, :fail, :smspay, :smsimport]
  protect_from_forgery :except => [:ahuetdaitedve, :success, :fail, :smspay, :smsimport] 
  
  def smsimport
    country="Россия"
    file_name='tariffs_service_56443.csv'
    if File.exist?(file_name)
      File.open(file_name, 'r'){ |file|
        str = file.read
        Smsbil.delete_all
        str.split("\n").each do |tmp|
          country=$1 if tmp=~/\A(.+?);\Z/
          if tmp=~/\A(\d+);(\d+);(.+?);([\d,]+);(\w+);([\d,]+);(\w+)\Z/
            #	 $1=1121;$2=107;TELE2;$4=1,43;$5=rur;  $6=3; $7=rur
            #Номер;ID оператора;Оператор;Доход партнера;Валюта партнера;Цена SMS для абонента;Валюта абонента
            sms = Smsbil.new()
            sms.country = country
            sms.phone = $1
            sms.op_id = $2
            sms.op_name = $3
            sms.income = $4
            sms.price = $6+$7
            sms.income.gsub!(/[,]/,'.')
            sms.price.gsub!(/[,]/,'.')
            sms.income=sms.income.to_f*1.6
            sms.save!
          end
        end
      }
      File.delete(file_name)
      @string = "файл удален"
    end
    @smsbils = Smsbil.find(:all, :order => "country, op_name")
  end

  def take_sms
    @sms = Smsbil.find(params[:id])
    render(:layout => 'mainlayer') if request.xhr?
  end
  
  def smspay
    #  <hash>
    #  <skey>5e26c66707624a9eeb8efa794d10c97a</skey>
    #  <msg>ox985</msg>
    #  <smsid>1252037077</smsid>
    #  <cost>4.61134054658</cost>
    #  <date>2009-10-12 16:59:19</date>
    #  <country-id>45909</country-id>
    #  <operator>operator</operator>
    #  <operator-id>299</operator-id>
    #  <action>smspay</action>
    #  <try>1</try>
    #  <num>1121</num>
    #  <controller>wm</controller>
    #  <sign>7de33232637c3617ab5fe153339f1fa7</sign>
    #  <test>1</test>
    #  <cost-rur>170.18199</cost-rur>
    #  <user-id>71111111111</user-id>
    #  <ran>5</ran>
    #  <msg-trans>ox985</msg-trans>
    #</hash>
    resp = "smsid:#{params[:smsid]}\n"
    resp += "status:reply\n\n"
	
    if ((Digest::MD5.hexdigest(my_conf('sms_key',"sms-pay-secret-key"))).upcase==params[:skey].upcase) and params[:msg]=~/.*?(\d+)/
      if(User.exists?($1))
        user = User.find($1)
        money = (params[:cost_rur]).to_s.to_f
        domain = user.login+'.oxnull.net'
        domain = user.domain if not user.domain.nil? and user.domain.size > 3
        Syslog.open('oxmaind')
        Syslog.crit("WEBMONEY SMS add #{money.to_s}р to id=#{params[:msg]}(#{domain}). date=#{params[:date]} sign=#{params[:sign]} smsid=#{params[:smsid]}")
        Syslog.close

        server = XMLRPC::Client.new2("http://89.208.146.80:1979")
        server.call("add_balance",user.id,money*1.6)
        #server = XMLRPC::Client.new2("http://89.208.146.83:1979")
        #server.call("register_payment",domain, money.to_s )
        resp += "#{params[:smsid]}[#{domain}]: Спасибо (http://oxnull.net)\n"

        #user.money = server.call("get_balance", current_profile.id)
        user.save!
      else
        Syslog.open('oxmaind')
        Syslog.crit("WEBMONEY SMS error #{params['cost-rur'].to_s}p to id=#{params[:msg]}. date=#{params[:date]} sign=#{params[:sign]} smsid=#{params[:smsid]}")
        Syslog.close
        resp += "#{params[:smsid]}: Не верно указан oxID (http://oxnull.net)\n"
      end
    else
      Syslog.open('oxmaind')
      Syslog.crit("WEBMONEY SMS error HASH #{params['cost-rur'].to_s}p to id=#{params[:msg]}. date=#{params[:date]} sign=#{params[:sign]} smsid=#{params[:smsid]}")
      Syslog.close
      resp += "#{params[:smsid]}: Непонятная ошибка с хешем (http://oxnull.net)\n"
    end
    render :text => resp
  end
  
  def ahuetdaitedve
    if User.exists?(params[:oxid])
      user = User.find(params[:oxid])
      money = (params[:LMI_PAYMENT_AMOUNT]).to_f# + user.money
      domain = user.login+'.oxnull.net'
      domain = user.domain if not user.domain.nil? and user.domain.size > 3
      
      ourhash = params[:LMI_PAYEE_PURSE]+params[:LMI_PAYMENT_AMOUNT]+params[:LMI_PAYMENT_NO]+params[:LMI_MODE]+params[:LMI_SYS_INVS_NO]+params[:LMI_SYS_TRANS_NO]+params[:LMI_SYS_TRANS_DATE]+my_conf('wm_key','tu4gou8aihiquoo2aisied8kieth7Iez1vo8xaeHoo6eenguvu')+params[:LMI_PAYER_PURSE]+params[:LMI_PAYER_WM]
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
      user.money = server.call("get_balance", current_profile.id)
      user.save!
    else
      #render :text => 'ok'
      #redirect_to :action => 'success'
    end
    render :action => 'success'
  end

  def index
    service_prerender()
    render(:layout => 'mainlayer') if request.xhr?
  end

  def add_service
    server = XMLRPC::Client.new2("http://89.208.146.80:1979")
    if params[:mydo]=='add'
      server.call("service_bridge",'service_add', current_profile.id.to_s, params[:id],'1')
      session[params[:id].to_s] = 1
      params[:mydo]='del'
    else
      server.call("service_bridge",'service_del', current_profile.id.to_s, params[:id],'1')
      session[params[:id].to_s] = 0
      params[:mydo]='add'
    end
    @service_size = session[params[:id].to_s]
    current_profile.money = server.call("get_balance", current_profile.id)
    current_profile.save!
    get_my_site(current_profile)
    render :layout => false
  end

  def math_service
    #
    #@service_size=server.call("service_bridge",'service_stat', current_profile.id.to_s, params[:id],1)
    #@service_size = @service_size.to_s.to_i
    @service_size = 0
    ss = '0'
    ss = params[:id].to_s if params[:id]=='0' or params[:id]=='1' or params[:id]=='2'
    @service_size = session[ss].to_s.to_i if not session[ss].nil? and session[ss].size > 0
    @service_size += 1 if(params[:math]=='plus')
    @service_size -= 1 if(params[:math]=='minus')
    if(params[:math]=='accept')
      server = XMLRPC::Client.new2("http://89.208.146.80:1979")
      old_size=server.call("service_bridge",'service_stat', current_profile.id.to_s, params[:id],1)
      old_size = old_size.to_s.to_i
      if(old_size > 0)
        server.call("service_bridge",'service_del', current_profile.id.to_s, params[:id],'1')
      end
      if(@service_size >0)
        server.call("service_bridge",'service_add', current_profile.id.to_s, params[:id],@service_size)
      end
      current_profile.money = server.call("get_balance", current_profile.id)
      current_profile.save!
      get_my_site(current_profile)
    end
    session[ss] = @service_size.to_s
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
