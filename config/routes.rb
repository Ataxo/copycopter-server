Copycopter::Application.routes.draw do
  namespace :api do
    namespace :v2 do
      resources :projects, :only => [] do
        resources :deploys, :only => [:create]
        resources :draft_blurbs, :only => [:create, :index]
        resources :published_blurbs, :only => [:index]
      end
    end
  end

  resources :projects, :only => [:index, :show] do
    member do
      match 'publish'
      match 'csv'
      match 'import_csv'
      match '/empty_blurbs' => 'projects#empty_blurbs'
    end

    resources :blurbs, :only => [:destroy]
    resources :locales, :only => [:new]
  end

  resources :localizations, :only => [] do
    resources :versions, :only => [:new, :create]
  end

  match "/oauth2callback" => "oauth#oauth_callback", :as => "oauth_callback"
  match "/sign_out" => "oauth#sign_out", :as => "sign_out"

  root :to => 'projects#index'
end
