#require 'tl_client'
class PostsController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  # If you want "remember me" functionality, add this before_filter to Application Controller
  #before_filter :login_from_cookie
  skip_filter :authenticate_profile!, :only => [:show, :index]

  before_filter :load_blog
  before_filter :update_online_url, :only =>[:index, :show, :new, :edit]
  before_filter :check_right, :except => [:show, :index, :show_ajax]
  before_filter :set_gmtoffset, :only =>[:index, :show]
  before_filter :find_last, :only =>[:index, :show]
  
  protect_from_forgery 
 
  def index
	load_linkfeed()
    @per_page=10
    @count=0
    @per_page=100 if params[:format]!='html'
    offset=0
    return redirect_to "http://oxnull.net/old/#{$1}" if not request.request_uri.scan(/(#hello=\w+)/).empty?
    offset = @page*@per_page if not @page.nil?
    if params[:favorite]=='favorite'
      tmp = [18]
      tmp = current_profile.favorite.split(',') if logged_in? and not current_profile.favorite.nil?
      @count = Post.count(:all, :conditions =>{:blog_id=>tmp})
      offset=@count-@per_page if @page.nil? or @page == (@count/@per_page).to_i
      offset=0 if offset < 0
      @posts = Post.where(:blog_id=>tmp).order('id ASC').limit(@per_page).offset(offset)
      
    elsif params[:favorite]=='all'
      @count = Post.count
      offset=@count-@per_page if @page.nil? or @page == (@count/@per_page).to_i
      offset=0 if offset < 0
      @posts = Post.order('id ASC').limit(@per_page).offset(offset)
      
    elsif params[:favorite]=='random'
      @posts = Post.order("rand()").limit(@per_page)
    elsif params[:favorite]=='last' and logged_in?
      @posts=find_last_posts(current_profile)
    elsif params.has_key?('favorite')
      @posts = Post.find_tagged_with(params[:favorite])
    else
      @count = Post.count(:all, :conditions=>{:blog_id => @blog.id})
      offset=@count-@per_page if @page.nil? or @page == (@count/@per_page).to_i
      offset=0 if offset < 0
      @posts = Post.where(:blog_id => @blog.id).order('id ASC').limit(@per_page).offset(offset)
    end
    @posts.reverse!
    @page = @count/@per_page if @page.nil?
    @keywords = @posts.map{|post| post.tag_list}.flatten.uniq.join(', ')
    @description = @posts.map{|post| post.title}.join('. ')
    @offset = offset;
  end
  
  def show
	load_linkfeed()
	#@tl=Trustlink::TlClient.new('9a46eaebf5cac91e3b0e3e079f5f59cfd3474da3',request, {:encoding=>'UTF-8'})
    @post = Post.find(params[:id]) if Post.exists?(params[:id])
	if profile_signed_in? and not @post.nil?
		@comment = Comment.new()
		@comment.text = current_profile.last_comment_input 
		remove_from_last(current_profile, params[:id])
		session[:last_comment]=@post.comments.last.id if @post.comments.size > 0
	end
  end
   
  def new
    #return render :text=> "нельзя" if not can_edit?
    @post = @blog.posts.new
	@post.text=current_profile.last_post_input
  end
  
  def post_try
	return render :text=>'А ты точно человек?' if not can_send_email?(current_profile,2)
	return render :text=>"" if not request.post? or params[:text].size > 10000
	current_profile.last_post_input = params[:text]
	current_profile.updated_at=Time.now.utc if current_profile.last_post_input.size < 10 and params[:text].to_s.size > 10 or current_profile.last_post_input.size > 10 and params[:text].to_s.size < 10
	current_profile.save!
	return render :text=>"" if params[:text].blank? or params[:text].size < 1
	return render :text=> "<div style='text-indent:1em;'>"+ya_speller(tte(params[:text]))+"</div>"
	#@post = Post.new
	#@post.text = params[:text]
	#render(:layout => 'mainlayer')
  end
  
  def create
    block_profile(current_profile,"Спамер что ли?") if not can_send_email?(current_profile)
    @post = @blog.posts.new(params[:post])
    @post.profile_id=params[:post][:profile_id]
    @post.tag_list = params[:post][:tag_list]
    @post.last_comment = 'Недавно создана.'
	@post.created_at = Time.now.utc
	@post.updated_at = Time.now.utc
	block_profile(profile_id,"Спамер что ли?") if check_police("new_post",current_profile.id,30.minutes.ago) > 1
    if @post.save
      flash[:notice] = "Статья успешно создана."
      flash[:warning] = "Статья успешно создана, но в ней не хватает разделителя" if @post.text.length > 4000 and @post.text.scan(' --- ').empty?
      tmp = Array.new()
      tmp = current_profile.favorite.split(',') if not current_profile.favorite.nil?
      tmp.insert(-1, params[:blog_id].to_s)
      current_profile.favorite=tmp.uniq.join(',')
	  current_profile.last_post_input = ""
      current_profile.save!
      redirect_to blog_post_url(@blog,@post)
    else
      render :action => 'new'
    end
  end
  
  def edit
    flash[:warning] = "Статья слишком большая, в ней не хватает разделителя" if @post.text.length > 4000 and @post.text.scan(' --- ').empty?
    #@post = Post.find(params[:id])
    #return render :text=> "нельзя" if not can_edit?(@post)
  end
  
  def update
    #@post = Post.find(params[:id])
    #return render :text=> "нельзя" if not can_edit?(@post)
    params[:post][:last_comment]='Недавно отредактирована.'
    if @post.update_attributes(params[:post])
      flash[:notice] = "Статья успешно обновлена."
      if @post.tag_list != params[:post][:tag_list]
        @post.tag_list = params[:post][:tag_list]
		current_profile.last_post_input = ""
		current_profile.save!
        @post.save!
      end
      flash[:warning] = "Статья успешно обновлена, но в ней не хватает разделителя" if @post.text.length > 4000 and @post.text.scan(' --- ').empty?
      redirect_to blog_post_url(@blog,@post)
    else
      flash[:warning] = "Статья слишком большая, в ней не хватает разделителя" if @post.text.length > 4000 and @post.text.scan(' --- ').empty?
      render :action => 'edit'
    end
  end
  
  def destroy
    #@post = Post.find(params[:id])
    #return render :text=> "нельзя" if not can_edit?(@post)
    @post.destroy
    flash[:notice] = "Статья успешно удалена."
    redirect_to blog_posts_url(@blog)
  end

  private 
  def load_blog
    @blog_id = params[:blog_id]
    @page = nil
    if not @blog_id.nil?
      tmp = @blog_id.split('-')
      if tmp.size > 1 and tmp[-1].to_i.to_s == tmp[-1]
        @page = tmp[-1].to_i
        tmp.delete_at(-1)
      end
      @blog_id = tmp.join('-')
      if @blog_id.to_i.to_s != @blog_id
        params[:favorite]=@blog_id
      elsif @blog_id.to_i != 0
        @blog = Blog.find(@blog_id)
      end
    end
  end

  def check_right
    @post = Post.find(params[:id]) if params[:id]
    return render :text=> "нельзя" if not can_edit?(@post)
  end
end
