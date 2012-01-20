class InviteController < ApplicationController
	before_filter :only_post, :only =>[:save,:confirm_true,:confirm_false,:delete]
	skip_filter :authenticate_profile!, :only => [:list,:show]
	before_filter :update_online_url, :only =>[:list, :show]
  def save
	block_profile(current_profile,"Спамер что ли?") if check_police("new_invite",current_profile.id,1.day.ago) > 2 or not can_send_email?(current_profile)
	#Invite.where("invited_user is NULL AND created_at < ?",Time.now-7.days).map{|i|i.destroy}
	return render :text=> 'Очень плохое описание' if params[:invite][:text].size < 200
	inv = Invite.new()
	inv.status='Ждет одобрения'
	inv.title = params[:invite][:title]
	inv.text = params[:invite][:text]
	max=inv.text.split(/[\s\.]/).sort_by{|i|i.size}.last
	if max.length > 60 or inv.text=~/(.)\1{3,}/
		block_profile(current_profile,"Сам ты тролололо!")
		return render :text=>"Сам ты тролололо!"
	end
	#return render :text=>max if max.size > 40 
	#return render :text=>inv.text[inv.text=~/(.)\1{3,}/..-1] if inv.text=~/(.)\1{3,}/
	#return render :text=>'ok'
	inv.profile_id=current_profile.id
	inv.delete_days = params[:invite][:delete_days].to_i
	if inv.save
		Profile.adepts.each do |adept|
			UserMailer.call_adept_invite(adept,inv).deliver
		end
	end
	return redirect_to :action=>'show',:id=>inv.id
  end
  
  def index
	return render :text=> 'Вы не активировали свой аккаунт' if not can_send_email?(current_profile)
	@invite = Invite.new()
	#написать статью
  end
  
  def all
	load_linkfeed()
	@invites = Invite.where("id > 1000 and (status = 'ok' or status = 'revoke')").order('id DESC')
  end
  
  def show
	load_linkfeed()
	@invite = Invite.find(params[:id])
  end
  
  def accept
	@invite = Invite.find(params[:id])
	return render :text => 'err' if @invite.nil? or @invite.profile!=current_profile or not @invite.invited_user.nil? or @invite.status!='ok'
	@user=User.new
	if request.post?
		@user.oxdomain = params[:user][:oxdomain]
		@user.wtf = 'none'
		@user.wtf = 'joomla' if params[:wtf]=='joomla'
		@user.wtf = 'phpbb' if params[:wtf]=='smf'
		@user.wtf = 'wordpress' if params[:wtf]=='wordpress'
		@user.profile_id = current_profile.id
		@user.created_at=Time.now
		@user.updated_at=Time.now
		@user.email = current_profile.email
		if(params[:user][:delete_days].to_i > 0)
			@user.delete_date = Time.now + params[:user][:delete_days].to_i.days
			@user.delete_bool=true
		end
		if @user.save
			@invite.status='ok'
			@invite.invited_user=@user.id
			@invite.save!
			addtask(@user.id,"create")
			return redirect_to :controller=>'main', :action=>'index'
		else
			flash[:warning] = @user.errors.full_messages.join(" ")
		end
	end
  end
  
  def confirm_true
	return render :text=>'err' if not current_profile.adept?
	invite = Invite.find(params[:id])
	invite.ox_rank = my_conf('min_ox_rank_for_register',2).to_f + 0.1
	invite.save!
	render :text=>'ok'
  end
  
  def confirm_false
	return render :text=>'err' if not current_profile.adept?
	invite = Invite.find(params[:id])
	invite.ox_rank = my_conf('min_ox_rank_for_delete_invite',-3).to_f - 0.1
	invite.save!
	render :text=>'ok'  
  end
  
  def admin_invite
	return render :text=>'err' if not current_profile.admin?
	i = Invite.new
	i.status='ok'
	i.invite_string = (Digest::MD5.hexdigest(Time.now.to_s)).upcase
	i.profile_id=current_profile.id
	i.save!
	return redirect_to :controller=>'invite',:id=>i.id,:action=>'accept'
  end
  
  def delete
  i = Invite.find(params[:id])
  return render :text => 'err' if i.nil? or i.profile!=current_profile
  i.destroy
  render :text=>'ok'  
  end
  
  def status
	#return redirect_to :controller=>'main', :action=>'index'
  end
  
  def list
	load_linkfeed()
	Invite.where("status = 'ok' and updated_at < ?",3.days.ago).where(:invited_user=>nil).each do |i|
		i.status='revoke'
		i.save!
		UserMailer.invite_end(i.profile,"Отклонена из-за неактивности").deliver if can_send_email?(i)
	end
	Invite.where("status <> 'ok' and status <> 'revoke'").each do |i|
		if i.ox_rank < my_conf('min_ox_rank_for_delete_invite',-2).to_f or i.created_at < 5.days.ago
			i.status='revoke'
			i.save!
			UserMailer.invite_end(i.profile,"Отклонена").deliver if can_send_email?(i)
		elsif i.ox_rank > my_conf('min_ox_rank_for_register',2).to_f
			i.invite_string = (Digest::MD5.hexdigest(Time.now.to_s)).upcase
			i.status='ok'
			i.save!
			UserMailer.invite_end(i.profile,"Одобрена").deliver if can_send_email?(i)
		end
	end
	@invites = Invite.where("status <> 'ok' and status <> 'revoke'").order('id DESC')
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
