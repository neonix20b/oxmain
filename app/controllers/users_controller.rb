class UsersController < ApplicationController
	include AuthenticatedSystem
	before_filter :login_from_cookie
	before_filter :login_required
	
	def index
		@users = User.find(:all,
			:conditions=>["status='2' AND created_at<=? AND created_at>? AND `right`='user'",8.days.ago,365.days.ago],
			:order=>'id DESC')
	end
	
	def remove_list
		@users = User.find(:all,:conditions=>{:status=>'vote'},:order=>'ox_rank')
	end
	
	def vote_delete
		return render :text=>"нельзя" if not request.post?
		vote_user=User.find(params[:id])
		vote_user.count=0 if vote_user.status=='2'
		vote_user.ox_rank -= ox_power()
		vote_user.ox_rank=(vote_user.ox_rank*1000).round.to_f/1000
		vote_user.count -= 1
		vote_user.status='vote'
		vote_user.save!
		return render :text=>vote_user.count
		#sql.execute("select webhosting.remove_user(#{params[:id]})");
	end

end
