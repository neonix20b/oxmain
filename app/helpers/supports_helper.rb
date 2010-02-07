module SupportsHelper
  def support_sw(support)
    if support.worker_id.nil?
      if support.user_id != current_user.id
        return rlink("Взять на выполнение", {:controller => 'main', :action => 'support_work', :id => support.id, :do=>'get'},"support_#{support.id}", 'post')
      else
        return "Ожидается исполнитель"
      end
    else
      ret = profile_link(User.find(support.worker_id))
      ret += ': '
      if support.worker_id==current_user.id and (support.status=='open' or support.status=='share')
        ret += rlink("[Отказаться]", {:controller => 'main', :action => 'support_work', :id => support.id, :do=>'del'},"support_#{support.id}", 'post')
        ret += ' '
        ret += rlink("[Готово!]", {:controller => 'main', :action => 'support_work', :id => support.id, :do=>'close'},"support_#{support.id}", 'post')
      elsif support.user_id==current_user.id and support.status=='close'
        ret += 'Готово! '
        ret += rlink("[Одобрить!]", {:controller => 'main', :action => 'support_work', :id => support.id, :do=>'accept'},"support_#{support.id}", 'post')
        ret += ' '
        ret += rlink("[Пожаловаться!]", {:controller => 'main', :action => 'support_work', :id => support.id, :do=>'nu_nah'},"support_#{support.id}", 'post')
      elsif support.status=='close'
        ret += 'Ожидается заказчик'
      elsif support.status=='nu_nah'
        ret += 'Ожидается модератор'
      elsif support.status=='open' or support.status=='share'
        ret += 'В работе'
      end
      return ret
    end
  end

  def can_view_support?(support)
    return true if can_edit?(support)
    return true if support.status=='share' and support.worker_id == current_user.id
    return true if support.updated_at < 30.minutes.ago and support.worker_id == current_user.id
    return false
  end
end
