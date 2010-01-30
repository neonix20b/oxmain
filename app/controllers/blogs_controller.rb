class BlogsController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem
  # If you want "remember me" functionality, add this before_filter to Application Controller
  before_filter :login_from_cookie, :except => [:show, :index]
  
  def index
    @blogs = Blog.all
  end
  
  def show
    @blog = Blog.find(params[:id])
    redirect_to blog_posts_url(@blog)
  end
  
  def new
    return render :text=> "нельзя" if not can_edit_blog?
    @blog = Blog.new
  end
  
  def create
    return render :text=>"нельзя" if not can_edit_blog?
    @blog = Blog.new(params[:blog])
    if @blog.save
      flash[:notice] = "Блог \"#{@blog.name}\" удачно создан."
      redirect_to @blog
    else
      render :action => 'new'
    end
  end
  
  def edit
    return render :text=> "нельзя" if not can_edit_blog?
    @blog = Blog.find(params[:id])
  end
  
  def update
    return render :text=> "нельзя" if not can_edit_blog?
    @blog = Blog.find(params[:id])
    if @blog.update_attributes(params[:blog])
      flash[:notice] = "Блог \"#{@blog.name}\" удачно обновлен."
      redirect_to @blog
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    return render :text=> "нельзя" if not can_edit_blog?
    @blog = Blog.find(params[:id])
    @blog.destroy
    flash[:notice] = "Блог удачно удален."
    redirect_to blogs_url
  end
end
