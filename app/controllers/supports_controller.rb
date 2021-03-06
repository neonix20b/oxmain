class SupportsController < ApplicationController
  #before_filter :login_from_cookie
  skip_filter :authenticate_profile!, :only =>[:index]
  before_filter :check_right, :except => [:show, :index]
  before_filter :update_online_url

  def index
    @supports = Support.all(:order => 'money DESC')
	@supports.each do |support|
		support.destroy if 5.days.ago.utc > support.updated_at.utc
	end
    return render :partial => "supports_list", :locals => {:supports => @supports} if request.xhr?
	load_linkfeed()
  end
  
  def show
	return redirect_to supports_url if not Support.exists?(params[:id])
    @support = Support.find(params[:id])
    render :partial => "show_support", :locals => {:support => @support} if request.xhr?
  end
  
  def new
    @support = Support.new
    @support.task = 'Подробное описание в чем проблема и что делалось до того как она появилась'
    @support.info = 'Дополнительные сведения для работы(если необходимо): логин/пароль от админки'
    @support.name = 'Название заявки, отображающее суть проблемы'
    flash[:warning] = "У Вас недостаточно ox'ов для создания заявок." if current_profile.money < 5
  end
  
  def create
    @support = Support.new(params[:support])
    @support.user_id=params[:support][:user_id]
    if transfer_money(current_profile, User.find(3), @support.money.to_f) and @support.save
      flash[:notice] = "Заявка успешно создана."
      redirect_to @support
    else
      flash[:warning] = "У Вас недостаточно ox'ов для создания заявки." if current_profile.money < 5+@support.money.to_f
      render :action => 'new'
    end
  end
  
  def edit
    #@support = Support.find(params[:id])
  end
  
  def update
    #@support = Support.find(params[:id])
    params[:support].delete('money')
    if @support.update_attributes(params[:support])
      flash[:notice] = "Заявка успешно обновлена."
      redirect_to @support
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    #@support = Support.find(params[:id])
    @support.destroy
    flash[:notice] = "Заявка успешно удалена."
    redirect_to supports_url
  end

  private
  def check_right
    @support = Support.find(params[:id]) if params[:id]
    return render :text=> "нельзя" if not can_edit?(@post)
  end
  
end
