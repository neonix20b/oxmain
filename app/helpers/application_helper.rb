# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include TagsHelper
  
  def logged_in?
	return profile_signed_in?
  end
  
  def choose_design
	if profile_signed_in? and not current_profile.design.nil? and File.exists?(Rails.root.to_s+'/public/stylesheets/design/'+current_profile.design+".css")
		return stylesheet_link_tag 'design/'+ current_profile.design
	else
		#designs = (Dir.new(Rails.root.to_s+'/public/stylesheets/design/').entries - [".", ".."]).map{|d| d[0..-5]}
		#return stylesheet_link_tag 'design/'+ designs[rand(designs.size)]
		return stylesheet_link_tag 'design/ox_violet'
	end
  end
  
    def get_my_site(user)
    begin
#      @invites = Invite.where(:user_id => user.id)
#      inv = Invite.where(:invited_user => user.id).first
#      if inv.nil?
#        @master = 'oxnull.net'
#      else
#        inv = User.find(inv.user_id)
#        @master = inv.login + '.oxnull.net'
#        @master = inv.domain if inv.domain
#      end
      server = XMLRPC::Client.new2("http://89.208.146.80:1979")
      (@disk_current_size,@disk_max_size,@mysql_current_size,@mysql_max_size) = server.call("user_quotas", user.id)
#      t = server.call("last_update", user.id)
#      @last_upd = t.to_datetime.strftime("%d.%m.%Y в %H:%M")
#      #@last_upd=@last_upd.to_date.to_s
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
  
	def oxservices
		return Oxservice.order("id")
	end
	def s_qq(user,id_in_server)
		return session['ox'+user.id.to_s][id_in_server.to_s]['qtt'].to_s.to_i
	end
	def s_sw(user,id_in_server)
		return session['ox'+user.id.to_s][id_in_server.to_s]['sw'].to_s.to_i
	end
  
  def set_page_title(title)
    return javascript_tag("document.title = '#{title}'");
  end
  
  def kick_profile(prof)
	prof=Profile.find(prof)
	return rlink("Заблокировать (удалить комменты за день)",{:controller=>'oxlib',:action=>'kick_profile',:id=>prof.id},'profile_control','post', "Точно заблокировать пользователя?")
  end
  
  def invite_link(invite)
	return "" if invite.nil? or not Invite.exists?(invite)
	invite = Invite.find(invite)
	color='inherit'
	color='green' if invite.status=='ok'
	color='red' if invite.status=='revoke'
	color='black' if not invite.invited_user.nil? and User.find(invite.invited_user).status=='removed'
	return link_to("#{invite.id}: #{invite.title}",{:controller=>'invite',:action=>'show',:id=>invite.id},:style=>"color:#{color};")
  end

  def show_last_url(user)
	url=user.last_url
	text=url
	if(url=="/")
		text = "Ищет новое на главной" 
	elsif(url.scan(/\/users\/live/).size != 0)
		text = "Любопытствует в песочнице" 
	elsif(url=="forget_close")
		return "Сидит с открытой вкладкой браузера" 
	elsif(url=="/main/index.html" or url=="/main/")
		text = "Управляет сайтом" 
	elsif(url.scan(/pm\/chat\//).size != 0)
		if user.last_pm_input.size > 10
			return "Пишет личное сообщение" 
		else
			return "Читает личные сообщения" 
		end
	elsif (url.scan(/\/blogs\/\d+\/posts\/(\d+)\./).size != 0)
		post_id=url.scan(/\/blogs\/\d+\/posts\/(\d+)/).first.first.to_i
		if Post.exists?(post_id)
			if not user.last_comment_input.nil? and user.last_comment_input.size > 10
				text = "Пишет комментарий в пост: "+Post.find(post_id).title
			else
				text = "Читает пост: "+Post.find(post_id).title
			end
		end
	elsif (url.scan(/\/profile\/(.+)\./).size != 0)
		text = "Просматривает профиль пользователя " + url.scan(/\/profile\/(.+)\./).first.first
	elsif (url.scan(/\/blogs\/(\d+)\/posts\/new/).size != 0)
		blog=Blog.find(url.scan(/\/blogs\/(\d+)\/posts\/new/).first.first.to_i)
		text = "Создает статью в блоге " + blog.name
		url = blog_posts_path(blog)
	elsif (url.scan(/\/blogs\/\d+\/posts\/(\d+)\/edit/).size != 0)
		post=Post.find(url.scan(/\/blogs\/\d+\/posts\/(\d+)\/edit/).first.first.to_i)
		text = "Редактирует статью: " + post.title
		url = blog_post_path(post.blog_id, post)
	elsif (url.scan(/supports/).size != 0)
		text = "Работает с заявками"
		url = supports_path
	else
		text = "Просматривает "+url
	end
	link_to(text,url)
  end
  
  def delete_profile(profile)
	if current_profile.admin?
		return rlink("Удалить этот аккаунт", {:controller=>'oxlib',:action=>'delete_profile',:id=>profile.id},'profile_table','post', "Точно удалить пользователя?")
	else
		return ""
	end
  end
  
  def tte(text, mode=[:filter_html])
	return "" if text.nil? or text==""
    ret = RedCloth.new(text, mode).to_html
	ret.gsub!(/http:\/\/www.youtube.com\/v\/([\w\-]+)[;\&\w=0-9]*/){ youtube_tag($1) }
    ret.gsub!(/http:\/\/www.youtube.com\/watch\?v=([\w\-]+)[;\&\w=0-9]*/){ youtube_tag($1) }
	ret.gsub!(/\s(http:\/\/[~\w\d\-\.\/;&#\?]+)/, ' '+RedCloth.new('"\1":\1', [:lite_mode]).to_html+' ')
	return ret
  end
  
  def ya_speller(spell_text,spell=true)
	if spell and spell_text[-6..-1].scan(/[\.,\?!:;\)]<\/p>/).size != 0
		res = Net::HTTP.post_form(URI.parse('http://speller.yandex.net/services/spellservice/checkText'),
								  {'text'=>spell_text,:format=>'html',:options=>1+2+4+8})
		res.body.to_s.gsub(/<word>(.+?)<\/word>(<s>(.+?)<\/s>)?/){ spell_text.gsub!($1,"<s style='color:red;'>#{$1}</s>[#{$3}]") }
	end
    return spell_text
  end
  
  def right_switch(user)
	return "" if not current_profile.admin?
	return rlink('Сделать адептом', {:controller=>'users',:action=>'right_switcher', :id => user.id}) if not user.adept?
	return rlink('Сделать юзером', {:controller=>'users',:action=>'right_switcher', :id => user.id})
  end
  
  def remove_user_sw(user)
	#return render :text=>'Сделать кнопку бана'
	if current_profile.adept? or user.profile==current_profile
		ret = "<div id='remove_#{user.id.to_s}'"
		ret +=link_to_remote "[x] Удалить",
				:url =>{:controller=>'users',:action=>'vote_delete',:id=>user.id},
				:confirm=>"Точно отправить "+user_site_link(user,false)+" на удаление?",
				:method => 'POST',
				:update => 'remove_'+user.id.to_s
		ret += "</div>"
		return ret
	else
		return ""
	end
  end

  def youtube_tag(tag)
   "<object type='application/x-shockwave-flash' data='http://www.youtube.com/v/#{tag}' width='425' height='355'>
	<param name='movie' value='http://www.youtube.com/v/#{tag}' />
	<param name='FlashVars' value='playerMode=embedded' />
  </object>"
#	"<iframe class='youtube-player' type='text/html' width='640' height='385' 
#		src='http://www.youtube.com/embed/#{tag}' frameborder='0'>
#	</iframe>"
  end

  def one_news(post,div='div')
    "#{link_to h(post.title),blog_post_path(post.blog_id, post, :anchor => "comment_try")}
    <#{div} style='font-size:xx-small;'>#{post.last_comment}</#{div}>"
  end

  def find_last_posts(user=current_profile,limit=50)
    tmp=[]
    tmp = user.last_posts.split(',') if not user.last_posts.nil?
    #if not Post.exists?(:id=>tmp)
      tmp.each do |post_id|
        tmp -= [post_id] if not Post.exists?(post_id)
      end
    #end
    #ищем все посты у которых дата больше чем последнего просмотра
    blog_ids = []
    blog_ids = user.favorite.split(',') if not user.favorite.nil?
    posts = Post.where("blog_id IN (?) and updated_at > ?",blog_ids, user.last_view)
    posts.each do |post|
      tmp+=[post.id.to_s]
    end
    if not posts.nil? or user.last_view > 1.hour.ago.utc
      tmp=tmp.compact.uniq
      user.last_posts = tmp.join(',')
      user.last_view = Time.now.utc
      user.save!
    end
    return Post.limit(limit).find(tmp)
  end

  def menu_posts
    ret = link_to("Все статьи", blog_posts_path('all'))+' | '
    ret += link_to("Случайные статьи", blog_posts_path('random'))
    if profile_signed_in?
      ret = ret + ' | '+link_to("Избранные блоги", blog_posts_path('favorite'))
      ret = ret + ' | '+link_to("Последние непрочитанные", blog_posts_path('last'))
	  posts=find_last_posts(current_profile)
	  if posts.count>0
		  ret = ret+'('+posts.count.to_s+')'
	  end
    end
    return ret
  end

  def remove_from_last(user=current_profile, post_id=nil)
    tmp=[]
    tmp = user.last_posts.split(',') if not user.last_posts.nil?
    if tmp.include?(post_id.to_s)
      tmp -= [post_id.to_s] if post_id
      tmp=tmp.compact.uniq
      user.last_posts = tmp.join(',')
      user.last_view = Time.now.utc
      user.save!
    end
  end
  
  def chat_link(link_text,msg)
	id = msg.profile_from
	id=msg.profile_to if current_profile.id==id
	return link_to(link_text,{:controller=>'pm',:action=>'chat',:id=>id, :anchor => "end_doc"})
  end
  
	def one_pm(msg,spell=false)
		user = Profile.find(msg.profile_from) 
		ret="<div class='comment_box' id='pm_#{msg.id.to_s}'>
		<div class='comment_head' id='pm_head_#{msg.id.to_s}'>
		  <div style='float:left;'>
			#{profile_link(user)}&nbsp;&nbsp;"
		time_head = show_time(msg.created_at)
		time_head += " → " + show_time(msg.updated_at) if msg.created_at!=msg.updated_at
		ret+=time_head
		ret +="&nbsp;&nbsp;"
		ret +=chat_link("#",msg) if not msg.readed
		ret +="</div>
		  <div style='float:right;' id='pm_status_#{msg.id.to_s}'>"
		ret += "непрочитанное" if not msg.readed
		ret+="</div>
		</div>
		<div>
		  <span class='comment_avatar'>#{image_tag(h(user.avatar), :width=>'50px', :class=>'png')}</span>
		  <div class='comment_tte'>#{ya_speller(tte(msg.post),spell)}</div>
		</div>
	  </div>"
	  return ret
	end
	
	def one_chat(msg)
		user = nil
		user = Profile.find(msg.profile_from) if Profile.exists?(msg.profile_from)
		if current_profile.id == msg.profile_from
			user=nil
			user = Profile.find(msg.profile_to) if Profile.exists?(msg.profile_to)
		end
		ret="<div class='comment_box' id='pm_#{msg.id.to_s}'>
		<div class='comment_head' id='pm_head_#{msg.id.to_s}'>
		  <div style='float:left;'>"
		ret +=	profile_link(user)+"  "
		time_head = show_time(msg.created_at)
		time_head += " → " + show_time(msg.updated_at) if msg.created_at!=msg.updated_at
		ret += chat_link(time_head,msg)
		ret +="&nbsp;&nbsp;"
		ret +=chat_link("#",msg) if not msg.readed
		ret +="</div><div style='float:right;' id='pm_status_#{msg.id.to_s}'>"
		ret += chat_link("непрочитанное",msg) if not msg.readed
		ret += " "
		if not user.nil?
			if msg.profile_to == user.id
				ret += chat_link(image_tag("pm_out.png", :width=>'64px', :class=>'png'),msg)
			else
				ret += chat_link(image_tag("pm_in.png", :width=>'64px', :class=>'png'),msg)
			end
		end
		ret += " "
		ret+="</div>
		</div>
		<div>
		  <span class='comment_avatar'>#{image_tag(h(user.avatar), :style=>'width:50px;', :class=>'png') if not user.nil?}</span>
		  <div class='comment_tte'>#{tte msg.post}</div>
		</div>
	  </div>"
	  return ret
	end

  def one_comment(comment,user,spell=false,root_link=false)
	return "" if comment.nil?
	user = Profile.new if user.nil?
    ret="<div class='comment_box' id='com_#{comment.id.to_s}'>
    <div class='comment_head'>
      <div style='float:left;'>
        #{profile_link(user)}&nbsp;&nbsp;#{show_time(comment.created_at)}&nbsp;&nbsp;"
	ret+=link_to "#", request.request_uri+'#com_'+comment.id.to_s if not spell and not root_link
	ret+=" " + comment_del_field(comment) if not spell
	ret+="</div>"
	ret+="<div style='float:right;'>#{comment_root_link(comment) if root_link} #{ox_rank_field(comment)}</div>" if not spell
	ret+="</div>
			<div>
			<span class='comment_avatar'>#{image_tag(h(user.avatar), :style=>'width:50px;', :class=>'png')}</span>
			<div class='comment_tte'>#{ya_speller(tte(comment.text), spell)}</div>
			</div>
		</div>"
	return ret
  end
  
  def comment_root_link(com)
	if not com.post.nil?
		return link_to("найти", blog_post_url(com.post.blog,com.post, :anchor => "com_#{com.id}")) + " →"
	elsif not com.invite.nil?
		return link_to("найти", url_for(:controller=>'invite',:action=>'show',:id=>com.invite.id, :anchor => "com_#{com.id}")) + " →"
	end
  end
  
  def one_online_comment(comment,url)
    "<div class='comment_box' id='com_#{comment.id.to_s}'>
    <div class='comment_head'>
      <div style='float:left;'>
        #{profile_link(comment.profile)}&nbsp;&nbsp;#{show_time(comment.updated_at)}&nbsp;&nbsp;
      </div>
	  <div style='float:right;'>
        #{link_to("→",url)}&nbsp;&nbsp;
      </div>
    </div>
    <div>
      <span class='comment_avatar'>#{image_tag(h(comment.profile.avatar), :width=>'50px', :class=>'png')}</span>
      <div class='comment_tte'>#{h(comment.text)}</div>
    </div>
  </div>"
  end

  def comment_del_field(comment)
	if profile_signed_in?
		return "" if Poll.exists?(:obj_id=>comment.class.name.to_s+"_"+comment.id.to_s,:profile_id=>current_profile.id)
		return rlink("Удалить",{:controller =>'main',:action =>'comment_work', :id=>comment.id,:do=>'del'},"com_#{comment.id.to_s}") if can_edit?(comment)
		return rlink("Удалить",{:controller =>'oxlib',:action =>'comment_del', :id=>comment.id},"com_#{comment.id.to_s}") if current_profile.adept?
	end
	return ""
  end

  def show_time(time, format="%d %B %Y, %H:%M")
	return "неизвестно" if time.nil?
    return Russian::strftime(time.utc.in_time_zone(session[:gmtoffset].to_i.minutes), format) if not session.nil? and session.has_key?("gmtoffset")
    return Russian::strftime(time.utc, "#{format} UTC")
  end
  
  def profile_link(user=current_profile,link=true)
	return "Анонимус" if user.nil? or user.id.nil?
	ret = ""
	if user.respond_to?("profile_id")
		return "Анонимус" if not Profile.exists?(user.profile_id)
		user=Profile.find(user.profile_id)
	end	
	if user.show_name.nil? or user.show_name==""
		user.created_at=Time.now if user.created_at.nil?
		n=user.email.index("@")
		ret = user.email[0,n]
		ret += "_"+user.id.to_s
		user.show_name = ret
		user.save!
	end
	ret = user.show_name 

    return h(ret) if link==false
    return link_to(h(ret),{:controller=>'account',:action=>'profile',:id=>ret})
  end

  def user_site_link(user,link=true)
	return "Еще не создан" if user.nil?
	user = User.find(user)
	if (user.created_at + 1.days) > Time.now and (not profile_signed_in? or user.profile!=current_profile )
		return "До ссылки #{(user.created_at - Time.now + 1.days).to_i/60 } мин."
	end
    ret = user.oxdomain + '.oxnull.net'
    ret = user.domain if not user.domain.nil? and user.domain.size > 3
	if user.status=="removed"
		link=false 
		ret = user.oxdomain + '.oxnull.net'
		ret += " (Удален)"
	end
    return h(ret) if link==false
    return link_to(h(ret),"http://"+h(ret),:onclick=>"window.open(this.href);return false;")
  end

  def can_edit?(obj=nil,profile=current_profile)
    return false if profile.nil?
    return true if obj.nil?
    return false if obj.respond_to?('status') and (obj.status!='open' or not obj.worker_id.nil? or obj.profile_id != profile.id)
    return false if obj.class.name=='Comment' and obj.created_at.utc < 2.minutes.ago.utc and not profile.admin?
    return true if obj.profile_id == profile.id or profile.admin?
    return false
  end

  def can_edit_blog?(profile=current_profile)
    return false if profile.nil?
    return true if profile.admin?
    return false
  end
  
  def vote_helper(obj,only_rank=false,user=current_profile,plus_txt="+",minus_txt="-")
	only_rank=true if not profile_signed_in?
	ox_rank = obj.ox_rank
	count=""
	if only_rank
		count = ox_rank.to_s
		count = "#{obj.old_rank.to_s}" if obj.respond_to?('old_rank')
	else
		count = obj.count.to_i.to_s
		if profile_signed_in? and user.admin?
			count +=" (+#{ox_rank})" if ox_rank > 0
			count +=" (#{ox_rank})" if ox_rank < 0
		end
	end
	count = "+"+count.to_s if count.to_i > 0
	color = '#646197' if ox_rank.to_i < 0
    color = '#589680' if ox_rank.to_i > 0
    color = '#6b8095' if ox_rank.to_i == 0
	span_id=obj.class.name.to_s+"_"+obj.id.to_s
	minus=""
	plus=""
	qq=""
	if profile_signed_in? 
		if (obj.respond_to?('profile_id') and obj.profile_id!=user.id or not obj.respond_to?('profile_id') and obj.id!=user.id) and 
				not Poll.exists?(:obj_id=>obj.class.name.to_s+"_"+obj.id.to_s,:profile_id=>user.id)
		  minus = rlink(minus_txt,{:controller=>'main', :action=>'vote_minus', :obj=>obj.class.name, :id => obj.id, :span_id=>span_id},span_id)
		  plus = rlink(plus_txt,{:controller=>'main', :action=>'vote_plus', :obj=>obj.class.name, :id => obj.id, :span_id=>span_id},span_id)
		elsif ox_rank!=0 or obj.count!=0
			qq=rlink('?',{:controller=>'oxlib',:action=>'voters_list', :obj=>obj.class.name, :id => obj.id, :span_id=>span_id},'ox_rank_helper_div') 
		end
	end
	return "<span id='#{span_id}'>#{minus} <strong style='color:#{color};'>#{count}</strong> #{plus} #{qq}</span>"
  end

  def ox_rank_field(obj,label=nil,wtf=nil, action='ox_rank_helper')
	vote_helper(obj)
  end
  
  def get_voters(obj_id_string)
	voters=Poll.where(:obj_id=>obj_id_string).order("id DESC").map{|p| {'profile'=>p.profile,'vote'=>p.vote}}.uniq
	return voters
  end
  
  def bool_to_i(var)
	return "+1" if var
	return "-1"
  end

  def author(post)
    if post.profile.nil?
      return "Анонимус"
    else
      return profile_link(post.profile)
    end
  end

  def help_button(link)
    "<a href='http://wiki.oxnull.net/index.php/#{link}' target='_blank'>#{image_tag("question.png")}</a>"
  end

  def true_button(text)
    submit_tag(text)
		#"<!--<span style='float: left;clear:right;white-space: nowrap;'>#{image_tag('btn_left.png')}</span>-->
		#<!--<span class='btn_middle'>#{text}</span>-->
    #<!--<span style='float: right;white-space: nowrap;'>#{image_tag('btn_right.png')}</span>-->"
    #"<button type='submit' style='padding: 0px;cursor: pointer;background-color:transparent;border-width: 0;'>
    #  <span class='btn_middle'>#{text}</span>
    # </button>"
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
      :id => "spinner",
      :size => "16x16",
      :style =>"display: none;" )
  end

  def service_switch(mydo,service_id,div)
    text='Работает'
    text='Выкл' if mydo=='add'
    rlink(text,{:controller=> 'wm', :action => "add_service", :id => service_id, :div =>div, :mydo=>mydo, :layer=>params[:layer]},div)
  end

  def rlink(text, url, div='main_div',method='post',conf=nil)
    link_to_remote text,
      :update => div,
      :before => "Element.show('spinner')",
      :success => "Element.hide('spinner')",
      :method => method,
	  :confirm=>conf,
      :url => url
  end

  def easybutton(txt,form,url,div='main_div')
    link_to txt,
      :update => div,
      :url => url,
	  :remote => true,
      :submit => form
  end
  
  def pm_count
	return "" if not profile_signed_in?
	size=Privatemessage.where(:profile_to=>current_profile.id,:readed=>false).size
	return "(#{size})" if size > 0
	return ""
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
