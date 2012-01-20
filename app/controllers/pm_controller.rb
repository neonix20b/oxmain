class PmController < ApplicationController
	def chat(lim=30)
		return render :text => "нельзя" if current_profile.id==params[:id].to_i
		update_online_url()
		do_not_read_a=Array.new
		ids=[current_profile.id,params[:id].to_i]
		if lim!=0
			@chat_list = Privatemessage.where(:profile_from=>ids,:profile_to=>ids).order("created_at DESC").limit(lim)
		else
			@chat_list = Privatemessage.where(:profile_from=>ids,:profile_to=>ids).order("created_at DESC")
		end
		@chat_list.each do |cl|
			if (not cl.readed) 
				if cl.profile_to == current_profile.id
					cl.readed=true
					cl.save!
					cl.readed=false
				else
					do_not_read_a += [cl.id]
				end
			end
		end
		@chat_list.reverse!
		session[:do_not_read] = do_not_read_a
		@profile_from = Profile.find(params[:id])
		@privatemessage = Privatemessage.new
		@privatemessage.post=current_profile.last_pm_input
		@user_from=Profile.find(params[:id]) if Profile.exists?(params[:id]) 
	end
	
	def history
		chat(0)
		render :action=>'chat'
	end
	
	def chat_ajax
		return render :text=>"" if not request.post?
		ids=[current_profile.id,params[:id].to_i]
		@chat_list_read = Privatemessage.where(:profile_from=>ids,:profile_to=>ids, :id=>session[:do_not_read], :readed=>true).order("created_at ASC").limit(10)
		@chat_list_read.each do |cl|
			session[:do_not_read] -= [cl.id]
		end
		@chat_list_new = Privatemessage.where(:profile_from=>params[:id].to_i,:profile_to=>current_profile.id, :readed=>false).order("created_at ASC").limit(10)
		@chat_list_new.each do |cl|
			cl.readed=true
			cl.save!
			cl.readed=false
		end
		render(:layout => 'mainlayer')
	end
	
	def post_msg
		return render :text=>"" if not request.post? or not can_send_email?(current_profile,2)
		pm=Privatemessage.new(params[:privatemessage])
		pm.profile_from = current_profile.id
		#block_profile(profile_id,"Спамер что ли?") if check_police("new_pm",current_profile.id,2.minutes.ago) > 10
		return render :text => "нельзя" if pm.profile_to == pm.profile_from
		pm.save!
		current_profile.last_pm_input = ""
		current_profile.save!
		UserMailer.send_pm(Profile.find(pm.profile_to),pm).deliver if can_send_email?(Profile.find(pm.profile_to))
		redirect_to :action=>'chat',:id=>pm.profile_to, :anchor => "end_doc"
	end
	
	def pm_try
	    return render :text=>"" if not request.post? or not can_send_email?(current_profile,2)
		current_profile.last_pm_input = params[:post]
		current_profile.save!
		return render :text=>"" if params[:post].blank? or params[:post].size < 1
		@pm = Privatemessage.new
		@pm.updated_at = Time.now
		@pm.created_at = Time.now
		@pm.profile_from = current_profile.id
		@pm.profile_to = params[:id].to_i
		@pm.id = 46
		@pm.post = params[:post]
		render(:layout => 'mainlayer')
	end
	
	def chat_list
		@chat_list = Array.new
		id_list = Privatemessage.where(:profile_to=>current_profile.id).select("DISTINCT profile_to,profile_from").map{|c| c.profile_from}
		id_list += Privatemessage.where(:profile_from=>current_profile.id).select("DISTINCT profile_to,profile_from").map{|c| c.profile_to}
		id_list.uniq!
		id_list=id_list.sort_by do |ff|
			Privatemessage.where("profile_to=? OR profile_from=?",ff,ff).order("created_at DESC").first.created_at
		end
		id_list.reverse!
		id_list.each do |ff|
			@chat_list+=[Privatemessage.where("profile_to=? OR profile_from=?",ff,ff).order("created_at DESC").first]
		end
	end
end
