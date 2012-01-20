module SupportsHelper
  def support_sw(support)
    if support.worker_id.nil?
      if support.user_id != current_profile.id
        return rlink("Взять на выполнение", {:controller => 'main', :action => 'support_work', :id => support.id, :do=>'get'},"support_#{support.id}", 'post')
      else
        return "Ожидается исполнитель"
      end
    else
      ret = profile_link(User.find(support.worker_id))
      ret += ': '
      if support.worker_id==current_profile.id and (support.status=='open' or support.status=='share')
		ret += 'Вы исполнитель. '
        ret += rlink("[Отказаться от выполнения]", {:controller => 'main', :action => 'support_work', :id => support.id, :do=>'del'},"support_#{support.id}", 'post')
        ret += ' '
        ret += rlink("[Я все сделал]", {:controller => 'main', :action => 'support_work', :id => support.id, :do=>'close'},"support_#{support.id}", 'post')
      elsif support.user_id==current_profile.id and support.status=='close'
        ret += 'Готово! '
        ret += rlink("[Одобрить работу]", {:controller => 'main', :action => 'support_work', :id => support.id, :do=>'accept'},"support_#{support.id}", 'post')
        ret += ' '
        ret += rlink("[Пожаловаться и сменить исполнителя!]", {:controller => 'main', :action => 'support_work', :id => support.id, :do=>'nu_nah'},"support_#{support.id}", 'post')
      elsif logged_in? and current_profile.right!='user' and (support.status=='nu_nah' or (support.status=='close' and (Time.now - support.updated_at).to_i/3600 > 23))
        ret += '<strong>Жалоба! </strong> ' if support.status=='nu_nah'
        ret += rlink("[Одобрить работу и закрыть]", {:controller => 'main', :action => 'support_work', :id => support.id, :do=>'accept'},"support_#{support.id}", 'post')
        ret += ' '
        ret += rlink("[Удалить исполнителя]", {:controller => 'main', :action => 'support_work', :id => support.id, :do=>'del'},"support_#{support.id}", 'post')
      elsif support.status=='close'
        ret += "Ожидается заказчик: #{(Time.now - support.updated_at).to_i/3600}ч."
      elsif support.status=='nu_nah'
        ret += 'Ожидается модератор'
	  elsif (support.status=='open' or support.status=='share') and logged_in? and current_profile.id==support.user_id and (Time.now - support.updated_at).to_i/60 > 60
		ret += 'В работе '
		ret += rlink("[Пожаловаться и сменить исполнителя!]", {:controller => 'main', :action => 'support_work', :id => support.id, :do=>'nu_nah'},"support_#{support.id}", 'post')
      elsif support.status=='open' or support.status=='share'
        ret += 'В работе'
      end
      return ret
    end
  end

  def can_view_support?(support)
    return true if support.user_id == current_profile.id
    return true if support.status=='share' and support.worker_id == current_profile.id
    if support.updated_at < support.time.minutes.ago and support.worker_id == current_profile.id
      support.status='share'
      support.save!
      return true
    end
    return false
  end
end
