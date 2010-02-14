class PostsController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem
  # If you want "remember me" functionality, add this before_filter to Application Controller
  before_filter :login_from_cookie, :except => [:show, :index]
  before_filter :load_blog
  before_filter :check_right, :except => [:show, :index]
  
  def index
    if params[:favorite]=='true'
      tmp = [18]
      tmp = current_user.favorite.split(',') if logged_in? and not current_user.favorite.nil?
      @posts = Post.find(:all, :conditions =>{:blog_id=>tmp}, :order => 'id DESC')
    elsif params[:favorite]=='all'
      @posts = Post.find(:all, :order => 'id DESC')
    elsif params[:favorite]=='rand'
      @posts = Post.find(:all, :order=>"rand()")
    elsif params[:favorite]=='last' and logged_in?
      @posts=find_last_posts(current_user)
    elsif params.has_key?('favorite')
      @posts = Post.find_tagged_with(params[:favorite])
    else
      @posts = Post.find(:all, :conditions=>{:blog_id => @blog.id},:order => 'id DESC')
    end
  end
  
  def show
    @post = Post.find(params[:id])
    @comment = Comment.new()
    remove_from_last(current_user, params[:id]) if logged_in?
  end
  
  def new
    #return render :text=> "нельзя" if not can_edit?
    @post = @blog.posts.new
  end
  
  def create
    #return render :text=> "нельзя" if not can_edit?
    @post = @blog.posts.new(params[:post])
    @post.user_id=params[:post][:user_id]
    @post.tag_list = params[:post][:tag_list]
    if @post.save
      flash[:notice] = "Статья успешно создана."
      flash[:notice] = "Статья успешно создана, но в ней не хватает разделителя" if @post.text.length > 4000 and @post.text.scan(' --- ').empty?
      redirect_to blog_post_url(@blog,@post)
    else
      render :action => 'new'
    end
  end
  
  def edit
    flash[:notice] = "Статья слишком большая, в ней не хватает разделителя" if @post.text.length > 4000 and @post.text.scan(' --- ').empty?
    #@post = Post.find(params[:id])
    #return render :text=> "нельзя" if not can_edit?(@post)
  end
  
  def update
    #@post = Post.find(params[:id])
    #return render :text=> "нельзя" if not can_edit?(@post)
    if @post.update_attributes(params[:post])
      flash[:notice] = "Статья успешно обновлена."
      if @post.tag_list != params[:post][:tag_list]
        @post.tag_list = params[:post][:tag_list]
        @post.save!
      end
      flash[:notice] = "Статья успешно обновлена, но в ней не хватает разделителя" if @post.text.length > 4000 and @post.text.scan(' --- ').empty?
      redirect_to blog_post_url(@blog,@post)
    else
      flash[:notice] = "Статья слишком большая, в ней не хватает разделителя" if @post.text.length > 4000 and @post.text.scan(' --- ').empty?
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
    blog_id = params[:blog_id]
    @blog = Blog.find(blog_id) if blog_id != nil and blog_id != 0 and blog_id != '0'
  end

  def check_right
    @post = Post.find(params[:id]) if params[:id]
    return render :text=> "нельзя" if not can_edit?(@post)
  end
end
