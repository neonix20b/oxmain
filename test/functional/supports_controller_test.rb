require 'test_helper'

class SupportsControllerTest < ActionController::TestCase
  def test_index
    get :index
    assert_template 'index'
  end
  
  def test_show
    get :show, :id => Support.first
    assert_template 'show'
  end
  
  def test_new
    get :new
    assert_template 'new'
  end
  
  def test_create_invalid
    Support.any_instance.stubs(:valid?).returns(false)
    post :create
    assert_template 'new'
  end
  
  def test_create_valid
    Support.any_instance.stubs(:valid?).returns(true)
    post :create
    assert_redirected_to support_url(assigns(:support))
  end
  
  def test_edit
    get :edit, :id => Support.first
    assert_template 'edit'
  end
  
  def test_update_invalid
    Support.any_instance.stubs(:valid?).returns(false)
    put :update, :id => Support.first
    assert_template 'edit'
  end
  
  def test_update_valid
    Support.any_instance.stubs(:valid?).returns(true)
    put :update, :id => Support.first
    assert_redirected_to support_url(assigns(:support))
  end
  
  def test_destroy
    support = Support.first
    delete :destroy, :id => support
    assert_redirected_to supports_url
    assert !Support.exists?(support.id)
  end
end
