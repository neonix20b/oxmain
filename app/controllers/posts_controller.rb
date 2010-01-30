class PostsController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem
  # If you want "remember me" functionality, add this before_filter to Application Controller
  before_filter :login_from_cookie, :except => [:show, :index]
  before_filter :load_blog
  
  def index
    @posts = @blog.posts
  end
  
  def show
    @post = Post.find(params[:id])
    @comment = Comment.new()
  end
  
  def new
    @post = @blog.posts.new
  end
  
  def create
    @post = @blog.posts.new(params[:post])
    @post.user_id=params[:post][:user_id]
    if @post.save
      flash[:notice] = "Статья успешно создана."
      redirect_to blog_post_url(@blog,@post)
    else
      render :action => 'new'
    end
  end
  
  def edit
    @post = Post.find(params[:id])
    return render :text=> "нельзя" if not can_edit?(@post)
  end
  
  def update
    @post = Post.find(params[:id])
    return render :text=> "нельзя" if not can_edit?(@post)
    if @post.update_attributes(params[:post])
      flash[:notice] = "Статья успешно обновлена."
      redirect_to blog_post_url(@blog,@post)
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @post = Post.find(params[:id])
    return render :text=> "нельзя" if not can_edit?(@post)
    @post.destroy
    flash[:notice] = "Статья успешно удалена."
    redirect_to blog_posts_url(@blog)
  end

  private
  def load_blog
    blog_id = params[:blog_id]
    @blog = Blog.find(blog_id) if blog_id != nil && blog_id != 0
  end

end
