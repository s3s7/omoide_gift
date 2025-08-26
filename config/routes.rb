Rails.application.routes.draw do
  root "static_pages#top"

  devise_for :users, controllers: {
    omniauth_callbacks: "omniauth_callbacks"
  }
  # User mypage routes
  get "mypage", to: "users#show"
  get "mypage/edit", to: "users#edit"
  patch "mypage", to: "users#update"

  # お気に入り一覧
  get "favorites", to: "favorites#index"

  # 管理者専用機能
  namespace :admin do
    # 管理者ダッシュボード
    root "dashboard#index"
    get "dashboard", to: "dashboard#index"

    # ユーザー管理
    resources :users, only: [ :index, :show, :edit, :update ] do
      member do
        patch :toggle_role  # 管理者権限の切り替え
        patch :toggle_status  # アカウント有効/無効の切り替え（将来的な拡張用）
      end
    end

    # ギフト記録管理
    resources :gift_records, only: [ :index, :show, :edit, :update, :destroy ] do
      member do
        patch :toggle_public  # 公開/非公開の切り替え
      end
    end

    # ギフト相手管理
    resources :gift_people, only: [ :index, :show, :edit, :update, :destroy ]

    # コメント管理
    resources :comments, only: [ :index, :show, :edit, :update, :destroy ]

    # 基本データ管理
    resources :events, except: [ :show ]
    resources :relationships, except: [ :show ]
    resources :gift_item_categories, except: [ :show ]

    # システム統計
    get "statistics", to: "statistics#index"
  end

  # Static pages for footer links and navigation
  get "how_to_use", to: "static_pages#how_to_use"
  get "terms", to: "static_pages#terms"
  get "privacy", to: "static_pages#privacy"
  get "contact", to: "static_pages#contact"

  resources :gift_records do
    collection do
      get :private_index
      get :autocomplete
      post :dismiss_share
    end
    # お気に入り機能
    member do
      post :toggle_favorite, to: "favorites#toggle"
    end
    # コメント機能
    resources :comments, except: [ :index, :show ]
  end
  resources :gift_people do
    collection do
      get :autocomplete
    end
  end

  # 記念日リマインダー機能
  resources :reminds do
    member do
      patch :resend  # 通知リセット用
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
end
