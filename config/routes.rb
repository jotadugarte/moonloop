Rails.application.routes.draw do
  get  "sign_in", to: "sessions#new"
  post "sign_in", to: "sessions#create"
  get  "sign_up", to: "registrations#new"
  post "sign_up", to: "registrations#create"
  resources :sessions, only: [ :index, :show, :destroy ]
  resources :habit_categories, only: [ :index, :create, :edit, :update, :destroy ]
  resources :user_habits, only: [ :index, :create, :edit, :update ] do
    member do
      patch :activate
      patch :deactivate
    end
    collection do
      post :create_from_template
    end
  end
  resource  :password, only: [ :edit, :update ]
  resource  :profile, only: [ :edit, :update ]
  resources :weight_logs, only: %i[index new create destroy] do
    member do
      get :confirm_destroy
    end
  end
  get "mi_dia", to: "my_day#show", as: :my_day
  get "informes", to: "reports#show", as: :informes
  resources :habit_completions, only: [ :create, :destroy ]
  resources :exercise_routines, only: %i[index create edit update destroy] do
    member do
      get :confirm_destroy
      post :duplicate
      post :accept_source_update
    end
  end
  resources :menus, only: [ :index, :create, :edit, :update ] do
    member do
      post :accept_source_update
    end
    resources :menu_entries, only: [ :create ], module: :menus do
      delete :clear, on: :collection
    end
  end
  resources :recipes
  resource :phase, only: %i[show update] do
    post :dismiss_reminder, on: :member
    post :repeat_last_assignment, on: :member
    post :repeat_last_routine_assignment, on: :member
  end
  resources :phase_assignments, only: %i[new create edit update destroy]
  resources :exercise_routine_assignments, only: %i[new create edit update destroy]
  resources :phase_programs, only: %i[index create edit update destroy] do
    member do
      post :apply
    end
    resources :phase_program_assignments, only: %i[new create edit update destroy]
  end
  resources :public_recipes, only: [ :index ]
  resources :public_menus, only: %i[index show] do
    member do
      post :adopt
    end
  end
  resources :public_exercise_routines, only: %i[index show] do
    member do
      post :adopt
    end
  end
  resources :public_phase_programs, only: %i[index show] do
    member do
      post :adopt
    end
  end
  namespace :admin do
    resources :recipes, only: [] do
      member do
        patch :revoke_public_share
      end
    end
    resources :menus, only: [] do
      member do
        patch :revoke_public_share
      end
    end
    resources :exercise_routines, only: [] do
      member do
        patch :revoke_public_share
      end
    end
    resources :phase_programs, only: [] do
      member do
        patch :revoke_public_share
      end
    end
  end
  namespace :identity do
    resource :email,              only: [ :edit, :update ]
    resource :email_verification, only: [ :show, :create ]
    resource :password_reset,     only: [ :new, :edit, :create, :update ]
  end
  root "home#index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
