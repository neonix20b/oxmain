class UsersController < ApplicationController
	skip_filter :authenticate_profile!, :only =>[:live, :top]
	before_filter :not_user, :except =>[:remove_list, :live, :vote_delete, :top]
	before_filter :only_post, :only =>[:vote_delete]
	
	def index
		@users = User.where(:status=>'2').where("created_at < ?",2.weeks.ago).order('id DESC')
		#@users = User.fin1d(:all,
		#	:conditions=>["status='2' AND created_at<=? AND `right`='user'",14.days.ago],
		#	:order=>'id DESC')
	end
	
	def top
		@top10 = Profile.where("ox_rank > 10").order('ox_rank DESC').limit(10)#.map{|p|[p.show_name,p.ox_rank]}
		@most_user10=User.find(:all, :conditions => "profile_id IS NOT NULL", :select => "id, profile_id, count(id) as user_count", :group => "profile_id", :order => "user_count DESC", :limit=>10)
		@most_comments10=Comment.find(:all, :conditions => ["profile_id IS NOT NULL AND created_at > ?",3.month.ago], :select => "id, profile_id, count(id) as comment_count", :group => "profile_id", :order => "comment_count DESC", :limit=>10)
		@most_commentsRank=Comment.find(:all, :conditions => ["profile_id IS NOT NULL AND created_at > ? AND ox_rank > 1.5",3.month.ago], :select => "id, profile_id, avg(ox_rank) as comment_rank", :group => "profile_id", :order => "comment_rank DESC", :limit=>10)
		@most_posts10=Post.find(:all, :conditions => ["profile_id IS NOT NULL AND created_at > ?",12.month.ago], :select => "id, profile_id, count(id) as post_count", :group => "profile_id", :order => "post_count DESC", :limit=>10)
		@most_postsRank=Post.find(:all, :conditions => ["profile_id IS NOT NULL AND created_at > ? AND ox_rank > 2",12.month.ago], :select => "id, profile_id, avg(ox_rank) as post_rank", :group => "profile_id", :order => "post_rank DESC", :limit=>10)
		@most_pm10=Privatemessage.find(:all, :conditions => ["profile_from IS NOT NULL AND created_at > ?",3.month.ago], :select => "profile_from, count(id) as pm_count", :group => "profile_from", :order => "pm_count DESC", :limit=>10).map{|pm| pm.profile}
		@most_enter10=Profile.find(:all, :order=>"sign_in_count DESC", :limit=>10)
		#render :action=>'index'
	end
	
	def remove_list
		update_online_url()
		@users = User.where(:status=>'vote').order('ox_rank')
	end
	
	def vote_delete
		vote_user=User.find(params[:id])
		return render :text=>"Уже удален" if vote_user.status=="removed"
		return render :text=>"Уже на голосовании" if vote_user.status=="vote"
		if current_profile.adept? or vote_user.profile==current_profile
			if vote_user.status=='2'
				vote_user.count=0 
				vote_user.ox_rank = 0
				UserMailer.delete_site_vote(vote_user.profile,user_site_link(vote_user,false)).deliver if not vote_user.profile.nil?
			end
			vote_user.ox_rank -= ox_power()
			vote_user.ox_rank = (vote_user.ox_rank*1000).round.to_f/1000
			vote_user.count -= 1
			vote_user.status='vote'
			vote_user.save!
			vote = Poll.new(:obj_id=>"vote_user_delete_#{vote_user.id}",:vote=>1,:profile_id=>current_profile.id)
			vote.save!
		end
		#if vote_user.ox_rank < -1
		#	addtask(vote_user.id,"remove_user") 
		#	return render :text=>"Будет удален"
		#else
			return render :text=>vote_user.count
		#end
		#sql.execute("select webhosting.remove_user(#{params[:id]})");
	end
	
	def right_switcher
		return render :text=>"нельзя" if not current_profile.admin?
		user=Profile.find(params[:id])
		user.adept=user.adept==false
		user.save!
		return render :text => user.adept
	end
	
	def adept_list
		@users = Profile.where(:adept=>true).order("ox_rank DESC")
		render :template => "users/index"
	end
	
	def live
		load_linkfeed()
		@comments = Profile.where("last_comment_input <> \"\" AND updated_at > ? AND last_url LIKE '%posts%'", 10.minutes.ago).order('updated_at DESC').map{|u| 
			u.comments.new({:updated_at => u.updated_at, :created_at => u.updated_at, :id=>46, :text => u.last_comment_input, :ox_rank=>0, :count=>0});
		}
		@posts = Profile.where("last_post_input <> \"\" AND updated_at > ?", 10.minutes.ago).order('updated_at DESC').map{|u| 
			u.posts.new({:updated_at => u.updated_at, :created_at => u.updated_at, :id=>46, :text => u.last_post_input});
		}
		if request.post?
			render(:layout => 'mainlayer') 
		elsif logged_in?
			update_online_url()
		end
	end

	private
	def not_user
		return render :text=>"нельзя" if not current_profile.adept?
	end
end
