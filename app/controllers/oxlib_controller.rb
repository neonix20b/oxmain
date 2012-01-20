class OxlibController < ApplicationController
	before_filter :only_post, :except=>[:all_profile,:email]
	def show_post_ajax
		post = Post.find(params[:id])
		return redirect_to blog_post_url(post.blog,post) if not request.post?
		if not session[:last_comment].nil? and post.comments.size > 0 and session[:last_comment]!=post.comments.last.id
			find_last_posts(current_profile,3) if logged_in?
			remove_from_last(current_profile, params[:id]) if logged_in?
			@comms = Comment.where("post_id = ? AND id > ?",post.id, session[:last_comment])
			session[:last_comment]=post.comments.last.id
		end
		render(:layout => false)
	end
	
	def voters_list
		#obj = params[:obj].camelize.constantize.find(params[:id])
		@voters=get_voters(params[:obj]+"_"+params[:id])
		render(:layout => 'popup')
	end
	
	def set_post_master
		return render :text => '11' if not current_profile.adept?
		post=Post.find(params[:post_id])
		return render :text => '11' if not post.profile.nil?
		post.profile_id = params[:profile_id].to_i
		post.save!
		"Покровские ворота, соломенная шляпа, здравствуйте  ваша тетя"
		render :text => post.to_xml
	end
	
	def kick_profile
		render :text=>'err' if not current_profile.adept?
		prof=Profile.find(params[:id])
		block_profile(prof)
		return render :text=>'Кикнут'
	end
	
	def destroy_post
		@post = Post.find(params[:id])
		return render :text=> "нельзя" if not can_edit?(@post)
		@post.destroy
		flash[:notice] = "Статья успешно удалена."
		return render :text=> "Удалено" 
		#redirect_to blog_posts_url(@blog)
	end
	
	def delete_profile
		if current_profile.admin?
			p=Profile.find(params[:id])
			p.destroy
			return render :text=>'Удалено'
		end
	end
	
	def all_profile
		@profile=Profile.find(params[:id]) if Profile.exists?(params[:id])
		@comments = Comment.where(:profile_id=>params[:id]).order("id DESC")
		@posts = Post.where(:profile_id=>params[:id]).order("id DESC")
		@users = User.where(:profile_id=>params[:id]).order("id DESC")
	end
	
	def comment_del
		return "" if not current_profile.adept?
		comment = Comment.find(params[:id])
		return "err" if Poll.exists?(:obj_id=>comment.class.name.to_s+"_"+comment.id.to_s,:profile_id=>current_profile.id)
		comment.vote_delete += 1
		if comment.vote_delete > 2
			prof = comment.profile
			txt = comment.text
			comment.destroy
			return render :text=>"Комментарий #{profile_link(prof,false)} успешно удален. Его текст:<br/>#{txt}"
		else
			vote = Poll.new(:obj_id=>comment.class.name.to_s+"_"+comment.id.to_s,:vote=>1,:profile_id=>current_profile.id)
			vote.save!
			comment.save!
			return render :text=>"Комментарий помечен для удаления и ждет коллективного решения. #{comment.vote_delete}"
		end
	end
end
