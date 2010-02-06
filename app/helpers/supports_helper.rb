module SupportsHelper
  def support_sw(support)
    if support.worker_id.nil?
      return rlink("Взять на выполнение", {:controller => 'main', :action => 'support_work', :id => @support.id, :do=>'get'},"support_#{@support.id}", 'post')
    else
      return "Закреплено за "+profile_link(User.find(support.worker_id))
    end
  end
end
