# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def help_button(link)
    "<a href='http://wiki.oxnull.net/index.php/#{link}' target='_blank'>#{image_tag("question.png")}</a>"
  end

  def true_button(text)
    "<button type='submit' style='padding: 0px;cursor: pointer;background-color:transparent;border-width: 0;'>
	<span>
		<span style='float: left;'>#{image_tag('btn_left.png')}</span>
		<span class='btn_middle'>#{text}</span>
		<span style='float: left;'>#{image_tag('btn_right.png')}</span>
	</span>
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
      :align => "absmiddle",
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

  def rlink(text, url, div='main_div')
    link_to_remote text,
      :update => div,
      :before => "Element.show('spinner')",
      :success => "Element.hide('spinner')",
      :method => 'get',
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
