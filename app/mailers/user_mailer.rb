class UserMailer < ActionMailer::Base
  default :from => "oxnull <oxmain@oxnull.net>"
  
  def new_comment(profile_reciver,comment)
	@comment=comment
	render :text=> "#{profile_reciver.show_name} <#{profile_reciver.email}>"
	mail(:to =>"#{profile_reciver.show_name} <#{profile_reciver.email}>",
		 :subject => "Новый комментарий")
  end
  
  def invite_end(profile_reciver,status)
	@status=status
	mail(:to => "#{profile_reciver.show_name} <#{profile_reciver.email}>",
		 :subject => "Заявка #{status}")
  end
  
  def simple_mail(profile_reciver,text,subject="oxnull")
	@text=text
	@profile=profile_reciver
	mail(:to => "#{profile_reciver.show_name} <#{profile_reciver.email}>",
		 :subject => subject)
	
  end
  
  def call_adept_invite(profile_reciver,invite)
	@profile=profile_reciver
	@invite=invite
	mail(:to => "#{profile_reciver.show_name} <#{profile_reciver.email}>",
		 :subject => "Запрос на инвайт")
  end
  
  def send_pm(profile_reciver,pm)
	@profile_from=Profile.find(pm.profile_from)
	@pm=pm
	mail(:to => "#{profile_reciver.show_name} <#{profile_reciver.email}>",
		 :subject => "Вы получили личное сообщение от #{@profile_from.show_name}")
  end
  
  def delete_site_vote(profile_reciver,site_link)
	@profile=profile_reciver
	@site_link=site_link
	mail(:to => "#{profile_reciver.show_name} <#{profile_reciver.email}>",
		 :subject => "Удаление сайта")
  end
end
