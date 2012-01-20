Oxmain::Application.routes.draw do
  devise_for :profiles

  resources :supports
  resources :blogs
  resources :blogs do
      resources :posts
  end
  match 'profile/:id.:format' => 'account#profile'
  match '/' => 'posts#index', :blog_id => 'all', :format => 'html'
  root :to => 'posts#index', :blog_id => 'all', :format => 'html'
  match 'error(/:id)' => 'main#error'
  match ':controller' => '#index'
  match ':controller/:action/:id.:format'
  match ':controller/:action/:id', :constraints => {:id => /[\-\d]+/}
  match ':controller/:action'
  match ':controller/:action.:format'
end
