Rails.application.routes.draw do

  constraints subdomain: "www" do
    get "/" => redirect { |params| "https://coderwall.com" }
  end

  resources :jobs do
    post :publish
  end

  # This disables serving any web requests other then /assets out of CloudFront
  match '*path', via: :all, to: 'pages#show', page: 'not_found',
    constraints: CloudfrontConstraint.new

  root  'protips#home'
  get   '/trending(/:page)'       => 'protips#index', order_by: :score,        as: :trending
  get   '/popular(/:page)'        => 'protips#index', order_by: :views_count,  as: :popular
  get   '/fresh(/:page)'          => 'protips#index', order_by: :created_at,   as: :fresh
  get   '/:topic/popular(/:page)' => 'protips#index', order_by: :views_count,  as: :popular_topic, :constraints => { :topic => /.*/ }
  get   '/:topic/fresh(/:page)'   => 'protips#index', order_by: :created_at,   as: :fresh_topic, :constraints => { :topic => /.*/ }

  get   '/p/trending'       => redirect("/trending", status: 302)
  get   '/p/popular'        => redirect("/popular", status: 302)
  get   '/p/fresh'          => redirect("/fresh", status: 302)
  get    "/signin"     => "clearance/sessions#new",                as: :sign_in
  delete "/signout"    => "clearance/sessions#destroy",            as: :sign_out
  get    "/signup"     => "clearance/users#new",                   as: :sign_up
  get    '/faq'        => 'pages#show',          page: 'faq',      as: :faq
  get    '/tos'        => 'pages#show',          page: 'tos',      as: :tos
  get    '/privacy_policy' => 'pages#show',    page: 'privacy',  as: :privacy
  get    '/404'            => "pages#show",    page: 'not_found'
  get    '/500'            => "pages#show",    page: 'server_error'
  get    '/helloworld'     => "users#edit",    finish_signup: true, as: :finish_signup
  get    '/styleguide'     => "pages#show",    page: 'styleguide'
  get    '/delete_account' => 'users#show',    delete_account: true
  get    '/p/u/:username',     to: redirect("/%{username}/protips", status:302)
  get    '/twitter/:username', to: redirect("/404", status:302)
  get    '/github/:username',  to: redirect("/404", status:302)
  get    '/team/:slug'     => 'teams#show'
  get    '/live' => 'streams#index', as: :live_streams
  get    '/live/lunch-and-learn.ics' => 'streams#invite', as: :lunch_and_learn_invite
  get    '/.well-known/acme-challenge/:id' => 'pages#verify'

  resources :passwords, controller: "clearance/passwords", only: [:create, :new]
  resource :session,    controller: "clearance/sessions",  only: [:create]

  resources :team
  resources :streams, only: [:new, :show, :create, :update] do
    get :edit, on: :collection
  end

  resources :users do
    member do
      get '/endorsements' => 'users#show' #legacy url
      resources :likes, only: :index
    end
  end

  resources :users, controller: "clearance/users", only: [:create] do
    resources :pictures
    resource :password,
      controller: "clearance/passwords",
      only: [:create, :edit, :update]
  end

  resources :comments do |comment|
    resources :likes, only: :create
    collection do
      get '/spam'      => 'comments#spam'
    end
  end

  resources :protips, path: '/p' do
    resources :likes, only: :create
    collection do
      get '/spam'      => 'protips#spam'
      get '/:id/edit'  => 'protips#edit'  #this prevents next route from clobbering edit
      get '/:id/:slug' => 'protips#show', as: :slug
    end
  end

  resources :streams, path: '/s', only: [:show] do
    get :comments
    get :popout
  end


  get '/:username'          => 'users#show',   as: :profile
  get '/:username/protips'  => 'users#show',   as: :profile_protips,  protips:  true
  get '/:username/comments' => 'users#show',   as: :profile_comments, comments: true
  get '/:username/live'     => 'streams#show', as: :profile_stream
  get '/:username/live/stats' => 'streams#stats', as: :live_stream_stats
  get '/:username/impersonate' => 'users#impersonate', as: :impersonate

  get '/stylesheets/jquery.coderwall.css', to: redirect(status: 301) {
    '/legacy.jquery.coderwall.css'
  }
  get '/javascripts/jquery.coderwall.js',  to: redirect(status: 301) {
    '/legacy.jquery.coderwall.js'
  }

  resources :hooks, only: [] do
    collection do
      post 'sendgrid'
      post 'quickstream' => 'quickstream#webhook'
    end
  end
end
