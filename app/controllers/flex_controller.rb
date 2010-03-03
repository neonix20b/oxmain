require "base64"
require 'xmlrpc/client'
class FlexController < ApplicationController
  include AuthenticatedSystem
  before_filter :login_from_cookie
  protect_from_forgery :except => [:adept_def, :service_change, :dotask, :password_change, :my_site, :service_list, :tag_control]
  #FIXME удалить строчку ниже когда станем популярными :)
  before_filter :find_last, :only =>[:my_site]

  def sms_phone
    #country = "Россия"
    if params[:country] and params[:op_name]
      #country = params[:country]
      #выдать список номеров с ценами
      @phones = Smsbil.find(:all,
        :conditions=>{:country=>params[:country], :op_name =>params[:op_name]},
        :select => 'country,op_name,phone,price,income,id', :order=> "price")
    elsif params[:country]
      #показать список операторов
      @operators = Smsbil.find(:all,
        :conditions=>['country LIKE ?',params[:country]+'%'],
        :select => 'DISTINCT op_name, op_id', :order=> "op_name")
    else
      #поиск всех стран
      @countries = Smsbil.find(:all, :select => 'DISTINCT country', :order=> "country")
    end
    render(:layout => 'mainlayer') if request.xhr?
  end
  
  def tag_control
    return unless request.post?
    #p.tag_list.add("Great", "Awful")
    #p.tag_list.remove("Funny")
    if(params[:id]=='set_tags')
      if current_user.right != 'user' or current_user.id.to_s == params[:user_id].to_s
        user = User.find(params[:user_id])
        params[:tags] = '' if(params[:tags].to_s.split(/,/).size > 5 )
        params[:tags] = '' if(params[:tags].to_s.index(",") == nil )
        user.tag_list = params[:tags]
        user.save!
        render :text => params[:tags].length
      else
        render :text =>'пнх'
      end
    elsif(params[:id]=='find')
      @users = User.find_tagged_with(params[:tags])
      #render :text => @users.to_xml
    elsif(params[:id]=='list')
      @tags = User.tag_counts(:order => "name")
      render :text => @tags.to_xml
    end
  end
  
  def dotask
    return unless request.post?
    user=my_right()
    params[:id] = params[:task]
    if(params[:id]=='rebuild')
      params[:wtf]='phpbb' if params[:wtf]=='smf'
      user.update_attribute('wtf', params[:wtf])
      app_rebuild(user)
      render :text=>'ok '+params[:wtf]
    elsif (params[:id]=='deattach')
      app_deatt(user)
      render :text=>'ok'

    elsif (params[:id]=='attach')
      app_attach(params[:domain],user)
      render :text=>'ok'

    elsif (params[:id]=='newinvite')
      inv = Invite.new()
      inv.user_id = user.id
      inv.invite_string = (Digest::MD5.hexdigest(Time.now.to_s)).upcase
      inv.save!
      render :text=>'oxnull.net/#hello='+inv.invite_string
      
    elsif (params[:id]=='delinvite')
      Invite.delete_all({:user_id => user.id, :invite_string => params[:invite]})
      render :text=>'ok'
      
    else
      render :text=>'omg'
    end

  end

  def my_site
    return unless request.post?
    @user=my_right()
    get_my_site(@user)
  end

  def service_list
    return unless request.post?
    @user=my_right()
    server = XMLRPC::Client.new2("http://89.208.146.80:1979")
    @discription = server.call("service_bridge",'service_list',1,1,1)
    @discription.each do |d|
      d[4]=server.call("service_bridge",'service_stat', @user.id.to_s, d[1].to_s,1)
    end
    @user.money = server.call("get_balance", @user.id)
  end

  def password_change
    return unless request.post?
    if current_user.right == 'admin' and params[:user_id]
      ss = User.find(params[:user_id])
    else
      ss=User.authenticate(current_user.login, Base64.decode64(params[:od]))
    end
    return render :text => 'error' if ss.nil?
    ss.password=Base64.decode64(params[:sd])
    ss.password_confirmation=Base64.decode64(params[:sd])
    ss.save!
    render :text=>'ok'
  end

  def service_change
    return unless request.post?
    @user=my_right()
    server = XMLRPC::Client.new2("http://89.208.146.80:1979")
    if(params[:oldsize].to_i > 0)
      server.call("service_bridge",'service_del', @user.id.to_s, params[:serviceid],'1')
    end
    if(params[:size].to_i > 0)
      server.call("service_bridge",'service_add', @user.id.to_s, params[:serviceid],params[:size])
    end
    @user.money = server.call("get_balance", @user.id)
    render :text => @user.money
  end

  def adept_def
    return unless request.post? and current_user.right != 'user'
    @users = User.find(:all,:conditions =>['id LIKE ? or login LIKE ? or domain LIKE ? or email LIKE ?','%'+params[:search]+'%', '%'+params[:search]+'%', '%'+params[:search]+'%','%'+params[:search]+'%'], :order=> "login")
  end

  private
  def my_right
    user = User.new()
    if current_user.right == 'admin' and params[:user_id]
      user = User.find(params[:user_id])
    else
      user = current_user
    end
    return user
  end
end


