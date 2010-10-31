class InviteController < ApplicationController
  include AuthenticatedSystem
  before_filter :login_from_cookie, :only =>[:list]
  before_filter :login_required, :only => [:list]
  def save
	if request.post?
		#проверить что не спам
		inv = Invite.new()
		inv.status='Ждет одобрения'
		inv.text = params[:invite][:text]
		inv.user_id=1
		inv.save!
		redirect_to :action=>'status',:id=>inv.id,:key=>(Digest::MD5.hexdigest(inv.created_at.to_s)).upcase
	end
  end
  
  def index
	@invite = Invite.new()
	#написать статью
  end
  
  def status
	@invite=Invite.find(params[:id])
	render :text =>'omg' if not Invite.exists?(params[:id]) or (Digest::MD5.hexdigest(@invite.created_at.to_s)).upcase != params[:key].upcase
	#проверка состояния
  end
  
  def list
	@invites = Invite.find(:all,:conditions=>"status <> 'ok'",:order => 'id ASC')
	@invites.each do |i|
		if i.ox_rank < my_conf('min_ox_rank_for_delete_invite',-5).to_f or i.created_at < 10.days.ago
			@invites -=[i]
			i.destroy 
		elsif i.ox_rank > my_conf('min_ox_rank_for_register',1).to_f
			i.invite_string = (Digest::MD5.hexdigest(Time.now.to_s)).upcase
			i.status='ok'
			i.save!
			@invites -=[i]
		end
	end
  end
  
  def it_is_spam
	inv=Invite.find(params[:id])
	inv.spam += 1
	if inv.spam > my_conf('spam_after_N_votes',2).to_i
		inv.destroy
		render :text=>'Удалено'
	else
		inv.save!
		render :text=>'Помечено как спам'
	end
  end
  
end
