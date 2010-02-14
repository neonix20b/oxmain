# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include TagsHelper

  def tte(text, mode=[:filter_html])
    return RedCloth.new(text, mode).to_html
  end

  def show_time(time)
    return Russian::strftime(time.utc, "%d %B %Y, %H:%M UTC")
  end
  
  def profile_link(user=current_user,link=true)
    ret = user.login
    ret = user.show_name if not user.show_name.nil?
    return h(ret) if link==false
    return link_to(h(ret),{:controller=>'account',:action=>'profile',:id=>user.login})
  end

  def user_site_link(user=current_user,link=true)
    ret = user.login + '.oxnull.net'
    ret = user.domain if not user.domain.nil? and user.domain.size > 3
    return h(ret) if link==false
    return link_to(h(ret),"http://"+h(ret))
  end

  def can_edit?(obj=nil)
    return false if not logged_in?
    return true if obj.nil?
    return false if obj.respond_to?('status') and (obj.status!='open' or not obj.worker_id.nil? or obj.user_id != current_user.id)
    return true if obj.user_id == current_user.id
    #return true if current_user.right=='admin'
    return false
  end

  def can_edit_blog?
    return false if not logged_in?
    return true if current_user.right=='admin'
    return false
  end

  def ox_rank_field(obj,label=nil,wtf=nil, action='ox_rank_helper')
    ox_rank = obj.ox_rank
    count = ox_rank
    count = obj.count.to_i.to_s if obj.respond_to?('count')
    color = ' rgb(204, 0, 0)' if count.to_i < 0
    color = 'rgb(51, 153, 0)' if count.to_i > 0
    color = 'white' if count.to_i == 0
    count = '+'+count if count.to_i > 0
    span_id="ox_rank_#{obj.class.name}_#{obj.id.to_s}"
    if label.nil? and logged_in? and obj.user_id!=current_user.id
      minus_txt = '-'
      plus_txt = '+'
      minus = rlink(minus_txt,{:controller=>'main', :action=>action, :do=>'minus', :obj=>obj.class.name, :id => obj.id, :span_id=>span_id},'ox_rank_helper_div','post')
      plus = rlink(plus_txt,{:controller=>'main', :action=>action, :do=>'plus', :obj=>obj.class.name, :id => obj.id, :span_id=>span_id},'ox_rank_helper_div','post')
      return "<span id='#{span_id}'>#{minus} <strong style='color:#{color};'>#{count}</strong> #{plus}</span>"
    elsif logged_in? and obj.user_id!=current_user.id
      return rlink(label,{:controller=>'main', :action=>action, :do=>wtf, :obj=>obj.class.name, :id => obj.id, :span_id=>span_id},span_id,'post')
    else
      return "<strong style='color:#{color};'>#{count}</strong>"
    end
  end

  def author(post)
    if post.user.nil?
      return "Анонимус"
    else
      return profile_link(post.user)
    end
  end

  def help_button(link)
    "<a href='http://wiki.oxnull.net/index.php/#{link}' target='_blank'>#{image_tag("question.png")}</a>"
  end

  def true_button(text)

		#"<!--<span style='float: left;clear:right;white-space: nowrap;'>#{image_tag('btn_left.png')}</span>-->
		#<!--<span class='btn_middle'>#{text}</span>-->
    #<!--<span style='float: right;white-space: nowrap;'>#{image_tag('btn_right.png')}</span>-->"
    "<button type='submit' style='padding: 0px;cursor: pointer;background-color:transparent;border-width: 0;'>
      <span class='btn_middle'>#{text}</span>
     </button>"
  end
  
  def shorthead(name)
    "<div id='oxheadshort'><h5>#{name}</h5></div><br/>" if params[:format].nil?
  end

  def longthead(name)
    "<div id='oxheadlong'>#{name}</div><br/>" if params[:format].nil?
  end

  def plus_minus(math,service_id,q_size,div)
    text = 'минус'
    text = 'плюс' if(math=='plus')
    text = '[ok]' if(math=='accept')
    text='[-]' if text == 'минус'
    text='[+]' if text == 'плюс'
    return text if q_size.to_s.to_i < 1 and math=='minus'#'минус'
    return rlink(text, {:controller=> 'wm', :action => "math_service", :id => service_id,:math=>math, :div => div, :layer=>params[:layer]}, div)
  end

  def spiner
    image_tag("spinner.gif",
      :align => "middle",
      :border => 0,
      :id => "spinner",
      :size => "16x16",
      :style =>"display: none;" )
  end

  def service_switch(mydo,service_id,div)
    text='Работает'
    text='Выкл' if mydo=='add'
    rlink(text,{:controller=> 'wm', :action => "add_service", :id => service_id, :div =>div, :mydo=>mydo, :layer=>params[:layer]},div)
  end

  def rlink(text, url, div='main_div',method='get')
    link_to_remote text,
      :update => div,
      :before => "Element.show('spinner')",
      :success => "Element.hide('spinner')",
      :method => method,
      :url => url
  end

  def easybutton(txt,form,url,div='main_div')
    link_to_remote txt,
      :update => div,
      :url => url,
      :submit => form
  end

  # Локализация сообщения об ошибках
  def error_messages_for(*params)
    options = params.extract_options!.symbolize_keys
    if object = options.delete(:object)
      objects = [object].flatten
    else
      objects = params.collect {|object_name| instance_variable_get("@#{object_name}") }.compact
    end
    count   = objects.inject(0) {|sum, object| sum + object.errors.count }
    unless count.zero?
      html = {}
      [:id, :class].each do |key|
        if options.include?(key)
          value = options[key]
          html[key] = value unless value.blank?
        else
          html[key] = 'errorExplanation'
        end
      end
      options[:object_name] ||= params.first
      errors = ""
      if count == 1
        errors = "произошла одна ошибка"
      else
        if count < 4
          errors = "произошло #{count} ошибки"
        else
          errors = "произошло #{count} ошибок"
        end
      end
      options[:header_message] = "Во время сохранения #{errors}" unless options.include?(:header_message)
      options[:message] ||= 'Неверно заполнены следующие поля:' unless options.include?(:message)
      error_messages = objects.map {|object| object.errors.full_messages.map {|msg| content_tag(:li, msg) } }

      contents = ''
      contents << content_tag(options[:header_tag] || :h2, options[:header_message]) unless options[:header_message].blank?
      contents << content_tag(:p, options[:message]) unless options[:message].blank?
      contents << content_tag(:ul, error_messages)

      content_tag(:div, contents, html)
    else
      ''
    end
  end
end
